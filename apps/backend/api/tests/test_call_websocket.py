import pytest
from app.main import app
from app.services.audio_stream_buffer import AudioStreamBufferService, analyze_audio_placeholder
from fastapi.testclient import TestClient

client = TestClient(app)


@pytest.mark.asyncio
async def test_audio_stream_buffer_placeholder():
    service = AudioStreamBufferService()
    chunk = b"\x00\x01\x02\x03\x04"
    result = await service.handle_incoming_audio_chunk("sess_1", chunk)
    assert result["status"] == "audio_received"
    assert result["bytes_len"] == 5

    buf = service.get_or_create_buffer("sess_1")
    assert buf.total_bytes == 5
    assert buf.get_full_audio() == chunk


def test_call_websocket_lifecycle():
    with client.websocket_connect("/api/v1/call/ws/test_session_999") as websocket:
        # 1. Server sends call_connected event
        connected_data = websocket.receive_json()
        assert connected_data["type"] == "call_connected"
        assert connected_data["session_id"] == "test_session_999"

        # 2. Client sends start_call
        websocket.send_json({"type": "start_call"})
        started_data = websocket.receive_json()
        assert started_data["type"] == "call_started"

        # 3. Client sends binary audio stream
        websocket.send_bytes(b"\x11\x22\x33\x44\x55")

        # 4. Client sends ping
        websocket.send_json({"type": "ping"})
        pong_data = websocket.receive_json()
        assert pong_data["type"] == "pong"

        # 5. Client sends user_transcript (uses Mock LLM / Ollama fallback in test)
        websocket.send_json({"type": "user_transcript", "text": "Halo Luna, selamat pagi!"})
        thinking_data = websocket.receive_json()
        assert thinking_data["type"] == "ai_thinking"

        # 6. Receive AI transcript / binary TTS audio or finished signal
        received_types = []
        for _ in range(5):
            try:
                msg = websocket.receive()
                if "bytes" in msg and msg["bytes"]:
                    received_types.append("binary_audio")
                elif "text" in msg and msg["text"]:
                    data = websocket.receive_json()
                    received_types.append(data.get("type"))
            except Exception:
                break

        # 7. Client sends end_call
        websocket.send_json({"type": "end_call"})
