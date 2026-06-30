"""drop ai_conversion_history table (unify on hashed ai_conversion_logs)

ai_conversion_history は平文の input_text / converted_text を保存する legacy テーブルで、
SHA-256 ハッシュ化された ai_conversion_logs と責務が重複していた（review #5）。
プライバシー方針に従い history を廃止し、logs に一本化する。

downgrade は c1a2b3d4e5f6 適用後の状態（politeness_level_enum が小文字
casual/normal/polite）で history を再構築する。

Revision ID: e1f2a3b4c5d6
Revises: c1a2b3d4e5f6
Create Date: 2026-06-30
"""

from collections.abc import Sequence
from typing import Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "e1f2a3b4c5d6"
down_revision: Union[str, Sequence[str], None] = "c1a2b3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """history のインデックス・テーブル・enum 型を削除する。"""
    op.drop_index("idx_ai_conversion_session", table_name="ai_conversion_history")
    op.drop_index("idx_ai_conversion_created_at", table_name="ai_conversion_history")
    op.drop_table("ai_conversion_history")
    op.execute("DROP TYPE IF EXISTS politeness_level_enum")


def downgrade() -> None:
    """history テーブルと enum（小文字）・インデックスを再構築する。"""
    op.create_table(
        "ai_conversion_history",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("input_text", sa.Text(), nullable=False),
        sa.Column("converted_text", sa.Text(), nullable=False),
        sa.Column(
            "politeness_level",
            sa.Enum(
                "casual",
                "normal",
                "polite",
                name="politeness_level_enum",
                create_constraint=True,
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
        "idx_ai_conversion_session",
        "ai_conversion_history",
        ["user_session_id"],
        unique=False,
    )
