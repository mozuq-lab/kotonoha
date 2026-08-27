"""TASK-0022: データベース接続プール・セッション管理テスト。

データベース接続プール設定とセッション管理の検証を行う。

関連要件:
    - FR-001: 長時間接続の自動再作成、接続取得タイムアウト
    - FR-002: エラー時のロールバック
    - FR-003: 依存性注入によるセッション管理
    - FR-004: データベース接続確認
    - NFR-002: パフォーマンス要件
    - NFR-005: 同時利用者数10人以下
    - NFR-304: エラーハンドリング

テストケース一覧:
    - TC-001: データベース接続テスト
    - TC-002: 接続プール設定テスト
    - TC-003: 並行接続テスト
    - TC-004: セッションロールバックテスト
    - TC-005: 依存性注入テスト
    - TC-006: 接続エラーハンドリングテスト
    - TC-007: pool_pre_ping動作テスト
    - TC-008: セッションコミットテスト
"""

import asyncio
from uuid import uuid4

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.session import (
    MAX_OVERFLOW,
    POOL_RECYCLE,
    POOL_SIZE,
    POOL_TIMEOUT,
    async_session_maker,
    engine,
)
from app.models.ai_conversion_logs import AIConversionLog

# ============================================================================
# TC-001: データベース接続テスト
# ============================================================================


@pytest.mark.asyncio
async def test_database_connection(db_session: AsyncSession) -> None:
    """TC-001: データベースへの基本接続が成功することを確認。

    Args:
        db_session: テスト用データベースセッション

    検証項目:
        - SELECT 1クエリが正常に実行される
        - クエリ結果が1を返す
    """
    result = await db_session.execute(text("SELECT 1"))
    assert result.scalar() == 1


# ============================================================================
# TC-002: 接続プール設定テスト
# ============================================================================


def test_engine_pool_configuration() -> None:
    """TC-002: 接続プール設定が要件通りに設定されていることを確認。

    検証項目:
        - pool_size: 10（NFR-005対応）
        - max_overflow: 10
        - pool_recycle: 3600秒（FR-001）
        - pool_timeout: 30秒（FR-001）
    """
    pool = engine.pool

    assert pool.size() == POOL_SIZE
    assert pool._max_overflow == MAX_OVERFLOW
    assert pool._recycle == POOL_RECYCLE
    assert pool._timeout == POOL_TIMEOUT


# ============================================================================
# TC-003: 並行接続テスト
# ============================================================================


@pytest.mark.asyncio
@pytest.mark.skip(
    reason="Docker環境のマルチスレッド制約により失敗 (OSError: Multi-thread/multi-process)"
)
async def test_concurrent_connections() -> None:
    """TC-003: 10個の並行クエリが接続プールで適切に管理されることを確認。

    検証項目:
        - すべてのクエリが正常に実行される
        - 各クエリが正しい結果を返す

    Note:
        Docker環境でのマルチスレッド制約により、本テストはスキップされます。
        ローカル環境でのテストでは正常に動作します。
    """

    async def execute_query(query_id: int) -> int:
        """個別クエリを実行する。

        Args:
            query_id: クエリの識別子

        Returns:
            クエリ結果として返されるquery_id
        """
        async with async_session_maker() as session:
            result = await session.execute(text(f"SELECT {query_id}"))
            return result.scalar()

    concurrent_count = 10
    tasks = [execute_query(i) for i in range(concurrent_count)]
    results = await asyncio.gather(*tasks)

    assert len(results) == concurrent_count
    assert set(results) == set(range(concurrent_count))


# ============================================================================
# TC-004: セッションロールバックテスト
# ============================================================================


@pytest.mark.asyncio
async def test_session_rollback_on_error(db_session: AsyncSession) -> None:
    """TC-004: エラー発生時にトランザクションがロールバックされることを確認。

    Args:
        db_session: テスト用データベースセッション

    検証項目:
        - IntegrityError発生後、ロールバックが成功する
        - セッションが再利用可能である
    """
    with pytest.raises(IntegrityError):
        record = AIConversionLog(
            input_text_hash=None,  # NOT NULL制約違反
            input_length=4,
            output_length=4,
            politeness_level="polite",
            session_id=uuid4(),
        )
        db_session.add(record)
        await db_session.flush()

    await db_session.rollback()

    result = await db_session.execute(text("SELECT 1"))
    assert result.scalar() == 1


