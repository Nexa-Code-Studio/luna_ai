import pytest
from ai.services.symptom_service import SymptomService
from shared.domain_types import SymptomDuration


def test_symptom_service_extraction():
    service = SymptomService()
    text = "Aku sebulan ini males banget ketemu teman dan hampir tiap malam susah tidur"
    
    result = service.extract_symptoms(text)
    
    assert len(result.extracted_symptoms) == 2
    codes = {e.symptom_code for e in result.extracted_symptoms}
    assert "social_withdrawal" in codes
    assert "sleep_disturbance" in codes
    assert result.duration == SymptomDuration.ONE_MONTH_OR_MORE
    assert result.has_somatic_signals is True
    assert result.has_behavioral_signals is True


def test_symptom_service_empty_text():
    service = SymptomService()
    result = service.extract_symptoms("")
    assert len(result.extracted_symptoms) == 0
    assert result.duration == SymptomDuration.UNSPECIFIED
