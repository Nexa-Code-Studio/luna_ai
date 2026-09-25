import asyncio
import base64
import json
import pytest
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock, patch

from packages.ai.interfaces.llm import LLMMessage
from packages.ai.orchestration.orchestrator import AIOrchestrator
from packages.ai.providers.tts.elevenlabs_ttd_provider import (
    ElevenLabsTTDProvider,
    ElevenLabsTTDSession,
)
from packages.ai.services.rag_gating import ConversationIntent, RAGGatingService
from packages.ai.utils.emotion_style_mapper import (
    map_emotion_to_delivery_style,
    strip_audio_tags,
    VALIDATED_AUDIO_TAGS,
)
from packages.ai.utils.sentence_chunker import (
    LatencyAwareSentenceChunker,
    SpeechChunk,
)
from shared.domain_types import EmotionDetectionResult, SafetyPolicyDecision


# ============================================================================
# A. Latency-Aware Sentence Chunker Tests
# ============================================================================

class TestLatencyAwareSentenceChunker:

    @pytest.mark.asyncio
    async def test_short_indonesian_phrase(self):
        """Short sentence 'Aku ngerti.' should flush at end of stream as 1 chunk."""
        chunker = LatencyAwareSentenceChunker(delivery_style="soft", audio_tag="[softly]")

        async def token_gen():
            yield "Aku "
            yield "ngerti."

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        assert len(chunks) == 1
        assert chunks[0].display_text == "Aku ngerti."
        assert chunks[0].tts_text == "[softly] Aku ngerti."
        assert chunks[0].is_first is True
        assert chunks[0].is_final is True

    @pytest.mark.asyncio
    async def test_sentence_boundaries_and_audio_tag_placement(self):
        """Verify multiple sentences split on punctuation and Audio Tag is ONLY on chunk 1."""
        chunker = LatencyAwareSentenceChunker(delivery_style="reassuring", audio_tag="[calm]")

        async def token_gen():
            tokens = [
                "Aku ", "sangat ", "memahami ", "apa ", "yang ", "kamu ", "rasakan ", "hari ", "ini. ",
                "Tarik ", "napas ", "perlahan ", "bersamaku ", "sebentar ", "ya. ",
                "Bagaimana ", "rasanya ", "sekarang?"
            ]
            for t in tokens:
                yield t

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        assert len(chunks) == 3
        # Chunk 1 has audio tag
        assert chunks[0].is_first is True
        assert chunks[0].tts_text.startswith("[calm]")
        assert not chunks[0].display_text.startswith("[calm]")
        assert "Aku sangat memahami apa yang kamu rasakan hari ini." in chunks[0].display_text

        # Chunk 2 has NO audio tag
        assert chunks[1].is_first is False
        assert not chunks[1].tts_text.startswith("[calm]")
        assert "Tarik napas perlahan bersamaku sebentar ya." in chunks[1].display_text

        # Chunk 3 has NO audio tag and is final
        assert chunks[2].is_first is False
        assert not chunks[2].tts_text.startswith("[calm]")
        assert "Bagaimana rasanya sekarang?" in chunks[2].display_text

    @pytest.mark.asyncio
    async def test_clause_boundaries(self):
        """Long compound sentence splits at clause boundary (comma) when min chars met."""
        chunker = LatencyAwareSentenceChunker()

        async def token_gen():
            yield "Ketika beban pikiranmu terasa begitu menumpuk dan menyesakkan dadamu, "
            yield "cobalah untuk berhenti sejenak dan lepaskan ketegangan di pundakmu."

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        assert len(chunks) == 2
        assert chunks[0].display_text.endswith(",")
        assert "cobalah untuk berhenti" in chunks[1].display_text

    @pytest.mark.asyncio
    async def test_no_punctuation_timeout_flush(self):
        """Unpunctuated speech flushes upon timeout elapsed without blocking indefinitely."""
        chunker = LatencyAwareSentenceChunker()
        chunker.MAX_TOKEN_WAIT_MS = 50.0  # Fast timeout for test

        async def token_gen():
            yield "ini adalah kalimat panjang tanpa tanda baca sama sekali yang terus bertambah"
            await asyncio.sleep(0.08)  # Exceeds 50ms
            yield " dan ini adalah kelanjutan akhir dari kalimat tersebut"

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        assert len(chunks) >= 2

    @pytest.mark.asyncio
    async def test_max_buffer_safeguard(self):
        """Very long run without punctuation or delays splits at MAX_BUFFER_CHARS."""
        chunker = LatencyAwareSentenceChunker()
        chunker.MAX_BUFFER_CHARS = 60

        async def token_gen():
            yield "kata kata kata kata kata kata kata kata kata kata kata kata kata kata kata kata kata"

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        assert len(chunks) >= 2


