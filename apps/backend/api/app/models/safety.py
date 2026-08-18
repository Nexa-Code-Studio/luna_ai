import uuid
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel
from app.models.enums import SafetyEventStatus


class EmotionAnalysis(BaseModel):
    __tablename__ = "emotion_analyses"

    message_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ai_worker_run_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ai_worker_runs.id", ondelete="SET NULL"),
        nullable=True,
    )
    primary_emotion: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    secondary_emotion: Mapped[str | None] = mapped_column(String(50), nullable=True)
    confidence: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)
    emotions: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)
    intensity: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)

    __table_args__ = (Index("idx_emotion_analyses_created_at", "created_at"),)


class SafetyAnalysis(BaseModel):
    __tablename__ = "safety_analyses"

    message_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ai_worker_run_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ai_worker_runs.id", ondelete="SET NULL"),
        nullable=True,
    )
    risk_level: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    risk_type: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    confidence: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)
    detected: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    reasoning: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (Index("idx_safety_analyses_created_at", "created_at"),)


class SafetyEvent(BaseModel):
    __tablename__ = "safety_events"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    conversation_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("conversations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    safety_analysis_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("safety_analyses.id", ondelete="SET NULL"),
        nullable=True,
    )
    severity: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    event_type: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=SafetyEventStatus.OPEN,
        index=True,
    )
    detected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
        server_default=func.now(),
        index=True,
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolution_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    safety_analysis: Mapped[Optional["SafetyAnalysis"]] = relationship("SafetyAnalysis")
