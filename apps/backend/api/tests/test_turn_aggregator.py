import time
import pytest

from app.core.call_config import CallTurnConfig
from app.services.turn_aggregator import TurnAggregator, merge_overlapping_segments
from app.services.turn_detection_service import TurnDetectionService


def test_merge_overlapping_segments():
    # 1. Exact overlap of tail and head
    seg1 = "saya mau pesan tiket"
    seg2 = "tiket untuk besok pagi"
    merged = merge_overlapping_segments(seg1, seg2)
    assert merged == "saya mau pesan tiket untuk besok pagi"

    # 2. Multi-word overlap
    seg_a = "halo selamat pagi apa"
    seg_b = "selamat pagi apa kabar kamu"
    merged_multi = merge_overlapping_segments(seg_a, seg_b)
    assert merged_multi == "halo selamat pagi apa kabar kamu"

    # 3. No overlap
    seg_x = "saya tinggal di bandung"
    seg_y = "cuaca sangat dingin"
    merged_no = merge_overlapping_segments(seg_x, seg_y)
    assert merged_no == "saya tinggal di bandung cuaca sangat dingin"

    # 4. Subset / containment
    seg_sub1 = "saya mau pesan tiket besok"
    seg_sub2 = "tiket besok"
    merged_sub = merge_overlapping_segments(seg_sub1, seg_sub2)
    assert merged_sub == "saya mau pesan tiket besok"


def test_fast_commit_phrase():
    config = CallTurnConfig(complete_phrase_wait_ms=600)
    agg = TurnAggregator("call_test_1", initial_turn_id=1, config=config)

    # User says "ya benar"
    agg.add_final_segment("ya benar", stt_session_id=1)
    agg.update_stt_status("done", stt_session_id=1)

    eval_result = agg.evaluate_turn()
    assert eval_result.decision == "COMMIT"
    assert eval_result.semantic_class == "fast_commit"

    transcript = agg.commit()
    assert transcript == "ya benar"
    assert agg.is_committed is True


def test_incomplete_phrase_keeps_turn_open_for_stt_restart():
    config = CallTurnConfig(incomplete_phrase_wait_ms=1500)
    agg = TurnAggregator("call_test_2", initial_turn_id=1, config=config)

    # Segment 1 in STT session 1: "saya mau pesan untuk"
    agg.add_final_segment("saya mau pesan untuk", stt_session_id=1)
    agg.update_stt_status("done", stt_session_id=1)

    eval_result = agg.evaluate_turn()
    # Sentence ends with "untuk" (incomplete), recognizer stopped -> should KEEP_OPEN
    assert eval_result.decision == "KEEP_OPEN"
    assert eval_result.semantic_class == "incomplete"
    assert agg.is_committed is False

    # STT restarts in session 2, user finishes: "tiket besok pagi"
    agg.add_final_segment("tiket besok pagi", stt_session_id=2)
    assert agg.current_turn.stt_session_count == 2
    assert agg.current_turn.restart_count == 1

    # Overlap/stitched transcript
    full_text = agg.get_aggregated_transcript()
    assert full_text == "saya mau pesan untuk tiket besok pagi"


def test_hard_inactivity_timeout():
    config = CallTurnConfig(hard_max_inactivity_ms=100)  # 100ms for fast unit test
    agg = TurnAggregator("call_test_3", initial_turn_id=1, config=config)

    agg.add_final_segment("kalau misalnya saya", stt_session_id=1)
    # Simulate waiting past hard timeout
    time.sleep(0.12)

    eval_result = agg.evaluate_turn()
    assert eval_result.decision == "COMMIT"
    assert eval_result.reason == "hard_timeout"


def test_manual_force_commit():
    agg = TurnAggregator("call_test_4", initial_turn_id=1)
    agg.add_final_segment("saya ingin berkonsultasi", stt_session_id=1)

    transcript = agg.force_commit()
    assert transcript == "saya ingin berkonsultasi"
    assert agg.is_committed is True
    metrics = agg.get_turn_metrics()
    assert metrics["forced_commit"] is True
    assert metrics["endpoint_reason"] == "manual_commit"


def test_empty_transcript_does_not_commit():
    agg = TurnAggregator("call_test_5", initial_turn_id=1)
    agg.update_stt_status("done", stt_session_id=1)

    eval_result = agg.evaluate_turn()
    assert eval_result.decision == "KEEP_OPEN"
    assert eval_result.reason == "empty_transcript"
    assert agg.is_committed is False


def test_turn_reset_increments_turn_id():
    agg = TurnAggregator("call_test_6", initial_turn_id=1)
    agg.add_final_segment("halo luna", stt_session_id=1)
    agg.commit()

    agg.reset_for_new_turn()
    assert agg.user_turn_id == 2
    assert agg.is_committed is False
    assert len(agg.current_turn.segments) == 0
    assert agg.get_aggregated_transcript() == ""