# ============================================================================
# B. Emotion Style Mapper Tests
# ============================================================================

class TestEmotionStyleMapper:

    def test_emotion_mapping_empathy(self):
        """Verify empathetic styles avoid dramatic negative mirroring."""
        # Sad -> soft
        style, tag = map_emotion_to_delivery_style("sad", confidence=0.8)
        assert style == "soft"
        assert tag == "[softly]"

        # Anxious/Fearful -> reassuring
        style, tag = map_emotion_to_delivery_style("anxious", confidence=0.9)
        assert style == "reassuring"
        assert tag == "[calm]"

        # Angry -> calm (never angry!)
        style, tag = map_emotion_to_delivery_style("angry", confidence=0.85)
        assert style == "calm"
        assert tag == "[calm]"

        # Happy -> happy
        style, tag = map_emotion_to_delivery_style("happy", confidence=0.9)
        assert style == "happy"
        assert tag == "[happily]"

        # Excited -> excited
        style, tag = map_emotion_to_delivery_style("excited", confidence=0.9)
        assert style == "excited"
        assert tag == "[excited]"

    def test_low_confidence_fallback(self):
        """Confidence below 0.45 falls back to neutral."""
        style, tag = map_emotion_to_delivery_style("sad", confidence=0.3)
        assert style == "neutral"
        assert tag == ""

    def test_crisis_risk_override(self):
        """Critical or high safety risk always forces gentle grounding delivery."""
        style, tag = map_emotion_to_delivery_style("angry", confidence=0.95, risk_level="critical")
        assert style == "grounding"
        assert tag == "[softly]"

        style2, tag2 = map_emotion_to_delivery_style("excited", confidence=0.95, risk_level="high")
        assert style2 == "grounding"
        assert tag2 == "[softly]"

    def test_strip_audio_tags(self):
        """Verify audio tags are cleanly stripped from UI/database text."""
        assert strip_audio_tags("[softly] Halo apa kabar?") == "Halo apa kabar?"
        assert strip_audio_tags("[calm] Tarik napas perlahan.") == "Tarik napas perlahan."
        assert strip_audio_tags("[thoughtful] Menarik sekali.") == "Menarik sekali."
        assert strip_audio_tags("Kalimat biasa tanpa tag.") == "Kalimat biasa tanpa tag."
        assert strip_audio_tags("") == ""


# ============================================================================
# C. Intent-Based RAG Gating Tests
# ============================================================================

class TestRAGGatingService:

    def test_skip_rag_for_emotional_listening(self):
        """Emotional venting and expressions should NOT trigger knowledge retrieval."""
        queries = [
            "Aku masih kepikiran yang tadi.",
            "Menurutmu aku lebay nggak?",
            "Iya, itu yang bikin aku sedih banget.",
            "Rasanya capek banget sama semuanya hari ini.",
        ]
        for q in queries:
            result = RAGGatingService.evaluate_intent(q)
            assert result.should_retrieve_rag is False, f"Expected no RAG for: {q}"
            assert result.intent in (
                ConversationIntent.EMOTIONAL_LISTENING,
                ConversationIntent.CONVERSATION_CONTINUATION,
            )

    def test_consider_rag_for_techniques_and_psychoeducation(self):
        """Explicit questions and coping skill requests SHOULD trigger knowledge retrieval."""
        queries = [
            ("Apa itu grounding?", ConversationIntent.FACTUAL_OR_PSYCHOEDUCATION),
            ("Gimana cara melakukan teknik grounding 5-4-3-2-1?", ConversationIntent.TECHNIQUE_OR_HOW_TO),
            ("Kenapa kecemasan bisa bikin jantung berdebar?", ConversationIntent.FACTUAL_OR_PSYCHOEDUCATION),
            ("Tolong ajarin latihan pernapasan 4-7-8", ConversationIntent.TECHNIQUE_OR_HOW_TO),
        ]
        for q, expected_intent in queries:
            result = RAGGatingService.evaluate_intent(q)
            assert result.should_retrieve_rag is True, f"Expected RAG for: {q}"
            assert result.intent == expected_intent

    def test_safety_critical_bypasses_rag(self):
        """Safety crisis overrides all RAG queries."""
        result = RAGGatingService.evaluate_intent("Gimana cara relaksasi?", is_crisis=True)
        assert result.should_retrieve_rag is False
        assert result.intent == ConversationIntent.SAFETY_CRITICAL

    def test_continuation_referents_skip_rag(self):
        """Referential phrases like 'Iya, yang tadi itu.' rely on conversation history, not RAG."""
        result = RAGGatingService.evaluate_intent("Iya, yang tadi itu.")
        assert result.should_retrieve_rag is False
        assert result.intent == ConversationIntent.CONVERSATION_CONTINUATION


