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


def get_client_ip(request: Request) -> str:
    """
    【機能概要】: クライアントIPアドレスを取得
    【実装方針】: X-Forwarded-Forヘッダーを優先、なければリクエストクライアントIPを使用

    Args:
        request: FastAPIリクエストオブジェクト

    Returns:
        str: クライアントIPアドレス
    """
    # X-Forwarded-Forヘッダーを確認（プロキシ/ロードバランサー経由）
    forwarded_for = request.headers.get("X-Forwarded-For", "")

    if forwarded_for:
        # カンマ区切りの場合は最初のIPを取得（最左がオリジナルクライアント）
        ip = forwarded_for.split(",")[0].strip()
        if ip:
            return ip

    # フォールバック: リクエストクライアントIP
    if request.client and request.client.host:
        return request.client.host

    # 最終フォールバック
    return "unknown"


# レート制限設定: 10秒に1回
AI_RATE_LIMIT = "1/10seconds"


# Limiterインスタンス作成
limiter = Limiter(
    key_func=get_client_ip,
    default_limits=[],  # デフォルトは制限なし（AI系のみ制限）
)


async def rate_limit_exceeded_handler(
    request: Request, exc: RateLimitExceeded
) -> JSONResponse:
    """
    【機能概要】: レート制限超過時のエラーハンドラー
    【実装方針】: 統一されたエラーレスポンス形式で429エラーを返す

    Args:
        request: FastAPIリクエストオブジェクト
        exc: RateLimitExceeded例外

    Returns:
        JSONResponse: 429エラーレスポンス
    """
    # Retry-After値を計算（制限ウィンドウの残り秒数）
    # slowapiのdetailから取得（形式: "1 per 10 second"）
    retry_after = 10  # デフォルト10秒

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
            "X-RateLimit-Limit": "1",
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
