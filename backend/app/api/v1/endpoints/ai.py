"""
AI変換エンドポイント

【機能概要】: AI変換機能のエンドポイント
【実装予定】: TASK-0025でレート制限、TASK-0027〜0028で本実装

TASK-0025: レート制限ミドルウェア実装
🔵 NFR-101: レート制限（1リクエスト/10秒/IP）
"""

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db_session
from app.core.rate_limit import AI_RATE_LIMIT, limiter
from app.schemas.ai_conversion import (
    AIConversionRequest,
    AIConversionResponse,
    AIRegenerateRequest,
)

router = APIRouter()


@router.post(
    "/convert",
    response_model=AIConversionResponse,
    summary="AI変換API",
    description="入力文字列を指定の丁寧さレベルでAI変換します（レート制限: 10秒に1回）",
)
@limiter.limit(AI_RATE_LIMIT)
async def convert_text(
    request: Request,
    conversion_request: AIConversionRequest,
    db: AsyncSession = Depends(get_db_session),
) -> JSONResponse:
    """
    【機能概要】: AI変換エンドポイント（仮実装）
    【実装方針】: レート制限を適用、本実装はTASK-0027で行う

    Args:
        request: FastAPIリクエストオブジェクト（レート制限用）
        conversion_request: AI変換リクエストデータ
        db: データベースセッション

    Returns:
        AIConversionResponse: AI変換レスポンス
    """
    # 仮実装: 入力テキストをそのまま返す（TASK-0027で本実装）
    response_data = {
        "converted_text": f"{conversion_request.input_text}（変換済み）",
        "original_text": conversion_request.input_text,
        "politeness_level": conversion_request.politeness_level.value,
        "processing_time_ms": 100,
    }

    return JSONResponse(
        content=response_data,
        headers={
            "X-RateLimit-Limit": "1",
            "X-RateLimit-Remaining": "0",
            "X-RateLimit-Reset": "10",
        },
    )


@router.post(
    "/regenerate",
    response_model=AIConversionResponse,
    summary="AI再変換API",
    description="前回と異なる変換結果を取得します（レート制限: 10秒に1回）",
)
@limiter.limit(AI_RATE_LIMIT)
async def regenerate_text(
    request: Request,
    regenerate_request: AIRegenerateRequest,
    db: AsyncSession = Depends(get_db_session),
) -> JSONResponse:
    """
    【機能概要】: AI再変換エンドポイント（仮実装）
    【実装方針】: レート制限を適用、本実装はTASK-0028で行う

    Args:
        request: FastAPIリクエストオブジェクト（レート制限用）
        regenerate_request: AI再変換リクエストデータ
        db: データベースセッション

    Returns:
        AIConversionResponse: AI変換レスポンス
    """
    # 仮実装: 前回結果と異なる結果を返す（TASK-0028で本実装）
    response_data = {
        "converted_text": f"{regenerate_request.input_text}（再変換済み）",
        "original_text": regenerate_request.input_text,
        "politeness_level": regenerate_request.politeness_level.value,
        "processing_time_ms": 150,
    }

    return JSONResponse(
        content=response_data,
        headers={
            "X-RateLimit-Limit": "1",
            "X-RateLimit-Remaining": "0",
            "X-RateLimit-Reset": "10",
        },
    )
