import logging

from shared.domain_types import (
    LLMMode,
    ProtocolAction,
    ResponseMode,
    SafetyAction,
    SafetyGateInput,
    SafetyPolicyDecision,
)

logger = logging.getLogger(__name__)


class SafetyGate:
    """
    Pure Policy Decision Engine for Luna AI.

    Note:
    - Evaluates RiskAssessmentOutput and maps strictly to safety policy permissions & execution modes.
    - Pure service (NO Qdrant calls, NO DB calls, NO HTTP calls, NO hardcoded phone numbers, NO side effects).
    """

    def evaluate_policy(self, input_data: SafetyGateInput) -> SafetyPolicyDecision:
        """
        Main Policy Decision Entrypoint.
        Maps risk_output to a pure SafetyPolicyDecision payload.
        """
        risk_res = input_data.risk_output
        r_level = risk_res.risk_level.lower()
        r_type = risk_res.risk_type
        rule = risk_res.decision_rule

        logger.info(f"SafetyGate evaluating policy for risk_level='{r_level}', rule='{rule}'")

        if r_level == "critical":
            return SafetyPolicyDecision(
                risk_level=r_level,
                risk_type=r_type,
                decision_rule=rule,
                mode=ResponseMode.CRISIS,
                response_policy=ProtocolAction.IMMEDIATE_HOTLINE,
                llm_mode=LLMMode.NONE,
                allow_normal_rag=False,
                requires_crisis_sop=True,
                requires_human_escalation=True,  # Pure Policy Flag
                allowed_actions=[
                    SafetyAction.CRISIS_TEMPLATE,
                    SafetyAction.RESOURCE_RESOLUTION,
                    SafetyAction.HUMAN_ESCALATION,
                ],
                prohibited_actions=[
                    SafetyAction.NORMAL_RAG,
                    SafetyAction.BOUNDED_LLM,
                ],
                resource_category="emergency_hotline_directory",
                audit_required=True,
            )

        if r_level == "high":
            return SafetyPolicyDecision(
                risk_level=r_level,
                risk_type=r_type,
                decision_rule=rule,
                mode=ResponseMode.CRISIS,
                response_policy=ProtocolAction.CRISIS_REFERRAL,
                llm_mode=LLMMode.BOUNDED_CRISIS,
                allow_normal_rag=False,
                requires_crisis_sop=True,
                requires_human_escalation=True,  # Pure Policy Flag
                allowed_actions=[
                    SafetyAction.BOUNDED_LLM,
                    SafetyAction.CRISIS_TEMPLATE,
                    SafetyAction.RESOURCE_RESOLUTION,
                    SafetyAction.HUMAN_ESCALATION,
                ],
                prohibited_actions=[
                    SafetyAction.NORMAL_RAG,
                ],
                resource_category="crisis_referral_directory",
                audit_required=True,
            )

        if r_level == "medium":
            return SafetyPolicyDecision(
                risk_level=r_level,
                risk_type=r_type,
                decision_rule=rule,
                mode=ResponseMode.COPING,
                response_policy=ProtocolAction.STRUCTURED_COPING,
                llm_mode=LLMMode.NORMAL,
                allow_normal_rag=True,
                requires_crisis_sop=False,
                requires_human_escalation=False,
                allowed_actions=[
                    SafetyAction.STRUCTURED_COPING,
                    SafetyAction.BOUNDED_LLM,
                    SafetyAction.NORMAL_RAG,
                ],
                prohibited_actions=[
                    SafetyAction.CRISIS_TEMPLATE,
                    SafetyAction.HUMAN_ESCALATION,
                ],
                resource_category="structured_coping",
                audit_required=True,
            )

        if r_level == "low":
            return SafetyPolicyDecision(
                risk_level=r_level,
                risk_type=r_type,
                decision_rule=rule,
                mode=ResponseMode.NORMAL,
                response_policy=risk_res.protocol_action,
                llm_mode=LLMMode.NORMAL,
                allow_normal_rag=True,
                requires_crisis_sop=False,
                requires_human_escalation=False,
                allowed_actions=[
                    SafetyAction.NORMAL_RAG,
                    SafetyAction.STRUCTURED_COPING,
                    SafetyAction.BOUNDED_LLM,
                ],
                prohibited_actions=[
                    SafetyAction.CRISIS_TEMPLATE,
                    SafetyAction.HUMAN_ESCALATION,
                ],
                resource_category="mild_psychoeducation",
                audit_required=True,
            )

        # Default: 'none'
        return SafetyPolicyDecision(
            risk_level="none",
            risk_type=r_type,
            decision_rule=rule,
            mode=ResponseMode.NORMAL,
            response_policy=ProtocolAction.NORMAL_RAG,
            llm_mode=LLMMode.NORMAL,
            allow_normal_rag=True,
            requires_crisis_sop=False,
            requires_human_escalation=False,
            allowed_actions=[
                SafetyAction.NORMAL_RAG,
                SafetyAction.BOUNDED_LLM,
            ],
            prohibited_actions=[
                SafetyAction.CRISIS_TEMPLATE,
                SafetyAction.HUMAN_ESCALATION,
            ],
            resource_category="none",
            audit_required=True,
        )
