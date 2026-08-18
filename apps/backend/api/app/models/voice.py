import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel
from app.models.enums import VoiceSessionStatus


class VoiceSession(BaseModel):
    __tablename__ = "voice_sessions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=VoiceSessionStatus.ACTIVE,
        index=True,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
        server_default=func.now(),
    )
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships
    turns: Mapped[list["VoiceTurn"]] = relationship(
        "VoiceTurn", back_populates="voice_session", cascade="all, delete-orphan"
    )


class VoiceTurn(BaseModel):
    __tablename__ = "voice_turns"

    voice_session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("voice_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    message_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("messages.id", ondelete="SET NULL"),
        nullable=True,
    )
    speaker: Mapped[str] = mapped_column(String(20), nullable=False)
    audio_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    transcript: Mapped[str | None] = mapped_column(Text, nullable=True)
    sequence_number: Mapped[int] = mapped_column(Integer, nullable=False)
    stt_provider: Mapped[str | None] = mapped_column(String(50), nullable=True)
    stt_model: Mapped[str | None] = mapped_column(String(100), nullable=True)
    tts_provider: Mapped[str | None] = mapped_column(String(50), nullable=True)
    tts_model: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Relationships
    voice_session: Mapped["VoiceSession"] = relationship("VoiceSession", back_populates="turns")

    __table_args__ = (
        UniqueConstraint(
            "voice_session_id",
            "sequence_number",
            name="uq_voice_turns_session_sequence",
        ),
        Index("idx_voice_turns_session_sequence", voice_session_id, sequence_number),
    )
