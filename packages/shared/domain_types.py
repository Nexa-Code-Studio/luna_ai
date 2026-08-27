from enum import StrEnum
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class CallStatus(StrEnum):
    IDLE = "idle"
    CONNECTING = "connecting"
    ACTIVE = "active"
    ENDED = "ended"
    FAILED = "failed"


class SystemStatusResponse(BaseModel):
    status: str
    version: str
    database: str
    redis: str
    qdrant: str


class ApiResponse(BaseModel, Generic[T]):
    success: bool
    data: T | None = None
    error: str | None = None


class EmotionDetectionResult(BaseModel):
    """
    Structured output schema for voice emotion detection.
    Note: Emotion detection results represent voice-level signals/context only
    and do NOT constitute clinical mental health diagnoses.
    """
    primary_emotion: str
    confidence: float
    scores: dict[str, float]
    model_used: str = "iic/emotion2vec_plus_large"
    latency_ms: float


class MentalHealthKnowledgeItem(BaseModel):
    """
    Normalized Mental Health RAG Knowledge Item.
    Note: The `condition` field represents topical/taxonomical association,
    NOT a clinical diagnosis of the user.
    """
    id: str
    condition: str
    knowledge_type: str
    title: str
    content: str
    evidence_level: str
    source: str
    source_reference: str
    limitations: str


class SymptomDuration(StrEnum):
    RECENT = "recent"                     # < 1 week
    ONE_TO_TWO_WEEKS = "1_to_2_weeks"     # 1 - 2 weeks
    ONE_MONTH_OR_MORE = "1_month_or_more" # >= 1 month
    CHRONIC = "chronic"                   # Months / years
    UNSPECIFIED = "unspecified"           # Not explicitly stated


class ExtractedSymptomEvidence(BaseModel):
    symptom_code: str
    symptom_name: str
    category: str
    user_quote: str
    confidence: float
    severity_signal: str


class SymptomExtractionResult(BaseModel):
    """
    Structured output schema for user symptom & evidence extraction.
    Note: Symptom extraction represents natural speech evidence only
    and does NOT constitute a clinical diagnosis.
    """
    extracted_symptoms: list[ExtractedSymptomEvidence]
    duration: SymptomDuration = SymptomDuration.UNSPECIFIED
    has_somatic_signals: bool = False
    has_cognitive_signals: bool = False
    has_emotional_signals: bool = False
    has_behavioral_signals: bool = False


class SignalPolarity(StrEnum):
    POSITIVE = "positive"            # Direct assertion by user about self
    NEGATED = "negated"              # User explicitly negates ideation ("nggak mau mati")
    REPORTED_OTHER = "reported_other"# User reports ideation of another person ("temanku mau...")
    HYPOTHETICAL = "hypothetical"    # Conditional/fear-based ("takut kalau nanti aku...")
    FIGURATIVE = "figurative"        # Idiomatic expression ("capek uas mati gue")


class TemporalContext(StrEnum):
    CURRENT = "current"              # Immediate / active right now
    RECENT = "recent"                # Within last 1-4 weeks
    HISTORICAL = "historical"        # Past history (> 1 month ago, currently denied)
    UNKNOWN = "unknown"


class IntentLevel(StrEnum):
    NONE = "none"
    PASSIVE = "passive"              # Ideation without immediate plan/action
    ACTIVE = "active"                # Intent with plan/action in progress
    UNSPECIFIED = "unspecified"


class RiskTarget(StrEnum):
    SELF = "self"
    OTHER = "other"
    UNSPECIFIED = "unspecified"


class MentalHealthSeverity(StrEnum):
    NONE = "none"
    LOW = "low"
    MODERATE = "moderate"
    SEVERE = "severe"


class ProtocolAction(StrEnum):
    NORMAL_RAG = "NORMAL_RAG"
    STRUCTURED_COPING = "STRUCTURED_COPING"
    SAFETY_REVIEW = "SAFETY_REVIEW"
    CRISIS_REFERRAL = "CRISIS_REFERRAL"
    IMMEDIATE_HOTLINE = "IMMEDIATE_HOTLINE"


