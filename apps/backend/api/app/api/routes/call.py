import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.services.audio_stream_buffer import AudioStreamBufferService
from app.services.call_session_manager import call_session_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/call", tags=["Call"])
audio_buffer_service = AudioStreamBufferService()


@router.websocket("/ws/{session_id}")
async def websocket_call_endpoint(
    websocket: WebSocket,
    session_id: str,
) -> None:
    """Bi-directional WebSocket endpoint for AI Phone Call sessions.
    
    Supports:
    - Binary frames: Incoming raw microphone audio bytes (forwarded to audio_buffer_service).
    - Text/JSON frames: Control events (`start_call`, `user_transcript`, `user_interrupted`, `end_call`, `ping`).
    """
    await websocket.accept()
    session = call_session_manager.register_session(session_id, websocket)
    logger.info(f"🔌 [WEBSOCKET CONNECTED] Session: {session_id}")

    try:
        # Pre-load previous conversation history from DB so DeepSeek LLM remembers past context
        await call_session_manager.load_conversation_history(session)

        # Notify client connection accepted
        await websocket.send_json({
            "type": "call_connected",
            "session_id": session_id,
            "message": "Connected to Luna AI Phone Service",
        })

        while True:
            message = await websocket.receive()
            if "bytes" in message and message["bytes"]:
                audio_bytes = message["bytes"]
                logger.info(f"🎙️ [INCOMING MIC AUDIO] Session {session_id}: Received {len(audio_bytes)} raw mic bytes")
                await audio_buffer_service.handle_incoming_audio_chunk(session_id, audio_bytes)
            
            elif "text" in message and message["text"]:
                try:
                    payload = json.loads(message["text"])
                    event_type = payload.get("type")

                    if event_type == "start_call":
                        logger.info(f"🚀 [CALL SESSION STARTED] Session {session_id}")
                        await websocket.send_json({"type": "call_started", "session_id": session_id})

                    elif event_type == "user_transcript":
                        user_text = payload.get("text", "")
                        logger.info(f"💬 [INCOMING USER SPEECH] Session {session_id}: '{user_text}'")
                        await call_session_manager.handle_user_transcript(session, user_text)

                    elif event_type == "user_interrupted":
                        logger.info(f"⚡ [USER INTERRUPTED AI] Session {session_id}")
                        session.cancel_active_ai_task()
                        await websocket.send_json({"type": "interrupted_ack"})

                    elif event_type == "end_call":
                        duration_sec = payload.get("duration_seconds")
                        logger.info(f"🛑 [CALL ENDED BY USER] Session {session_id}, Duration: {duration_sec}s")
                        await call_session_manager.update_session_end(session_id, duration_seconds=duration_sec)
                        break

                    elif event_type == "ping":
                        await websocket.send_json({"type": "pong"})

                except json.JSONDecodeError:
                    logger.warning(f"⚠️ [INVALID JSON] Session {session_id}: Received malformed JSON")

    except WebSocketDisconnect:
        logger.info(f"🔌 [WEBSOCKET DISCONNECTED] Session {session_id}")
    except Exception as e:
        logger.error(f"❌ [WEBSOCKET ERROR] Session {session_id}: {e}")
    finally:
        call_session_manager.unregister_session(session_id)
        audio_buffer_service.clear_session(session_id)
