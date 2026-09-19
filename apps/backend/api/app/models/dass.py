import uuid
from datetime import date
from typing import Any

from sqlalchemy import Boolean, Date, ForeignKey, Index, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import BaseModel


class DASSAssessment(BaseModel):
    """Model untuk menyimpan asesmen 21 butir DASS-21, skor subskala, status verifikasi user,

    dan detail bukti kalimat percakapan.
    """

    __tablename__ = "dass_assessments"

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
    assessed_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # Subscale Scores (Final Scaled Score: Raw Sum * 2, rentang 0-42)
    depression_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    anxiety_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    stress_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Severity Level Categories (Normal, Mild, Moderate, Severe, Extremely Severe)
    depression_severity: Mapped[str] = mapped_column(String(30), default="Normal", nullable=False)
    anxiety_severity: Mapped[str] = mapped_column(String(30), default="Normal", nullable=False)
    stress_severity: Mapped[str] = mapped_column(String(30), default="Normal", nullable=False)

    # Status & User Editing
    verified_by_user: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="auto_extracted", nullable=False)

    # 21 items detail array with question, score (0-3), evidence, confidence, is_user_edited
    items: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list, nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "assessed_date", name="uq_user_dass_date"),
        Index("idx_dass_user_date", user_id, assessed_date),
    )
