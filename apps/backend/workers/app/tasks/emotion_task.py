import logging
import os
from typing import Any

from ai.services.emotion_service import EmotionService
from shared.domain_types import EmotionDetectionResult

logger = logging.getLogger(__name__)

# Cached instance within the same worker process
_emotion_service_instance: EmotionService | None = None


def get_emotion_service() -> EmotionService:
    """
    Returns cached EmotionService instance to preserve lazy model loading
    and model instance reuse within the same ARQ worker process.
    """
    global _emotion_service_instance
    if _emotion_service_instance is None:
        _emotion_service_instance = EmotionService()
    return _emotion_service_instance


async def detect_voice_emotion_task(
    ctx: dict[str, Any],
    audio_path: str,
    conversation_id: str | None = None,
    message_id: str | None = None,
) -> dict[str, Any]:
    """
    ARQ Background Task adapter for voice emotion recognition using EmotionService.

    Args:
        ctx: ARQ context dictionary.
        audio_path: Path to input audio file.
        conversation_id: Optional UUID/ID of current conversation.
        message_id: Optional UUID/ID of source message.

    Returns:
        JSON-serializable dictionary containing emotion detection result.
    """
    logger.info(f"Executing detect_voice_emotion_task for audio: '{audio_path}'")

    if not os.path.exists(audio_path):
        raise FileNotFoundError(f"Audio file for emotion detection not found at: {audio_path}")

    service = get_emotion_service()
    result: EmotionDetectionResult = service.predict(audio_path)

    return {
        "status": "completed",
        "audio_path": audio_path,
        "conversation_id": conversation_id,
        "message_id": message_id,
        "emotion_result": result.model_dump(),
    }