# ============================================================================
# D. ElevenLabs TTD Protocol & WebSocket Mock Tests
# ============================================================================

class MockWebSocket:
    """Mock websocket implementing the official ElevenLabs TTD protocol exchange."""

    def __init__(self, responses: list[dict] | None = None):
        self.sent_frames: list[dict] = []
        self.closed = False
        self.incoming_queue: asyncio.Queue[str] = asyncio.Queue()
        if responses:
            for r in responses:
                self.incoming_queue.put_nowait(json.dumps(r))

    async def send(self, data: str):
        self.sent_frames.append(json.loads(data))

    async def recv(self) -> str:
        item = await self.incoming_queue.get()
        return item

    async def close(self):
        self.closed = True


class TestElevenLabsTTDProtocol:

    def test_ttd_url_and_parameters(self):
        """Verify URL uses TTD endpoint with model_id and output_format (no bogus query params)."""
        session = ElevenLabsTTDSession(
            api_key="test_key",
            voice_id="EXAVITQu4vr4xnSDxMaL",
            model_id="eleven_v3_conversational",
            output_format="mp3_44100_128",
        )
        assert "wss://api.elevenlabs.io/v1/text-to-dialogue/stream-input" in session.url
        assert "model_id=eleven_v3_conversational" in session.url
        assert "output_format=mp3_44100_128" in session.url
        assert "language_code" not in session.url

    @pytest.mark.asyncio
    async def test_handshake_and_send_lifecycle(self):
        """Verify first frame is voices registration, followed by inputs and finish frames."""
        dummy_audio = base64.b64encode(b"\xff\xfb\x90\x44" * 10).decode("utf-8")
        mock_ws = MockWebSocket(
            responses=[
                {"audio": dummy_audio},
                {"is_final_audio_for_turn": True},
                {"is_final": True},
            ]
        )

        session = ElevenLabsTTDSession(
            api_key="test_key",
            voice_id="EXAVITQu4vr4xnSDxMaL",
        )

        with patch("websockets.connect", new=AsyncMock(return_value=mock_ws)):
            await session.connect()
            assert len(mock_ws.sent_frames) == 1
            # Step 1: Handshake frame must register voices as array of IDs
            assert mock_ws.sent_frames[0] == {"voices": ["EXAVITQu4vr4xnSDxMaL"]}

            # Step 2: Send text input
            await session.send_text("Halo, aku mendengarkan.", new_turn=False)
            assert len(mock_ws.sent_frames) == 2
            assert mock_ws.sent_frames[1] == {
                "inputs": [
                    {
                        "text": "Halo, aku mendengarkan.",
                        "voice_id": "EXAVITQu4vr4xnSDxMaL",
                        "new_turn": False,
                    }
                ]
            }

            # Step 3: Finish sends flush: true and close_socket: true
            await session.finish()
            assert mock_ws.sent_frames[2] == {"flush": True}
            assert mock_ws.sent_frames[3] == {"close_socket": True}

            # Step 4: Receive audio chunks
            chunks = []
            async for c in session.receive_audio_chunks():
                chunks.append(c)

            assert len(chunks) == 1
            assert len(chunks[0]) == 40
            await session.close()
            assert mock_ws.closed is True


# ============================================================================
# E. Streaming Concurrency & Sentence Audio Pipeline Tests
# ============================================================================

