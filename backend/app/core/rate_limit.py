"""
レート制限ミドルウェア

【ファイル目的】: AI変換APIへのリクエスト数を制限
【ファイル内容】: slowapiを使用したレート制限設定、エラーハンドラー

TASK-0025: レート制限ミドルウェア実装
🔵 NFR-101: レート制限（1リクエスト/10秒/IP）
🔵 NFR-002: AI変換の応答時間を平均3秒以内（レート制限チェックは10ms以内）
"""

import logging

from fastapi import Request, Response
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from starlette.responses import JSONResponse

from app.core.config import settings

logger = logging.getLogger(__name__)


def get_client_ip(request: Request) -> str:
    """
    【機能概要】: レート制限用のクライアント識別子（IP）を取得
    【実装方針】: 設定された信頼プロキシ段数に応じて X-Forwarded-For を安全に解釈する

    セキュリティ:
        X-Forwarded-For はクライアントが自由に付与できるヘッダーであり、最左の値を
        無条件に信頼するとヘッダーを書き換えるだけでIP単位のレート制限を回避できる。
        本実装では settings.TRUSTED_PROXY_COUNT で「自身が運用する信頼できるプロキシ段数」
        を明示し、X-Forwarded-For の右からN番目（= 信頼プロキシが観測したクライアントIP）
        のみを採用する。0 の場合は X-Forwarded-For を一切信頼せず接続元IPを使用する。

    Args:
        request: FastAPIリクエストオブジェクト

    Returns:
        str: クライアントIPアドレス（取得不可時は "unknown"）
    """
    proxy_count = settings.TRUSTED_PROXY_COUNT

    if proxy_count > 0:
        forwarded_for = request.headers.get("X-Forwarded-For", "")
        # カンマ区切りで複数IPが連なる。末尾が最も自身に近いプロキシが付与した値。
        parts = [ip.strip() for ip in forwarded_for.split(",") if ip.strip()]
        if parts:
            # 右からproxy_count番目（チェーンより短ければ最左）を採用
            index = min(proxy_count, len(parts))
            return parts[-index]

    # X-Forwarded-Forを信頼しない、または値が無い場合は接続元IPを使用
    if request.client and request.client.host:
        return request.client.host

    # 最終フォールバック
    return "unknown"


# レート制限設定（設定駆動。デフォルトは NFR-101: 1リクエスト/10秒）
AI_RATE_LIMIT = f"{settings.RATE_LIMIT_TIMES}/{settings.RATE_LIMIT_SECONDS}seconds"


def resolve_storage_uri() -> str | None:
    """設定値からLimiterに渡すstorage_uriを解決する。

    settings.RATE_LIMIT_STORAGE_URI が空文字列（デフォルト）の場合は None を返し、
    slowapi/limitsにプロセス内メモリストレージを使用させる。値が設定されている
    場合はそのまま返す（例: "redis://host:6379"）。マルチワーカー/マルチインスタンス
    構成では、共有ストレージ（Redis等）を指定しないとレート制限がプロセスごとに
    独立してしまい、実質的な制限が設定値より緩くなる点に注意。

    Returns:
        str | None: Limiterに渡すstorage_uri（未設定時はNone）。
    """
    return settings.RATE_LIMIT_STORAGE_URI or None


class RateLimitStorageError(RuntimeError):
    """レート制限ストレージの構築に失敗した場合の例外。

    RATE_LIMIT_STORAGE_URIが未対応のスキームであったり、スキームが要求する
    依存パッケージ（例: redis://系スキームには`redis`パッケージ）が
    インストールされていない場合に送出する。原因の生例外（limits.errors.
    ConfigurationError等）は`__cause__`として保持される。
    """


def _build_limiter(storage_uri: str | None) -> Limiter:
    """Limiterインスタンスを構築する。

    【実装方針】: limits/slowapiはストレージバックエンドの構築失敗時に
    `limits.errors.ConfigurationError`を送出するが、そのメッセージだけでは
    「起動できない」という事実と「何を直せばよいか」が伝わりにくい。
    本関数はストレージ構築を試み、失敗した場合は原因（未対応スキーム／
    依存パッケージ不足等）と対処方法が分かるメッセージで`RateLimitStorageError`
    を送出し、エラーログにも記録することで、起動失敗の診断を容易にする。

    注意: ここではストレージオブジェクトの構築のみを検証し、Redis等の
    実サーバーへの接続確認は行わない（limits/slowapiは接続を遅延して行うため）。

    Args:
        storage_uri: resolve_storage_uri()で解決したstorage_uri
            （Noneの場合はインメモリストレージが使われる）。

    Returns:
        Limiter: 構築されたLimiterインスタンス。

    Raises:
        RateLimitStorageError: ストレージの構築に失敗した場合
            （未対応スキーム、依存パッケージ不足等）。
    """
    try:
        return Limiter(
            key_func=get_client_ip,
            default_limits=[],  # デフォルトは制限なし（AI系のみ制限）
            storage_uri=storage_uri,
        )
    except Exception as exc:
        message = (
            "レート制限ストレージの初期化に失敗しました "
            f"(RATE_LIMIT_STORAGE_URI={storage_uri!r})。"
            "RATE_LIMIT_STORAGE_URIのスキームが未対応であるか、"
            "そのスキームが要求する依存パッケージ（例: redis://系スキームには"
            "'redis'パッケージ）がインストールされていない可能性があります。"
            "requirements.txtの内容とインストール状況を確認してください。"
        )
        logger.error(message, exc_info=exc)
        raise RateLimitStorageError(message) from exc


# Limiterインスタンス作成
limiter = _build_limiter(resolve_storage_uri())


async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """
    【機能概要】: レート制限超過時のエラーハンドラー
    【実装方針】: 統一されたエラーレスポンス形式で429エラーを返す

    Args:
        request: FastAPIリクエストオブジェクト
        exc: RateLimitExceeded例外

    Returns:
        JSONResponse: 429エラーレスポンス
    """
    # Retry-After値（制限ウィンドウ秒数）と制限回数を設定から取得
    retry_after = settings.RATE_LIMIT_SECONDS
    limit = settings.RATE_LIMIT_TIMES

    # エラーレスポンス（api-endpoints.mdの仕様に準拠）
    error_response = {
        "success": False,
        "data": None,
        "error": {
            "code": "RATE_LIMIT_EXCEEDED",
            "message": "リクエスト数が上限に達しました。しばらく待ってから再試行してください。",
            "status_code": 429,
            "retry_after": retry_after,
        },
    }

    return JSONResponse(
        status_code=429,
        content=error_response,
        headers={
            "Retry-After": str(retry_after),
            "X-RateLimit-Limit": str(limit),
            "X-RateLimit-Remaining": "0",
            "X-RateLimit-Reset": str(retry_after),
        },
    )


def add_rate_limit_headers(response: Response, limit: int, remaining: int, reset: int) -> Response:
    """
    【機能概要】: レスポンスにレート制限ヘッダーを追加
    【実装方針】: X-RateLimit-*ヘッダーを設定

    Args:
        response: FastAPIレスポンスオブジェクト
        limit: 制限回数
        remaining: 残り回数
        reset: リセットまでの秒数

    Returns:
        Response: ヘッダーを追加したレスポンス
    """
    response.headers["X-RateLimit-Limit"] = str(limit)
    response.headers["X-RateLimit-Remaining"] = str(remaining)
    response.headers["X-RateLimit-Reset"] = str(reset)
    return response
