"""
AI変換エンドポイント

【機能概要】: AI変換機能のエンドポイント
【実装方針】: AIClientを使用してテキスト変換、ログ記録、エラーハンドリング

TASK-0025: レート制限ミドルウェア実装
TASK-0027: AI変換エンドポイント実装
"""

import asyncio
import logging
import uuid
from dataclasses import dataclass

from fastapi import APIRouter, BackgroundTasks, Depends, Request
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.api.deps import get_session_factory, require_api_key
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

# バックグラウンドでのログ書き込み1回あたりの許容時間（秒）。
# 接続プール待ちやcommitがハングしても、応答済みのリクエストを無期限にブロックしないための上限。
BACKGROUND_LOG_TIMEOUT_SECONDS: float = 5.0


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
    )


async def _persist_conversion_log(
    session_factory: async_sessionmaker[AsyncSession],
    *,
    input_text: str,
    output_text: str,
    politeness_level: str,
    conversion_time_ms: int | None,
    ai_provider: str,
    session_id: uuid.UUID,
    is_success: bool,
    error_message: str | None = None,
) -> None:
    """
    独立した短命セッションでAI変換ログを永続化する

    【機能概要】: FastAPIの`BackgroundTasks`経由（応答返却後）に呼び出され、
                  session_factoryから新規に取得した独立したセッションでログを
                  書き込みcommitする。
    【実装方針】: リクエストスコープのセッション（get_db_session）は応答返却後には
                  既にクローズされている可能性があるため再利用せず、必ず新規セッションを
                  取得する。書き込み全体を`BACKGROUND_LOG_TIMEOUT_SECONDS`でタイムアウト
                  させることで、接続プール待ちやcommitのハングが無期限に続くことを防ぐ。
                  セッションは例外・タイムアウトの有無にかかわらずfinallyで必ずクローズ
                  する。失敗時は警告ログのみとし例外を再送出しない
                  （応答は既に返却済みのため、ここで例外を送出しても誰も救えない）。

    Args:
        session_factory: 独立したセッションを生成するファクトリ
        input_text: 元の入力テキスト
        output_text: 変換後テキスト（失敗時は空文字）
        politeness_level: 丁寧さレベル
        conversion_time_ms: 変換処理時間（ミリ秒、失敗時はNone）
        ai_provider: 実際に使用したAIプロバイダー名
        session_id: セッションID
        is_success: 成功フラグ
        error_message: エラーメッセージ（失敗時のみ）
    """

    async def _write() -> None:
        session = session_factory()
        try:
            await create_conversion_log(
                db=session,
                input_text=input_text,
                output_text=output_text,
                politeness_level=politeness_level,
                conversion_time_ms=conversion_time_ms,
                ai_provider=ai_provider,
                session_id=session_id,
                is_success=is_success,
                error_message=error_message,
            )
            await session.commit()
        finally:
            await session.close()

    try:
        await asyncio.wait_for(_write(), timeout=BACKGROUND_LOG_TIMEOUT_SECONDS)
    except Exception:
        logger.warning(
            "Failed to persist AI conversion log in background "
            "(session_id=%s, is_success=%s); dropping this log entry.",
            session_id,
            is_success,
            exc_info=True,
        )


async def _log_conversion_success_background(
    session_factory: async_sessionmaker[AsyncSession],
    input_text: str,
    output_text: str,
    politeness_level: str,
    conversion_time_ms: int,
    ai_provider: str,
    session_id: uuid.UUID,
) -> None:
    """
    AI変換成功ログをバックグラウンドで記録する

    【機能概要】: 変換成功時のログを応答返却後に非同期で記録する。
    【実装方針】: DB書き込みが失敗・ハングしても、応答には一切影響しない
                  （呼び出し時点で成功応答は既に返却済みのため）。

    Args:
        session_factory: 独立したセッションを生成するファクトリ
        input_text: 入力テキスト
        output_text: 変換後テキスト
        politeness_level: 丁寧さレベル
        conversion_time_ms: 変換処理時間（ミリ秒）
        ai_provider: 実際に使用したAIプロバイダー名
        session_id: セッションID
    """
    await _persist_conversion_log(
        session_factory,
        input_text=input_text,
        output_text=output_text,
        politeness_level=politeness_level,
        conversion_time_ms=conversion_time_ms,
        ai_provider=ai_provider,
        session_id=session_id,
        is_success=True,
    )