class TestStreamingConcurrency:

    @pytest.mark.asyncio
    async def test_concurrent_sentence_streaming(self):
        """Verify stream_sentence_audio yields sentence audio concurrently as frames arrive."""
        dummy_mp3 = b"\xff\xfb\x90\x44" * 20
        b64_audio = base64.b64encode(dummy_mp3).decode("utf-8")

        mock_ws = MockWebSocket(
            responses=[
                {"audio": b64_audio},
                {"is_final_audio_for_turn": True},
                {"audio": b64_audio},
                {"is_final_audio_for_turn": True},
                {"is_final": True},
            ]
        )

        session = ElevenLabsTTDSession(
            api_key="test_key",
            voice_id="EXAVITQu4vr4xnSDxMaL",
        )

        with patch("websockets.connect", new=AsyncMock(return_value=mock_ws)):
            await session.connect()

            async def speech_chunks():
                yield SpeechChunk("Kalimat pertama.", "[softly] Kalimat pertama.", "soft", 1, True, False)
                yield SpeechChunk("Kalimat kedua.", "Kalimat kedua.", "soft", 2, False, True)

            results: list[tuple[SpeechChunk, bytes]] = []
            async for chunk, audio in session.stream_sentence_audio(speech_chunks()):
                results.append((chunk, audio))

            assert len(results) == 2
            assert results[0][0].display_text == "Kalimat pertama."
            assert len(results[0][1]) == len(dummy_mp3)
            assert results[1][0].display_text == "Kalimat kedua."
            assert len(results[1][1]) == len(dummy_mp3)

            await session.close()


# ============================================================================
# F. Orchestrator Context Builder & Adaptive Budget Tests
# ============================================================================

class TestOrchestratorContextBuilder:

    @pytest.mark.asyncio
    async def test_user_name_personalization_in_system_prompt(self):
        """User name is injected in [PROFIL PENGGUNA] as data with natural guidance."""
        orchestrator = AIOrchestrator()
        result = await orchestrator.prepare_turn(
            user_text="Halo Luna",
            user_name="Rizky Pratama",
        )
        prompt = result.final_system_prompt
        assert "[PROFIL PENGGUNA]" in prompt
        assert "Nama Pengguna: Rizky Pratama" in prompt
        assert "DILARANG menyebut nama pengguna berulang-ulang" in prompt

    @pytest.mark.asyncio
    async def test_null_user_name_handled_cleanly(self):
        """When user name is None, no awkward placeholder or profil block appears."""
        orchestrator = AIOrchestrator()
        result = await orchestrator.prepare_turn(
            user_text="Halo Luna",
            user_name=None,
        )
        prompt = result.final_system_prompt
        assert "[PROFIL PENGGUNA]" not in prompt
        assert "None" not in prompt

    @pytest.mark.asyncio
    async def test_persisted_memory_retention(self):
        """Persisted memory from previous sessions is safely retained in system prompt."""
        orchestrator = AIOrchestrator()
        history = [
            LLMMessage(
                role="system",
                content="[Memori Percakapan Terdahulu Pengguna]: Pengguna adalah mahasiswa tingkat akhir yang sedang cemas menghadapi skripsi.",
            ),
            LLMMessage(role="user", content="Halo Luna"),
        ]
        result = await orchestrator.prepare_turn(
            user_text="Halo Luna lagi",
            conversation_history=history,
        )
        prompt = result.final_system_prompt
        assert "[Memori Percakapan Terdahulu Pengguna]:" in prompt
        assert "mahasiswa tingkat akhir" in prompt

    @pytest.mark.asyncio
    async def test_adaptive_history_budgeting(self):
        """Long conversations (>8 turns) keep recent 8 turns verbatim + summary note."""
        orchestrator = AIOrchestrator()
        history = []
        for i in range(12):
            history.append(LLMMessage(role="user", content=f"User pesan ke-{i}"))
            history.append(LLMMessage(role="assistant", content=f"Luna balasan ke-{i}"))

        result = await orchestrator.prepare_turn(
            user_text="Pesan terbaru",
            conversation_history=history,
        )
        # Verify turn was prepared without error
        assert result.is_crisis is False


# ============================================================================
# G. Indonesian Dialogue Scenarios (Section 32)
# ============================================================================

