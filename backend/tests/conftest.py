"""
pytestテスト設定ファイル

テスト用のフィクスチャとセットアップを定義する。

【実装方針】: pytest-asyncio 0.25.x の推奨パターンに従い、各テストで独立したイベントループを使用
【セキュリティ】: テスト用データベースと本番データベースを分離し、データ漏洩を防止
🔵 この実装は要件定義書（line 67-75）とpytest-asyncio公式ドキュメントに基づく
"""

import os
from collections.abc import AsyncGenerator
from pathlib import Path
from urllib.parse import urlparse

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# 【テスト前準備】: テスト用のデータベース接続URLを環境変数から取得
# 【環境初期化】: 本番環境とは異なるテストデータベースを使用し、データの分離を保証
# 【セキュリティ】: 本番データベースへの誤接続を防ぐため、明示的にテストDB URLを指定
# 🔵 NFR-105（環境変数をアプリ内にハードコードせず、安全に管理）に基づく
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://kotonoha_user:your_secure_password_here@localhost:5432/kotonoha_test",
)

# 【テーブル名定義】: TRUNCATE対象のアプリケーションテーブル（alembic_versionは除く）
# 🔵 test_migration_execution.py が alembic_version を参照するため TRUNCATE 対象から除外
_APP_TABLES = ["ai_conversion_logs", "error_logs"]


@pytest.fixture(scope="session")
def _alembic_schema():
    """
    セッションスコープで alembic upgrade head を実行してスキーマを構築する（同期処理）。

    【テスト目的】: alembic_version テーブルを含む完全なスキーマをテスト DB に構築
    【実装方針】: session-scope の同期フィクスチャとして実装し、pytest-asyncio の
                  loop scope 衝突を回避する。alembic の env.py が
                  settings.DATABASE_URL_SYNC（POSTGRES_* から構築）を読み取るため、
                  TEST_DATABASE_URL の接続情報を settings に一時パッチして
                  テスト DB（ローカル kotonoha_test / CI test_db 等）に向ける。
    【注意】: test_engine フィクスチャが依存し、セッション全体で1回だけ実行される
    🔵 この内容は要件定義書（line 60-69, line 169-183）に基づく
    """
    from alembic import command
    from alembic.config import Config
    from app.core.config import settings

    # 【URL制御】: env.py は settings.DATABASE_URL_SYNC（POSTGRES_* から構築）を参照する。
    # TEST_DATABASE_URL の全コンポーネントを settings に一時パッチして alembic を
    # テスト DB に向ける（DB名ハードコードを避け、ローカル/CI 両対応）。
    # object.__setattr__ で Pydantic の __setattr__ をバイパスする。
    _parsed = urlparse(TEST_DATABASE_URL)
    _patched = {
        "POSTGRES_USER": _parsed.username,
        "POSTGRES_PASSWORD": _parsed.password,
        "POSTGRES_HOST": _parsed.hostname,
        "POSTGRES_PORT": _parsed.port or 5432,
        "POSTGRES_DB": _parsed.path.lstrip("/"),
    }
    _originals = {key: getattr(settings, key) for key in _patched}
    for _key, _value in _patched.items():
        object.__setattr__(settings, _key, _value)

    alembic_ini_path = str(Path(__file__).resolve().parents[1] / "alembic.ini")
    alembic_cfg = Config(alembic_ini_path)

    try:
        # 【スキーマ構築】: alembic upgrade head でマイグレーションを実行
        # alembic_version テーブルも含めて完全なスキーマを構築する
        command.upgrade(alembic_cfg, "head")
        yield
        # 【クリーンアップ】: テストセッション終了時にスキーマを削除
        command.downgrade(alembic_cfg, "base")
    finally:
        # 【状態復元】: パッチした settings を元の値に戻す
        for _key, _value in _originals.items():
            object.__setattr__(settings, _key, _value)


@pytest.fixture(scope="function")
async def test_engine(_alembic_schema):
    """
    テスト用の非同期エンジンを作成（各テスト関数ごとに作成）

    【テスト目的】: テスト用データベースへの接続エンジンを提供
    【テスト内容】: SQLAlchemy 2.x の非同期エンジンを作成し、テスト完了後にクリーンアップ
    【期待される動作】: テストデータベースに接続し、セッション作成の基盤を提供
    【実装方針】: スキーマは _alembic_schema が構築済みのため create_all/drop_all は行わない。
                  各テスト後はアプリケーションテーブルを TRUNCATE してデータ分離を保証する。
                  alembic_version テーブルは TRUNCATE しない（test_migration_execution.py が参照）。
    🔵 この内容は要件定義書（line 67-75）に基づく

    Yields:
        AsyncEngine: テスト用の非同期データベースエンジン
    """
    # 【テストデータ準備】: テスト用データベース接続エンジンを作成
    # 【初期条件設定】: echo=False でSQL出力を抑制（必要に応じてTrueに変更可能）
    # 【パフォーマンス最適化】: pool_size=5 で接続プールを制限（テスト環境では少数で十分）
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        pool_pre_ping=True,  # 【接続健全性チェック】: 接続の有効性を確認してから使用
        pool_size=5,  # 【接続プールサイズ】: テスト用に小さめに設定
        max_overflow=5,  # 【追加接続数】: 必要に応じて追加接続を許可
    )

    yield engine

    # 【テスト後処理】: アプリケーションテーブルを TRUNCATE してデータ分離を保証
    # 【注意】: alembic_version は削除しない（test_migration_execution.py が参照するため）
    # 【状態復元】: 各テストが書き込んだデータを次のテストに持ち越さないようにする
    truncate_sql = f"TRUNCATE {', '.join(_APP_TABLES)} RESTART IDENTITY CASCADE"
    async with engine.begin() as conn:
        await conn.execute(text(truncate_sql))

    # 【テスト後処理】: エンジンとすべての接続を適切にクローズ
    # 【リソースリーク防止】: イベントループクローズ前に接続プールをクリーンアップ
    # 🔵 SQLAlchemy 2.x の推奨クリーンアップ手順
    await engine.dispose()


