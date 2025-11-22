"""
ヘルスチェックエンドポイント

【機能概要】: システム稼働状況とデータベース接続確認エンドポイント
【実装方針】: データベース接続確認、AIプロバイダー情報、タイムスタンプ、バージョン情報を提供

TASK-0029: ヘルスチェックエンドポイント実装（GET /api/v1/health）
🔵 NFR-304, NFR-504に基づく
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db_session
from app.core.config import settings
from app.schemas.health import HealthErrorResponse, HealthResponse
from app.utils import ai_client as ai_client_module

router = APIRouter()


def get_current_timestamp() -> str:
    """
    【機能概要】: 現在時刻をISO 8601形式で取得するヘルパー関数
    【設計方針】: DRY原則に基づき、タイムスタンプ生成を一箇所に集約

    Returns:
        str: ISO 8601形式のタイムスタンプ（UTC、例: "2025-11-20T12:34:56Z"）
    """
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def get_ai_provider_status() -> str:
    """
    【機能概要】: 有効なAIプロバイダーを確認するヘルパー関数
    【設計方針】: AIClient の初期化状態を確認し、使用可能なプロバイダーを返す

    Returns:
        str: AIプロバイダー名（"anthropic", "openai", "none"）

    🔵 TASK-0029に基づく
    """
    ai_client = ai_client_module.ai_client
    if ai_client.anthropic_client:
        return "anthropic"
    elif ai_client.openai_client:
        return "openai"
    return "none"


@router.get(
    "",
    response_model=HealthResponse,
    responses={
        200: {"description": "ヘルスチェック成功"},
        500: {"model": HealthErrorResponse},
    },
)
async def health_check(
    db: AsyncSession = Depends(get_db_session),
) -> HealthResponse:
    """
    【機能概要】: ヘルスチェックエンドポイント - システム稼働状況とデータベース接続確認
    【実装方針】: データベース接続確認（SELECT 1実行）、AIプロバイダー確認、タイムスタンプ、バージョン情報を含む

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