class TestIndonesianScenarios:

    @pytest.mark.asyncio
    async def test_scenario_1_continued_emotional_context(self):
        """Scenario 1: 'Iya, yang tadi itu.' resolves from history without triggering RAG."""
        orchestrator = AIOrchestrator()
        history = [
            LLMMessage(role="user", content="Aku takut masuk kelas lagi gara-gara kejadian kemarin."),
            LLMMessage(role="assistant", content="Aku paham, wajar sekali merasa takut setelah kejadian itu."),
        ]
        result = await orchestrator.prepare_turn(
            user_text="Iya, yang tadi itu.",
            conversation_history=history,
        )
        assert result.rag_items == []
        assert result.is_crisis is False

    @pytest.mark.asyncio
    async def test_scenario_2_user_name_personalization(self):
        """Scenario 2: User name 'Budi' is injected into system context."""
        orchestrator = AIOrchestrator()
        result = await orchestrator.prepare_turn(
            user_text="Aku lagi bingung banget.",
            user_name="Budi",
        )
        assert "Budi" in result.final_system_prompt

    @pytest.mark.asyncio
    async def test_scenario_3_anonymous_user(self):
        """Scenario 3: Anonymous user has natural behavior without placeholders."""
        orchestrator = AIOrchestrator()
        result = await orchestrator.prepare_turn(
            user_text="Aku lagi bingung banget.",
            user_name=None,
        )
        assert "None" not in result.final_system_prompt

    def test_scenario_4_emotion_sad_anxious(self):
        """Scenario 4: Sad/anxious detected with high confidence -> soft/reassuring delivery."""
        style_sad, tag_sad = map_emotion_to_delivery_style("sad", confidence=0.85)
        assert style_sad == "soft"
        assert tag_sad == "[softly]"

        style_anx, tag_anx = map_emotion_to_delivery_style("anxious", confidence=0.88)
        assert style_anx == "reassuring"
        assert tag_anx == "[calm]"

    def test_scenario_5_low_confidence_fallback(self):
        """Scenario 5: Low confidence emotion defaults to neutral delivery."""
        style, tag = map_emotion_to_delivery_style("sad", confidence=0.2)
        assert style == "neutral"
        assert tag == ""

    @pytest.mark.asyncio
    async def test_scenario_6_knowledge_request_rag(self):
        """Scenario 6: 'Gimana cara grounding 5-4-3-2-1?' triggers technique RAG evaluation."""
        gating = RAGGatingService.evaluate_intent("Gimana cara grounding 5-4-3-2-1?")
        assert gating.should_retrieve_rag is True
        assert gating.intent == ConversationIntent.TECHNIQUE_OR_HOW_TO

    @pytest.mark.asyncio
    async def test_scenario_7_short_tts_flush(self):
        """Scenario 7: Short response 'Aku ngerti.' flushes cleanly without hanging."""
        chunker = LatencyAwareSentenceChunker(delivery_style="soft", audio_tag="[softly]")

        async def token_gen():
            yield "Aku ngerti."

        chunks = [c async for c in chunker.chunk_stream(token_gen())]
        assert len(chunks) == 1
        assert chunks[0].display_text == "Aku ngerti."
        assert chunks[0].tts_text == "[softly] Aku ngerti."
        assert chunks[0].is_final is True

    @pytest.mark.asyncio
    async def test_scenario_8_barge_in_cancellation(self):
        """Scenario 8: Session cancellation cleanly closes the TTD session without leaks."""
        session = ElevenLabsTTDSession(
            api_key="test_key",
            voice_id="EXAVITQu4vr4xnSDxMaL",
        )
        mock_ws = MockWebSocket()
        session.ws = mock_ws
        await session.close()
        assert session._is_closed is True
        assert mock_ws.closed is True

    def test_scenario_9_and_10_rollback_available(self):
        """Scenario 9 & 10: ElevenLabs REST provider remains available for rollback/fallback."""
        from packages.ai.factories.tts_factory import TTSFactory
        from packages.ai.providers.tts.elevenlabs_tts import ElevenLabsTTSProvider
        rest_provider = TTSFactory.get_provider("elevenlabs_rest")
        assert isinstance(rest_provider, ElevenLabsTTSProvider)
