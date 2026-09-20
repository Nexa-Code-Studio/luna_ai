import asyncio
import logging
import os
import time
from collections.abc import AsyncGenerator
from dataclasses import dataclass
from typing import Any, List, Optional

from ai.factories.llm_factory import LLMFactory
from ai.factories.tts_factory import TTSFactory
from ai.interfaces.embedding import BaseEmbeddingProvider
from ai.interfaces.llm import BaseLLMProvider, LLMMessage
from ai.interfaces.stt import BaseSTTProvider
from ai.interfaces.tts import BaseTTSProvider
from ai.interfaces.vector_store import BaseVectorStore
from ai.services.embedding_service import DefaultEmbeddingProvider
from ai.services.emotion_service import EmotionService
from ai.services.rag import RAGService
from ai.services.risk_assessment_service import RiskAssessmentService
from ai.services.safety_gate import SafetyGate
from ai.services.symptom_service import SymptomService
from ai.vector_store.qdrant import QdrantVectorStore
from packages.shared.config import settings
from shared.domain_types import (
    EmotionDetectionResult,
    LLMMode,
    MentalHealthSeverity,
    ProtocolAction,
    ResponseMode,
    RiskAssessmentInput,
    RiskAssessmentOutput,
    SafetyGateInput,
    SafetyPolicyDecision,
    SymptomExtractionResult,
)

logger = logging.getLogger(__name__)

CRISIS_SOP_MESSAGE = (
    "Aku mendengar betapa berat dan melelahkannya apa yang sedang kamu rasakan saat ini. "
    "Ketahuilah bahwa kamu sangat berharga dan kamu tidak harus menanggung ini sendirian. "
    "Tolong segera hubungi layanan darurat kesehatan mental bebas pulsa Kemenkes di 119 ekstensi 8, "
    "atau Hotline LISA di 0811-3855-472. "
    "Aku di sini untuk mendengarkan, tapi tolong hubungi orang terdekat atau tenaga profesional sekarang juga ya."
)


@dataclass
class OrchestratedTurnResult:
    """Kontainer hasil pemrosesan giliran percakapan yang lengkap dengan audit keamanan & metadata."""
    user_text: str
    emotion: EmotionDetectionResult
    symptoms: SymptomExtractionResult
    risk_output: RiskAssessmentOutput
    safety_decision: SafetyPolicyDecision
    rag_items: list[dict[str, Any]]
    is_crisis: bool
    final_system_prompt: str
    token_stream: AsyncGenerator[str, None]
    execution_time_ms: float = 0.0


