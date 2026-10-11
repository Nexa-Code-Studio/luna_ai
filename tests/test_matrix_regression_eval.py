"""
End-to-End Test Matrix Regression for ElevenLabs v4 Turbo & DeepSeek Prompting.
Implements the minimum test matrix defined in Section 6.1 of the implementation plan.
"""

import asyncio
import unittest
from unittest.mock import MagicMock

from packages.ai.orchestration.orchestrator import AIOrchestrator
from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from packages.ai.utils.emotion_style_mapper import (
    map_emotion_to_delivery_style,
    strip_audio_tags,
)
from packages.ai.utils.sentence_chunker import (
    LatencyAwareSentenceChunker,
    SpeechChunk,
)
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts
from packages.shared.config import settings


class DynamicMockLLM(BaseLLMProvider):
    def __init__(self, token_responses: dict[str, list[str]]):
        self.token_responses = token_responses

    async def generate_response(self, messages: list[LLMMessage], **kwargs) -> str:
        last_user = next((m.content for m in reversed(messages) if m.role == "user"), "")
        tokens = self.token_responses.get(last_user, ["Halo, aku di sini mendengarkanmu."])
        return "".join(tokens)

    async def stream_response(self, messages: list[LLMMessage], **kwargs):
        last_user = next((m.content for m in reversed(messages) if m.role == "user"), "")
        tokens = self.token_responses.get(last_user, ["Halo,", " aku", " di sini", " mendengarkanmu."])
        for t in tokens:
            yield t


