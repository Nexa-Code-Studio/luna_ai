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
