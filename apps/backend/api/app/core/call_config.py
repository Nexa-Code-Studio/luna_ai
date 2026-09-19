from dataclasses import dataclass
import os


@dataclass
class CallTurnConfig:
    """Centralized configuration for Hybrid Half-Duplex AI Call system and Turn Endpointing."""

    # Adaptive Endpointing Timers (milliseconds)
    complete_phrase_wait_ms: int = int(os.getenv("CALL_COMPLETE_PHRASE_WAIT_MS", "650"))
    normal_phrase_wait_ms: int = int(os.getenv("CALL_NORMAL_PHRASE_WAIT_MS", "900"))
    incomplete_phrase_wait_ms: int = int(os.getenv("CALL_INCOMPLETE_PHRASE_WAIT_MS", "1500"))
    hesitation_wait_ms: int = int(os.getenv("CALL_HESITATION_WAIT_MS", "1400"))
    hard_max_inactivity_ms: int = int(os.getenv("CALL_HARD_MAX_INACTIVITY_MS", "2200"))

    # Hardware and transition guards (milliseconds)
    stt_restart_delay_ms: int = int(os.getenv("CALL_STT_RESTART_DELAY_MS", "200"))
    playback_to_listen_guard_ms: int = int(os.getenv("CALL_PLAYBACK_TO_LISTEN_GUARD_MS", "200"))
    barge_in_to_listen_guard_ms: int = int(os.getenv("CALL_BARGE_IN_TO_LISTEN_GUARD_MS", "150"))

    # Feature flags
    enable_adaptive_endpoint: bool = os.getenv("CALL_ENABLE_ADAPTIVE_ENDPOINT", "true").lower() == "true"
    enable_thesis_logging: bool = os.getenv("CALL_ENABLE_THESIS_LOGGING", "true").lower() == "true"
    auto_restart_stt: bool = os.getenv("CALL_AUTO_RESTART_STT", "true").lower() == "true"
    max_restarts_per_turn: int = int(os.getenv("CALL_MAX_RESTARTS_PER_TURN", "10"))


call_config = CallTurnConfig()