class TestMatrixRegressionEvaluation(unittest.IsolatedAsyncioTestCase):
    """Executes the Section 6.1 test matrix against Luna AI orchestration & TTS pipeline."""

    def setUp(self):
        self.mock_llm = DynamicMockLLM({
            "Halo": ["[warmly] Halo! ", "Senang bisa terhubung denganmu hari ini. ", "Ada apa?"],
            "Aku lagi capek banget, rasanya sendirian.": [
                "[softly] Aku dengar betapa melelahkannya hari ini untukmu... ",
                "Kamu nggak sendirian sekarang, aku ada di sini untuk menemanimu.",
            ],
            "Aku takut presentasi besok.": [
                "[calm] Wajar kok merasa gugup sebelum hari penting seperti besok. ",
                "Tarik napas perlahan, kita bisa latihan atau bicarakan apa yang paling bikin cemas.",
            ],
            "Aku kesel banget sama temenku.": [
                "[calm] Pasti nggak nyaman rasanya ya saat ada hal yang bikin kesel dengan teman. ",
                "Mau cerita apa yang sebenarnya terjadi?",
            ],
            "Aku akhirnya lulus!": [
                "[warmly] Wah, selamat ya atas kelulusanmu! ",
                "Ikut senang mendengarnya, semua perjuanganmu terbayar.",
            ],
            "Yang tadi itu... masih bikin kepikiran.": [
                "[thoughtful] Hal yang tadi kita bahas memang wajar kalau masih mengganjal... ",
                "Bagian mana yang paling sering terlintas di pikiranmu?",
            ],
            "Bedanya stres dan cemas apa?": [
                "Stres biasanya muncul karena tekanan atau pemicu yang jelas, sedangkan cemas lebih berupa kekhawatiran yang menetap bahkan saat pemicunya sudah lewat.",
            ],
            "Aku udah nggak kuat ngerjain semua tugas.": [
                "[softly] Bebannya terasa menumpuk banget ya saat semuanya datang bersamaan. ",
                "Istirahat sejenak dulu, yuk, kamu nggak harus beresin semuanya malam ini.",
            ],
            "Yaudah deh, terserah.": [
                "[calm] Nggak apa-apa kok kalau sekarang lagi nggak ingin banyak bicara. ",
                "Aku tetap di sini kalau kamu butuh ruang.",
            ],
            "Aku sudah tidak tahan lagi, aku mau bunuh diri malam ini.": [
                "Bypass to CRISIS SOP",
            ],
        })
        self.orchestrator = AIOrchestrator(llm_provider=self.mock_llm)

    async def test_scenario_1_short_greeting(self):
        """Sapaan pendek 'Halo': Ringkas, ramah, tag vokal aman, audio keluar meski buffer kecil."""
        turn = await self.orchestrator.prepare_turn(user_text="Halo")
        self.assertFalse(turn.is_crisis)
        self.assertIn("[LAYER 1 — IDENTITAS & PERAN LUNA]", turn.final_system_prompt)

        tokens = [t async for t in turn.token_stream]
        full_text = "".join(tokens)
        self.assertTrue(full_text.startswith("[warmly]"))

        # Verify chunking and normalizer
        async def token_gen():
            for t in tokens:
                yield t

        chunker = LatencyAwareSentenceChunker()
        chunks = [c async for c in chunker.chunk_stream(token_gen())]
        self.assertGreaterEqual(len(chunks), 1)
        # Test display vs tts purity
        display_clean = strip_audio_tags(full_text)
        self.assertNotIn("[warmly]", display_clean)
        self.assertEqual(display_clean, "Halo! Senang bisa terhubung denganmu hari ini. Ada apa?")

    async def test_scenario_2_sadness_validation(self):
        """Sedih: 'Aku lagi capek banget, rasanya sendirian.' Validasi konkret, tidak overacting."""
        turn = await self.orchestrator.prepare_turn(user_text="Aku lagi capek banget, rasanya sendirian.")
        self.assertFalse(turn.is_crisis)
        self.assertEqual(turn.emotion.primary_emotion, "sad")
        # System prompt delivery recommendation must be soft
        self.assertIn("rekomendasi nada: soft", turn.final_system_prompt)

    async def test_scenario_3_anxiety_calm(self):
        """Cemas: 'Aku takut presentasi besok.' Menenangkan tanpa mengabaikan konteks."""
        turn = await self.orchestrator.prepare_turn(user_text="Aku takut presentasi besok.")
        self.assertFalse(turn.is_crisis)
        self.assertIn("rekomendasi nada: reassuring", turn.final_system_prompt)

    async def test_scenario_4_anger_non_mirroring(self):
        """Marah: 'Aku kesel banget sama temenku.' Tidak defensif, tidak meniru marah."""
        turn = await self.orchestrator.prepare_turn(user_text="Aku kesel banget sama temenku.")
        self.assertFalse(turn.is_crisis)
        self.assertIn("rekomendasi nada: calm", turn.final_system_prompt)
        self.assertNotIn("rekomendasi nada: angry", turn.final_system_prompt)

    async def test_scenario_5_positive_warmth(self):
        """Positif: 'Aku akhirnya lulus!' Hangat wajar tanpa hiperaktivitas teater."""
        turn = await self.orchestrator.prepare_turn(user_text="Aku akhirnya lulus!")
        self.assertFalse(turn.is_crisis)
        self.assertIn("rekomendasi nada: warm", turn.final_system_prompt)

    async def test_scenario_6_informal_indonesian_preservation(self):
        """Gaya informal: 'Aku udah nggak kuat ngerjain semua tugas.' Tetap natural, bukan dipaksa baku."""
        raw_speech = "Aku udah nggak kuat ngerjain tugas, capek bgt kok."
        normalized = sanitize_text_for_tts(raw_speech)
        self.assertIn("udah", normalized)
        self.assertIn("nggak", normalized)
        self.assertIn("banget", normalized)
        self.assertIn("kok", normalized)
        self.assertNotIn("tidak", normalized)
        self.assertNotIn("sudah", normalized)

    async def test_scenario_7_crisis_safeguard(self):
        """Risiko kritis: kasus bunuh diri di-bypass secara deterministik ke hotline LISA / 119."""
        turn = await self.orchestrator.prepare_turn(user_text="Aku sudah tidak tahan lagi, aku mau bunuh diri malam ini.")
        self.assertTrue(turn.is_crisis)
        self.assertEqual(turn.final_system_prompt, "[CRISIS SOP PROTOCOL ACTIVATED]")
        tokens = [t async for t in turn.token_stream]
        full_output = "".join(tokens)
        self.assertIn("119 ekstensi 8", full_output)
        self.assertIn("LISA", full_output)

    async def test_scenario_8_broken_audio_tag_safeguard(self):
        """Audio tag rusak [soft lintas token terlindungi oleh _is_inside_bracket."""
        chunker = LatencyAwareSentenceChunker()

        async def stream_with_broken_tag():
            yield "[soft"
            yield "ly] "
            yield "Halo, aku di sini mendengarkanmu."

        chunks = [c async for c in chunker.chunk_stream(stream_with_broken_tag())]
        self.assertEqual(len(chunks), 1)
        # Bracket was not severed mid-tag
        self.assertEqual(chunks[0].tts_text, "[softly] Halo, aku di sini mendengarkanmu.")
        self.assertEqual(chunks[0].display_text, "Halo, aku di sini mendengarkanmu.")


if __name__ == "__main__":
    unittest.main()
