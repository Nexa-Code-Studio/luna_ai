from datetime import date
from typing import Any
import uuid

from sqlalchemy import JSON, Boolean, Date, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class CopingActivity(BaseModel):
    """Catalog of evidence-based psychological coping and mindfulness activities."""

    __tablename__ = "coping_activities"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(100), nullable=False)
    target_condition: Mapped[str] = mapped_column(
        String(50), nullable=False, default="general", index=True
    )  # 'stress', 'anxiety', 'depression', 'general'
    duration: Mapped[str] = mapped_column(String(50), nullable=False)
    difficulty: Mapped[str] = mapped_column(String(50), nullable=False, default="Pemula")
    description: Mapped[str] = mapped_column(Text, nullable=False)
    instructions: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    rationale: Mapped[str | None] = mapped_column(Text, nullable=True)
    icon_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class UserActivityCompletion(BaseModel):
    """Records daily completion of coping activities by users."""

    __tablename__ = "user_activity_completions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    activity_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("coping_activities.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    completed_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    activity: Mapped["CopingActivity"] = relationship("CopingActivity", lazy="joined")
