"""
Alembic環境設定

SQLAlchemy対応のマイグレーション設定。
環境変数から設定を読み込み、データベーススキーマの管理を行う。
"""

from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool

from alembic import context

# Alembic設定オブジェクト
config = context.config

# ロガーの設定
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 環境変数から設定を読み込み
import sys
from pathlib import Path

# app.core.config をインポートするためにパスを追加
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.config import settings  # noqa: E402

# データベースURLを環境変数から設定（同期URL）
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL_SYNC)

# モデルのMetaDataオブジェクトをインポート
# ここでは将来のモデル追加に備えて、base.pyからインポートする想定
# from app.db.base import Base
# target_metadata = Base.metadata

# 現時点ではモデル未作成なので、Noneのまま
# TASK-0008でモデル実装後に更新予定
target_metadata = None


def run_migrations_offline() -> None:
    """
    オフラインモードでのマイグレーション実行

    データベース接続を行わず、SQLスクリプトを生成する。
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """
    オンラインモードでのマイグレーション実行

    データベースに接続し、マイグレーションを実行する。
    """
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
