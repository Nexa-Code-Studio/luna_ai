"""Voice Character Modes Registry for Luna AI.

Defines the curated voice character modes:
- mode_2 (Default): Jessica (cgSgspJ2msm6clMCkdW9) + [happily]
- mode_4: Jessica (cgSgspJ2msm6clMCkdW9) + [playful]
- mode_7: Laura (FGY2WhTYpPnrIDTdsKH5) + [happily]
"""

from dataclasses import dataclass
from typing import Literal

VoiceModeId = Literal["mode_2", "mode_4", "mode_7"]
DEFAULT_VOICE_MODE: VoiceModeId = "mode_2"


@dataclass(frozen=True)
class VoiceCharacterMode:
    id: str
    name: str
    voice_id: str
    baseline_style: str
    baseline_tag: str
    description: str
    baseline_voice_settings: dict[str, float] | None = None


VOICE_CHARACTER_MODES: dict[str, VoiceCharacterMode] = {
    "mode_2": VoiceCharacterMode(
        id="mode_2",
        name="Luna - Jessica Ceria (Default)",
        voice_id="cgSgspJ2msm6clMCkdW9",
        baseline_style="happy",
        baseline_tag="[happily]",
        description="Jessica dengan intonasi ceria, hangat, ramah, dan pitch lebih tinggi.",
        baseline_voice_settings={
            "stability": 0.45,
            "similarity_boost": 0.80,
            "style": 0.30,
            "speed": 1.02,
        },
    ),
    "mode_4": VoiceCharacterMode(
        id="mode_4",
        name="Luna - Jessica Playful",
        voice_id="cgSgspJ2msm6clMCkdW9",
        baseline_style="playful",
        baseline_tag="[playful]",
        description="Jessica dengan intonasi lincah, ekspresif, manis, santai, dan akrab.",
        baseline_voice_settings={
            "stability": 0.45,
            "similarity_boost": 0.80,
            "style": 0.25,
            "speed": 1.02,
        },
    ),
    "mode_7": VoiceCharacterMode(
        id="mode_7",
        name="Luna - Laura Muda & Enerjik",
        voice_id="FGY2WhTYpPnrIDTdsKH5",
        baseline_style="happy",
        baseline_tag="[happily]",
        description="Laura dengan intonasi perempuan muda, cerdas, artikulatif, dan berenergi.",
        baseline_voice_settings={
            "stability": 0.45,
            "similarity_boost": 0.80,
            "style": 0.30,
            "speed": 1.02,
        },
    ),
}


def get_voice_character_mode(mode_id: str | None = None) -> VoiceCharacterMode:
    """Resolve voice character mode, defaulting to mode_2.

    Accepts raw identifiers such as 'mode_2', '2', 'mode2', etc.
    """
    if not mode_id:
        return VOICE_CHARACTER_MODES[DEFAULT_VOICE_MODE]

    clean = mode_id.strip().lower()
    # Normalize '2' -> 'mode_2', 'mode2' -> 'mode_2', etc.
    if clean in VOICE_CHARACTER_MODES:
        return VOICE_CHARACTER_MODES[clean]
    if clean.isdigit() and f"mode_{clean}" in VOICE_CHARACTER_MODES:
        return VOICE_CHARACTER_MODES[f"mode_{clean}"]
    if clean.startswith("mode") and not clean.startswith("mode_"):
        normalized = f"mode_{clean[4:]}"
        if normalized in VOICE_CHARACTER_MODES:
            return VOICE_CHARACTER_MODES[normalized]

    return VOICE_CHARACTER_MODES[DEFAULT_VOICE_MODE]
