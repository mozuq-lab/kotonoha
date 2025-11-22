"""
FastAPIメインアプリケーション

【ファイル目的】: kotonoha APIのエントリーポイント
【ファイル内容】: アプリケーション初期化、ルーター設定、CORS設定、ライフサイクルイベント
"""

from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import AsyncIterator

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.api import api_router
from app.core.config import settings
from app.core.rate_limit import limiter, rate_limit_exceeded_handler
from app.core.logging_config import get_logger, setup_logging
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


# FastAPIアプリケーション作成
# 後方互換性のため、openapi_urlはルートレベル（/openapi.json）を維持
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url="/openapi.json",
    description="文字盤コミュニケーション支援アプリ バックエンドAPI",
    lifespan=lifespan,
)

# レート制限設定
# TASK-0025: レート制限ミドルウェア実装
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

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


def get_current_timestamp() -> str:
    """
    【機能概要】: 現在時刻をISO 8601形式で取得するヘルパー関数
    【設計方針】: DRY原則に基づき、タイムスタンプ生成を一箇所に集約

    Returns:
        str: ISO 8601形式のタイムスタンプ（UTC、例: "2025-11-20T12:34:56Z"）
    """
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


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
    【実装方針】: データベース接続確認（SELECT 1実行）、タイムスタンプ、バージョン情報を含む
    【後方互換性】: /health エンドポイントをルートレベルでも提供（/api/v1/health と同等）

    Args:
        db: データベースセッション（依存性注入）

    Returns:
        HealthResponse: ヘルスチェックレスポンス

    Raises:
        HTTPException: データベース接続失敗時に500エラーを返す
    """
    try:
        timestamp = get_current_timestamp()
        await db.execute(text("SELECT 1"))
        return HealthResponse(
            status="ok",
            database="connected",
            version=settings.VERSION,
            timestamp=timestamp,
        )
    except Exception as e:
        error_message = (
            str(e)
            if settings.ENVIRONMENT == "development"
            else "Database connection failed"
        )
        error_timestamp = get_current_timestamp()
        error_response = HealthErrorResponse(
            status="error",
            database="disconnected",
            error=error_message,
            version=settings.VERSION,
            timestamp=error_timestamp,
        )
        raise HTTPException(status_code=500, detail=error_response.model_dump())
