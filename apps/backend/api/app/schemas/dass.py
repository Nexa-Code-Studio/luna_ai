from datetime import date
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class DASSItemSchema(BaseModel):
    item_id: int = Field(..., ge=1, le=21, description="Nomor butir 1 sampai 21")
    scale: str = Field(..., description="Subskala: 'stress', 'anxiety', atau 'depression'")
    question_text: str = Field(..., description="Teks pertanyaan resmi DASS-21")
    score: int = Field(0, ge=0, le=3, description="Skor butir 0 (Tidak Pernah) s.d 3 (Hampir Selalu)")
    evidence: str | None = Field(None, description="Kutipan bukti kalimat percakapan dari user")
    confidence: float = Field(0.0, ge=0.0, le=1.0, description="Tingkat keyakinan deteksi AI")
    is_user_edited: bool = Field(False, description="Flag apakah skor butir ini telah diedit oleh user")


class DASSItemUpdate(BaseModel):
    item_id: int = Field(..., ge=1, le=21)
    score: int = Field(..., ge=0, le=3)


class DASSAssessmentUpdate(BaseModel):
    items: list[DASSItemUpdate] = Field(..., min_length=1, max_length=21)


class SubscaleScoreSummary(BaseModel):
    raw_sum: int
    final_score: int
    severity: str


class DASSAssessmentResponse(BaseModel):
    id: UUID | None = None
    user_id: UUID
    conversation_id: UUID | None = None
    assessed_date: date
    depression_score: int
    anxiety_score: int
    stress_score: int
    depression_severity: str
    anxiety_severity: str
    stress_severity: str
    verified_by_user: bool
    status: str
    items: list[DASSItemSchema]

    model_config = ConfigDict(from_attributes=True)
