"""Unit and Integration Tests for Dynamic Voice Modulation Engine and Voice Character Modes (Mode 2, 4, 7)."""

import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
import pytest

from packages.ai.interfaces.llm import LLMMessage
from packages.shared.domain_types import EmotionDetectionResult
from packages.ai.utils.emotion_style_mapper import (
    VALIDATED_AUDIO_TAGS,
    map_emotion_to_delivery_style,
    resolve_dynamic_voice_style,
    strip_audio_tags,
)
from packages.ai.utils.voice_character_modes import (
    DEFAULT_VOICE_MODE,
    VOICE_CHARACTER_MODES,
    VoiceCharacterMode,
    get_voice_character_mode,
)
from apps.backend.api.app.services.call_session_manager import CallSession, CallSessionManager


class TestVoiceCharacterModes:
    """Test voice character mode definitions and resolution."""

    def test_default_mode_is_mode_2(self):
        assert DEFAULT_VOICE_MODE == "mode_2"
        mode = get_voice_character_mode()
        assert mode.id == "mode_2"
        assert mode.voice_id == "cgSgspJ2msm6clMCkdW9"  # Jessica
        assert mode.baseline_tag == "[happily]"
        assert mode.baseline_style == "happy"

    def test_mode_4_definition(self):
        mode = get_voice_character_mode("mode_4")
        assert mode.id == "mode_4"
        assert mode.voice_id == "cgSgspJ2msm6clMCkdW9"  # Jessica
        assert mode.baseline_tag == "[playful]"
        assert mode.baseline_style == "playful"

    def test_mode_7_definition(self):
        mode = get_voice_character_mode("mode_7")
        assert mode.id == "mode_7"
        assert mode.voice_id == "FGY2WhTYpPnrIDTdsKH5"  # Laura
        assert mode.baseline_tag == "[happily]"
        assert mode.baseline_style == "happy"

    def test_mode_id_normalization_aliases(self):
        # '2' -> mode_2
        assert get_voice_character_mode("2").id == "mode_2"
        assert get_voice_character_mode("mode2").id == "mode_2"
        # '4' -> mode_4
        assert get_voice_character_mode("4").id == "mode_4"
        assert get_voice_character_mode("mode4").id == "mode_4"
        # '7' -> mode_7
        assert get_voice_character_mode("7").id == "mode_7"
        assert get_voice_character_mode("mode7").id == "mode_7"

    def test_invalid_mode_falls_back_to_mode_2(self):
        assert get_voice_character_mode("invalid_mode_xyz").id == "mode_2"
        assert get_voice_character_mode("").id == "mode_2"
        assert get_voice_character_mode(None).id == "mode_2"


class TestDynamicVoiceModulation:
    """Test Empathetic Adaptive Modulation for all emotional states and modes."""

    # 1. Mode 2 (Default: Jessica + [happily])
    def test_mode_2_neutral_uses_baseline_tag(self):
        res = resolve_dynamic_voice_style(mode_id="mode_2", detected_emotion="neutral")
        assert res.mode.id == "mode_2"
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[happily]"
        assert res.delivery_style == "happy"
        assert res.is_emotion_override is False

    def test_mode_2_sad_dynamically_modulates_to_softly(self):
        res = resolve_dynamic_voice_style(mode_id="mode_2", detected_emotion="sad")
        assert res.mode.id == "mode_2"
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[softly]"
        assert res.delivery_style == "soft"
        assert res.is_emotion_override is True

    def test_mode_2_anxious_dynamically_modulates_to_calm(self):
        res = resolve_dynamic_voice_style(mode_id="mode_2", detected_emotion="fearful")
        assert res.mode.id == "mode_2"
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[calm]"
        assert res.delivery_style == "reassuring"
        assert res.is_emotion_override is True

    def test_mode_2_angry_dynamically_modulates_to_calm(self):
        res = resolve_dynamic_voice_style(mode_id="mode_2", detected_emotion="angry")
        assert res.mode.id == "mode_2"
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[calm]"
        assert res.delivery_style == "calm"
        assert res.is_emotion_override is True

    def test_mode_2_happy_uses_happily(self):
        res = resolve_dynamic_voice_style(mode_id="mode_2", detected_emotion="happy")
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[happily]"
        assert res.delivery_style == "happy"

    def test_mode_2_excited_modulates_to_excited(self):
        res = resolve_dynamic_voice_style(mode_id="mode_2", detected_emotion="excited")
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[excited]"
        assert res.delivery_style == "excited"
        assert res.is_emotion_override is True

    def test_mode_2_crisis_forces_grounding_softly(self):
        res = resolve_dynamic_voice_style(
            mode_id="mode_2", detected_emotion="happy", risk_level="critical"
        )
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[softly]"
        assert res.delivery_style == "grounding"
        assert res.is_emotion_override is True

    # 2. Mode 4 (Jessica Playful)
    def test_mode_4_neutral_uses_playful_tag(self):
        res = resolve_dynamic_voice_style(mode_id="mode_4", detected_emotion="neutral")
        assert res.mode.id == "mode_4"
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[playful]"
        assert res.delivery_style == "playful"
        assert res.is_emotion_override is False

    def test_mode_4_sad_dynamically_modulates_to_softly(self):
        res = resolve_dynamic_voice_style(mode_id="mode_4", detected_emotion="sad")
        assert res.mode.id == "mode_4"
        assert res.voice_id == "cgSgspJ2msm6clMCkdW9"
        assert res.audio_tag == "[softly]"
        assert res.delivery_style == "soft"
        assert res.is_emotion_override is True

    # 3. Mode 7 (Laura)
    def test_mode_7_neutral_uses_laura_and_happily(self):
        res = resolve_dynamic_voice_style(mode_id="mode_7", detected_emotion="neutral")
        assert res.mode.id == "mode_7"
        assert res.voice_id == "FGY2WhTYpPnrIDTdsKH5"
        assert res.audio_tag == "[happily]"
        assert res.delivery_style == "happy"
        assert res.is_emotion_override is False

    def test_mode_7_sad_dynamically_modulates_to_softly_with_laura_voice(self):
        res = resolve_dynamic_voice_style(mode_id="mode_7", detected_emotion="sad")
        assert res.mode.id == "mode_7"
        assert res.voice_id == "FGY2WhTYpPnrIDTdsKH5"
        assert res.audio_tag == "[softly]"
        assert res.delivery_style == "soft"
        assert res.is_emotion_override is True

    def test_mode_7_crisis_forces_softly_with_laura_voice(self):
        res = resolve_dynamic_voice_style(
            mode_id="mode_7", detected_emotion="neutral", risk_level="high"
        )
        assert res.mode.id == "mode_7"
        assert res.voice_id == "FGY2WhTYpPnrIDTdsKH5"
        assert res.audio_tag == "[softly]"
        assert res.delivery_style == "grounding"

    def test_low_confidence_reverts_to_mode_baseline(self):
        # Confidence < 0.45 should NOT trigger emotional caricature
        res = resolve_dynamic_voice_style(
            mode_id="mode_4", detected_emotion="sad", confidence=0.3
        )
        assert res.audio_tag == "[playful]"
        assert res.delivery_style == "playful"
        assert res.is_emotion_override is False


