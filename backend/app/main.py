"""
FastAPIメインアプリケーション

【ファイル目的】: kotonoha APIのエントリーポイント
【ファイル内容】: アプリケーション初期化、ルーター設定、CORS設定、ライフサイクルイベント
"""

from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import Depends, FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.api import api_router
from app.api.v1.endpoints.health import get_ai_provider_status, get_current_timestamp
from app.core.config import settings
from app.core.exceptions import (
    database_exception_handler,
    global_exception_handler,
    validation_exception_handler,
)
from app.core.logging_config import get_logger, setup_logging
from app.core.rate_limit import limiter, rate_limit_exceeded_handler
from app.db.session import get_db
from app.schemas.health import HealthErrorResponse, HealthResponse, RootResponse

# ロギング設定を初期化
setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """
    【機能概要】: アプリケーションのライフサイクルイベントを管理
    【実装方針】: 起動時・終了時の処理をここに集約
    """
    # 起動時の処理
    logger.info(f"Starting {settings.PROJECT_NAME}...")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"API Version: {settings.VERSION}")
    yield
    # 終了時の処理
    logger.info(f"Shutting down {settings.PROJECT_NAME}...")
    # AIクライアントのHTTPリソースを明示的にクローズ
    from app.utils import ai_client as ai_client_module

    await ai_client_module.ai_client.aclose()


# ドキュメント（Swagger UI / ReDoc / OpenAPI）を公開する環境のallowlist。
# staging/production等、allowlist外の環境では実装詳細の漏えい防止のため非公開にする。
_DOCS_ENABLED_ENVIRONMENTS = frozenset({"development", "test"})


def _resolve_docs_urls(environment: str) -> tuple[str | None, str | None, str | None]:
    """環境に応じたSwagger UI / ReDoc / OpenAPIの公開URLを解決する。

    allowlist外の環境（staging, production等）ではすべて None を返し、
    FastAPIにドキュメントエンドポイント自体を生成させない。

    Args:
        environment: 現在の実行環境（settings.ENVIRONMENT）。

    Returns:
        tuple[str | None, str | None, str | None]:
            (docs_url, redoc_url, openapi_url)。非公開時はすべて None。
    """
    if environment not in _DOCS_ENABLED_ENVIRONMENTS:
        return None, None, None
    # 後方互換性のため、openapi_urlはルートレベル（/openapi.json）を維持
    return "/docs", "/redoc", "/openapi.json"


_docs_url, _redoc_url, _openapi_url = _resolve_docs_urls(settings.ENVIRONMENT)

# FastAPIアプリケーション作成
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=_openapi_url,
    docs_url=_docs_url,
    redoc_url=_redoc_url,
    description="文字盤コミュニケーション支援アプリ バックエンドAPI",
    lifespan=lifespan,
)

# レート制限設定
# TASK-0025: レート制限ミドルウェア実装
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

# グローバルエラーハンドラー登録
# TASK-0031: グローバルエラーハンドラー・例外処理実装
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(SQLAlchemyError, database_exception_handler)
app.add_exception_handler(Exception, global_exception_handler)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS_LIST,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# APIルーターを登録
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", response_model=RootResponse)
async def root() -> RootResponse:
    """
    【機能概要】: ルートエンドポイント - アプリケーション稼働確認
    【実装方針】: 最もシンプルなエンドポイント、データベースアクセスなし

    Returns:
        RootResponse: メッセージとバージョン情報を含むレスポンス
    """
    return RootResponse(message="kotonoha API is running", version=settings.VERSION)


@app.get(
    "/health",
    response_model=HealthResponse,
    responses={
        200: {"description": "ヘルスチェック成功（データベース接続正常）"},
        500: {
            "description": "ヘルスチェック失敗（データベース接続失敗）",
            "model": HealthErrorResponse,
        },
    },
)
async def health_check(
    db: AsyncSession = Depends(get_db),
) -> HealthResponse | HealthErrorResponse:
    """
    【機能概要】: ヘルスチェックエンドポイント - システム稼働状況とデータベース接続確認
    【実装方針】: データベース接続確認（SELECT 1実行）、AIプロバイダー確認、タイムスタンプ、バージョン情報を含む
    【後方互換性】: /health エンドポイントをルートレベルでも提供（/api/v1/health と同等）

    Args:
        db: データベースセッション（依存性注入）

    Returns:
        HealthResponse: ヘルスチェックレスポンス

    Raises:
        HTTPException: データベース接続失敗時に500エラーを返す

    🔵 TASK-0029: AI プロバイダー確認機能を追加
    """
    try:
        timestamp = get_current_timestamp()
        await db.execute(text("SELECT 1"))

        # AIプロバイダー確認
        ai_provider = get_ai_provider_status()

        return HealthResponse(
            status="ok",
            database="connected",
            ai_provider=ai_provider,
            version=settings.VERSION,
            timestamp=timestamp,
        )
    except Exception as e:
        error_message = (
            str(e) if settings.ENVIRONMENT == "development" else "Database connection failed"
        )
        error_timestamp = get_current_timestamp()
        error_response = HealthErrorResponse(
            status="error",
            database="disconnected",
            error=error_message,
            version=settings.VERSION,
            timestamp=error_timestamp,
        )
        raise HTTPException(status_code=500, detail=error_response.model_dump()) from e
