from dataclasses import dataclass
import logging
import re
from typing import Literal

from app.core.call_config import CallTurnConfig, call_config

logger = logging.getLogger(__name__)

TurnDecisionType = Literal["KEEP_OPEN", "COMMIT", "WAIT"]


@dataclass
class TurnDetectionResult:
    decision: TurnDecisionType
    wait_ms: int
    reason: str
    semantic_class: str
    confidence: float


class TurnDetectionService:
    """Adaptive Turn Detection and Semantic Endpointing for conversational speech in Bahasa Indonesia."""

    INCOMPLETE_TAIL_WORDS = {
        "dan", "atau", "karena", "kalau", "jika", "untuk", "dengan", "dari", "ke",
        "yang", "jadi", "terus", "kemudian", "tapi", "tetapi", "namun", "sehingga",
        "supaya", "agar", "soalnya", "sedangkan", "yaitu", "yakni", "tentang",
        "seperti", "bagaikan", "maupun", "lalu", "pada", "saat", "ketika", "kalo",
    }

    INCOMPLETE_TAIL_PHRASES = [
        "saya mau", "saya ingin", "aku mau", "aku ingin", "kalau misalnya",
        "yang saya maksud", "jadi sebenarnya", "untuk yang", "terus kalau",
        "maksud saya", "maksudku", "bisa tolong", "apakah bisa", "gimana kalau",
    ]

    HESITATION_WORDS = {
        "hmm", "hm", "eh", "eee", "ee", "anu", "sebentar", "bentar",
        "apa ya", "gimana ya", "aduh", "wait", "uhm", "uh",
    }

    FAST_COMMIT_EXACT = {
        "ya", "ya benar", "benar", "iya", "iya benar", "betul", "tidak", "bukan",
        "tidak jadi", "nggak", "enggak", "oke", "siap", "sudah", "belum", "tentu",
        "bisa", "baik", "paham", "terima kasih", "makasih", "cukup",
    }

    def __init__(self, config: CallTurnConfig | None = None) -> None:
        self.config = config or call_config

    def _clean_text(self, text: str) -> str:
        """Strip punctuation and normalize whitespace."""
        text = text.lower().strip()
        text = re.sub(r"[^\w\s]", " ", text)
        return re.sub(r"\s+", " ", text).strip()

    def classify_transcript(self, text: str) -> tuple[str, int, str]:
        """Classify Indonesian linguistic cues.
        
        Returns:
            tuple: (semantic_class, wait_ms, reason)
        """
        clean = self._clean_text(text)
        if not clean:
            return "empty", self.config.normal_phrase_wait_ms, "empty_transcript"

        # Check fast commit exact match
        if clean in self.FAST_COMMIT_EXACT:
            return "fast_commit", self.config.complete_phrase_wait_ms, "complete_phrase"

        # Check multi-word incomplete phrases at the end of text
        for phrase in self.INCOMPLETE_TAIL_PHRASES:
            if clean.endswith(phrase):
                return "incomplete", self.config.incomplete_phrase_wait_ms, "trailing_incomplete_phrase"

        words = clean.split()
        last_word = words[-1]

        # Check single-word incomplete connective/preposition at the end
        if last_word in self.INCOMPLETE_TAIL_WORDS:
            return "incomplete", self.config.incomplete_phrase_wait_ms, "trailing_incomplete_word"

        # Check hesitation / filler words at the end
        if last_word in self.HESITATION_WORDS or clean in self.HESITATION_WORDS:
            return "hesitation", self.config.hesitation_wait_ms, "hesitation_pause"

        # General complete/normal clause heuristic:
        # If last word ends with terminal punctuation in original text, e.g. ".", or contains >= 4 words
        # and doesn't look incomplete, tune between complete and normal wait
        return "normal", self.config.normal_phrase_wait_ms, "normal_phrase"

    def evaluate_endpoint(
        self,
        aggregated_transcript: str,
        latest_partial: str = "",
        time_since_last_activity_ms: float = 0.0,
        last_stt_status: str = "listening",
        number_of_segments: int = 1,
    ) -> TurnDetectionResult:
        """Evaluate if user conversation turn should KEEP_OPEN, COMMIT, or WAIT."""
        effective_text = (aggregated_transcript.strip() or latest_partial.strip())

        if not effective_text:
            return TurnDetectionResult(
                decision="KEEP_OPEN" if last_stt_status in ("done", "notListening") else "WAIT",
                wait_ms=self.config.normal_phrase_wait_ms,
                reason="empty_transcript",
                semantic_class="empty",
                confidence=1.0,
            )

        # 1. Hard inactivity timeout check (must commit even if incomplete phrase)
        if time_since_last_activity_ms >= self.config.hard_max_inactivity_ms:
            return TurnDetectionResult(
                decision="COMMIT",
                wait_ms=0,
                reason="hard_timeout",
                semantic_class="hard_timeout",
                confidence=1.0,
            )

        semantic_class, wait_ms, reason = self.classify_transcript(effective_text)

        # 2. Check if silence exceeds the adaptive wait threshold (with 25ms timer tolerance)
        if time_since_last_activity_ms >= (wait_ms - 25):
            return TurnDetectionResult(
                decision="COMMIT",
                wait_ms=0,
                reason=f"{semantic_class}_timeout",
                semantic_class=semantic_class,
                confidence=0.9 if semantic_class == "fast_commit" else 0.8,
            )

        # 3. If OS speech recognizer stopped but wait_ms has not expired yet:
        if last_stt_status in ("done", "notListening"):
            if semantic_class == "fast_commit":
                # Fast affirmations can commit on recognizer completion
                return TurnDetectionResult(
                    decision="COMMIT",
                    wait_ms=0,
                    reason="fast_commit_on_recognizer_done",
                    semantic_class=semantic_class,
                    confidence=0.95,
                )
            # Incomplete or normal sentences with remaining wait budget should keep turn open and restart STT
            remaining_wait = max(100, int(wait_ms - time_since_last_activity_ms))
            return TurnDetectionResult(
                decision="KEEP_OPEN",
                wait_ms=remaining_wait,
                reason=reason,
                semantic_class=semantic_class,
                confidence=0.85 if semantic_class == "incomplete" else 0.75,
            )

        # 4. User is still actively speaking or pause is within normal speaking window
        remaining_wait = max(50, int(wait_ms - time_since_last_activity_ms))
        return TurnDetectionResult(
            decision="WAIT",
            wait_ms=remaining_wait,
            reason=reason,
            semantic_class=semantic_class,
            confidence=0.7,
        )
