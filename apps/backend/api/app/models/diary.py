import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Index, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class DiaryEntry(BaseModel):
    __tablename__ = "diary_entries"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    entry_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    content: Mapped[str | None] = mapped_column(Text, nullable=True)
    mood_tag: Mapped[str | None] = mapped_column(String(50), nullable=True)
    mood_emoji: Mapped[str | None] = mapped_column(String(10), nullable=True)
    ai_insight: Mapped[str | None] = mapped_column(Text, nullable=True)
    emotional_reflection: Mapped[str | None] = mapped_column(Text, nullable=True)
    important_events: Mapped[dict | list | None] = mapped_column(JSONB, nullable=True)

    safety_event_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("safety_events.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    __table_args__ = (
        UniqueConstraint("user_id", "entry_date", name="uq_user_diary_entry_date"),
        Index("idx_diary_entries_user_date", user_id, entry_date),
    )
