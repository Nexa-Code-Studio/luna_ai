import asyncio
import json
import os
import sys
import time
from pathlib import Path

# Add project root and packages to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
sys.path.insert(0, str(PROJECT_ROOT / "packages"))

from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.interfaces.llm import LLMMessage
from packages.ai.services.embedding_service import DefaultEmbeddingProvider
from packages.ai.services.emotion_service import EmotionService
from packages.ai.services.knowledge_ingestion_service import KnowledgeIngestionService
from packages.ai.services.rag import RAGService
from packages.ai.services.risk_assessment_service import RiskAssessmentService
from packages.ai.services.safety_gate import SafetyGate
from packages.ai.vector_store.qdrant import QdrantVectorStore
from packages.shared.config import settings
from shared.domain_types import (
    MentalHealthKnowledgeItem,
    RiskAssessmentInput,
    SafetyGateInput,
    SymptomExtractionResult,
)
from tests.test_orchestration.pdf_reporter import generate_pdf_report


AUDIO_STT_MAP = {
    "1.wav": "Kan aku udah bilang berkali-kali, tapi kamu masih melakukan hal yang sama. Aku rasanya stres dan dikecewakan.",
    "2.wav": "Aku sebenarnya takut banget kalau sesuatu yang buruk tuh bakal terjadi... Aku merasa cemas dan panik secara fisik.",
    "3.wav": "Hari ini aku pergi ke kampus dan mengikuti kegiatan seperti biasa.",
    "4.wav": "Aku akhir-akhir ini rasanya capek dan sedih terus. Merasa tidak ada semangat dan kehilangan harapan.",
    "5.wav": "Wah, akhirnya selesai juga! Aku senang banget hari ini!",
}


