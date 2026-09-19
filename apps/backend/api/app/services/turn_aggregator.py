from dataclasses import dataclass, field
import logging
import time
from typing import Any

from app.core.call_config import CallTurnConfig, call_config
from app.services.turn_detection_service import TurnDetectionResult, TurnDetectionService

logger = logging.getLogger(__name__)


def merge_overlapping_segments(existing_text: str, new_segment: str) -> str:
    """Merge two segments deterministically by deduplicating word-level overlap."""
    clean_exist = existing_text.strip()
    clean_new = new_segment.strip()

    if not clean_exist:
        return clean_new
    if not clean_new:
        return clean_exist

    # Normalize words for matching
    exist_words = clean_exist.split()
    new_words = clean_new.split()

    # Check for complete subset/containment
    if clean_exist.lower().endswith(clean_new.lower()):
        return clean_exist

    # Match up to 6 overlapping words between tail of exist and head of new
    max_overlap = min(len(exist_words), len(new_words), 6)
    for k in range(max_overlap, 0, -1):
        tail_words = [w.lower().strip(".,!?") for w in exist_words[-k:]]
        head_words = [w.lower().strip(".,!?") for w in new_words[:k]]
        if tail_words == head_words:
            # Merged: keep all existing words + remainder of new words
            remainder = new_words[k:]
            if remainder:
                return clean_exist + " " + " ".join(remainder)
            return clean_exist

    return clean_exist + " " + clean_new


@dataclass
class UserTurnState:
    call_id: str
    user_turn_id: int
    segments: list[str] = field(default_factory=list)
    latest_partial: str = ""
    created_at: float = field(default_factory=time.time)
    last_activity_at: float = field(default_factory=time.time)
    last_final_segment_at: float | None = None
    stt_session_count: int = 1
    last_stt_status: str = "listening"
    endpoint_reason: str = ""
    semantic_class: str = ""
    endpoint_wait_ms: int = 0
    committed: bool = False
    forced_commit: bool = False
    barge_in: bool = False
    restart_count: int = 0


class TurnAggregator:
    """Manages user turn aggregation, segment stitching, deduplication, and endpoint evaluation."""

    def __init__(
        self,
        call_id: str,
        initial_turn_id: int = 1,
        config: CallTurnConfig | None = None,
    ) -> None:
        self.call_id = call_id
        self.config = config or call_config
        self.detection_service = TurnDetectionService(self.config)
        self.current_turn = UserTurnState(call_id=call_id, user_turn_id=initial_turn_id)
        self.seen_stt_sessions: set[int] = set()

    @property
    def user_turn_id(self) -> int:
        return self.current_turn.user_turn_id

    @property
    def is_committed(self) -> bool:
        return self.current_turn.committed

    def register_stt_session(self, stt_session_id: int) -> None:
        if stt_session_id not in self.seen_stt_sessions:
            self.seen_stt_sessions.add(stt_session_id)
            self.current_turn.stt_session_count = len(self.seen_stt_sessions)
            if len(self.seen_stt_sessions) > 1:
                self.current_turn.restart_count += 1
            self.current_turn.last_activity_at = time.time()

    def add_partial(self, text: str, stt_session_id: int) -> None:
        if self.current_turn.committed:
            logger.debug(f"⚠️ [TURN AGGREGATOR] Discarding partial for committed turn {self.user_turn_id}")
            return
        self.register_stt_session(stt_session_id)
        self.current_turn.latest_partial = text.strip()
        self.current_turn.last_activity_at = time.time()

    def add_final_segment(self, text: str, stt_session_id: int) -> None:
        if self.current_turn.committed:
            logger.debug(f"⚠️ [TURN AGGREGATOR] Discarding final segment for committed turn {self.user_turn_id}")
            return
        self.register_stt_session(stt_session_id)
        clean_text = text.strip()
        if clean_text:
            self.current_turn.segments.append(clean_text)
            self.current_turn.latest_partial = ""
            now = time.time()
            self.current_turn.last_activity_at = now
            self.current_turn.last_final_segment_at = now

    def update_stt_status(self, status: str, stt_session_id: int) -> None:
        if self.current_turn.committed:
            return
        self.register_stt_session(stt_session_id)
        self.current_turn.last_stt_status = status
        self.current_turn.last_activity_at = time.time()

    def get_aggregated_transcript(self) -> str:
        """Returns normalized, deduplicated transcript of all final segments in this turn."""
        if not self.current_turn.segments:
            return self.current_turn.latest_partial.strip()

        aggregated = self.current_turn.segments[0]
        for seg in self.current_turn.segments[1:]:
            aggregated = merge_overlapping_segments(aggregated, seg)

        return aggregated.strip()

    def evaluate_turn(self) -> TurnDetectionResult:
        """Evaluate whether to KEEP_OPEN, COMMIT, or WAIT."""
        if self.current_turn.committed:
            return TurnDetectionResult(
                decision="COMMIT",
                wait_ms=0,
                reason="already_committed",
                semantic_class=self.current_turn.semantic_class or "committed",
                confidence=1.0,
            )

        aggregated = self.get_aggregated_transcript()
        elapsed_ms = (time.time() - self.current_turn.last_activity_at) * 1000.0

        result = self.detection_service.evaluate_endpoint(
            aggregated_transcript=aggregated,
            latest_partial=self.current_turn.latest_partial,
            time_since_last_activity_ms=elapsed_ms,
            last_stt_status=self.current_turn.last_stt_status,
            number_of_segments=len(self.current_turn.segments),
        )

        self.current_turn.endpoint_reason = result.reason
        self.current_turn.semantic_class = result.semantic_class
        self.current_turn.endpoint_wait_ms = result.wait_ms

        return result

    def commit(self, reason: str | None = None) -> str:
        """Commit the current turn and return full aggregated transcript."""
        if not self.current_turn.committed:
            self.current_turn.committed = True
            if reason:
                self.current_turn.endpoint_reason = reason
            logger.info(
                f"✅ [TURN COMMITTED] Call {self.call_id} | Turn {self.user_turn_id} | "
                f"Reason: '{self.current_turn.endpoint_reason}' | "
                f"Segments: {len(self.current_turn.segments)} | Sessions: {self.current_turn.stt_session_count}"
            )
        return self.get_aggregated_transcript()

    def force_commit(self) -> str:
        """User manually tapped 'Selesai' / submit."""
        self.current_turn.forced_commit = True
        return self.commit(reason="manual_commit")

    def get_turn_metrics(self) -> dict[str, Any]:
        """Structured thesis evaluation metrics for this user turn."""
        t = self.current_turn
        now = time.time()
        final_text = self.get_aggregated_transcript()
        return {
            "call_id": t.call_id,
            "user_turn_id": t.user_turn_id,
            "segment_count": len(t.segments),
            "stt_session_count": t.stt_session_count,
            "restart_count": t.restart_count,
            "aggregated_text_length": len(final_text),
            "turn_started_at": t.created_at,
            "last_activity_at": t.last_activity_at,
            "committed_at": now if t.committed else None,
            "endpoint_wait_ms": t.endpoint_wait_ms,
            "endpoint_reason": t.endpoint_reason,
            "semantic_class": t.semantic_class,
            "barge_in": t.barge_in,
            "forced_commit": t.forced_commit,
        }

    def reset_for_new_turn(self, new_turn_id: int | None = None) -> None:
        """Prepare aggregator for next logical user conversation turn."""
        next_id = new_turn_id if new_turn_id is not None else self.current_turn.user_turn_id + 1
        self.seen_stt_sessions.clear()
        self.current_turn = UserTurnState(call_id=self.call_id, user_turn_id=next_id)
