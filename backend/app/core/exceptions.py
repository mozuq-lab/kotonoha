"""
グローバル例外ハンドラーモジュール

【機能概要】: FastAPIアプリケーション全体で発生する例外を統一的に処理
【実装方針】: エラーログのデータベース保存、適切なHTTPレスポンス返却

TASK-0031: グローバルエラーハンドラー・例外処理実装
🔵 NFR-301（基本機能継続利用）、NFR-304（データベースエラーハンドリング）に基づく
"""

import logging
import traceback

from fastapi import Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import settings
from app.db import session as db_session
from app.models.error_logs import ErrorLog

logger = logging.getLogger(__name__)


async def log_error_to_db(
    error_type: str,
    error_message: str,
    error_code: str | None,
    endpoint: str,
    http_method: str,
    stack_trace: str | None = None,
) -> None:
    """
    【機能概要】: エラー情報をデータベースに保存
    【実装方針】: エラーログ保存自体がエラーになっても本処理に影響を与えない

    Args:
        error_type: エラータイプ名（例外クラス名）
        error_message: エラーメッセージ
        error_code: エラーコード（オプション）
        endpoint: エラー発生エンドポイント
        http_method: HTTPメソッド
        stack_trace: スタックトレース（開発環境のみ保存）

    🔵 NFR-304に基づく
    """
    try:
        # 【async_session_maker を直接使わない理由】: 本関数は例外ハンドラから
        # 呼ばれ、FastAPIの依存性注入を経由しない。モジュール変数を直接参照すると
        # 依存性オーバーライドが効かず、テスト実行中のエラーログ書き込みが
        # 開発用DBへ飛んでしまう（tests/conftest.py が差し替えられるよう、
        # 必ず get_session_maker() 経由で解決する）。
        session_maker = db_session.get_session_maker()
        async with session_maker() as session:
            error_log = ErrorLog(
                error_type=error_type,
                error_message=error_message[:500],  # メッセージ長を制限
                error_code=error_code,
                endpoint=endpoint[:255] if endpoint else None,
                http_method=http_method,
                stack_trace=stack_trace if settings.ENVIRONMENT == "development" else None,
            )
            session.add(error_log)
            await session.commit()
            logger.debug(f"Error logged to database: {error_type}")
    except Exception as e:
        # エラーログ保存自体がエラーになっても本処理を継続
        logger.error(f"Failed to log error to database: {e}")


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    【機能概要】: 未処理例外のグローバルハンドラー
    【実装方針】: 予期しない例外をキャッチし、適切なエラーレスポンスを返す

    Args:
        request: FastAPIリクエストオブジェクト
        exc: 発生した例外

    Returns:
        JSONResponse: 500エラーレスポンス

    🔵 NFR-301（基本機能継続利用）に基づく
    """
    error_type = type(exc).__name__
    error_message = str(exc)
    stack_trace = traceback.format_exc()

    logger.error(f"Unhandled exception: {error_type} - {error_message}\n{stack_trace}")

    # エラーログをデータベースに保存
    await log_error_to_db(
        error_type=error_type,
        error_message=error_message,
        error_code="INTERNAL_ERROR",
        endpoint=str(request.url.path),
        http_method=request.method,
        stack_trace=stack_trace,
    )

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "予期しないエラーが発生しました",
            "detail": "しばらく待ってから再試行してください",
            "error_code": "INTERNAL_ERROR",
        },
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    """
    【機能概要】: バリデーションエラーハンドラー
    【実装方針】: 入力データ検証エラーを統一フォーマットで返す

    Args:
        request: FastAPIリクエストオブジェクト
        exc: バリデーションエラー

    Returns:
        JSONResponse: 422エラーレスポンス

    🔵 NFR-301に基づく
    """
    # エラー詳細をシリアライズ可能な形式に変換
    errors = []
    for error in exc.errors():
        serializable_error = {
            "type": error.get("type", "unknown"),
            "loc": error.get("loc", []),
            "msg": error.get("msg", ""),
        }
        errors.append(serializable_error)

    logger.warning(f"Validation error at {request.url.path}: {errors}")

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "入力データが不正です",
            "detail": errors,
            "error_code": "VALIDATION_ERROR",
        },
    )


async def database_exception_handler(
    request: Request,
    exc: SQLAlchemyError,
) -> JSONResponse:
    """
    【機能概要】: データベースエラーハンドラー
    【実装方針】: データベース関連エラーを適切にハンドリング

    Args:
        request: FastAPIリクエストオブジェクト
        exc: SQLAlchemyエラー

    Returns:
        JSONResponse: 503エラーレスポンス

    🔵 NFR-304（データベースエラーハンドリング）に基づく
    """
    error_message = str(exc)
    stack_trace = traceback.format_exc()

    logger.error(f"Database error at {request.url.path}: {error_message}")

    await log_error_to_db(
        error_type="SQLAlchemyError",
        error_message=error_message,
        error_code="DATABASE_ERROR",
        endpoint=str(request.url.path),
        http_method=request.method,
        stack_trace=stack_trace,
    )

    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={
            "error": "データベースエラーが発生しました",
            "detail": "しばらく待ってから再試行してください",
            "error_code": "DATABASE_ERROR",
        },
    )