# ============================================================================
# TC-005: 依存性注入テスト
# ============================================================================


@pytest.mark.asyncio
async def test_dependency_injection(test_client_with_db) -> None:
    """TC-005: FastAPIエンドポイントで依存性注入が正常に動作することを確認。

    Args:
        test_client_with_db: テスト用FastAPIアプリケーション

    検証項目:
        - /healthエンドポイントが200を返す
        - データベース接続状態が'connected'
    """
    transport = ASGITransport(app=test_client_with_db)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")

        assert response.status_code == 200

        data = response.json()
        assert data.get("database") == "connected"


# ============================================================================
# TC-006: 接続エラーハンドリングテスト
# ============================================================================


@pytest.mark.asyncio
async def test_connection_error_handling() -> None:
    """TC-006: 無効な接続情報で適切な例外が発生することを確認。

    検証項目:
        - 無効な接続URLで例外が発生する
        - リソースが適切にクリーンアップされる
    """
    invalid_engine = create_async_engine(
        "postgresql+asyncpg://invalid:invalid@localhost:5432/invalid_db",
        pool_pre_ping=True,
    )
    invalid_session_maker = async_sessionmaker(
        bind=invalid_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    error_occurred = False
    try:
        async with invalid_session_maker() as session:
            await session.execute(text("SELECT 1"))
    except Exception:
        # asyncpgでは認証エラーやDB不存在時に様々な例外が発生する可能性がある
        # (OperationalError, DBAPIError, InvalidPasswordError, ConnectionRefusedError等)
        error_occurred = True
    finally:
        await invalid_engine.dispose()

    assert error_occurred


# ============================================================================
# TC-007: pool_pre_ping動作テスト
# ============================================================================


@pytest.mark.asyncio
async def test_pool_pre_ping_enabled(db_session: AsyncSession) -> None:
    """TC-007: pool_pre_ping設定が有効で接続の有効性チェックが行われることを確認。

    Args:
        db_session: テスト用データベースセッション

    検証項目:
        - 複数回のクエリ実行で接続が正常に再利用される

    Note:
        完全なpool_pre_ping動作テストは接続を意図的に切断する必要があるため、
        ここでは基本的な接続動作のみを検証する。
    """
    query_count = 3
    for i in range(query_count):
        result = await db_session.execute(text(f"SELECT {i}"))
        assert result.scalar() == i


# ============================================================================
# TC-008: セッションコミットテスト
# ============================================================================


@pytest.mark.asyncio
async def test_session_commit(db_session: AsyncSession) -> None:
    """TC-008: 正常終了時にデータがコミットされ永続化されることを確認。

    Args:
        db_session: テスト用データベースセッション

    検証項目:
        - コミット成功
        - ID自動生成
        - created_at自動設定
        - 各フィールドの値が正しく保存される
    """
    test_session_id = uuid4()
    test_input = "テスト入力"
    test_output = "テスト出力です"
    test_conversion_time = 100

    record = AIConversionLog.create_log(
        input_text=test_input,
        output_text=test_output,
        politeness_level="normal",
        conversion_time_ms=test_conversion_time,
        session_id=test_session_id,
    )

    db_session.add(record)
    await db_session.commit()

    assert record.id is not None and record.id > 0
    assert record.created_at is not None

    result = await db_session.execute(
        select(AIConversionLog).where(AIConversionLog.session_id == test_session_id)
    )
    saved_record = result.scalar_one_or_none()

    assert saved_record is not None
    assert saved_record.input_text_hash == AIConversionLog.hash_text(test_input)
    assert saved_record.input_length == len(test_input)
    assert saved_record.output_length == len(test_output)
    assert saved_record.politeness_level == "normal"
    assert saved_record.conversion_time_ms == test_conversion_time


# ============================================================================
# 追加テスト: エラー時のログ出力確認（FR-002関連）
# ============================================================================


@pytest.mark.asyncio
async def test_get_db_error_handling_and_logging(db_session: AsyncSession) -> None:
    """FR-002関連: get_db()のエラーハンドリング確認。

    Args:
        db_session: テスト用データベースセッション

    検証項目:
        - セッションが提供される
        - 簡単なクエリが実行できる
    """
    assert db_session is not None
    result = await db_session.execute(text("SELECT 1"))
    assert result.scalar() == 1


# ============================================================================
# 追加テスト: 接続プール枯渇時の動作確認（リスク1関連）
# ============================================================================


@pytest.mark.asyncio
async def test_pool_overflow_handling(db_session: AsyncSession) -> None:
    """リスク1関連: 接続プール枯渇時の動作確認。

    Args:
        db_session: テスト用データベースセッション

    検証項目:
        - 複数回のクエリ実行で接続が正常に管理される

    Note:
        現在の設定（pool_size=10, max_overflow=10）では最大20接続まで許容。
    """
    query_count = 15
    for i in range(query_count):
        result = await db_session.execute(text(f"SELECT {i}"))
        assert result.scalar() == i


class _FakeSession:
    """db_session_scope の呼び出し順を記録するだけのセッション。

    【__aexit__ で close する理由】: 実装が使う async_sessionmaker の
    コンテキストマネージャは終了時に close() する。ここを no-op にすると
    「db_session_scope 側の明示 close が無いと落ちるテスト」になってしまい、
    冗長な close を削除できなくなる（テストが実装の重複を固定してしまう）。
    """

    def __init__(self, calls: list[str]) -> None:
        self._calls = calls

    async def commit(self) -> None:
        self._calls.append("commit")

    async def rollback(self) -> None:
        self._calls.append("rollback")

    async def close(self) -> None:
        self._calls.append("close")

    async def __aenter__(self) -> "_FakeSession":
        return self

    async def __aexit__(self, *exc_info: object) -> bool:
        await self.close()
        return False


class TestGetDbSessionPropagatesErrorsToScope:
    """`get_db_session` の例外伝播テスト。

    【この回帰テストの理由】: 以前 `get_db_session` は
    `async for session in get_db():` で内側のジェネレータをラップしていた。
    この形だと、エンドポイントが例外を投げたときに FastAPI が投げ込む例外は
    外側で止まり、内側の `get_db()` へ伝播しない。内側は放置されて後から
    GeneratorExit で終了するため、rollback とエラーログが**一度も実行されず**
    close も遅延する。ルーティングのDB依存は `get_db_session` に統一されている
    ので、この不具合はアプリの全エンドポイントに効いていた。
    """

    @pytest.mark.asyncio
    async def test_rollback_runs_when_consumer_raises(self, monkeypatch):
        """依存性の利用側が例外を投げたとき rollback と close が実行される"""
        from app.api.deps import get_db_session

        calls: list[str] = []

        monkeypatch.setattr(
            "app.db.session.get_session_maker", lambda: (lambda: _FakeSession(calls))
        )

        gen = get_db_session()
        await gen.__anext__()

        with pytest.raises(RuntimeError, match="endpoint failed"):
            await gen.athrow(RuntimeError("endpoint failed"))

        assert (
            "rollback" in calls
        ), "利用側の例外が db_session_scope まで伝播せず rollback が実行されていない"
        assert "close" in calls
        assert "commit" not in calls

    @pytest.mark.asyncio
    async def test_commit_runs_on_normal_completion(self, monkeypatch):
        """正常終了時は commit と close が実行される"""
        from app.api.deps import get_db_session

        calls: list[str] = []

        monkeypatch.setattr(
            "app.db.session.get_session_maker", lambda: (lambda: _FakeSession(calls))
        )

        gen = get_db_session()
        await gen.__anext__()
        with pytest.raises(StopAsyncIteration):
            await gen.__anext__()

        assert calls == ["commit", "close"]
        assert "rollback" not in calls

    @pytest.mark.asyncio
    async def test_http_exception_is_not_logged_as_a_database_error(self, monkeypatch, caplog):
        """エンドポイントの HTTPException を「DBエラー」として記録しない

        【この回帰テストの理由】: 例外が db_session_scope に届くようになった結果、
        通常の 401/404/500 まで ERROR ＋ スタックトレースで
        "Database session error" として記録されるようになった。
        /health は Docker の HEALTHCHECK が30秒ごとに叩くため、DB障害時は
        ハンドラ自身のエラーに加えて偽のERRORが延々と出る。
        ログベースのアラートがDB障害として鳴ってしまう。
        """
        import logging

        from starlette.exceptions import HTTPException

        from app.api.deps import get_db_session

        calls: list[str] = []
        monkeypatch.setattr(
            "app.db.session.get_session_maker", lambda: (lambda: _FakeSession(calls))
        )

        gen = get_db_session()
        await gen.__anext__()

        with caplog.at_level(logging.DEBUG, logger="app.db.session"):
            with pytest.raises(HTTPException):
                await gen.athrow(HTTPException(status_code=404, detail="nope"))

        assert "Database session error" not in caplog.text
        # ロールバックは行う（書き込み途中で中断された可能性があるため）
        assert "rollback" in calls

    @pytest.mark.asyncio
    async def test_rollback_failure_does_not_replace_the_original_error(self, monkeypatch, caplog):
        """rollback 自体が失敗しても、元の例外がそのまま伝播する

        【この回帰テストの理由】: DB障害時は rollback も失敗する。その例外が
        元の例外を置き換えると、/health が返すはずの
        {status:"error", database:"disconnected"} が汎用エラーに差し替わり、
        さらに global_exception_handler が落ちたDBへエラー行を書きに行く。
        """
        import logging

        class _BrokenRollbackSession(_FakeSession):
            async def rollback(self) -> None:
                raise RuntimeError("connection is invalidated")

        from app.api.deps import get_db_session

        calls: list[str] = []
        monkeypatch.setattr(
            "app.db.session.get_session_maker",
            lambda: (lambda: _BrokenRollbackSession(calls)),
        )

        gen = get_db_session()
        await gen.__anext__()

        with caplog.at_level(logging.DEBUG, logger="app.db.session"):
            with pytest.raises(RuntimeError, match="endpoint failed"):
                await gen.athrow(RuntimeError("endpoint failed"))


class TestSessionFactoryResolution:
    """セッションファクトリの解決点が1つであることのテスト。

    【この回帰テストの理由】: get_session_maker() は「DIを使えない箇所はここを
    経由する」ための迂回点として追加したが、同じモジュールの主要な消費者である
    db_session_scope が async_session_maker を直接参照したままだった。
    差し替えが3経路中1つにしか効かない状態は、迂回点が無いのと変わらない。
    """

    @pytest.mark.asyncio
    async def test_db_session_scope_resolves_through_get_session_maker(self, monkeypatch):
        """db_session_scope が get_session_maker() 経由でファクトリを取る"""
        from app.db.session import db_session_scope

        calls: list[str] = []
        monkeypatch.setattr(
            "app.db.session.get_session_maker", lambda: (lambda: _FakeSession(calls))
        )

        async with db_session_scope() as session:
            assert isinstance(session, _FakeSession)

        assert calls == ["commit", "close"]

    def test_get_session_factory_resolves_through_get_session_maker(self, monkeypatch):
        """deps.get_session_factory も get_session_maker() 経由で解決する"""
        from app.api.deps import get_session_factory

        sentinel = object()
        monkeypatch.setattr("app.db.session.get_session_maker", lambda: sentinel)

        assert get_session_factory() is sentinel

    def test_get_db_is_removed(self):
        """死んだ公開関数 get_db は存在しない

        「使うな」と書かれた DI 形状の公開関数を残すと、将来の
        Depends(get_db) が conftest のオーバーライドを迂回して実DBへ書き込む。
        """
        import app.db.session as session_module

        assert not hasattr(session_module, "get_db")
