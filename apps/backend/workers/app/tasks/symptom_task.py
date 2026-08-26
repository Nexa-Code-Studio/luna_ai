import logging
from typing import Any

from ai.services.symptom_service import SymptomService
from shared.domain_types import SymptomExtractionResult

logger = logging.getLogger(__name__)

_symptom_service_instance: SymptomService | None = None


def get_symptom_service() -> SymptomService:
    """
    Returns cached SymptomService instance for reuse within the worker process.
    """
    global _symptom_service_instance
    if _symptom_service_instance is None:
        _symptom_service_instance = SymptomService()
    return _symptom_service_instance


async def extract_symptom_task(
    ctx: dict[str, Any],
    user_text: str,
    conversation_id: str | None = None,
    message_id: str | None = None,
) -> dict[str, Any]:
    """
    ARQ Background Task adapter for extracting symptom & evidence from user text.

    Args:
        ctx: ARQ context dictionary.
        user_text: Natural user text input.
        conversation_id: Optional UUID/ID of current conversation.
        message_id: Optional UUID/ID of source message.

    Returns:
        JSON-serializable dictionary containing extracted symptoms & duration.
    """
    logger.info(f"Executing extract_symptom_task for conversation: {conversation_id}")

    service = get_symptom_service()
    result: SymptomExtractionResult = service.extract_symptoms(user_text)

    return {
        "status": "completed",
        "user_text": user_text,
        "conversation_id": conversation_id,
        "message_id": message_id,
        "symptom_result": result.model_dump(),
    }