class RiskSignal(BaseModel):
    signal_type: str                  # "suicidal_ideation", "self_harm", "hopelessness", etc.
    polarity: SignalPolarity = SignalPolarity.POSITIVE
    temporal_context: TemporalContext = TemporalContext.CURRENT
    intent: IntentLevel = IntentLevel.UNSPECIFIED
    target: RiskTarget = RiskTarget.SELF
    evidence: str
    confidence: float = 0.90


class RiskAssessmentInput(BaseModel):
    user_text: str
    symptom_result: SymptomExtractionResult
    emotion_result: EmotionDetectionResult | None = None
    dass_scores: dict[str, int] | None = None
    history_signals: list[RiskSignal] = []


class RiskAssessmentOutput(BaseModel):
    """
    Pure evaluation output for safety triage and mental health severity.
    Note: Safety risk evaluation determines risk levels & protocol actions,
    but executes NO side effects.
    """
    mental_health_severity: MentalHealthSeverity
    risk_level: str                  # "none" | "low" | "medium" | "high" | "critical"
    risk_type: str                   # "none" | "self_harm" | "suicide" | "violence" | "abuse" | "other"
    decision_rule: str              # e.g., "PASSIVE_IDEATION_CURRENT", "DASS_SEVERITY_EVALUATION"
    evidence: list[str]             # Explicit audit trail text
    evidence_confidence: float      # Confidence score of evidence interpretation (0.0 - 1.0)
    requires_escalation: bool      # True if risk_level in ["high", "critical"]
    protocol_action: ProtocolAction


class ResponseMode(StrEnum):
    NORMAL = "normal"
    COPING = "coping"
    CRISIS = "crisis"


class LLMMode(StrEnum):
    NONE = "none"                     # Freeform LLM is strictly disabled; use verified crisis templates
    BOUNDED_CRISIS = "bounded_crisis" # LLM is restricted to strictly bounded, empathetic phrasing without advice
    NORMAL = "normal"                 # Standard LLM response generation


class SafetyAction(StrEnum):
    NORMAL_RAG = "normal_rag"
    STRUCTURED_COPING = "structured_coping"
    BOUNDED_LLM = "bounded_llm"
    CRISIS_TEMPLATE = "crisis_template"
    RESOURCE_RESOLUTION = "resource_resolution"
    HUMAN_ESCALATION = "human_escalation"


class SafetyGateInput(BaseModel):
    risk_output: RiskAssessmentOutput
    conversation_id: str | None = None
    message_id: str | None = None


class SafetyPolicyDecision(BaseModel):
    """
    Pure Policy Decision Payload produced by SafetyGate.
    Note: Policy decision determines permissions & execution modes,
    but executes NO side effects.
    """
    risk_level: str                 # Retained from RiskAssessmentOutput for downstream audit
    risk_type: str                  # Retained from RiskAssessmentOutput
    decision_rule: str              # Retained from RiskAssessmentOutput (e.g. "PASSIVE_IDEATION_CURRENT")
    mode: ResponseMode              # NORMAL | COPING | CRISIS
    response_policy: ProtocolAction # NORMAL_RAG | STRUCTURED_COPING | SAFETY_REVIEW | CRISIS_REFERRAL | IMMEDIATE_HOTLINE
    llm_mode: LLMMode               # NONE | BOUNDED_CRISIS | NORMAL
    allow_normal_rag: bool
    requires_crisis_sop: bool
    requires_human_escalation: bool # Pure Policy Flag (NOT a side effect call)
    allowed_actions: list[SafetyAction]
    prohibited_actions: list[SafetyAction]
    resource_category: str          # "none", "mild_psychoeducation", "structured_coping", "crisis_referral_directory", "emergency_hotline_directory"
    audit_required: bool = True





