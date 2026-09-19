"""add_dass_assessments

Revision ID: 0002_add_dass_assessments
Revises: 0001_initial_schema
Create Date: 2026-09-19 18:40:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0002_add_dass_assessments"
down_revision: str | None = "0001_initial_schema"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "dass_assessments",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("conversation_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("assessed_date", sa.Date(), nullable=False),
        sa.Column("depression_score", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("anxiety_score", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("stress_score", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("depression_severity", sa.String(length=30), nullable=False, server_default=sa.text("'Normal'")),
        sa.Column("anxiety_severity", sa.String(length=30), nullable=False, server_default=sa.text("'Normal'")),
        sa.Column("stress_severity", sa.String(length=30), nullable=False, server_default=sa.text("'Normal'")),
        sa.Column("verified_by_user", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("status", sa.String(length=30), nullable=False, server_default=sa.text("'auto_extracted'")),
        sa.Column("items", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'[]'::jsonb")),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["conversation_id"], ["conversations.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "assessed_date", name="uq_user_dass_date"),
    )
    op.create_index("idx_dass_user_date", "dass_assessments", ["user_id", "assessed_date"])
    op.create_index(op.f("ix_dass_assessments_user_id"), "dass_assessments", ["user_id"], unique=False)
    op.create_index(op.f("ix_dass_assessments_assessed_date"), "dass_assessments", ["assessed_date"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_dass_assessments_assessed_date"), table_name="dass_assessments")
    op.drop_index(op.f("ix_dass_assessments_user_id"), table_name="dass_assessments")
    op.drop_index("idx_dass_user_date", table_name="dass_assessments")
    op.drop_table("dass_assessments")
