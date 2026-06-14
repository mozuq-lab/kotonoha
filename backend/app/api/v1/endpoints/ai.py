"""
AI変換エンドポイント

【機能概要】: AI変換機能のエンドポイント
【実装方針】: AIClientを使用してテキスト変換、ログ記録、エラーハンドリング

TASK-0025: レート制限ミドルウェア実装
TASK-0027: AI変換エンドポイント実装
"""

import logging
import uuid
from dataclasses import dataclass

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db_session, require_api_key
from app.core.config import settings
from app.core.rate_limit import AI_RATE_LIMIT, limiter
from app.crud.crud_ai_conversion import create_conversion_log
from app.schemas.ai_conversion import (
    AIConversionRequest,
    AIConversionResponse,
    AIRegenerateRequest,
)
from app.utils import ai_client as ai_client_module
from app.utils.exceptions import (
    AIConversionException,
    AIProviderException,
    AIRateLimitException,
    AITimeoutException,
)

logger = logging.getLogger(__name__)

router = APIRouter()


def _rate_limit_headers(remaining: int | None = None) -> dict[str, str]:
    """設定値に基づくレート制限ヘッダーを生成する。"""
    remaining_count = (
        max(settings.RATE_LIMIT_TIMES - 1, 0) if remaining is None else max(remaining, 0)
    )
    return {
        "X-RateLimit-Limit": str(settings.RATE_LIMIT_TIMES),
        "X-RateLimit-Remaining": str(remaining_count),
        "X-RateLimit-Reset": str(settings.RATE_LIMIT_SECONDS),
    }


@dataclass(frozen=True)
class ErrorInfo:
    """エラー情報を保持するデータクラス"""

    code: str
    message: str
    status_code: int


# エラー定義マッピング
ERROR_DEFINITIONS: dict[type[Exception], ErrorInfo] = {
    AITimeoutException: ErrorInfo(
        code="AI_API_TIMEOUT",
        message="AI変換APIがタイムアウトしました。しばらく待ってから再度お試しください。",
        status_code=504,
    ),
    AIProviderException: ErrorInfo(
        code="AI_PROVIDER_ERROR",
        message="AI変換サービスが一時的に利用できません。しばらく待ってから再度お試しください。",
        status_code=503,
    ),
    AIRateLimitException: ErrorInfo(
        code="AI_RATE_LIMIT",
        message="AI変換APIのレート制限に達しました。しばらく待ってから再度お試しください。",
        status_code=429,
    ),
    AIConversionException: ErrorInfo(
        code="AI_API_ERROR",
        message="AI変換APIからのレスポンスに失敗しました。しばらく待ってから再度お試しください。",
        status_code=500,
    ),
}

# デフォルトエラー（予期しないエラー用）
DEFAULT_ERROR = ErrorInfo(
    code="INTERNAL_ERROR",
    message="予期しないエラーが発生しました。",
    status_code=500,
)


def _create_error_response(error_info: ErrorInfo) -> JSONResponse:
    """
    統一エラーレスポンスを生成

    【機能概要】: エラーレスポンスを統一形式で生成
    【実装方針】: success, data, errorフィールドを含むJSON形式

    Args:
        error_info: エラー情報（コード、メッセージ、ステータスコード）

    Returns:
        JSONResponse: 統一形式のエラーレスポンス
    """
    return JSONResponse(
        status_code=error_info.status_code,
        content={
            "success": False,
            "data": None,
            "error": {
                "code": error_info.code,
                "message": error_info.message,
                "status_code": error_info.status_code,
            },
        },
        headers=_rate_limit_headers(remaining=0 if error_info.status_code == 429 else None),
    )


async def _log_conversion_error(
    db: AsyncSession,
    input_text: str,
    politeness_level: str,
    session_id: uuid.UUID,
    error: Exception,
) -> None:
    """
    AI変換エラーをログに記録

    【機能概要】: 変換失敗時のログを統一的に記録
    【実装方針】: 共通のログ記録パターンを抽出

    Args:
        db: データベースセッション
        input_text: 入力テキスト
        politeness_level: 丁寧さレベル
        session_id: セッションID
        error: 発生したエラー
    """
    await create_conversion_log(
        db=db,
        input_text=input_text,
        output_text="",
        politeness_level=politeness_level,
        session_id=session_id,
        is_success=False,
        error_message=str(error),
    )