async def _log_conversion_error_background(
    session_factory: async_sessionmaker[AsyncSession],
    input_text: str,
    politeness_level: str,
    ai_provider: str,
    session_id: uuid.UUID,
    error: Exception,
) -> None:
    """
    AI変換エラーログをバックグラウンドで記録する

    【機能概要】: 変換失敗時のログを応答返却後に非同期で記録する。
    【実装方針】: DB書き込みが失敗・ハングしても、応答には一切影響しない
                  （呼び出し時点で意図したエラー応答は既に返却済みのため）。

    Args:
        session_factory: 独立したセッションを生成するファクトリ
        input_text: 入力テキスト
        politeness_level: 丁寧さレベル
        ai_provider: 実際に使用したAIプロバイダー名
        session_id: セッションID
        error: 発生したエラー
    """
    await _persist_conversion_log(
        session_factory,
        input_text=input_text,
        output_text="",
        politeness_level=politeness_level,
        conversion_time_ms=None,
        ai_provider=ai_provider,
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
    background_tasks: BackgroundTasks,
    session_factory: async_sessionmaker[AsyncSession] = Depends(get_session_factory),
    _: None = Depends(require_api_key),
) -> JSONResponse:
    """
    【機能概要】: AI変換エンドポイント
    【実装方針】:
      - AIClientを使用してテキストを変換
      - 成功・失敗に関わらずログを記録するが、DBへの書き込みは応答返却後の
        BackgroundTasksへ委譲する（接続プール待ちやcommitのハングが応答をブロックしないため）
      - 例外に応じた適切なHTTPステータスコードを返却

    Args:
        request: FastAPIリクエストオブジェクト（レート制限用）
        conversion_request: AI変換リクエストデータ
        background_tasks: 応答返却後にログ書き込みを実行するためのタスクキュー
        session_factory: バックグラウンドタスクが独立したセッションを生成するためのファクトリ

    Returns:
        AIConversionResponse: AI変換レスポンス

    Raises:
        HTTPException: AI変換エラー時
    """
    input_text = conversion_request.input_text
    politeness_level = conversion_request.politeness_level.value
    session_id = uuid.uuid4()
    # 実際に使用されるAIプロバイダー（リクエストで明示指定できないため、常にデフォルト値）
    ai_provider = settings.DEFAULT_AI_PROVIDER

    try:
        # AI変換を実行
        converted_text, processing_time_ms = await ai_client_module.ai_client.convert_text(
            input_text=input_text,
            politeness_level=politeness_level,
        )

        # 成功時のログ記録は応答返却後にバックグラウンドで実行する
        # （DB障害・遅延があっても成功した変換結果は必ず返す）
        background_tasks.add_task(
            _log_conversion_success_background,
            session_factory,
            input_text,
            converted_text,
            politeness_level,
            processing_time_ms,
            ai_provider,
            session_id,
        )

        # 成功レスポンス
        response_data = {
            "converted_text": converted_text,
            "original_text": input_text,
            "politeness_level": politeness_level,
            "processing_time_ms": processing_time_ms,
        }

        return JSONResponse(content=response_data)

    except (
        AITimeoutException,
        AIProviderException,
        AIRateLimitException,
        AIConversionException,
    ) as e:
        # 既知のAI変換エラー
        error_info = _get_error_info(e)
        logger.error(f"AI conversion error ({error_info.code}): {e}")
        # エラーログの記録も応答返却後にバックグラウンドで実行する
        # （本エンドポイントはHTTPExceptionを送出せず常にJSONResponseを返すため、
        #  BackgroundTasksはこのエラーパスでも確実に実行される）
        background_tasks.add_task(
            _log_conversion_error_background,
            session_factory,
            input_text,
            politeness_level,
            ai_provider,
            session_id,
            e,
        )
        return _create_error_response(error_info)

    except Exception as e:
        # 予期しないエラー
        logger.exception(f"Unexpected error during AI conversion: {e}")
        background_tasks.add_task(
            _log_conversion_error_background,
            session_factory,
            input_text,
            politeness_level,
            ai_provider,
            session_id,
            e,
        )
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
    background_tasks: BackgroundTasks,
    session_factory: async_sessionmaker[AsyncSession] = Depends(get_session_factory),
    _: None = Depends(require_api_key),
) -> JSONResponse:
    """
    【機能概要】: AI再変換エンドポイント
    【実装方針】:
      - AIClientのregenerate_textを使用してテキストを再変換
      - 前回と異なる表現を生成
      - 成功・失敗に関わらずログを記録するが、DBへの書き込みは応答返却後の
        BackgroundTasksへ委譲する（接続プール待ちやcommitのハングが応答をブロックしないため）
      - 例外に応じた適切なHTTPステータスコードを返却

    TASK-0028: AI再変換エンドポイント実装（POST /api/v1/ai/regenerate）
    🔵 REQ-904（同じ丁寧さで再変換可能）に基づく

    Args:
        request: FastAPIリクエストオブジェクト（レート制限用）
        regenerate_request: AI再変換リクエストデータ
        background_tasks: 応答返却後にログ書き込みを実行するためのタスクキュー
        session_factory: バックグラウンドタスクが独立したセッションを生成するためのファクトリ

    Returns:
        AIConversionResponse: AI変換レスポンス
    """
    input_text = regenerate_request.input_text
    politeness_level = regenerate_request.politeness_level.value
    previous_result = regenerate_request.previous_result
    session_id = uuid.uuid4()
    # 実際に使用されるAIプロバイダー（リクエストで明示指定できないため、常にデフォルト値）
    ai_provider = settings.DEFAULT_AI_PROVIDER

    try:
        # AI再変換を実行
        converted_text, processing_time_ms = await ai_client_module.ai_client.regenerate_text(
            input_text=input_text,
            politeness_level=politeness_level,
            previous_result=previous_result,
        )

        # 成功時のログ記録は応答返却後にバックグラウンドで実行する
        # （DB障害・遅延があっても成功応答は必ず返す）
        background_tasks.add_task(
            _log_conversion_success_background,
            session_factory,
            input_text,
            converted_text,
            politeness_level,
            processing_time_ms,
            ai_provider,
            session_id,
        )

        # 成功レスポンス
        response_data = {
            "converted_text": converted_text,
            "original_text": input_text,
            "politeness_level": politeness_level,
            "processing_time_ms": processing_time_ms,
        }

        return JSONResponse(content=response_data)

    except (
        AITimeoutException,
        AIProviderException,
        AIRateLimitException,
        AIConversionException,
    ) as e:
        # 既知のAI変換エラー
        error_info = _get_error_info(e)
        logger.error(f"AI regeneration error ({error_info.code}): {e}")
        # エラーログの記録も応答返却後にバックグラウンドで実行する
        # （本エンドポイントはHTTPExceptionを送出せず常にJSONResponseを返すため、
        #  BackgroundTasksはこのエラーパスでも確実に実行される）
        background_tasks.add_task(
            _log_conversion_error_background,
            session_factory,
            input_text,
            politeness_level,
            ai_provider,
            session_id,
            e,
        )
        return _create_error_response(error_info)

    except Exception as e:
        # 予期しないエラー
        logger.exception(f"Unexpected error during AI regeneration: {e}")
        background_tasks.add_task(
            _log_conversion_error_background,
            session_factory,
            input_text,
            politeness_level,
            ai_provider,
            session_id,
            e,
        )
        return _create_error_response(DEFAULT_ERROR)