async def run_orchestration_pipeline():
    print("=" * 60)
    print(" 🚀 E2E Orchestration Pipeline Test Runner (Luna AI)")
    print("=" * 60)

    audio_dir = PROJECT_ROOT / "tests" / "test_emotion"
    audio_files = [f for f in ["1.wav", "2.wav", "3.wav", "4.wav", "5.wav"] if (audio_dir / f).exists()]

    if not audio_files:
        print(f"❌ Error: Tidak ada file audio WAV ditemukan di {audio_dir}")
        return

    # Initialize Services
    print("\n📦 Initializing Core Pipeline Services...")
    
    # 1. Emotion Service
    print(" - Loading EmotionService (emotion2vec_plus_large)...")
    emotion_service = EmotionService()
    
    # 2. Risk & Safety Gate
    risk_service = RiskAssessmentService()
    safety_gate = SafetyGate()
    
    # 3. Vector Store, Embedding & RAG
    qdrant_url = getattr(settings, "QDRANT_URL", "http://localhost:6333")
    print(f" - Connecting to Qdrant Vector DB: '{qdrant_url}'...")
    vector_store = QdrantVectorStore(url=qdrant_url)
    embedding_provider = DefaultEmbeddingProvider()
    rag_service = RAGService(vector_store=vector_store)
    ingestion_service = KnowledgeIngestionService(vector_store, embedding_provider)

    # Auto-seed Qdrant Knowledge Base
    seed_json_path = PROJECT_ROOT / "packages" / "ai" / "seeders" / "mental_health_knowledge.json"
    if seed_json_path.exists():
        print(" - Ingesting Mental Health Knowledge Base into Qdrant ('knowledge' collection)...")
        try:
            with open(seed_json_path, "r", encoding="utf-8") as f:
                raw_items = json.load(f)
            items = [MentalHealthKnowledgeItem(**item) for item in raw_items]
            count = await ingestion_service.ingest_items(items, collection_name="knowledge")
            print(f"   -> Successfully ingested {count} knowledge items into Qdrant.")
        except Exception as e:
            print(f"   ⚠️ Knowledge ingestion warning: {e}")

    # 4. LLM Provider
    llm_provider_name = settings.LLM_PROVIDER or "deepseek"
    print(f" - Loading LLM Provider from .env: '{llm_provider_name}'...")
    llm_provider = LLMFactory.get_provider(provider_type=llm_provider_name)

    results = []

    total_pipeline_start = time.perf_counter()

    for idx, filename in enumerate(audio_files, 1):
        audio_path = str(audio_dir / filename)
        stt_text = AUDIO_STT_MAP.get(filename, "Teks sampel audio")

        print(f"\n------------------------------------------------------------")
        print(f" 🎵 [{idx}/{len(audio_files)}] Processing: {filename}")
        print(f" 📝 STT Transcript: \"{stt_text}\"")
        print(f"------------------------------------------------------------")

        t_sample_start = time.perf_counter()

        # Step 1: Emotion Detection
        print(" [1/4] Running Voice Emotion Detection...")
        t_emo_start = time.perf_counter()
        try:
            emo_res = emotion_service.predict(audio_path)
            emo_latency = (time.perf_counter() - t_emo_start) * 1000
            primary_emotion = emo_res.primary_emotion
            emotion_confidence = emo_res.confidence
            print(f"   -> Emotion: {primary_emotion} ({emotion_confidence*100:.2f}%) in {emo_latency:.2f} ms")
        except Exception as e:
            print(f"   ⚠️ Emotion service warning: {e}")
            emo_res = None
            primary_emotion = "neutral"
            emotion_confidence = 0.5
            emo_latency = 0.0

        # Step 2: Risk Assessment & Safety Gate
        print(" [2/4] Running Risk Assessment & Safety Gate...")
        t_risk_start = time.perf_counter()
        risk_input = RiskAssessmentInput(
            user_text=stt_text,
            symptom_result=SymptomExtractionResult(extracted_symptoms=[]),
            emotion_result=emo_res
        )
        risk_output = risk_service.assess(risk_input)
        safety_input = SafetyGateInput(risk_output=risk_output)
        safety_decision = safety_gate.evaluate_policy(safety_input)
        risk_latency = (time.perf_counter() - t_risk_start) * 1000
        print(f"   -> Risk Level: {safety_decision.risk_level.upper()}, Policy: {safety_decision.response_policy}")

        # Step 3: RAG Retrieval from Qdrant
        print(" [3/4] Running RAG Vector Search (Qdrant)...")
        t_rag_start = time.perf_counter()
        rag_context_items = []
        try:
            query_vector = await embedding_provider.embed_query(stt_text)
            rag_context_items = await rag_service.search_relevant_context(
                collection_name="knowledge",
                query_embedding=query_vector,
                limit=3
            )
            rag_latency = (time.perf_counter() - t_rag_start) * 1000
            print(f"   -> RAG Found {len(rag_context_items)} context items in {rag_latency:.2f} ms")
            for r_idx, r_item in enumerate(rag_context_items, 1):
                title = r_item.get("title", "")
                print(f"      [{r_idx}] {title}")
        except Exception as e:
            rag_latency = (time.perf_counter() - t_rag_start) * 1000
            print(f"   ⚠️ RAG search fallback/warning: {e} ({rag_latency:.2f} ms)")

        # Step 4: System Prompt Formulation & LLM Response (without TTS)
        print(f" [4/4] Generating AI Response via LLM Provider '{llm_provider_name}'...")
        
        system_prompt = (
            "Kamu adalah Luna, seorang konselor kesehatan mental berbasis AI yang ramah, hangat, dan penuh empati.\n"
            f"Kondisi emosi pengguna terdeteksi dari nada suara: '{primary_emotion}' (confidence: {emotion_confidence*100:.1f}%).\n"
            f"Tingkat risiko keselamatan: '{safety_decision.risk_level}'.\n"
        )
        if rag_context_items:
            rag_text = "\n".join([f"- {item.get('title', '')}: {item.get('content', '')[:150]}..." for item in rag_context_items])
            system_prompt += f"\nGunakan referensi pengetahuan konseling berikut jika relevan:\n{rag_text}\n"

        system_prompt += "\nResponlah pengguna secara alami, hangat, dan berempati dalam Bahasa Indonesia singkat (1-3 kalimat)."

        messages = [
            LLMMessage(role="system", content=system_prompt),
            LLMMessage(role="user", content=stt_text)
        ]

        t_llm_start = time.perf_counter()
        token_usage = {}
        try:
            llm_res = await llm_provider.generate_response(messages)
            if hasattr(llm_res, "content"):
                llm_text = llm_res.content
            else:
                llm_text = str(llm_res)

            llm_latency = (time.perf_counter() - t_llm_start) * 1000
            
            if hasattr(llm_res, "raw_response") and isinstance(llm_res.raw_response, dict):
                usage = llm_res.raw_response.get("usage", {})
                token_usage = {
                    "prompt_tokens": usage.get("prompt_tokens", "N/A"),
                    "completion_tokens": usage.get("completion_tokens", "N/A"),
                    "total_tokens": usage.get("total_tokens", "N/A"),
                }
            print(f"   -> LLM Response ({llm_latency:.2f} ms): \"{llm_text}\"")
        except Exception as e:
            llm_latency = (time.perf_counter() - t_llm_start) * 1000
            llm_text = f"Error generating response: {e}"
            print(f"   ❌ LLM Generation Failed: {e}")

        total_sample_latency = (time.perf_counter() - t_sample_start) * 1000

        results.append({
            "filename": filename,
            "stt_text": stt_text,
            "emotion": primary_emotion,
            "emotion_confidence": emotion_confidence,
            "emotion_latency_ms": emo_latency,
            "risk_level": safety_decision.risk_level,
            "safety_policy": str(safety_decision.response_policy),
            "rag_context": rag_context_items,
            "rag_latency_ms": rag_latency,
            "system_prompt": system_prompt,
            "llm_response": llm_text,
            "llm_latency_ms": llm_latency,
            "token_usage": token_usage,
            "total_latency_ms": total_sample_latency,
        })

    total_pipeline_time = time.perf_counter() - total_pipeline_start

    # Summary Metrics Calculation
    avg_emo = sum(r["emotion_latency_ms"] for r in results) / len(results) if results else 0
    avg_rag = sum(r["rag_latency_ms"] for r in results) / len(results) if results else 0
    avg_llm = sum(r["llm_latency_ms"] for r in results) / len(results) if results else 0
    avg_total = sum(r["total_latency_ms"] for r in results) / len(results) if results else 0

    summary_metrics = {
        "total_files": len(results),
        "llm_provider": llm_provider_name,
        "llm_model": getattr(settings, "LLM_MODEL", "default"),
        "avg_emotion_latency": avg_emo,
        "avg_rag_latency": avg_rag,
        "avg_llm_latency": avg_llm,
        "avg_total_latency": avg_total,
        "total_pipeline_time_s": total_pipeline_time,
    }

    # Generate PDF Report
    pdf_path = str(PROJECT_ROOT / "tests" / "test_orchestration" / "orchestration_test_report.pdf")
    generate_pdf_report(results=results, summary_metrics=summary_metrics, output_path=pdf_path)

    print("\n============================================================")
    print(" 🎉 Pengujian Orkestrasi Selesai!")
    print(f" 📄 Laporan PDF Telah Dibuat: {pdf_path}")
    print("============================================================")


if __name__ == "__main__":
    asyncio.run(run_orchestration_pipeline())
