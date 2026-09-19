import json
import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_hybrid_websocket_fast_commit():
    with client.websocket_connect("/api/v1/call/ws/test_hybrid_1") as ws:
        connected = ws.receive_json()
        assert connected["type"] == "call_connected"

        # Client sends start_call
        ws.send_json({"type": "start_call"})
        started = ws.receive_json()
        assert started["type"] == "call_started"

        # User says "ya benar" (fast commit)
        ws.send_json({
            "type": "stt.final_segment",
            "call_id": "test_hybrid_1",
            "user_turn_id": 1,
            "stt_session_id": 1,
            "sequence": 1,
            "text": "ya benar",
        })
        ws.send_json({
            "type": "stt.status",
            "status": "done",
            "call_id": "test_hybrid_1",
            "user_turn_id": 1,
            "stt_session_id": 1,
        })

        # Expect thinking & committed events
        events_received = []
        for _ in range(6):
            try:
                msg = ws.receive()
                if "text" in msg and msg["text"]:
                    data = json.loads(msg["text"])
                    events_received.append(data.get("type"))
            except Exception:
                break

        assert "turn.committed" in events_received
        assert "ai.thinking" in events_received


def test_hybrid_websocket_incomplete_pause_keeps_turn_open():
    with client.websocket_connect("/api/v1/call/ws/test_hybrid_2") as ws:
        ws.receive_json()  # connected
        ws.send_json({"type": "start_call"})
        ws.receive_json()  # started

        # Segment 1: Incomplete phrase
        ws.send_json({
            "type": "stt.final_segment",
            "call_id": "test_hybrid_2",
            "user_turn_id": 1,
            "stt_session_id": 1,
            "sequence": 1,
            "text": "saya mau pesan untuk",
        })
        ws.send_json({
            "type": "stt.status",
            "status": "done",
            "call_id": "test_hybrid_2",
            "user_turn_id": 1,
            "stt_session_id": 1,
        })

        # Expect turn.keep_open
        msg = ws.receive_json()
        assert msg["type"] == "turn.keep_open"
        assert msg["user_turn_id"] == 1
        assert msg["restart_stt"] is True

        # Segment 2: Finished sentence in session 2
        ws.send_json({
            "type": "stt.final_segment",
            "call_id": "test_hybrid_2",
            "user_turn_id": 1,
            "stt_session_id": 2,
            "sequence": 2,
            "text": "besok pagi",
        })
        # Force commit or wait
        ws.send_json({
            "type": "user.force_commit",
            "call_id": "test_hybrid_2",
            "user_turn_id": 1,
        })

        # Expect turn.committed with merged text
        events = []
        for _ in range(5):
            try:
                data = ws.receive_json()
                events.append(data)
            except Exception:
                break

        committed_event = next((e for e in events if e.get("type") == "turn.committed"), None)
        assert committed_event is not None
        assert "saya mau pesan untuk besok pagi" in committed_event["final_transcript"]


def test_hybrid_websocket_barge_in():
    with client.websocket_connect("/api/v1/call/ws/test_hybrid_3") as ws:
        ws.receive_json()  # connected
        ws.send_json({"type": "start_call"})
        ws.receive_json()  # started

        # User triggers AI
        ws.send_json({
            "type": "stt.final_segment",
            "call_id": "test_hybrid_3",
            "user_turn_id": 1,
            "stt_session_id": 1,
            "sequence": 1,
            "text": "ceritakan lelucon",
        })
        ws.send_json({
            "type": "user.force_commit",
            "call_id": "test_hybrid_3",
            "user_turn_id": 1,
        })

        # User barges in
        ws.send_json({
            "type": "assistant.interrupt",
            "call_id": "test_hybrid_3",
            "assistant_turn_id": 1,
            "reason": "user_barge_in",
        })

        ack_found = False
        for _ in range(10):
            try:
                data = ws.receive_json()
                if data.get("type") == "assistant.interrupted_ack":
                    assert data["assistant_turn_id"] == 1
                    ack_found = True
                    break
            except Exception:
                break

        assert ack_found is True


def test_hybrid_websocket_call_sync():
    with client.websocket_connect("/api/v1/call/ws/test_hybrid_4") as ws:
        ws.receive_json()  # connected
        ws.send_json({"type": "start_call"})
        ws.receive_json()  # started

        ws.send_json({
            "type": "call.sync",
            "call_id": "test_hybrid_4",
            "known_state": "listening",
            "user_turn_id": 1,
            "assistant_turn_id": 0,
        })

        sync_state = ws.receive_json()
        assert sync_state["type"] == "call.sync_state"
        assert sync_state["active_user_turn_id"] == 1
