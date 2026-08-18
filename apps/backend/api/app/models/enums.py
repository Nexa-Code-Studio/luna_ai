from enum import StrEnum


class ConversationStatus(StrEnum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    DELETED = "deleted"


class MessageRole(StrEnum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class MessageType(StrEnum):
    TEXT = "text"
    VOICE = "voice"
    SYSTEM = "system"
    EVENT = "event"


class AIRunType(StrEnum):
    COUNSELING = "counseling"
    ANALYSIS = "analysis"
    SUMMARY = "summary"
    SAFETY_CHECK = "safety_check"
    MEMORY_EXTRACTION = "memory_extraction"


class AIRunStatus(StrEnum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class AIWorkerType(StrEnum):
    EMOTION = "emotion"
    SAFETY = "safety"
    INTENT = "intent"
    MEMORY = "memory"
    RAG = "rag"
    RECOMMENDATION = "recommendation"
    SUMMARIZATION = "summarization"


class RiskLevel(StrEnum):
    NONE = "none"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class RiskType(StrEnum):
    NONE = "none"
    SELF_HARM = "self_harm"
    SUICIDE = "suicide"
    VIOLENCE = "violence"
    ABUSE = "abuse"
    OTHER = "other"


class SafetyEventType(StrEnum):
    SUICIDE_RISK = "suicide_risk"
    SELF_HARM = "self_harm"
    VIOLENCE = "violence"
    EMERGENCY = "emergency"


class SafetyEventStatus(StrEnum):
    OPEN = "open"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


class MemoryType(StrEnum):
    PREFERENCE = "preference"
    PERSONAL_FACT = "personal_fact"
    IMPORTANT_EVENT = "important_event"
    RELATIONSHIP = "relationship"
    GOAL = "goal"
    RECURRING_ISSUE = "recurring_issue"
    EMOTIONAL_PATTERN = "emotional_pattern"


class VoiceSessionStatus(StrEnum):
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"


class VoiceSpeaker(StrEnum):
    USER = "user"
    ASSISTANT = "assistant"


class ConditionStatus(StrEnum):
    ACTIVE = "active"
    ARCHIVED = "archived"


class SymptomStatus(StrEnum):
    ACTIVE = "active"
    ARCHIVED = "archived"


class ConditionSymptomRelationship(StrEnum):
    ASSOCIATED = "associated"
    COMMON = "common"
    CHARACTERISTIC = "characteristic"


class EvidenceLevel(StrEnum):
    LOW = "low"
    MODERATE = "moderate"
    STRONG = "strong"


class SourceType(StrEnum):
    GUIDELINE = "guideline"
    JOURNAL = "journal"
    GOVERNMENT = "government"
    ORGANIZATION = "organization"
    BOOK = "book"
    WEBSITE = "website"


class KnowledgeType(StrEnum):
    OVERVIEW = "overview"
    SYMPTOM_ASSOCIATION = "symptom_association"
    RISK_FACTOR = "risk_factor"
    WARNING_SIGN = "warning_sign"
    TREATMENT = "treatment"
    SELF_HELP = "self_help"
    PSYCHOEDUCATION = "psychoeducation"
    CRISIS = "crisis"


class KnowledgeStatus(StrEnum):
    ACTIVE = "active"
    ARCHIVED = "archived"


class NotificationPolicyType(StrEnum):
    SAFETY_ALERT = "safety_alert"
    DAILY_REMINDER = "daily_reminder"
    MOOD_CHECK = "mood_check"
    INACTIVITY = "inactivity"


class NotificationChannel(StrEnum):
    PUSH = "push"
    EMAIL = "email"
    IN_APP = "in_app"


class NotificationStatus(StrEnum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    READ = "read"


class DeviceType(StrEnum):
    ANDROID = "android"
    IOS = "ios"
    WEB = "web"