def _get_error_info(error: Exception) -> ErrorInfo:
    """
    例外からエラー情報を取得

    【機能概要】: 例外の型に応じたエラー情報を返す
    【実装方針】: ERROR_DEFINITIONSマッピングを使用

    Args:
        error: 発生した例外

    Returns:
        ErrorInfo: 対応するエラー情報
    """
    return ERROR_DEFINITIONS.get(type(error), DEFAULT_ERROR)


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
    _: None = Depends(require_api_key),
) -> JSONResponse:
    """
    【機能概要】: AI変換エンドポイント
    【実装方針】:
      - AIClientを使用してテキストを変換
      - 成功・失敗に関わらずログを記録
      - 例外に応じた適切なHTTPステータスコードを返却

    Args:
        request: FastAPIリクエストオブジェクト（レート制限用）
        conversion_request: AI変換リクエストデータ
        db: データベースセッション

    Returns:
        AIConversionResponse: AI変換レスポンス

    Raises:
        HTTPException: AI変換エラー時
    """
    input_text = conversion_request.input_text
    politeness_level = conversion_request.politeness_level.value
    session_id = uuid.uuid4()

    try:
        # AI変換を実行
        converted_text, processing_time_ms = await ai_client_module.ai_client.convert_text(
            input_text=input_text,
            politeness_level=politeness_level,
        )

        # 成功時のログ記録
        await create_conversion_log(
            db=db,
            input_text=input_text,
            output_text=converted_text,
            politeness_level=politeness_level,
            conversion_time_ms=processing_time_ms,
            session_id=session_id,
            is_success=True,
        )

        # 成功レスポンス
        response_data = {
            "converted_text": converted_text,
            "original_text": input_text,
            "politeness_level": politeness_level,
            "processing_time_ms": processing_time_ms,
        }

        return JSONResponse(
            content=response_data,
            headers=_rate_limit_headers(),
        )

    except (
        AITimeoutException,
        AIProviderException,
        AIRateLimitException,
        AIConversionException,
    ) as e:
        # 既知のAI変換エラー
        error_info = _get_error_info(e)
        logger.error(f"AI conversion error ({error_info.code}): {e}")
        await _log_conversion_error(db, input_text, politeness_level, session_id, e)
        return _create_error_response(error_info)

    except Exception as e:
        # 予期しないエラー
        logger.exception(f"Unexpected error during AI conversion: {e}")
        await _log_conversion_error(db, input_text, politeness_level, session_id, e)
        return _create_error_response(DEFAULT_ERROR)


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
    _: None = Depends(require_api_key),
) -> JSONResponse:
    """
    【機能概要】: AI再変換エンドポイント
    【実装方針】:
      - AIClientのregenerate_textを使用してテキストを再変換
      - 前回と異なる表現を生成
      - 成功・失敗に関わらずログを記録
      - 例外に応じた適切なHTTPステータスコードを返却

    TASK-0028: AI再変換エンドポイント実装（POST /api/v1/ai/regenerate）
    🔵 REQ-904（同じ丁寧さで再変換可能）に基づく

    Args:
        request: FastAPIリクエストオブジェクト（レート制限用）
        regenerate_request: AI再変換リクエストデータ
        db: データベースセッション

    Returns:
        AIConversionResponse: AI変換レスポンス
    """
    input_text = regenerate_request.input_text
    politeness_level = regenerate_request.politeness_level.value
    previous_result = regenerate_request.previous_result
    session_id = uuid.uuid4()

    try:
        # AI再変換を実行
        converted_text, processing_time_ms = await ai_client_module.ai_client.regenerate_text(
            input_text=input_text,
            politeness_level=politeness_level,
            previous_result=previous_result,
        )

        # 成功時のログ記録
        await create_conversion_log(
            db=db,
            input_text=input_text,
            output_text=converted_text,
            politeness_level=politeness_level,
            conversion_time_ms=processing_time_ms,
            session_id=session_id,
            is_success=True,
        )

        # 成功レスポンス
        response_data = {
            "converted_text": converted_text,
            "original_text": input_text,
            "politeness_level": politeness_level,
            "processing_time_ms": processing_time_ms,
        }

        return JSONResponse(
            content=response_data,
            headers=_rate_limit_headers(),
        )

    except (
        AITimeoutException,
        AIProviderException,
        AIRateLimitException,
        AIConversionException,
    ) as e:
        # 既知のAI変換エラー
        error_info = _get_error_info(e)
        logger.error(f"AI regeneration error ({error_info.code}): {e}")
        await _log_conversion_error(db, input_text, politeness_level, session_id, e)
        return _create_error_response(error_info)

    except Exception as e:
        # 予期しないエラー
        logger.exception(f"Unexpected error during AI regeneration: {e}")
        await _log_conversion_error(db, input_text, politeness_level, session_id, e)
        return _create_error_response(DEFAULT_ERROR)
