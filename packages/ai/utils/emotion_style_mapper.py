from dataclasses import dataclass, field
import re
from typing import Any

from packages.ai.utils.voice_character_modes import (
    DEFAULT_VOICE_MODE,
    VoiceCharacterMode,
    get_voice_character_mode,
)

# Tested and validated ElevenLabs Audio Tags
COUNSELING_SAFE_AUDIO_TAGS: set[str] = {
    "softly", "calm", "thoughtful", "curious", "warmly", "reassuring",
    "gentle", "reflective", "steady", "soft", "warm",
}

PROHIBITED_AUDIO_TAGS: set[str] = {
    "crying", "screaming", "laughing", "chuckles", "sighs", "whispers",
    "clears throat", "sobbing", "panicking", "terrified", "angry", "shouting",
}

EXPRESSIVE_AUDIO_TAGS: set[str] = {
    "happily", "playful", "excited",
}

ALL_RECOGNIZED_AUDIO_TAGS: set[str] = (
    COUNSELING_SAFE_AUDIO_TAGS
    | PROHIBITED_AUDIO_TAGS
    | EXPRESSIVE_AUDIO_TAGS
    | {"grounding", "neutral"}
)

VALIDATED_AUDIO_TAGS: dict[str, str] = {
    "soft": "[softly]",
    "reassuring": "[calm]",
    "calm": "[calm]",
    "thoughtful": "[thoughtful]",
    "curious": "[curious]",
    "warm": "[warmly]",
    "happy": "[warmly]",
    "playful": "[warmly]",
    "excited": "[warmly]",
    "grounding": "[softly]",
    "neutral": "",
}

