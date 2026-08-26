import pytest
from app.tasks.risk_task import assess_risk_task
from shared.domain_types import ProtocolAction


@pytest.mark.asyncio
async def test_assess_risk_task_execution():
    ctx = {}
    user_text = "Aku capek banget hidup begini"
    symptom_payload = {
        "extracted_symptoms": [
            {
                "symptom_code": "hopelessness",
                "symptom_name": "Keputusasaan / No Future",
                "category": "cognitive",
                "user_quote": "Aku capek banget hidup",
                "confidence": 0.9,
                "severity_signal": "severe",
            }
        ],
        "duration": "unspecified",
        "has_cognitive_signals": True,
    }

    result = await assess_risk_task(
        ctx,
        user_text=user_text,
        symptom_result_dict=symptom_payload,
        conversation_id="conv-risk-123",
        message_id="msg-risk-456",
    )

    assert result["status"] == "completed"
    assert result["conversation_id"] == "conv-risk-123"
    assert "risk_result" in result

    risk_res = result["risk_result"]
    assert risk_res["risk_level"] == "high"
    assert risk_res["requires_escalation"] is True
    assert risk_res["protocol_action"] == ProtocolAction.CRISIS_REFERRAL
