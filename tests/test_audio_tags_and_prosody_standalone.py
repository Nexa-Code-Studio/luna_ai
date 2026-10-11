"""
Standalone Unit Tests for Emotion Audio Tag Policy, Selective Stripping, Sentence Chunker, and Text Normalizer.
Tests run using standard library unittest (no external pytest dependency required).
"""

import unittest
from unittest.mock import patch

from packages.ai.utils.emotion_style_mapper import (
    has_recognized_audio_tag,
    is_recognized_audio_tag,
    map_emotion_to_delivery_style,
    sanitize_tts_audio_tags,
    strip_audio_tags,
)
from packages.ai.utils.sentence_chunker import (
    LatencyAwareSentenceChunker,
    SpeechChunk,
    _is_inside_bracket,
)
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts


class TestAudioTagsAndProsody(unittest.IsolatedAsyncioTestCase):
    """Verifies audio tag policies, tag preservation vs stripping, chunking, and text normalization."""

    def test_is_recognized_audio_tag(self):
        """Recognizes valid single and compound delivery tags, rejects non-audio user brackets."""
        self.assertTrue(is_recognized_audio_tag("softly"))
        self.assertTrue(is_recognized_audio_tag("calm"))
        self.assertTrue(is_recognized_audio_tag("thoughtful"))
        self.assertTrue(is_recognized_audio_tag("curious"))
        self.assertTrue(is_recognized_audio_tag("warmly"))
        self.assertTrue(is_recognized_audio_tag("warm, calm"))
        self.assertTrue(is_recognized_audio_tag("soft, reflective"))
        self.assertTrue(is_recognized_audio_tag("gentle curiosity"))

        # Theatrical/prohibited tags are recognized as audio tags (so they can be filtered/stripped)
        self.assertTrue(is_recognized_audio_tag("crying"))
        self.assertTrue(is_recognized_audio_tag("laughing"))

        # Non-audio user bracketed text MUST return False
        self.assertFalse(is_recognized_audio_tag("sic"))
        self.assertFalse(is_recognized_audio_tag("1"))
        self.assertFalse(is_recognized_audio_tag("catatan"))
        self.assertFalse(is_recognized_audio_tag("referensi"))
        self.assertFalse(is_recognized_audio_tag("nama"))
        self.assertFalse(is_recognized_audio_tag(""))

    def test_strip_audio_tags_selectivity(self):
        """strip_audio_tags removes audio instructions but strictly preserves user brackets."""
        # Strips recognized tags
        self.assertEqual(strip_audio_tags("[softly] Halo apa kabar?"), "Halo apa kabar?")
        self.assertEqual(strip_audio_tags("[warm, calm] Aku mendengar ceritamu."), "Aku mendengar ceritamu.")
        self.assertEqual(strip_audio_tags("[calm] Tarik napas perlahan..."), "Tarik napas perlahan...")

        # Preserves user brackets
        user_text = "Data ini sesuai dengan kutipan [1] dan dokumen [sic] yang tercatat [catatan]."
        self.assertEqual(strip_audio_tags(user_text), user_text)

        # Mixed audio tag and user bracket
        mixed = "[softly] Pasien tercatat [1] sedang merasa lelah [sic]."
        self.assertEqual(strip_audio_tags(mixed), "Pasien tercatat [1] sedang merasa lelah [sic].")

    def test_sanitize_tts_audio_tags_prohibitions(self):
        """sanitize_tts_audio_tags strips theatrical tags and forces safe delivery in crisis."""
        # Normal risk strips theatrical tags
        self.assertEqual(
            sanitize_tts_audio_tags("[crying] Aku merasa sangat sedih.", risk_level="low"),
            "Aku merasa sangat sedih.",
        )
        self.assertEqual(
            sanitize_tts_audio_tags("[laughing] Itu kabar baik.", risk_level="low"),
            "Itu kabar baik.",
        )

        # High risk replaces theatrical/prohibited with softly
        sanitized_crisis = sanitize_tts_audio_tags("[screaming] Aku tidak tahan lagi.", risk_level="high")
        self.assertIn("[softly]", sanitized_crisis)
        self.assertNotIn("screaming", sanitized_crisis)

    def test_emotion_mapping_policy_v2_warmth(self):
        """V2 policy maps happiness to warmth and avoids negative emotion mirroring."""
        style_sad, tag_sad = map_emotion_to_delivery_style("sad", confidence=0.85)
        self.assertEqual(style_sad, "soft")
        self.assertEqual(tag_sad, "[softly]")

        # Fearful -> reassuring [calm]
        style_fear, tag_fear = map_emotion_to_delivery_style("fearful", confidence=0.9)
        self.assertEqual(style_fear, "reassuring")
        self.assertEqual(tag_fear, "[calm]")

        # Angry -> calm [calm] (never mirrors anger)
        style_ang, tag_ang = map_emotion_to_delivery_style("angry", confidence=0.9)
        self.assertEqual(style_ang, "calm")
        self.assertEqual(tag_ang, "[calm]")

        # Happy under V2 -> warm [warmly]
        style_hap, tag_hap = map_emotion_to_delivery_style("happy", confidence=0.9, policy_version="v2")
        self.assertEqual(style_hap, "warm")
        self.assertEqual(tag_hap, "[warmly]")

        # Low confidence -> neutral without tag
        style_low, tag_low = map_emotion_to_delivery_style("sad", confidence=0.3)
        self.assertEqual(style_low, "neutral")
        self.assertEqual(tag_low, "")

        # Critical risk -> grounding [softly]
        style_crit, tag_crit = map_emotion_to_delivery_style("excited", confidence=0.9, risk_level="critical")
        self.assertEqual(style_crit, "grounding")
        self.assertEqual(tag_crit, "[softly]")

    async def test_sentence_chunker_bracket_protection(self):
        """Chunker never splits tokens while inside [ ... ]."""
        self.assertTrue(_is_inside_bracket("Ini adalah awal [soft"))
        self.assertTrue(_is_inside_bracket("Teks [warm, calm"))
        self.assertFalse(_is_inside_bracket("Teks [warm, calm] sudah tertutup"))
        self.assertFalse(_is_inside_bracket("Teks biasa tanpa kurung"))

    async def test_sentence_chunker_tag_deduplication(self):
        """Chunker does NOT inject fallback tag if chunk already has inline recognized audio tag."""
        chunker = LatencyAwareSentenceChunker(delivery_style="soft", audio_tag="[softly]")

        async def token_gen():
            yield "[calm] Aku "
            yield "mendengarkan "
            yield "ceritamu dengan seksama."

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        self.assertEqual(len(chunks), 1)
        # Must NOT have "[softly] [calm]" duplicate!
        self.assertNotIn("[softly]", chunks[0].tts_text)
        self.assertTrue(chunks[0].tts_text.startswith("[calm]"))
        self.assertEqual(chunks[0].display_text, "Aku mendengarkan ceritamu dengan seksama.")

    async def test_sentence_chunker_fallback_only_on_first_chunk(self):
        """Chunker injects fallback audio_tag ONLY on the first chunk."""
        chunker = LatencyAwareSentenceChunker(delivery_style="soft", audio_tag="[softly]")

        async def token_gen():
            yield "Aku sangat memahami apa yang kamu rasakan hari ini. "
            yield "Tarik napas perlahan bersamaku sebentar ya. "
            yield "Bagaimana rasanya sekarang?"

        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(token_gen()):
            chunks.append(c)

        self.assertEqual(len(chunks), 3)
        # Chunk 1 has fallback audio tag
        self.assertTrue(chunks[0].tts_text.startswith("[softly]"))
        self.assertEqual(chunks[0].is_first, True)
        self.assertFalse(chunks[0].display_text.startswith("[softly]"))

        # Chunk 2 has NO audio tag
        self.assertFalse(chunks[1].tts_text.startswith("[softly]"))
        self.assertEqual(chunks[1].is_first, False)

        # Chunk 3 has NO audio tag
        self.assertFalse(chunks[2].tts_text.startswith("[softly]"))
        self.assertEqual(chunks[2].is_first, False)
        self.assertIn("Bagaimana rasanya sekarang?", chunks[2].display_text)

    def test_text_normalizer_conversational_informal_preservation(self):
        """Conversational mode preserves informal Indonesian words (nggak, udah, kok, aja, banget)."""
        raw = "Aku udah nggak kuat ngerjain tugas, capek bgt kok."
        cleaned = sanitize_text_for_tts(raw, normalizer_mode="conversational")
        # 'udah', 'nggak', 'kok' are preserved! 'bgt' expands to 'banget'
        self.assertIn("udah", cleaned)
        self.assertIn("nggak", cleaned)
        self.assertIn("banget", cleaned)
        self.assertIn("kok", cleaned)
        self.assertNotIn("tidak", cleaned)
        self.assertNotIn("sudah", cleaned)

    def test_text_normalizer_strict_mode(self):
        """Strict mode formalizes informal words if explicitly requested."""
        raw = "Aku udah nggak kuat."
        cleaned = sanitize_text_for_tts(raw, normalizer_mode="strict")
        self.assertIn("sudah", cleaned)
        self.assertIn("tidak", cleaned)

    def test_text_normalizer_chat_abbreviation_expansion(self):
        """Standard chat abbreviations are expanded cleanly."""
        raw = "Pertemuan tsb penting utk sy dan km krn berkaitan dgn tugas dll."
        cleaned = sanitize_text_for_tts(raw)
        self.assertIn("tersebut", cleaned)
        self.assertIn("untuk", cleaned)
        self.assertIn("saya", cleaned)
        self.assertIn("kamu", cleaned)
        self.assertIn("karena", cleaned)
        self.assertIn("dengan", cleaned)
        self.assertIn("dan lain-lain", cleaned)

    def test_text_normalizer_tag_and_ellipsis_preservation(self):
        """Audio tags and ellipses are safely preserved when preserve_audio_tags=True."""
        raw = "[warmly] Terima kasih sudah bercerita... Aku di sini mendengarkanmu. 😊"
        cleaned = sanitize_text_for_tts(raw, preserve_audio_tags=True)
        self.assertTrue(cleaned.startswith("[warmly]"))
        self.assertIn("...", cleaned)
        self.assertNotIn("😊", cleaned)


if __name__ == "__main__":
    unittest.main()
