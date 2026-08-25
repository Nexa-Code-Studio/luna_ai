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

