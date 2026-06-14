"""lowercase politeness_level_enum values

ai_conversion_history の politeness_level_enum はメンバー名（CASUAL/NORMAL/POLITE,
大文字）で作成されていたが、ai_conversion_logs は小文字（casual/normal/polite）で
保持しており、同一概念がテーブル間で大文字/小文字に分かれていた。

本マイグレーションで ENUM 値を小文字へリネームし、モデル側の values_callable
（.value=小文字を保存）と一致させてデータ表現を統一する。

PostgreSQL 10+ の ALTER TYPE ... RENAME VALUE を使用（既存データを保持したまま改名）。

Revision ID: c1a2b3d4e5f6
Revises: b5d6e2f8c9a0
Create Date: 2026-06-14
"""

from collections.abc import Sequence
from typing import Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c1a2b3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "b5d6e2f8c9a0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (旧値, 新値) のペア
_RENAMES = (
    ("CASUAL", "casual"),
    ("NORMAL", "normal"),
    ("POLITE", "polite"),
)


def upgrade() -> None:
    """ENUM値を大文字から小文字へリネームする。"""
    for old, new in _RENAMES:
        op.execute(f"ALTER TYPE politeness_level_enum RENAME VALUE '{old}' TO '{new}'")


def downgrade() -> None:
    """ENUM値を小文字から大文字へ戻す。"""
    for old, new in _RENAMES:
        op.execute(f"ALTER TYPE politeness_level_enum RENAME VALUE '{new}' TO '{old}'")
