from app.models import (
    AIRun,
    AIWorkerRun,
    BaseModel,
    Condition,
    ConditionSymptom,
    Conversation,
    ConversationSummary,
    EmotionAnalysis,
    Knowledge,
    KnowledgeChunk,
    Memory,
    Message,
    Notification,
    NotificationPolicy,
    RAGRetrieval,
    RAGRetrievalResult,
    SafetyAnalysis,
    SafetyEvent,
    Source,
    Symptom,
    User,
    UserDevice,
    VoiceSession,
    VoiceTurn,
)
from shared.database import Base


def test_all_22_models_registered_in_metadata() -> None:
    expected_tables = {
        "users",
        "user_devices",
        "conversations",
        "messages",
        "ai_runs",
        "ai_worker_runs",
        "emotion_analyses",
        "safety_analyses",
        "safety_events",
        "memories",
        "conversation_summaries",
        "voice_sessions",
        "voice_turns",
        "conditions",
        "symptoms",
        "condition_symptoms",
        "sources",
        "knowledge",
        "knowledge_chunks",
        "rag_retrievals",
        "rag_retrieval_results",
        "notification_policies",
        "notifications",
    }
    registered_tables = set(Base.metadata.tables.keys())
    assert expected_tables.issubset(registered_tables), (
        f"Missing tables: {expected_tables - registered_tables}"
    )


def test_model_class_tablenames() -> None:
    models = [
        (User, "users"),
        (UserDevice, "user_devices"),
        (Conversation, "conversations"),
        (Message, "messages"),
        (ConversationSummary, "conversation_summaries"),
        (AIRun, "ai_runs"),
        (AIWorkerRun, "ai_worker_runs"),
        (EmotionAnalysis, "emotion_analyses"),
        (SafetyAnalysis, "safety_analyses"),
        (SafetyEvent, "safety_events"),
        (Memory, "memories"),
        (VoiceSession, "voice_sessions"),
        (VoiceTurn, "voice_turns"),
        (Condition, "conditions"),
        (Symptom, "symptoms"),
        (ConditionSymptom, "condition_symptoms"),
        (Source, "sources"),
        (Knowledge, "knowledge"),
        (KnowledgeChunk, "knowledge_chunks"),
        (RAGRetrieval, "rag_retrievals"),
        (RAGRetrievalResult, "rag_retrieval_results"),
        (NotificationPolicy, "notification_policies"),
        (Notification, "notifications"),
    ]

    for model_cls, expected_tablename in models:
        assert issubclass(model_cls, BaseModel)
        assert model_cls.__tablename__ == expected_tablename
