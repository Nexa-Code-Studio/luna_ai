import pytest
from app.tasks.symptom_task import extract_symptom_task


@pytest.mark.asyncio
async def test_extract_symptom_task_execution():
    ctx = {}
    user_text = "Saya merasa sangat cemas dan sesak napas seminggu terakhir"
    
    result = await extract_symptom_task(
        ctx,
        user_text=user_text,
        conversation_id="test-conv-123",
        message_id="test-msg-456",
    )
    
    assert result["status"] == "completed"
    assert result["conversation_id"] == "test-conv-123"
    assert "symptom_result" in result
    
    symptom_res = result["symptom_result"]
    assert symptom_res["duration"] == "1_to_2_weeks"
    assert len(symptom_res["extracted_symptoms"]) > 0
    extracted_codes = [s["symptom_code"] for s in symptom_res["extracted_symptoms"]]
    assert "breathing_difficulty" in extracted_codes
