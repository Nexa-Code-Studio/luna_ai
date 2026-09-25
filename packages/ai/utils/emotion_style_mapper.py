from dataclasses import dataclass, field
import re
from typing import Any

from packages.ai.utils.voice_character_modes import (
    DEFAULT_VOICE_MODE,
    VoiceCharacterMode,
    get_voice_character_mode,
)

# Tested and validated ElevenLabs v3 Audio Tags for conversational Indonesian (legacy fallback)
VALIDATED_AUDIO_TAGS: dict[str, str] = {
    "soft": "[softly]",
    "reassuring": "[calm]",
    "calm": "[calm]",
    "thoughtful": "[thoughtful]",
    "happy": "[happily]",
    "playful": "[playful]",
    "excited": "[excited]",
    "grounding": "[softly]",
    "neutral": "",
}

# ElevenLabs Official Emotion Contract via voice_settings:
# - stability: 0.35-0.50 (more expressive/dynamic emotion); 0.65-0.85 (grounded/steady)
# - similarity_boost: 0.80 (voice fidelity)
# - style (style exaggeration): 0.20-0.35 (expressive emotion amplification without modifying text)
# - speed: 0.90-1.05 (pacing modulation)
STYLE_TO_VOICE_SETTINGS: dict[str, dict[str, float]] = {
    "happy": {
        "stability": 0.45,
        "similarity_boost": 0.80,
        "style": 0.30,
        "speed": 1.02,
    },
    "excited": {
        "stability": 0.40,
        "similarity_boost": 0.80,
        "style": 0.35,
        "speed": 1.05,
    },
    "playful": {
        "stability": 0.45,
        "similarity_boost": 0.80,
        "style": 0.25,
        "speed": 1.02,
    },
    "soft": {
        "stability": 0.65,
        "similarity_boost": 0.80,
        "style": 0.05,
        "speed": 0.92,
    },
    "reassuring": {
        "stability": 0.70,
        "similarity_boost": 0.80,
        "style": 0.00,
        "speed": 0.95,
    },
    "calm": {
        "stability": 0.75,
        "similarity_boost": 0.80,
        "style": 0.00,
        "speed": 0.95,
    },
    "thoughtful": {
        "stability": 0.60,
        "similarity_boost": 0.80,
        "style": 0.10,
        "speed": 0.96,
    },
    "grounding": {
        "stability": 0.80,
        "similarity_boost": 0.80,
        "style": 0.00,
        "speed": 0.90,
    },
    "neutral": {
        "stability": 0.55,
        "similarity_boost": 0.80,
        "style": 0.15,
        "speed": 1.00,
    },
}


def get_voice_settings_for_style(style: str) -> dict[str, float]:
    """Retrieve official ElevenLabs voice_settings dictionary for a given delivery style."""
    return STYLE_TO_VOICE_SETTINGS.get(style, STYLE_TO_VOICE_SETTINGS["neutral"]).copy()