# ElevenLabs Official Emotion Contract via voice_settings:
STYLE_TO_VOICE_SETTINGS: dict[str, dict[str, float]] = {
    "happy": {
        "stability": 0.45,
        "similarity_boost": 0.80,
        "style": 0.30,
        "speed": 1.02,
    },
    "warm": {
        "stability": 0.55,
        "similarity_boost": 0.80,
        "style": 0.15,
        "speed": 0.98,
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
    "curious": {
        "stability": 0.55,
        "similarity_boost": 0.80,
        "style": 0.10,
        "speed": 1.00,
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


def is_recognized_audio_tag(tag_str: str) -> bool:
    """Return True only if tag content represents a known audio/delivery instruction.
    Arbitrary user brackets like [sic], [1], [data], [pasien] return False.
    """
    if not tag_str:
        return False
    norm = tag_str.strip().lower()
    if norm in ALL_RECOGNIZED_AUDIO_TAGS:
        return True
    tokens = [t.strip() for t in re.split(r"[\s,]+", norm) if t.strip()]
    allowed_tokens = ALL_RECOGNIZED_AUDIO_TAGS | {"curiosity", "reflection", "reassurance", "grounded"}
    if tokens and all(t in allowed_tokens for t in tokens):
        return True
    return False


def has_recognized_audio_tag(text: str) -> bool:
    """Check if text contains any recognized inline audio tag."""
    if not text:
        return False
    for m in re.finditer(r"\[([a-zA-Z0-9_,\s\-\'\"]+)\]", text):
        if is_recognized_audio_tag(m.group(1)):
            return True
    return False


def strip_audio_tags(text: str) -> str:
    """Remove recognized delivery audio tags from text so visible chat transcripts remain pure,
    while carefully preserving non-audio bracketed text like [sic], [1], or [catatan].
    """
    if not text:
        return ""

    def _replace_tag(match: re.Match) -> str:
        tag_content = match.group(1).strip()
        if is_recognized_audio_tag(tag_content):
            return ""
        return match.group(0)

    cleaned = re.sub(r"\[([a-zA-Z0-9_,\s\-\'\"]+)\]\s*", _replace_tag, text)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def sanitize_tts_audio_tags(text: str, risk_level: str = "low") -> str:
    """Sanitize audio tags in TTS input:
    - Strips prohibited theatrical/negative tags ([crying], [laughing], [screaming], [angry])
    - If in crisis/high risk, forces calm/grounding tag or removes theatrical expressions
    """
    if not text:
        return ""

    def _sanitize(match: re.Match) -> str:
        content = match.group(1).strip().lower()
        if any(p in content for p in PROHIBITED_AUDIO_TAGS):
            if risk_level in ("high", "critical"):
                return "[softly] "
            return ""
        return match.group(0)

    return re.sub(r"\[([a-zA-Z0-9_,\s\-\'\"]+)\]\s*", _sanitize, text).strip()


# Regex to match any audio delivery tag (legacy single-word and v4 natural-language tags)
ALL_AUDIO_TAGS_PATTERN = re.compile(
    r"\[([a-zA-Z][a-zA-Z0-9_,\s\-\'\"]*)\]\s*",
    re.IGNORECASE,
)
_AUDIO_TAG_PATTERN = ALL_AUDIO_TAGS_PATTERN


def filter_voice_settings_for_model(
    model_id: str,
    voice_settings: dict[str, float] | None,
) -> dict[str, float] | None:
    """Filter voice settings based on model compatibility.
    
    ElevenLabs v4 (eleven_v4, eleven_v4_turbo) strictly supports only stability and similarity_boost.
    Passing style or speed is omitted for v4 to prevent API errors. Parameter values are clamped to 0.0-1.0.
    """
    if not voice_settings:
        return None
    if model_id.startswith("eleven_v4"):
        v4_settings: dict[str, float] = {}
        if "stability" in voice_settings:
            try:
                s_val = float(voice_settings["stability"])
                v4_settings["stability"] = max(0.0, min(1.0, round(s_val, 2)))
            except (ValueError, TypeError):
                v4_settings["stability"] = 0.50
        if "similarity_boost" in voice_settings:
            try:
                sb_val = float(voice_settings["similarity_boost"])
                v4_settings["similarity_boost"] = max(0.0, min(1.0, round(sb_val, 2)))
            except (ValueError, TypeError):
                v4_settings["similarity_boost"] = 0.80
        if "use_speaker_boost" in voice_settings:
            v4_settings["use_speaker_boost"] = bool(voice_settings["use_speaker_boost"])
        return v4_settings
    return voice_settings.copy()


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
    policy_version: str | None = None,
) -> tuple[str, str]:
    """Deterministically map detected user emotion, confidence, and risk to assistant delivery style and Audio Tag.

    Returns:
        tuple[str, str]: (delivery_style, audio_tag)
    """
    from packages.shared.config import settings
    active_policy = policy_version or getattr(settings, "LUNA_AUDIO_TAG_POLICY_VERSION", "v2")

    # 1. High risk / Crisis: Always prioritize grounding, stable, gentle delivery
    if risk_level in ("high", "critical"):
        return "grounding", "[softly]"

    # 2. Low confidence: Fallback to neutral delivery to avoid false emotional caricature
    if confidence < 0.45 or not detected_emotion or detected_emotion.strip().lower() in ("unknown", "neutral", "none"):
        return "neutral", ""

    emo_lower = detected_emotion.strip().lower()

    # 3. Empathetic response strategy (Do NOT mirror negative user emotion!)
    if emo_lower in ("sad", "grief", "melancholy"):
        style = "soft"
        tag = "[softly]"
    elif emo_lower in ("fearful", "anxious", "panic", "worry"):
        style = "reassuring"
        tag = "[calm]"
    elif emo_lower in ("angry", "frustrated", "irritated"):
        style = "calm"
        tag = "[calm]"
    elif emo_lower in ("happy", "joyful", "delighted"):
        if active_policy == "v2":
            style = "warm"
            tag = "[warmly]"
        else:
            style = "happy"
            tag = "[happily]"
    elif emo_lower in ("excited", "enthusiastic"):
        if active_policy == "v2":
            style = "warm"
            tag = "[warmly]"
        else:
            style = "excited"
            tag = "[excited]"
    elif emo_lower in ("surprised", "confused"):
        style = "thoughtful"
        tag = "[thoughtful]"
    else:
        style = "neutral"
        tag = ""

    return style, tag


def resolve_dynamic_voice_style(
    mode_id: str | None = None,
    detected_emotion: str | None = None,
    confidence: float = 1.0,
    risk_level: str = "low",
    intent: str | None = None,
) -> DynamicVoiceResolution:
    """Dynamically resolve voice ID and Audio Tag based on active Voice Character Mode and user emotional state."""
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
    if style in ("happy", "warm") and mode.baseline_style in ("happy", "playful"):
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
