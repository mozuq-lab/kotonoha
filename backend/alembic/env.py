"""
Alembic環境設定

SQLAlchemy対応のマイグレーション設定。
環境変数から設定を読み込み、データベーススキーマの管理を行う。
"""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

# Alembic設定オブジェクト
config = context.config

# ロガーの設定
if config.config_file_name is not None:
    # 【disable_existing_loggers=False にする理由】: 既定の True は、この時点までに
    # 生成済みのロガーをすべて無効化する。alembic.ini のロガー設定には app.* が
    # 含まれないため、アプリのロガーが軒並み黙る。
    # 影響が大きいのはテストで、DBセットアップで alembic を実行した以降は
    # アプリのログが1行も出なくなり、ログを検証するテストが「出力ゼロ」を
    # 静かに見逃す（実際に app.core.config のロガーが無効化されていた）。
    # 本番のマイグレーション実行でも、同一プロセスで何かを続ける場合に同じ問題が出る。
    fileConfig(config.config_file_name, disable_existing_loggers=False)

# 環境変数から設定を読み込み
import sys
from pathlib import Path

# app.core.config をインポートするためにパスを追加
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.config import settings  # noqa: E402

# データベースURLを環境変数から設定（同期URL）
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL_SYNC)

# モデルのMetaDataオブジェクトをインポート
# 【機能概要】: Alembicがモデル定義を認識し、マイグレーションファイルを自動生成できるようにする
# 【実装方針】: app.db.baseからBaseをインポートし、Base.metadataをtarget_metadataに設定
# 【テスト対応】: TASK-0009（初回マイグレーション実行）のテストを通すための実装
# 🔵 この実装は要件定義書（line 231-233, line 262-274）に基づく
from app.db.base import Base  # noqa: E402

target_metadata = Base.metadata


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
        compare_type=True,
        compare_server_default=True,
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
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