# Regex to safely match recognized audio tags or inline delivery tags at the beginning of speech
_AUDIO_TAG_PATTERN = re.compile(
    r"^\[(softly|calm|thoughtful|happily|playful|excited|sad|anxious|angry|soft|reassuring|whispers|clears throat|sighs)\]\s*",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class DynamicVoiceResolution:
    mode: VoiceCharacterMode
    voice_id: str
    delivery_style: str
    audio_tag: str
    is_emotion_override: bool
    voice_settings: dict[str, float] = field(default_factory=lambda: STYLE_TO_VOICE_SETTINGS["neutral"].copy())


def map_emotion_to_delivery_style(
    detected_emotion: str | None,
    confidence: float = 1.0,
    risk_level: str = "low",
    intent: str | None = None,
) -> tuple[str, str]:
    """Deterministically map detected user emotion, confidence, and risk to assistant delivery style and Audio Tag.

    Returns:
        tuple[str, str]: (delivery_style, audio_tag)
    """
    # 1. High risk / Crisis: Always prioritize grounding, stable, gentle delivery
    if risk_level in ("high", "critical"):
        return "grounding", VALIDATED_AUDIO_TAGS["grounding"]

    # 2. Low confidence: Fallback to neutral delivery to avoid false emotional caricature
    if confidence < 0.45 or not detected_emotion:
        return "neutral", VALIDATED_AUDIO_TAGS["neutral"]

    emo_lower = detected_emotion.strip().lower()

    # 3. Empathetic response strategy (Do NOT mirror negative user emotion!)
    if emo_lower in ("sad", "grief", "melancholy"):
        style = "soft"
    elif emo_lower in ("fearful", "anxious", "panic", "worry"):
        style = "reassuring"
    elif emo_lower in ("angry", "frustrated", "irritated"):
        style = "calm"
    elif emo_lower in ("happy", "joyful", "delighted"):
        style = "happy"
    elif emo_lower in ("excited", "enthusiastic"):
        style = "excited"
    elif emo_lower in ("surprised", "confused"):
        style = "thoughtful"
    else:
        style = "neutral"

    tag = VALIDATED_AUDIO_TAGS.get(style, "")
    return style, tag


def resolve_dynamic_voice_style(
    mode_id: str | None = None,
    detected_emotion: str | None = None,
    confidence: float = 1.0,
    risk_level: str = "low",
    intent: str | None = None,
) -> DynamicVoiceResolution:
    """Dynamically resolve voice ID and Audio Tag based on active Voice Character Mode and user emotional state.

    Implements Empathetic Adaptive Modulation:
    - Crisis / High Risk: Forces [softly] (grounding & validation) on active voice.
    - User Distress:
        - Sad / Grief -> dynamically modulates to [softly]
        - Fear / Anxiety -> dynamically modulates to [calm]
        - Anger / Frustration -> dynamically modulates to [calm]
    - User Positive:
        - Excited -> modulates to [excited]
        - Surprised -> modulates to [thoughtful]
    - User Neutral / Low Confidence / General:
        - Reverts to active mode's baseline style & tag:
            - Mode 2 -> [happily] (Jessica Ceria)
            - Mode 4 -> [playful] (Jessica Playful)
            - Mode 7 -> [happily] (Laura Ceria)
    """
    mode = get_voice_character_mode(mode_id)

    style, tag = map_emotion_to_delivery_style(
        detected_emotion=detected_emotion,
        confidence=confidence,
        risk_level=risk_level,
        intent=intent,
    )

    # When emotion is neutral or confidence is low, adopt the active mode's baseline personality & settings
    if style == "neutral":
        mode_settings = getattr(mode, "baseline_voice_settings", None) or get_voice_settings_for_style(mode.baseline_style)
        return DynamicVoiceResolution(
            mode=mode,
            voice_id=mode.voice_id,
            delivery_style=mode.baseline_style,
            audio_tag=mode.baseline_tag,
            is_emotion_override=False,
            voice_settings=mode_settings,
        )

    # If the user is happy and mode has a positive baseline, honor the mode's baseline personality & settings
    if style == "happy" and mode.baseline_style in ("happy", "playful"):
        mode_settings = getattr(mode, "baseline_voice_settings", None) or get_voice_settings_for_style(mode.baseline_style)
        return DynamicVoiceResolution(
            mode=mode,
            voice_id=mode.voice_id,
            delivery_style=mode.baseline_style,
            audio_tag=mode.baseline_tag,
            is_emotion_override=False,
            voice_settings=mode_settings,
        )

    # Otherwise, it's an empathetic dynamic override (soft, reassuring, calm, excited, etc.)
    return DynamicVoiceResolution(
        mode=mode,
        voice_id=mode.voice_id,
        delivery_style=style,
        audio_tag=tag,
        is_emotion_override=True,
        voice_settings=get_voice_settings_for_style(style),
    )


def strip_audio_tags(text: str) -> str:
    """Remove delivery audio tags from text so visible chat transcripts remain pure."""
    if not text:
        return ""
    # Strip leading delivery tags e.g. [softly], [playful], [happily]
    cleaned = _AUDIO_TAG_PATTERN.sub("", text.strip()).strip()
    return cleaned
