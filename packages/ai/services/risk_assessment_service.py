import logging
import re
from typing import List, Tuple

from shared.domain_types import (
    IntentLevel,
    MentalHealthSeverity,
    ProtocolAction,
    RiskAssessmentInput,
    RiskAssessmentOutput,
    RiskSignal,
    RiskTarget,
    SignalPolarity,
    TemporalContext,
)

logger = logging.getLogger(__name__)


class RiskAssessmentService:
    """
    Pure Evaluation Engine for Psychological Distress Severity and Safety Risk Classification.

    Note:
    - This is a pure evaluation service (NO HTTP, NO DB writes, NO Qdrant calls, NO side effects).
    - Triage logic is based on WHO EASE-derived decision trees.
    - Safety decision logic is 100% deterministic based on structured RiskSignal parsing.
    - Maintains dual-axis evaluation: `mental_health_severity` vs `risk_level`.
    """

    def parse_signals(self, input_data: RiskAssessmentInput) -> List[RiskSignal]:
        """
        Parses raw text, symptoms, and context into structured RiskSignal objects.
        """
        text = input_data.user_text.strip()
        lower_text = text.lower()
        signals: List[RiskSignal] = []

        # 1. Check active suicidal intent / plan
        active_plan_kws = ["mau bunuh diri", "sudah beli obat", "mau mengakhiri hidup", "mau melompat", "sudah siapkan tali", "mau mati malam ini"]
        for kw in active_plan_kws:
            if kw in lower_text:
                # Check for negation, reported speech, or figurative context
                polarity = SignalPolarity.POSITIVE
                target = RiskTarget.SELF
                temporal = TemporalContext.CURRENT
                intent = IntentLevel.ACTIVE

                if any(neg in lower_text for neg in ["tidak mau", "nggak mau", "gak mau", "bukan mau"]):
                    polarity = SignalPolarity.NEGATED
                    intent = IntentLevel.NONE
                elif any(oth in lower_text for oth in ["temanku", "teman aku", "orang lain", "dia mau"]):
                    polarity = SignalPolarity.REPORTED_OTHER
                    target = RiskTarget.OTHER
                elif any(hyp in lower_text for hyp in ["takut kalau", "takut nanti"]):
                    polarity = SignalPolarity.HYPOTHETICAL
                    intent = IntentLevel.NONE

                signals.append(
                    RiskSignal(
                        signal_type="suicidal_ideation",
                        polarity=polarity,
                        temporal_context=temporal,
                        intent=intent,
                        target=target,
                        evidence=f"Matched explicit active intent keyword '{kw}' in user text",
                        confidence=0.95,
                    )
                )
                break

        # 2. Check active self-harm in-progress or recent
        self_harm_kws = ["nyayat tangan", "melukai tangan", "ngelukai tangan", "iris tangan", "sayat tangan"]
        for kw in self_harm_kws:
            if kw in lower_text:
                polarity = SignalPolarity.POSITIVE
                target = RiskTarget.SELF
                temporal = TemporalContext.CURRENT
                intent = IntentLevel.ACTIVE if any(prog in lower_text for prog in ["sedang", "sekarang", "lagi"]) else IntentLevel.PASSIVE

                if "kemarin" in lower_text or "lalu" in lower_text or "dulu" in lower_text:
                    temporal = TemporalContext.HISTORICAL
                    intent = IntentLevel.NONE

                signals.append(
                    RiskSignal(
                        signal_type="self_harm",
                        polarity=polarity,
                        temporal_context=temporal,
                        intent=intent,
                        target=target,
                        evidence=f"Matched self-harm phrase '{kw}' in user text",
                        confidence=0.92,
                    )
                )
                break

        # 3. Check historical ideation denial ("bulan lalu sempat pengen mati, sekarang udah mendingan")
        if any(h in lower_text for h in ["dulu sempat", "bulan lalu sempat", "kemarin sempat pengen mati", "sempat pengen mati"]) and any(d in lower_text for d in ["sekarang udah mendingan", "sekarang sudah baik", "sekarang jauh lebih baik", "udah nggak", "tapi sekarang"]):
            signals.append(
                RiskSignal(
                    signal_type="historical_ideation",
                    polarity=SignalPolarity.POSITIVE,
                    temporal_context=TemporalContext.HISTORICAL,
                    intent=IntentLevel.NONE,
                    target=RiskTarget.SELF,
                    evidence="User explicitly mentioned historical ideation with current denial/recovery",
                    confidence=0.88,
                )
            )

        # 4. Check passive suicidal ideation / farewell / burden phrases
        elif not signals:
            passive_kws = ["capek hidup", "capek banget hidup", "berharap tidur gak bangun", "berharap tidak bangun", "kalau aku gak ada", "kalau aku tidak ada", "kalau aku nggak ada", "semua orang lebih baik", "semua orang bakal lebih baik", "mau pamit"]
            for kw in passive_kws:
                if kw in lower_text:
                    polarity = SignalPolarity.POSITIVE
                    target = RiskTarget.SELF
                    temporal = TemporalContext.CURRENT
                    intent = IntentLevel.PASSIVE

                    # Check figurative slang (e.g., "capek uas", "mati gue dikerjain bos")
                    if any(fig in lower_text for fig in ["mati gue", "dikerjain bos", "tugas ini", "soal uas", "soal ini", "game ini"]) and not any(active_kw in lower_text for active_kw in ["bunuh diri", "mengakhiri hidup"]):
                        polarity = SignalPolarity.FIGURATIVE
                        intent = IntentLevel.NONE

                    if any(neg in lower_text for neg in ["tidak mau", "nggak mau", "gak mau"]):
                        polarity = SignalPolarity.NEGATED
                        intent = IntentLevel.NONE

                    signals.append(
                        RiskSignal(
                            signal_type="passive_ideation",
                            polarity=polarity,
                            temporal_context=temporal,
                            intent=intent,
                            target=target,
                            evidence=f"Matched passive ideation phrase '{kw}'",
                            confidence=0.90,
                        )
                    )
                    break

        # 5. Include extracted symptoms as signals
        if input_data.symptom_result and input_data.symptom_result.extracted_symptoms:
            for s in input_data.symptom_result.extracted_symptoms:
                if s.symptom_code in ["hopelessness", "worthlessness", "meaninglessness"]:
                    signals.append(
                        RiskSignal(
                            signal_type=s.symptom_code,
                            polarity=SignalPolarity.POSITIVE,
                            temporal_context=TemporalContext.CURRENT,
                            intent=IntentLevel.PASSIVE,
                            target=RiskTarget.SELF,
                            evidence=f"Extracted symptom '{s.symptom_name}' ({s.user_quote})",
                            confidence=s.confidence,
                        )
                    )

        return signals

    def assess_mental_health_severity(
        self, dass_scores: dict[str, int] | None, symptom_result: any = None
    ) -> MentalHealthSeverity:
        """
        Evaluates general mental health distress severity (Axis A) based on DASS-21 norms & symptoms.
        Note: DASS severity measures distress level, NOT medical diagnosis or suicide risk.
        """
        if dass_scores:
            dep = dass_scores.get("depression", 0)
            anx = dass_scores.get("anxiety", 0)
            str_score = dass_scores.get("stress", 0)

            if dep >= 28 or anx >= 20 or str_score >= 34:
                return MentalHealthSeverity.SEVERE
            if dep >= 14 or anx >= 10 or str_score >= 19:
                return MentalHealthSeverity.MODERATE
            if dep >= 10 or anx >= 8 or str_score >= 15:
                return MentalHealthSeverity.LOW

        if symptom_result and hasattr(symptom_result, "extracted_symptoms"):
            s_count = len(symptom_result.extracted_symptoms)
            if s_count >= 2:
                return MentalHealthSeverity.MODERATE
            elif s_count >= 1:
                return MentalHealthSeverity.LOW

        return MentalHealthSeverity.NONE


    def assess_safety_risk(
        self, signals: List[RiskSignal], user_text: str
    ) -> Tuple[str, str, str, ProtocolAction, float, bool]:
        """
        Applies hierarchical WHO EASE-derived decision rules to determine safety risk level (Axis B).
        Precedence: CRITICAL > HIGH > SAFETY_REVIEW > MEDIUM > LOW > NONE.
        """
        lower_text = user_text.lower()
        evidence_list: List[str] = []

        # 1. Step 1: EXPLICIT_ACTIVE_INTENT (CRITICAL)
        active_signals = [
            s for s in signals
            if s.signal_type == "suicidal_ideation"
            and s.polarity == SignalPolarity.POSITIVE
            and s.target == RiskTarget.SELF
            and s.temporal_context == TemporalContext.CURRENT
            and s.intent == IntentLevel.ACTIVE
        ]
        if active_signals:
            ev = active_signals[0].evidence
            evidence_list.append(ev)
            return (
                "critical",
                "suicide",
                "EXPLICIT_ACTIVE_INTENT",
                ProtocolAction.IMMEDIATE_HOTLINE,
                active_signals[0].confidence,
                True,
            )

        # 2. Step 2: ACTIVE_SELF_HARM_IN_PROGRESS (CRITICAL)
        active_sh_signals = [
            s for s in signals
            if s.signal_type == "self_harm"
            and s.polarity == SignalPolarity.POSITIVE
            and s.target == RiskTarget.SELF
            and s.temporal_context == TemporalContext.CURRENT
            and s.intent == IntentLevel.ACTIVE
        ]
        if active_sh_signals:
            evidence_list.append(active_sh_signals[0].evidence)
            return (
                "critical",
                "self_harm",
                "ACTIVE_SELF_HARM_IN_PROGRESS",
                ProtocolAction.IMMEDIATE_HOTLINE,
                active_sh_signals[0].confidence,
                True,
            )

        # 3. Step 3: PASSIVE_IDEATION_CURRENT (HIGH)
        passive_signals = [
            s for s in signals
            if s.signal_type in ["passive_ideation", "suicidal_ideation"]
            and s.polarity == SignalPolarity.POSITIVE
            and s.target == RiskTarget.SELF
            and s.temporal_context == TemporalContext.CURRENT
        ]
        if passive_signals:
            evidence_list.append(passive_signals[0].evidence)
            return (
                "high",
                "suicide",
                "PASSIVE_IDEATION_CURRENT",
                ProtocolAction.CRISIS_REFERRAL,
                passive_signals[0].confidence,
                True,
            )

        # 4. Step 4: SELF_HARM_CURRENT (HIGH)
        current_sh_signals = [
            s for s in signals
            if s.signal_type == "self_harm"
            and s.polarity == SignalPolarity.POSITIVE
            and s.target == RiskTarget.SELF
            and s.temporal_context == TemporalContext.CURRENT
        ]
        if current_sh_signals:
            evidence_list.append(current_sh_signals[0].evidence)
            return (
                "high",
                "self_harm",
                "SELF_HARM_CURRENT",
                ProtocolAction.CRISIS_REFERRAL,
                current_sh_signals[0].confidence,
                True,
            )

        # 5. Step 5: NEGATED_STATEMENT_EVALUATION
        negated_signals = [s for s in signals if s.polarity == SignalPolarity.NEGATED]
        if negated_signals:
            evidence_list.append(negated_signals[0].evidence)
            return (
                "medium" if "sedih" in lower_text or "cemas" in lower_text else "low",
                "none",
                "NEGATED_STATEMENT_EVALUATION",
                ProtocolAction.STRUCTURED_COPING if "sedih" in lower_text or "cemas" in lower_text else ProtocolAction.SAFETY_REVIEW,
                negated_signals[0].confidence,
                False,
            )

        # 6. Step 6: REPORTED_OTHER_OR_HISTORICAL (SAFETY_REVIEW / LOW)
        other_or_historical = [
            s for s in signals
            if s.polarity == SignalPolarity.REPORTED_OTHER
            or s.temporal_context == TemporalContext.HISTORICAL
            or s.signal_type == "historical_ideation"
        ]
        if other_or_historical:
            s_item = other_or_historical[0]
            rule_name = "REPORTED_OTHER_SPEECH" if s_item.polarity == SignalPolarity.REPORTED_OTHER else "HISTORICAL_IDEATION_DENIAL"
            evidence_list.append(s_item.evidence)
            return (
                "low",
                "none",
                rule_name,
                ProtocolAction.SAFETY_REVIEW,
                s_item.confidence,
                False,
            )

        # 7. Step 7: FIGURATIVE_CONTEXT_DOWNGRADE (LOW)
        figurative_signals = [s for s in signals if s.polarity == SignalPolarity.FIGURATIVE]
        if figurative_signals:
            evidence_list.append(figurative_signals[0].evidence)
            return (
                "low",
                "none",
                "FIGURATIVE_CONTEXT_DOWNGRADE",
                ProtocolAction.NORMAL_RAG,
                0.85,
                False,
            )

        # 8. Step 8: DEFAULT EVALUATION (MEDIUM / LOW / NONE based on Mental Health Severity)
        hypo_signals = [s for s in signals if s.polarity == SignalPolarity.HYPOTHETICAL]
        if hypo_signals:
            evidence_list.append(hypo_signals[0].evidence)
            return (
                "medium",
                "none",
                "HYPOTHETICAL_FEAR_EVALUATION",
                ProtocolAction.STRUCTURED_COPING,
                0.88,
                False,
            )

        symptom_signals = [s for s in signals if s.signal_type in ["hopelessness", "worthlessness", "meaninglessness"]]
        if symptom_signals:
            evidence_list.append(symptom_signals[0].evidence)
            return (
                "medium",
                "none",
                "SEVERE_SYMPTOM_DISTRESS",
                ProtocolAction.STRUCTURED_COPING,
                0.85,
                False,
            )

        return (
            "none",
            "none",
            "DEFAULT_ROUTINE_CONVERSATION",
            ProtocolAction.NORMAL_RAG,
            0.95,
            False,
        )

    def assess(self, input_data: RiskAssessmentInput) -> RiskAssessmentOutput:
        """
        Main Pure Evaluation Entrypoint.
        Returns dual-axis output (MentalHealthSeverity & RiskLevel) + auditability details.
        """
        logger.info(f"Executing RiskAssessmentService.assess for text: '{input_data.user_text[:40]}...'")

        # 1. Parse structured signals
        signals = self.parse_signals(input_data)

        # 2. Assess Axis A: Mental Health Distress Severity
        mental_severity = self.assess_mental_health_severity(input_data.dass_scores, input_data.symptom_result)

        # 3. Assess Axis B: Safety Risk Level (Hierarchical WHO EASE Rules)
        risk_level, risk_type, decision_rule, action, confidence, escalation = self.assess_safety_risk(
            signals, input_data.user_text
        )

        # 4. Integrate mental_severity with safety risk if risk_level is 'none'
        if risk_level == "none":
            if mental_severity in [MentalHealthSeverity.SEVERE, MentalHealthSeverity.MODERATE]:
                risk_level = "medium"
                action = ProtocolAction.STRUCTURED_COPING
                decision_rule = "DASS_DISTRESS_EVALUATION"
            elif mental_severity == MentalHealthSeverity.LOW:
                risk_level = "low"
                action = ProtocolAction.STRUCTURED_COPING
                decision_rule = "MILD_DISTRESS_EVALUATION"

        evidence_str = [s.evidence for s in signals] if signals else ["No distress or safety signals detected"]

        return RiskAssessmentOutput(
            mental_health_severity=mental_severity,
            risk_level=risk_level,
            risk_type=risk_type,
            decision_rule=decision_rule,
            evidence=evidence_str,
            evidence_confidence=confidence,
            requires_escalation=escalation,
            protocol_action=action,
        )

