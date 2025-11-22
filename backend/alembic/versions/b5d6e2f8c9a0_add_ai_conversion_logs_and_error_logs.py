"""Add ai_conversion_logs and error_logs tables

Revision ID: b5d6e2f8c9a0
Revises: ac3a7c362e68
Create Date: 2025-11-22 12:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b5d6e2f8c9a0"
down_revision: str | Sequence[str] | None = "ac3a7c362e68"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """
    Upgrade schema.

    【機能概要】: ai_conversion_logsとerror_logsテーブルを作成する
    【実装方針】: TASK-0024の要件に基づき、AI変換ログとエラーログテーブルを作成
    【セキュリティ】: 入力テキストはハッシュ化して保存（input_text_hash）
    【パフォーマンス】: 検索用インデックスを追加

    関連要件:
        - FR-001: ログテーブルの定義
        - FR-004: エラーログテーブルの定義
        - NFR-003: インデックス設定
    """
    # ========================================
    # ai_conversion_logs テーブル作成
    # ========================================
    # 【テーブル作成】: AI変換ログテーブルを作成
    op.create_table(
        "ai_conversion_logs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("input_text_hash", sa.String(length=64), nullable=False),
        sa.Column("input_length", sa.Integer(), nullable=False),
        sa.Column("output_length", sa.Integer(), nullable=False),
        sa.Column("politeness_level", sa.String(length=20), nullable=False),
        sa.Column("conversion_time_ms", sa.Integer(), nullable=True),
        sa.Column("ai_provider", sa.String(length=50), nullable=True),
        sa.Column("is_success", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("session_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint(
            "politeness_level IN ('casual', 'normal', 'polite')",
            name="check_politeness_level",
        ),
    )

    # 【インデックス作成】: ai_conversion_logs用インデックス
    # 【created_atインデックス】: 時系列検索用
    op.create_index(
        "idx_ai_conversion_logs_created_at",
        "ai_conversion_logs",
        [sa.text("created_at DESC")],
        unique=False,
    )
    # 【input_text_hashインデックス】: ハッシュ検索用
    op.create_index(
        "idx_ai_conversion_logs_hash",
        "ai_conversion_logs",
        ["input_text_hash"],
        unique=False,
    )
    # 【session_idインデックス】: セッションごとのログ取得用
    op.create_index(
        "idx_ai_conversion_logs_session",
        "ai_conversion_logs",
        ["session_id"],
        unique=False,
    )

    # ========================================
    # error_logs テーブル作成
    # ========================================
    # 【テーブル作成】: エラーログテーブルを作成
    op.create_table(
        "error_logs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("error_type", sa.String(length=100), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("error_code", sa.String(length=50), nullable=True),
        sa.Column("endpoint", sa.String(length=255), nullable=True),
        sa.Column("http_method", sa.String(length=10), nullable=True),
        sa.Column("stack_trace", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # 【インデックス作成】: error_logs用インデックス
    # 【error_typeインデックス】: エラータイプ別検索用
    op.create_index(
        "idx_error_logs_type",
        "error_logs",
        ["error_type"],
        unique=False,
    )
    # 【created_atインデックス】: 時系列検索用
    op.create_index(
        "idx_error_logs_created_at",
        "error_logs",
        [sa.text("created_at DESC")],
        unique=False,
    )


def downgrade() -> None:
    """
    Downgrade schema.

    【機能概要】: ai_conversion_logsとerror_logsテーブルを削除する
    【実装方針】: upgrade()の逆順でインデックスとテーブルを削除
    """
    # ========================================
    # error_logs テーブル削除
    # ========================================
    # 【インデックス削除】: error_logs用インデックスを削除
    op.drop_index("idx_error_logs_created_at", table_name="error_logs")
    op.drop_index("idx_error_logs_type", table_name="error_logs")

    # 【テーブル削除】: error_logsテーブルを削除
    op.drop_table("error_logs")

    # ========================================
    # ai_conversion_logs テーブル削除
    # ========================================
    # 【インデックス削除】: ai_conversion_logs用インデックスを削除
    op.drop_index("idx_ai_conversion_logs_session", table_name="ai_conversion_logs")
    op.drop_index("idx_ai_conversion_logs_hash", table_name="ai_conversion_logs")
    op.drop_index("idx_ai_conversion_logs_created_at", table_name="ai_conversion_logs")

    # 【テーブル削除】: ai_conversion_logsテーブルを削除
    op.drop_table("ai_conversion_logs")
