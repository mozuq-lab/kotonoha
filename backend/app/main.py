"""
FastAPIメインアプリケーション

【ファイル目的】: kotonoha APIのエントリーポイント
【ファイル内容】: アプリケーション初期化、ルーター設定、CORS設定、ライフサイクルイベント
"""

from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from sqlalchemy.exc import SQLAlchemyError

from app.api.v1.api import api_router
from app.api.v1.endpoints.health import router as health_router
from app.core.config import settings, validate_production_settings
from app.core.exceptions import (
    database_exception_handler,
    global_exception_handler,
    validation_exception_handler,
)
from app.core.logging_config import get_logger, setup_logging
from app.core.rate_limit import limiter, rate_limit_exceeded_handler
from app.schemas.health import RootResponse

# ロギング設定を初期化
setup_logging()
logger = get_logger(__name__)

# 本番固有の必須設定を検証する（未設定ならここでアプリ起動を失敗させる）。
#
# 【config.py の import 時ではなくここで呼ぶ理由】: 検証を Settings 生成時に行うと、
# app.core.config を import するだけのプロセス（例: alembic/env.py）まで巻き添えになり、
# レート制限と無関係な `alembic upgrade head` が RATE_LIMIT_STORAGE_URI 未設定で
# 起動不能になる。APIアプリのエントリーポイントである本ファイルでのみ検証する。
validate_production_settings(settings)


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

# 【後方互換】ルートレベルの /health を提供する。
# README・docs/SETUP.md・既存の運用手順が /health を参照しているため残すが、
# ハンドラ実体は /api/v1/health と同一（app/api/v1/endpoints/health.py）にして
# 二重実装を避ける。以前は main.py 側に別実装があり、DB依存も get_db と
# get_db_session で食い違っていた。
app.include_router(health_router, prefix="/health", tags=["health"])


@app.get("/", response_model=RootResponse)
async def root() -> RootResponse:
    """
    【機能概要】: ルートエンドポイント - アプリケーション稼働確認
    【実装方針】: 最もシンプルなエンドポイント、データベースアクセスなし

    Returns:
        RootResponse: メッセージとバージョン情報を含むレスポンス
    """
    return RootResponse(message="kotonoha API is running", version=settings.VERSION)
