import uuid
from decimal import Decimal
from typing import Any

from sqlalchemy import ForeignKey, Index, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.orm import relationship as sa_relationship

from app.models.base import BaseModel
from app.models.enums import (
    ConditionStatus,
    ConditionSymptomRelationship,
    KnowledgeStatus,
    SymptomStatus,
)


class Condition(BaseModel):
    __tablename__ = "conditions"

    code: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=ConditionStatus.ACTIVE,
        index=True,
    )

    # Relationships
    symptoms: Mapped[list["ConditionSymptom"]] = sa_relationship(
        "ConditionSymptom", back_populates="condition", cascade="all, delete-orphan"
    )


class Symptom(BaseModel):
    __tablename__ = "symptoms"

    code: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=SymptomStatus.ACTIVE,
        index=True,
    )

    # Relationships
    conditions: Mapped[list["ConditionSymptom"]] = sa_relationship(
        "ConditionSymptom", back_populates="symptom", cascade="all, delete-orphan"
    )


class ConditionSymptom(BaseModel):
    __tablename__ = "condition_symptoms"

    condition_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("conditions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    symptom_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("symptoms.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    relationship: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default=ConditionSymptomRelationship.ASSOCIATED,
    )
    evidence_level: Mapped[str | None] = mapped_column(String(30), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    condition: Mapped["Condition"] = sa_relationship("Condition", back_populates="symptoms")
    symptom: Mapped["Symptom"] = sa_relationship("Symptom", back_populates="conditions")

    __table_args__ = (
        UniqueConstraint(
            "condition_id",
            "symptom_id",
            name="uq_condition_symptoms_cond_symp",
        ),
        Index("idx_condition_symptoms_cond_symp", condition_id, symptom_id),
    )


class Source(BaseModel):
    __tablename__ = "sources"

    name: Mapped[str] = mapped_column(String(500), nullable=False, index=True)
    organization: Mapped[str | None] = mapped_column(String(255), nullable=True)
    url: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_type: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    version: Mapped[str | None] = mapped_column(String(100), nullable=True)


class Knowledge(BaseModel):
    __tablename__ = "knowledge"

    code: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    condition_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("conditions.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("sources.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=KnowledgeStatus.ACTIVE,
        index=True,
    )
    metadata_json: Mapped[dict[str, Any] | None] = mapped_column("metadata", JSONB, nullable=True)

    # Relationships
    condition: Mapped["Condition | None"] = sa_relationship("Condition")
    source: Mapped["Source | None"] = sa_relationship("Source")
    chunks: Mapped[list["KnowledgeChunk"]] = sa_relationship(
        "KnowledgeChunk", back_populates="knowledge", cascade="all, delete-orphan"
    )


class KnowledgeChunk(BaseModel):
    __tablename__ = "knowledge_chunks"

    knowledge_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("knowledge.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    token_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    qdrant_point_id: Mapped[str | None] = mapped_column(String(100), unique=True, nullable=True)
    metadata_json: Mapped[dict[str, Any] | None] = mapped_column("metadata", JSONB, nullable=True)

    # Relationships
    knowledge: Mapped["Knowledge"] = sa_relationship("Knowledge", back_populates="chunks")

    __table_args__ = (
        UniqueConstraint(
            "knowledge_id",
            "chunk_index",
            name="uq_knowledge_chunks_knowledge_index",
        ),
        Index("idx_knowledge_chunks_knowledge_index", knowledge_id, chunk_index),
    )


class RAGRetrieval(BaseModel):
    __tablename__ = "rag_retrievals"

    ai_run_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ai_runs.id", ondelete="CASCADE"),
        nullable=False,
    )
    query: Mapped[str] = mapped_column(Text, nullable=False)

    # Relationships
    results: Mapped[list["RAGRetrievalResult"]] = sa_relationship(
        "RAGRetrievalResult", back_populates="retrieval", cascade="all, delete-orphan"
    )


class RAGRetrievalResult(BaseModel):
    __tablename__ = "rag_retrieval_results"

    retrieval_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("rag_retrievals.id", ondelete="CASCADE"),
        nullable=False,
    )
    knowledge_chunk_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("knowledge_chunks.id", ondelete="CASCADE"),
        nullable=False,
    )
    score: Mapped[Decimal | None] = mapped_column(Numeric(10, 8), nullable=True)
    rank: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Relationships
    retrieval: Mapped["RAGRetrieval"] = sa_relationship("RAGRetrieval", back_populates="results")
    knowledge_chunk: Mapped["KnowledgeChunk"] = sa_relationship("KnowledgeChunk")

    __table_args__ = (Index("idx_rag_retrieval_results_retrieval_rank", retrieval_id, rank),)