class AIOrchestrator:
    """Production Multi-Stage Counseling Orchestrator for Luna AI.

    Mengorkestrasi seluruh alur konseling:
    1. Emotion Ingestion (Voice Audio / Text Sentiment)
    2. Symptom Extraction (WHO-EASE Taxonomy)
    3. Risk Assessment & Safety Gate (Triage & Crisis Evaluation)
    4. RAG Retrieval from Qdrant (Mental Health Psychoeducation Knowledge)
    5. Empathetic Prompt Formulation
    6. LLM Streaming / Crisis Template Execution
    """

    def __init__(
        self,
        stt_provider: Optional[BaseSTTProvider] = None,
        llm_provider: Optional[BaseLLMProvider] = None,
        tts_provider: Optional[BaseTTSProvider] = None,
        emotion_service: Optional[EmotionService] = None,
        symptom_service: Optional[SymptomService] = None,
        risk_service: Optional[RiskAssessmentService] = None,
        safety_gate: Optional[SafetyGate] = None,
        rag_service: Optional[RAGService] = None,
        vector_store: Optional[BaseVectorStore] = None,
        embedding_provider: Optional[BaseEmbeddingProvider] = None,
        rag_timeout_seconds: float = 0.4,
    ):
        self.stt_provider = stt_provider
        self.llm_provider = llm_provider or LLMFactory.get_provider()
        self.tts_provider = tts_provider or TTSFactory.get_provider()
        self.emotion_service = emotion_service or EmotionService()
        self.symptom_service = symptom_service or SymptomService()
        self.risk_service = risk_service or RiskAssessmentService()
        self.safety_gate = safety_gate or SafetyGate()
        self.rag_timeout_seconds = rag_timeout_seconds

        # Inisialisasi komponen RAG Qdrant
        if rag_service and embedding_provider:
            self.rag_service = rag_service
            self.embedding_provider = embedding_provider
            self.vector_store = vector_store
        else:
            try:
                qdrant_url = getattr(settings, "QDRANT_URL", "http://localhost:6333")
                self.vector_store = vector_store or QdrantVectorStore(url=qdrant_url)
                self.embedding_provider = embedding_provider or DefaultEmbeddingProvider()
                self.rag_service = rag_service or RAGService(vector_store=self.vector_store)
            except Exception as e:
                logger.warning(f"⚠️ [ORCHESTRATOR] RAG components initialization deferred/fallback: {e}")
                self.rag_service = None
                self.embedding_provider = None
                self.vector_store = None

    def _infer_emotion_from_text(self, text: str) -> EmotionDetectionResult:
        """Heuristic sentiment fallback jika audio fisik belum tersedia/gagal."""
        text_lower = text.lower()
        if any(w in text_lower for w in ["senang", "bahagia", "suka", "lega", "puas", "bangga", "bersyukur"]):
            primary = "happy"
            confidence = 0.88
        elif any(w in text_lower for w in ["cemas", "takut", "khawatir", "stres", "panik", "deg-degan", "gemetar"]):
            primary = "fearful"
            confidence = 0.85
        elif any(w in text_lower for w in ["sedih", "kecewa", "menangis", "lelah", "hancur", "putus asa", "capek"]):
            primary = "sad"
            confidence = 0.80
        elif any(w in text_lower for w in ["marah", "kesal", "benci", "jengkel", "geram"]):
            primary = "angry"
            confidence = 0.82
        elif any(w in text_lower for w in ["kaget", "terkejut", "syok"]):
            primary = "surprised"
            confidence = 0.75
        else:
            primary = "neutral"
            confidence = 0.90

        scores = {k: (confidence if k == primary else 0.02) for k in [
            "angry", "disgusted", "fearful", "happy", "neutral", "other", "sad", "surprised", "unknown"
        ]}

        return EmotionDetectionResult(
            primary_emotion=primary,
            confidence=confidence,
            scores=scores,
            model_used="emotion2vec_plus_large (text-heuristic)",
            latency_ms=0.5,
        )

    def _detect_emotion(self, text: str, audio_path: Optional[str] = None) -> EmotionDetectionResult:
        """Mendeteksi emosi dari file audio jika ada, atau fallback ke analisis teks."""
        if audio_path and os.path.exists(audio_path):
            try:
                logger.info(f"🎙️ [ORCHESTRATOR] Running EmotionService on audio '{audio_path}'")
                return self.emotion_service.predict(audio_path)
            except Exception as e:
                logger.warning(f"⚠️ [ORCHESTRATOR] Voice emotion detection error, fallback to text: {e}")

        return self._infer_emotion_from_text(text)

    async def _fetch_rag_context(self, query_text: str) -> list[dict[str, Any]]:
        """Mengambil dokumen pengetahuan mental health dari Qdrant dengan batas timeout ketat."""
        if not self.rag_service or not self.embedding_provider:
            return []

        try:
            async def _search():
                query_vector = await self.embedding_provider.embed_query(query_text)
                return await self.rag_service.search_relevant_context(
                    collection_name="knowledge",
                    query_embedding=query_vector,
                    limit=2,
                )

            items = await asyncio.wait_for(_search(), timeout=self.rag_timeout_seconds)
            logger.info(f"📚 [ORCHESTRATOR] RAG retrieved {len(items)} knowledge chunks from Qdrant")
            return items
        except asyncio.TimeoutError:
            logger.warning(f"⏳ [ORCHESTRATOR] Qdrant RAG search timed out after {self.rag_timeout_seconds}s (skipped for latency)")
            return []
        except Exception as e:
            logger.warning(f"⚠️ [ORCHESTRATOR] RAG search error: {e}")
            return []

    def _compose_system_prompt(
        self,
        emotion: EmotionDetectionResult,
        safety_decision: SafetyPolicyDecision,
        rag_items: list[dict[str, Any]],
        dass_scores: Optional[dict[str, Any]] = None,
    ) -> str:
        """Menyusun system prompt empati konseling dinamis berdasarkan hasil observasi multi-agent."""
        prompt = (
            "Kamu adalah Luna, seorang konselor pendamping kesehatan mental AI yang ramah, hangat, dan penuh empati.\n"
            f"Kondisi emosi pengguna yang terobservasi: '{emotion.primary_emotion}' (confidence: {int(emotion.confidence * 100)}%).\n"
            f"Tingkat risiko keselamatan: '{safety_decision.risk_level}'. Kebijakan respon: '{safety_decision.response_policy}'.\n"
        )

        if dass_scores:
            dep = dass_scores.get("depression", 0)
            anx = dass_scores.get("anxiety", 0)
            st = dass_scores.get("stress", 0)
            if dep > 0 or anx > 0 or st > 0:
                prompt += (
                    f"Profil Psikometris Terkini Pengguna (DASS-21): Depresi (skor {dep}), Kecemasan (skor {anx}), Stres (skor {st}). "
                    f"Selaraskan empati dan kehangatanmu sesuai kondisi kerentanan emosional ini.\n"
                )

        if rag_items:
            knowledge_blocks = []
            for item in rag_items:
                title = item.get("title", "Pengetahuan Konseling")
                content = item.get("content", "")[:180]
                knowledge_blocks.append(f"- {title}: {content}")
            prompt += f"\nGunakan referensi pengetahuan konseling berikut jika relevan secara alami (jangan membaca kaku):\n" + "\n".join(knowledge_blocks) + "\n"

        prompt += (
            "\nPedoman Respon:\n"
            "1. Berbicaralah dalam Bahasa Indonesia yang santun, akrab, dan hangat (seperti teman bicara yang penuh pengertian).\n"
            "2. Berikan respon yang ringkas dan nyaman didengar (1-3 kalimat) karena ini adalah percakapan suara real-time.\n"
            "3. Validasi perasaan pengguna terlebih dahulu sebelum memberikan pandangan menenangkan atau pertanyaan terbuka ringan.\n"
            "4. Eksplorasi DASS-21 Non-Frontal: Saat pengguna mengungkapkan stres, cemas, atau sedih, ajukan pertanyaan terbuka reflektif yang mengeksplorasi sensasi fisik/otonomik (napas, detak jantung, ketegangan fisik) atau suasana hati (hilang antusias, rasa hampa) secara alami. DILARANG menyebut angka atau nomor butir kuesioner.\n"
            "5. Format Teks untuk Suara (TTS): Tulis dalam teks lisan murni. DILARANG menggunakan tanda bintang markdown (* atau **), simbol garis bawah, tanda pagar (#), bullet points (-), atau emoji. Tulis kata secara lengkap tanpa singkatan (misal: tulis 'dan lain-lain', bukan 'dll.').\n"
            "6. Gunakan tanda koma (,) dan titik (.) secara teratur dan wajar untuk mengatur jeda napas pelafalan suara.\n"
            "7. Jangan mendiagnosis penyakit mental secara klinis."
        )
        return prompt

    async def prepare_turn(
        self,
        user_text: str,
        conversation_history: Optional[list[LLMMessage]] = None,
        audio_path: Optional[str] = None,
        dass_scores: Optional[dict[str, Any]] = None,
    ) -> OrchestratedTurnResult:
        """Memproses seluruh evaluasi orkestrasi (Emosi -> Gejala -> Risiko -> RAG)

        dan mengembalikan OrchestratedTurnResult yang siap di-stream.
        """
        start_t = time.perf_counter()
        logger.info(f"🚀 [ORCHESTRATOR TURN START] User text: \"{user_text}\"")

        # 1. Deteksi Emosi (Voice atau Teks)
        emotion_res = self._detect_emotion(user_text, audio_path=audio_path)

        # 2. Ekstraksi Gejala
        symptom_res = self.symptom_service.extract_symptoms(user_text)

        # 3. Penilaian Risiko & Gerbang Keamanan (Memperhitungkan Profil DASS-21)
        risk_input = RiskAssessmentInput(
            user_text=user_text,
            symptom_result=symptom_res,
            emotion_result=emotion_res,
            dass_scores=dass_scores,
        )
        risk_output = self.risk_service.assess(risk_input)

        safety_input = SafetyGateInput(risk_output=risk_output)
        safety_decision = self.safety_gate.evaluate_policy(safety_input)

        logger.info(
            f"🛡️ [ORCHESTRATOR SAFETY] Risk Level: {safety_decision.risk_level.upper()}, "
            f"Policy: {safety_decision.response_policy}, Mode: {safety_decision.mode}"
        )

        # 4. Evaluasi Skenario Krisis
        is_crisis = ( 
            safety_decision.mode == ResponseMode.CRISIS
            or safety_decision.llm_mode == LLMMode.NONE
            or safety_decision.response_policy in [ProtocolAction.IMMEDIATE_HOTLINE, ProtocolAction.CRISIS_REFERRAL]
        )

        if is_crisis:
            logger.warning("🚨 [ORCHESTRATOR CRISIS ACTIVATED] Safety Gate triggered crisis intervention!")

            async def _crisis_stream_generator() -> AsyncGenerator[str, None]:
                # Stream kalimat-kalimat krisis secara teratur
                words = CRISIS_SOP_MESSAGE.split(" ")
                for i in range(0, len(words), 3):
                    chunk = " ".join(words[i:i + 3]) + " "
                    yield chunk
                    await asyncio.sleep(0.02)

            exec_time = (time.perf_counter() - start_t) * 1000
            return OrchestratedTurnResult(
                user_text=user_text,
                emotion=emotion_res,
                symptoms=symptom_res,
                risk_output=risk_output,
                safety_decision=safety_decision,
                rag_items=[],
                is_crisis=True,
                final_system_prompt="[CRISIS SOP PROTOCOL ACTIVATED]",
                token_stream=_crisis_stream_generator(),
                execution_time_ms=round(exec_time, 2),
            )

        # 5. RAG Retrieval jika diizinkan oleh Safety Policy
        rag_items: list[dict[str, Any]] = []
        if safety_decision.allow_normal_rag:
            rag_items = await self._fetch_rag_context(user_text)

        # 6. Formulasi Dynamic Empathetic Prompt
        system_prompt = self._compose_system_prompt(
            emotion_res, safety_decision, rag_items, dass_scores=dass_scores
        )

        # 7. Siapkan Message History
        messages: list[LLMMessage] = [LLMMessage(role="system", content=system_prompt)]
        if conversation_history:
            for msg in conversation_history:
                if msg.role != "system":
                    messages.append(msg)

        # Pastikan user message saat ini ada di akhir
        if not messages or messages[-1].role != "user" or messages[-1].content != user_text:
            messages.append(LLMMessage(role="user", content=user_text))

        # 8. Siapkan Token Stream dari LLM Provider
        token_stream = self.llm_provider.stream_response(messages)

        exec_time = (time.perf_counter() - start_t) * 1000
        logger.info(f"✅ [ORCHESTRATOR TURN READY] Ready in {exec_time:.2f}ms (Emosi: {emotion_res.primary_emotion})")

        return OrchestratedTurnResult(
            user_text=user_text,
            emotion=emotion_res,
            symptoms=symptom_res,
            risk_output=risk_output,
            safety_decision=safety_decision,
            rag_items=rag_items,
            is_crisis=False,
            final_system_prompt=system_prompt,
            token_stream=token_stream,
            execution_time_ms=round(exec_time, 2),
        )

    async def stream_orchestrated_turn(
        self,
        user_text: str,
        conversation_history: Optional[list[LLMMessage]] = None,
        audio_path: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """Convenience generator yang langsung mengalirkan token balasan hasil orkestrasi."""
        turn = await self.prepare_turn(
            user_text=user_text,
            conversation_history=conversation_history,
            audio_path=audio_path,
        )
        async for token in turn.token_stream:
            yield token

    async def process_turn(
        self,
        user_input: str | bytes,
        history: Optional[list[LLMMessage]] = None,
        context: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        """Eksekusi non-streaming (berguna untuk endpoint REST, worker, dan automated tests)."""
        text_input = user_input if isinstance(user_input, str) else "[Voice Audio]"
        turn = await self.prepare_turn(user_text=text_input, conversation_history=history)

        full_text_list = []
        async for token in turn.token_stream:
            full_text_list.append(token)
        response_text = "".join(full_text_list).strip()

        return {
            "input_text": text_input,
            "response_text": response_text,
            "emotion": turn.emotion.model_dump(),
            "symptoms": turn.symptoms.model_dump(),
            "risk_level": turn.safety_decision.risk_level,
            "safety_policy": str(turn.safety_decision.response_policy),
            "is_crisis": turn.is_crisis,
            "rag_items": turn.rag_items,
            "system_prompt": turn.final_system_prompt,
            "execution_time_ms": turn.execution_time_ms,
        }

    async def process_stream_turn(
        self,
        audio_stream: AsyncGenerator[bytes, None],
    ) -> AsyncGenerator[bytes, None]:
        """Placeholder interface streaming audio murni."""
        yield b""
