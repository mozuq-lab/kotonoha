"""
レート制限ミドルウェア

【ファイル目的】: AI変換APIへのリクエスト数を制限
【ファイル内容】: slowapiを使用したレート制限設定、エラーハンドラー

TASK-0025: レート制限ミドルウェア実装
🔵 NFR-101: レート制限（1リクエスト/10秒/IP）
🔵 NFR-002: AI変換の応答時間を平均3秒以内（レート制限チェックは10ms以内）
"""

from fastapi import Request, Response
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from starlette.responses import JSONResponse

from app.core.config import settings


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


# Limiterインスタンス作成
limiter = Limiter(
    key_func=get_client_ip,
    default_limits=[],  # デフォルトは制限なし（AI系のみ制限）
)


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
