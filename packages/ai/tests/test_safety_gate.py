import pytest

from ai.services.safety_gate import SafetyGate
from shared.domain_types import (
    LLMMode,
    MentalHealthSeverity,
    ProtocolAction,
    ResponseMode,
    RiskAssessmentOutput,
    SafetyAction,
    SafetyGateInput,
)


@pytest.fixture
def gate():
    return SafetyGate()


def test_critical_risk_policy(gate):
    risk = RiskAssessmentOutput(
        mental_health_severity=MentalHealthSeverity.SEVERE,
        risk_level="critical",
        risk_type="suicide",
        decision_rule="EXPLICIT_ACTIVE_INTENT",
        evidence=["User said mau bunuh diri"],
        evidence_confidence=0.95,
        requires_escalation=True,
        protocol_action=ProtocolAction.IMMEDIATE_HOTLINE,
    )
    inp = SafetyGateInput(risk_output=risk, conversation_id="c123")
    decision = gate.evaluate_policy(inp)

    assert decision.mode == ResponseMode.CRISIS
    assert decision.llm_mode == LLMMode.NONE
    assert decision.allow_normal_rag is False
    assert decision.requires_crisis_sop is True
    assert decision.requires_human_escalation is True
    assert SafetyAction.NORMAL_RAG in decision.prohibited_actions
    assert SafetyAction.BOUNDED_LLM in decision.prohibited_actions
    assert SafetyAction.CRISIS_TEMPLATE in decision.allowed_actions
    assert decision.resource_category == "emergency_hotline_directory"


def test_high_risk_policy(gate):
    risk = RiskAssessmentOutput(
        mental_health_severity=MentalHealthSeverity.MODERATE,
        risk_level="high",
        risk_type="suicide",
        decision_rule="PASSIVE_IDEATION_CURRENT",
        evidence=["User said capek hidup"],
        evidence_confidence=0.90,
        requires_escalation=True,
        protocol_action=ProtocolAction.CRISIS_REFERRAL,
    )
    inp = SafetyGateInput(risk_output=risk)
    decision = gate.evaluate_policy(inp)

    assert decision.mode == ResponseMode.CRISIS
    assert decision.llm_mode == LLMMode.BOUNDED_CRISIS
    assert decision.allow_normal_rag is False
    assert decision.requires_crisis_sop is True
    assert decision.requires_human_escalation is True
    assert SafetyAction.BOUNDED_LLM in decision.allowed_actions
    assert SafetyAction.NORMAL_RAG in decision.prohibited_actions
    assert decision.resource_category == "crisis_referral_directory"


def test_medium_risk_policy(gate):
    risk = RiskAssessmentOutput(
        mental_health_severity=MentalHealthSeverity.MODERATE,
        risk_level="medium",
        risk_type="none",
        decision_rule="DASS_DISTRESS_EVALUATION",
        evidence=["DASS depression elevated"],
        evidence_confidence=0.88,
        requires_escalation=False,
        protocol_action=ProtocolAction.STRUCTURED_COPING,
    )
    inp = SafetyGateInput(risk_output=risk)
    decision = gate.evaluate_policy(inp)

    assert decision.mode == ResponseMode.COPING
    assert decision.llm_mode == LLMMode.NORMAL
    assert decision.allow_normal_rag is True
    assert decision.requires_crisis_sop is False
    assert decision.requires_human_escalation is False
    assert SafetyAction.STRUCTURED_COPING in decision.allowed_actions
    assert decision.resource_category == "structured_coping"


def test_low_and_none_risk_policy(gate):
    risk = RiskAssessmentOutput(
        mental_health_severity=MentalHealthSeverity.NONE,
        risk_level="none",
        risk_type="none",
        decision_rule="DEFAULT_ROUTINE_CONVERSATION",
        evidence=["No distress"],
        evidence_confidence=0.95,
        requires_escalation=False,
        protocol_action=ProtocolAction.NORMAL_RAG,
    )
    inp = SafetyGateInput(risk_output=risk)
    decision = gate.evaluate_policy(inp)

    assert decision.mode == ResponseMode.NORMAL
    assert decision.llm_mode == LLMMode.NORMAL
    assert decision.allow_normal_rag is True
    assert decision.requires_crisis_sop is False
    assert decision.requires_human_escalation is False
    assert SafetyAction.NORMAL_RAG in decision.allowed_actions
    assert decision.resource_category == "none"
