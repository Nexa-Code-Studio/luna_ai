import pytest

from ai.services.emotion_service import EmotionDetectionResult
from ai.services.risk_assessment_service import RiskAssessmentService
from ai.services.symptom_service import SymptomService
from shared.domain_types import (
    MentalHealthSeverity,
    ProtocolAction,
    RiskAssessmentInput,
)


@pytest.fixture
def service():
    return RiskAssessmentService()


@pytest.fixture
def symptom_service():
    return SymptomService()


# 1. Normal conversation
def test_01_normal_conversation(service, symptom_service):
    text = "Selamat pagi Luna, kamu apa kabar?"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "none"
    assert res.protocol_action == ProtocolAction.NORMAL_RAG
    assert res.requires_escalation is False


# 2. Mild stress
def test_02_mild_stress(service, symptom_service):
    text = "Aku agak tegang mau presentasi besok"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level in ["low", "none"]
    assert res.requires_escalation is False


# 3. Moderate depression symptoms
def test_03_moderate_depression_symptoms(service, symptom_service):
    text = "Aku seminggu ini susah tidur dan males ketemu orang"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "medium"
    assert res.protocol_action == ProtocolAction.STRUCTURED_COPING
    assert res.requires_escalation is False


# 4. Passive suicidal ideation
def test_04_passive_suicidal_ideation(service, symptom_service):
    text = "Aku capek banget hidup begini"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "high"
    assert res.risk_type == "suicide"
    assert res.protocol_action == ProtocolAction.CRISIS_REFERRAL
    assert res.requires_escalation is True


# 5. Current suicidal intent
def test_05_current_suicidal_intent(service, symptom_service):
    text = "Aku mau mengakhiri hidupku"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "critical"
    assert res.risk_type == "suicide"
    assert res.protocol_action == ProtocolAction.IMMEDIATE_HOTLINE
    assert res.requires_escalation is True


# 6. Explicit plan
def test_06_explicit_plan(service, symptom_service):
    text = "Aku sudah beli obat banyak untuk nanti malam"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "critical"
    assert res.risk_type == "suicide"
    assert res.protocol_action == ProtocolAction.IMMEDIATE_HOTLINE
    assert res.requires_escalation is True


# 7. Historical self-harm
def test_07_historical_self_harm(service, symptom_service):
    text = "Aku kemarin ngelukai tanganku sendiri"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "low"
    assert res.protocol_action == ProtocolAction.SAFETY_REVIEW
    assert res.requires_escalation is False


# 8. Active self-harm in progress
def test_08_active_self_harm_in_progress(service, symptom_service):
    text = "Aku sedang melukai tanganku sekarang"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "critical"
    assert res.risk_type == "self_harm"
    assert res.protocol_action == ProtocolAction.IMMEDIATE_HOTLINE
    assert res.requires_escalation is True


# 9. Negated suicidal statement
def test_09_negated_suicidal_statement(service, symptom_service):
    text = "Aku merasa sedih tapi aku nggak mau bunuh diri"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level in ["low", "medium"]
    assert res.risk_level not in ["high", "critical"]
    assert res.requires_escalation is False


# 10. Figurative slang
def test_10_figurative_slang(service, symptom_service):
    text = "Mati gue dikerjain bos hari ini"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level in ["low", "none"]
    assert res.protocol_action == ProtocolAction.NORMAL_RAG
    assert res.requires_escalation is False


# 11. Reported speech
def test_11_reported_speech(service, symptom_service):
    text = "Temanku bilang dia mau bunuh diri"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "low"
    assert res.protocol_action == ProtocolAction.SAFETY_REVIEW
    assert res.requires_escalation is False


# 12. Hypothetical fear
def test_12_hypothetical_fear(service, symptom_service):
    text = "Aku takut banget kalau suatu saat aku sampai putus asa"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "medium"
    assert res.protocol_action == ProtocolAction.STRUCTURED_COPING
    assert res.requires_escalation is False


# 13. Historical ideation denial
def test_13_historical_ideation_denial(service, symptom_service):
    text = "Bulan lalu aku sempat pengen mati, tapi sekarang aku udah jauh lebih baik"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "low"
    assert res.protocol_action == ProtocolAction.SAFETY_REVIEW
    assert res.requires_escalation is False


# 14. Sad voice + no suicide text
def test_14_sad_voice_no_suicide_text(service, symptom_service):
    text = "Aku cuma kangen rumah"
    syms = symptom_service.extract_symptoms(text)
    emo = EmotionDetectionResult(
        primary_emotion="sad", confidence=0.85, scores={"sad": 0.85}, latency_ms=10.0
    )
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms, emotion_result=emo)
    res = service.assess(inp)

    assert res.risk_level in ["low", "none"]
    assert res.requires_escalation is False


# 15. Neutral voice + explicit suicide text
def test_15_neutral_voice_explicit_suicide_text(service, symptom_service):
    text = "Aku mau bunuh diri malam ini"
    syms = symptom_service.extract_symptoms(text)
    emo = EmotionDetectionResult(
        primary_emotion="neutral", confidence=0.90, scores={"neutral": 0.90}, latency_ms=10.0
    )
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms, emotion_result=emo)
    res = service.assess(inp)

    assert res.risk_level == "critical"
    assert res.requires_escalation is True


# 16. Severe DASS + no suicide
def test_16_severe_dass_no_suicide(service, symptom_service):
    text = "Aku merasa sedih banget tapi mau mencoba terapi"
    syms = symptom_service.extract_symptoms(text)
    dass = {"depression": 30, "anxiety": 12, "stress": 18}
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms, dass_scores=dass)
    res = service.assess(inp)

    assert res.mental_health_severity == MentalHealthSeverity.SEVERE
    assert res.risk_level in ["medium", "low"]
    assert res.requires_escalation is False


# 17. Severe DASS + suicide
def test_17_severe_dass_suicide(service, symptom_service):
    text = "Aku capek hidup"
    syms = symptom_service.extract_symptoms(text)
    dass = {"depression": 30, "anxiety": 15, "stress": 20}
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms, dass_scores=dass)
    res = service.assess(inp)

    assert res.mental_health_severity == MentalHealthSeverity.SEVERE
    assert res.risk_level == "high"
    assert res.requires_escalation is True


# 18. Hopelessness + farewell language
def test_18_hopelessness_farewell_language(service, symptom_service):
    text = "Aku pasrah, aku cuma mau pamit sama kalian semua"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "high"
    assert res.requires_escalation is True


# 19. Academic context + explicit suicide
def test_19_academic_context_explicit_suicide(service, symptom_service):
    text = "Karena UAS ini aku mau bunuh diri nanti malam"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level == "critical"
    assert res.requires_escalation is True


# 20. Academic context + figurative expression
def test_20_academic_context_figurative_expression(service, symptom_service):
    text = "UAS ini bikin mau mati rasanya"
    syms = symptom_service.extract_symptoms(text)
    inp = RiskAssessmentInput(user_text=text, symptom_result=syms)
    res = service.assess(inp)

    assert res.risk_level in ["low", "none"]
    assert res.requires_escalation is False