@pytest.fixture(scope="function")
async def test_session_maker(test_engine):
    """
    テスト用のセッションメーカーを作成

    【テスト目的】: 各テストケースで使用するセッションファクトリを提供
    【テスト内容】: async_sessionmakerを作成し、テストセッションの生成を可能にする
    【期待される動作】: テスト用のデータベースセッションを生成できる
    【実装方針】: test_engineに依存し、エンジンのライフサイクルと同期
    🔵 この内容は要件定義書（line 67-75）に基づく

    Returns:
        async_sessionmaker: テストセッション生成ファクトリ
    """
    # 【テストデータ準備】: セッションメーカーを作成
    # 【初期条件設定】: expire_on_commit=False でコミット後もオブジェクトにアクセス可能
    session_maker = async_sessionmaker(
        bind=test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )
    return session_maker


@pytest.fixture(scope="function")
async def db_session(test_session_maker) -> AsyncGenerator[AsyncSession, None]:
    """
    各テストケース用のデータベースセッションを作成

    【テスト目的】: 各テストケースに独立したデータベースセッションを提供
    【テスト内容】: セッションを作成し、テスト完了後にロールバック
    【期待される動作】: テスト間のデータ分離を保証し、各テストが独立して実行される
    【実装方針】: 未コミットの変更はロールバックで破棄する。コミット済みデータは
                  test_engine teardown の TRUNCATE で除去される。
    🔵 この内容は要件定義書（line 180-188）に基づく

    Yields:
        AsyncSession: テスト用の非同期データベースセッション
    """
    # 【テスト前準備】: 新しいセッションを作成
    # 【環境初期化】: テスト用のクリーンなセッションを提供
    async with test_session_maker() as session:
        yield session
        # 【テスト後処理】: テスト完了後、未コミットのトランザクションをロールバック
        # 【状態復元】: テストで作成されたデータをすべて破棄し、次のテストに影響しないようにする
        await session.rollback()
        # 【セッションクローズ】: セッションを明示的にクローズ
        await session.close()


@pytest.fixture(scope="function")
async def test_client_with_db(test_engine, test_session_maker):
    """
    テスト用データベースを使用するFastAPIテストクライアントを作成

    【テスト目的】: テスト用データベースに接続するFastAPIアプリケーションを提供
    【テスト内容】: get_db_session・get_session_factory依存性をオーバーライドし、
                    テスト用DBセッション／セッションファクトリを使用
    【期待される動作】: API呼び出し（および応答後に実行されるバックグラウンドタスクの
                        ログ書き込み）がテスト用データベースに接続する
    【実装方針】: FastAPIの依存性オーバーライド機能を使用。AI変換エンドポイントの
                  ログ書き込みはBackgroundTasks経由でget_session_factoryが返す
                  ファクトリから独立したセッションを取得するため、get_db_sessionだけ
                  でなくget_session_factoryも本番用（本物のDB）ではなくtest_session_maker
                  を返すようにオーバーライドする。
    🔵 FastAPI公式ドキュメント、テストパターンに基づく

    Yields:
        FastAPI: テスト用データベースに接続するFastAPIアプリケーション
    """
    from app.api.deps import get_db_session, get_session_factory
    from app.db.session import get_db
    from app.main import app

    # 【依存性オーバーライド関数】: test_session_makerから新しいセッションを作成
    # 各リクエストごとに新しいセッションを提供（イベントループ問題を回避）
    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        """テスト用データベースセッションを提供"""
        async with test_session_maker() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()

    # 【依存性オーバーライド】: 本番DBの代わりにテスト用DBを使用
    # get_db_sessionとget_db両方をオーバーライド（healthエンドポイント対応）
    app.dependency_overrides[get_db_session] = override_get_db
    app.dependency_overrides[get_db] = override_get_db

    # 【依存性オーバーライド】: バックグラウンドタスク（AI変換ログ書き込み）が
    # 独立したセッションを取得する際も、本番用DBではなくテスト用DBに向ける
    app.dependency_overrides[get_session_factory] = lambda: test_session_maker

    yield app

    # 【テスト後処理】: 依存性オーバーライドをクリア
    app.dependency_overrides.clear()


# ============================================================================
# テストヘルパー関数
# ============================================================================


def create_test_hash(text: str) -> str:
    """
    テスト用のハッシュ値を生成

    【目的】: 重複チェック用のハッシュ値を一貫した方法で生成
    【使用場面】: AI変換ログテスト、履歴テストなど

    Args:
        text: ハッシュ化する文字列

    Returns:
        SHA-256ハッシュ値（16進数文字列）
    """
    import hashlib

    return hashlib.sha256(text.encode()).hexdigest()


def create_test_conversion_request(
    input_text: str = "水 ぬるく", politeness_level: str = "normal"
) -> dict:
    """
    テスト用のAI変換リクエストボディを生成

    【目的】: 標準的なリクエストボディを簡潔に作成
    【使用場面】: AI変換エンドポイントテスト

    Args:
        input_text: 入力テキスト
        politeness_level: 丁寧さレベル（casual, normal, polite）

    Returns:
        リクエストボディの辞書
    """
    return {"input_text": input_text, "politeness_level": politeness_level}
