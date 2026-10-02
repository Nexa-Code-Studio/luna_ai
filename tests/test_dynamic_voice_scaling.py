import pytest
from packages.ai.utils.emotion_style_mapper import (
    resolve_dynamic_voice_style,
    get_voice_settings_for_style,
)
from packages.ai.orchestration.orchestrator import AIOrchestrator
from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from shared.domain_types import EmotionDetectionResult


class DummyLLMProvider(BaseLLMProvider):
    async def generate_response(self, messages: list[LLMMessage], **kwargs) -> str:
        return "Halo, aku mendengar ceritamu."

    async def stream_response(self, messages: list[LLMMessage], **kwargs):
        yield "Halo,"
        yield " aku mendengar."


def test_dynamic_voice_settings_intensity_scaling():
    """Memverifikasi bahwa intensitas yang berbeda menghasilkan modulasi style, stability, dan speed."""
    # Sadness: low intensity (0.2) vs high intensity (0.9)
    settings_sad_low = get_voice_settings_for_style("soft", intensity=0.2, confidence=0.8, detected_emotion="sad")
    settings_sad_high = get_voice_settings_for_style("soft", intensity=0.9, confidence=0.8, detected_emotion="sad")

    # High intensity sadness increases stability (calming, grounding anchor) and slows down pacing
    assert settings_sad_high["stability"] > settings_sad_low["stability"], "High intensity sadness should increase grounding stability"
    assert settings_sad_high["speed"] <= settings_sad_low["speed"], "High intensity sadness should lower or maintain slow speed"
    assert settings_sad_high["style"] >= settings_sad_low["style"], "High intensity sadness should modulate style"

    # Happiness: low intensity (0.2) vs high intensity (0.9)
    settings_happy_low = get_voice_settings_for_style("happy", intensity=0.2, confidence=0.85, detected_emotion="happy")
    settings_happy_high = get_voice_settings_for_style("happy", intensity=0.9, confidence=0.85, detected_emotion="happy")

    # High intensity happiness should have higher style amplification, lower stability (more animated intonation), and higher speed
    assert settings_happy_high["style"] > settings_happy_low["style"], "High intensity happiness should increase style exaggeration"
    assert settings_happy_high["stability"] < settings_happy_low["stability"], "High intensity happiness should lower stability for animation"
    assert settings_happy_high["speed"] >= settings_happy_low["speed"], "High intensity happiness should increase pacing"


def test_resolve_dynamic_voice_style_with_intensity():
    """Memverifikasi resolve_dynamic_voice_style meneruskan parameter intensitas secara akurat."""
    res_low = resolve_dynamic_voice_style(
        mode_id="mode_1",
        detected_emotion="sad",
        confidence=0.9,
        intensity=0.25,
        risk_level="low",
    )
    res_high = resolve_dynamic_voice_style(
        mode_id="mode_1",
        detected_emotion="sad",
        confidence=0.9,
        intensity=0.95,
        risk_level="low",
    )

    assert res_low.is_emotion_override is True
    assert res_high.is_emotion_override is True
    assert res_high.voice_settings["stability"] > res_low.voice_settings["stability"]
    assert res_high.voice_settings["style"] > res_low.voice_settings["style"]


@pytest.mark.asyncio
async def test_orchestrator_precomputed_emotion_and_prompt_guidance():
    """Memverifikasi bahwa prepare_turn menghormati precomputed_emotion dan memperkaya prompt dengan panduan nada emosional."""
    mock_llm = DummyLLMProvider()
    orchestrator = AIOrchestrator(llm_provider=mock_llm)

    precomputed = EmotionDetectionResult(
        primary_emotion="fearful",
        confidence=0.88,
        intensity=0.85,
        secondary_emotion="sad",
        scores={"fearful": 0.88, "sad": 0.10, "neutral": 0.02},
        model_used="emotion2vec_plus_large",
        latency_ms=120.0,
    )

    turn = await orchestrator.prepare_turn(
        user_text="Aku sangat panik menghadapi besok.",
        precomputed_emotion=precomputed,
    )

    # Pastikan orchestrator menggunakan precomputed emotion
    assert turn.emotion.primary_emotion == "fearful"
    assert turn.emotion.intensity == 0.85
    assert turn.emotion.secondary_emotion == "sad"
    assert turn.emotion.model_used == "emotion2vec_plus_large"

    # Pastikan system prompt memuat panduan nada konseling emosional dan persentase intensitas
    prompt = turn.final_system_prompt
    assert "fearful" in prompt
    assert "Intensitas: 85%" in prompt
    assert "Keyakinan: 88%" in prompt
    assert "Nuansa sekunder: 'sad'" in prompt
    assert "Panduan Nada Emosional Konseling:" in prompt
    assert "menenangkan nafas" in prompt or "grounding" in prompt
