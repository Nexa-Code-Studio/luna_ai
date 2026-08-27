import logging
from typing import Any

from ai.services.risk_assessment_service import RiskAssessmentService
from shared.domain_types import (
    EmotionDetectionResult,
    RiskAssessmentInput,
    RiskAssessmentOutput,
    SymptomExtractionResult,
)

logger = logging.getLogger(__name__)

_risk_service_instance: RiskAssessmentService | None = None


def get_risk_service() -> RiskAssessmentService:
    """
    Returns process-cached RiskAssessmentService instance for reuse within the worker.
    """
    global _risk_service_instance
    if _risk_service_instance is None:
        _risk_service_instance = RiskAssessmentService()
    return _risk_service_instance


async def assess_risk_task(
    ctx: dict[str, Any],
    user_text: str,
    symptom_result_dict: dict[str, Any] | None = None,
    emotion_result_dict: dict[str, Any] | None = None,
    dass_scores: dict[str, int] | None = None,
    conversation_id: str | None = None,
    message_id: str | None = None,
) -> dict[str, Any]:
    """
    ARQ Worker task adapter for risk assessment & safety evaluation.

    Args:
        ctx: ARQ context dictionary.
        user_text: Natural user text input.
        symptom_result_dict: Optional dictionary payload from SymptomExtractionResult.
        emotion_result_dict: Optional dictionary payload from EmotionDetectionResult.
        dass_scores: Optional dictionary of scaled DASS-21 subscale scores.
        conversation_id: Optional conversation UUID/ID.
        message_id: Optional message UUID/ID.

    Returns:
        JSON-serializable dictionary containing RiskAssessmentOutput evaluation.
    """
    logger.info(f"Executing assess_risk_task for conversation: {conversation_id}")

    symptom_res = (
        SymptomExtractionResult(**symptom_result_dict)
        if symptom_result_dict
        else SymptomExtractionResult(extracted_symptoms=[])
    )
    emotion_res = (
        EmotionDetectionResult(**emotion_result_dict)
        if emotion_result_dict
        else None
    )

    inp = RiskAssessmentInput(
        user_text=user_text,
        symptom_result=symptom_res,
        emotion_result=emotion_res,
        dass_scores=dass_scores,
    )

    service = get_risk_service()
    output: RiskAssessmentOutput = service.assess(inp)

    return {
        "status": "completed",
        "user_text": user_text,
        "conversation_id": conversation_id,
        "message_id": message_id,
        "risk_result": output.model_dump(),
    }