class TestAudioTagScrubber:
    """Test that all tags including [playful] and [happily] are stripped cleanly."""

    def test_strip_happily(self):
        raw = "[happily] Halo Andi! Senang sekali bisa ngobrol lagi sama kamu."
        assert strip_audio_tags(raw) == "Halo Andi! Senang sekali bisa ngobrol lagi sama kamu."

    def test_strip_playful(self):
        raw = "[playful] Hehehe, ada-ada aja ceritamu hari ini!"
        assert strip_audio_tags(raw) == "Hehehe, ada-ada aja ceritamu hari ini!"

    def test_strip_softly(self):
        raw = "[softly] Aku paham perasaanmu berat banget ya."
        assert strip_audio_tags(raw) == "Aku paham perasaanmu berat banget ya."

    def test_strip_calm(self):
        raw = "[calm] Tarik napas perlahan ya."
        assert strip_audio_tags(raw) == "Tarik napas perlahan ya."

    def test_strip_case_insensitive(self):
        raw = "[PLAYFUL] Halo semuanya!"
        assert strip_audio_tags(raw) == "Halo semuanya!"


@pytest.mark.asyncio
class TestCallSessionManagerDynamicVoiceIntegration:
    """Test CallSessionManager WebSocket event handling with voice_mode."""

    async def test_session_initializes_with_default_mode_2(self):
        fake_ws = MagicMock()
        session = CallSession(session_id="test_sess_1", websocket=fake_ws)
        assert session.voice_mode == "mode_2"

    async def test_session_initializes_with_custom_mode(self):
        fake_ws = MagicMock()
        session = CallSession(session_id="test_sess_2", websocket=fake_ws, voice_mode="mode_4")
        assert session.voice_mode == "mode_4"

    async def test_start_call_updates_voice_mode(self):
        fake_ws = AsyncMock()
        csm = CallSessionManager()
        session = csm.register_session("sess_mode_test", fake_ws)
        assert session.voice_mode == "mode_2"

        # Client sends start_call with voice_mode="mode_7"
        await csm.handle_event(session, {"type": "start_call", "voice_mode": "mode_7"})
        assert session.voice_mode == "mode_7"
        assert session.state == "listening"

        # Verifies response sent to client contains voice_mode
        fake_ws.send_json.assert_called_with({
            "type": "call_started",
            "session_id": "sess_mode_test",
            "voice_mode": "mode_7",
        })

    async def test_start_call_default_retains_mode_2_if_unspecified(self):
        fake_ws = AsyncMock()
        csm = CallSessionManager()
        session = csm.register_session("sess_mode_default", fake_ws)

        await csm.handle_event(session, {"type": "start_call"})
        assert session.voice_mode == "mode_2"
        fake_ws.send_json.assert_called_with({
            "type": "call_started",
            "session_id": "sess_mode_default",
            "voice_mode": "mode_2",
        })
