"""drop ai_conversion_history table (unified into ai_conversion_logs)

Revision ID: f1a2b3c4d5e6
Revises: b5d6e2f8c9a0
Create Date: 2026-06-28

The legacy ai_conversion_history table stored raw input/output text. It has been
superseded by the hashed ai_conversion_logs table (privacy-preserving), so the
history table and its dedicated politeness_level_enum type are dropped here.
downgrade() reconstructs the table exactly as migration ac3a7c362e68 created it.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f1a2b3c4d5e6"
down_revision: str | Sequence[str] | None = "b5d6e2f8c9a0"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Drop the ai_conversion_history table, its indexes, and the enum type."""
    op.drop_index("idx_ai_conversion_session", table_name="ai_conversion_history")
    op.drop_index("idx_ai_conversion_created_at", table_name="ai_conversion_history")
    op.drop_table("ai_conversion_history")
    # drop_table does not remove the PostgreSQL enum type, so drop it explicitly.
    sa.Enum(name="politeness_level_enum").drop(op.get_bind(), checkfirst=True)


def downgrade() -> None:
    """Recreate the ai_conversion_history table exactly as ac3a7c362e68 created it."""
    op.create_table(
        "ai_conversion_history",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("input_text", sa.Text(), nullable=False),
        sa.Column("converted_text", sa.Text(), nullable=False),
        sa.Column(
            "politeness_level",
            sa.Enum(
                "CASUAL", "NORMAL", "POLITE", name="politeness_level_enum", create_constraint=True
            ),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column("conversion_time_ms", sa.Integer(), nullable=True),
        sa.Column("user_session_id", sa.UUID(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_ai_conversion_created_at",
        "ai_conversion_history",
        [sa.text("created_at DESC")],
        unique=False,
    )
    op.create_index(
        "idx_ai_conversion_session", "ai_conversion_history", ["user_session_id"], unique=False
    )
