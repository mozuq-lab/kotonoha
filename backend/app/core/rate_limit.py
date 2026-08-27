"""
レート制限ミドルウェア

【ファイル目的】: AI変換APIへのリクエスト数を制限
【ファイル内容】: slowapiを使用したレート制限設定、エラーハンドラー

TASK-0025: レート制限ミドルウェア実装
🔵 NFR-101: レート制限（1リクエスト/10秒/IP）
🔵 NFR-002: AI変換の応答時間を平均3秒以内（レート制限チェックは10ms以内）
"""

import logging
from urllib.parse import urlsplit

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
        また、チェーンが設定段数に満たない場合（＝信頼プロキシを経由していない、
        あるいはヘッダーを偽装された場合）は X-Forwarded-For を採用せず接続元IPを使う。

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
        # チェーンが信頼プロキシ段数以上ある場合のみ、右からproxy_count番目を採用する。
        # チェーンが想定より短い場合は「信頼プロキシが付与した値」が存在しないため、
        # 最左（＝クライアントが自由に設定できる値）へフォールバックしてはならない。
        # その場合は X-Forwarded-For を無視して接続元IPを使う（フェイルクローズ）。
        if len(parts) >= proxy_count:
            return parts[-proxy_count]

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


def redact_storage_uri(storage_uri: str | None) -> str:
    """ストレージURIから資格情報を取り除いた、ログに出して安全な表現を返す。

    【この関数がある理由】: ENVIRONMENT=production では RATE_LIMIT_STORAGE_URI が
    必須であり、共有ストレージの実体は通常 `rediss://:password@host:6379` のように
    **パスワードを含むURI**になる。初期化失敗時のメッセージへ生のURIを埋めると、
    起動失敗のたびにパスワードが stderr とコンテナログへ出力される。

    【フェイルクローズで書く】: 本関数は `_build_limiter` の except 節から呼ばれる。
    つまり「URIが想定どおりに解釈できなかった」状況こそが本番の呼び出し文脈である。
    したがって、構造を確信できたときだけ読める形で返し、少しでも解釈に失敗したら
    スキーム以外は伏せる。また、ここで例外を投げると診断用の
    `RateLimitStorageError` に到達できなくなるため、本関数は例外を投げない。

    Args:
        storage_uri: resolve_storage_uri() が返したURI（Noneはインメモリ）。

    Returns:
        str: ログ出力に使える文字列。解釈できない部分は伏せる。
    """
    if storage_uri is None:
        return "None（未設定＝プロセス内メモリ）"

    try:
        parts = urlsplit(storage_uri)
    except ValueError:
        # 解析できない値は形すら推測できないため、全体を伏せる。
        return "<解析できないURI（内容は秘匿）>"

    scheme = parts.scheme
    if not scheme:
        # スキームが無いものはURIとして扱えない。誤設定の中身は出さない。
        return "<スキーム無しのURI（内容は秘匿）>"

    if not parts.netloc:
        # 【`//` を欠いた形】: urlsplit は `redis:pw@host:6379` のような入力の
        # userinfo を netloc ではなく path に入れる。ホストと資格情報を安全に
        # 切り分ける手段が無いため、スキーム以外は伏せる
        # （必須設定のタイポとして現実的に起こりうる形である）。
        if parts.path or parts.query:
            return f"{scheme}:<以降は秘匿（資格情報を含む可能性）>"
        return f"{scheme}://"

    try:
        hostname = parts.hostname or ""
        port = parts.port
    except ValueError:
        # ポート部が数値でない等。ホスト側を安全に取り出せないので伏せる。
        # （例外を投げると呼び出し元の except 節を壊すため、必ず値を返す）
        return f"{scheme}://<ホスト部を解析できないため秘匿>"

    host = f"{hostname}:{port}" if port is not None else hostname

    # userinfo（user:password）が付いていた場合のみ、その存在を示して中身は伏せる。
    netloc = f"***@{host}" if "@" in parts.netloc else host

    redacted = f"{scheme}://{netloc}{parts.path}"
    if parts.query:
        # クエリにも password= 等が載りうるため、キーごと出さない。
        redacted += "?<クエリは秘匿>"
    return redacted


def _credential_fragments(storage_uri: str | None) -> list[str]:
    """URIに含まれる資格情報の断片（userinfo とその構成要素）を返す。

    ライブラリがURIを丸ごとではなく一部だけメッセージに埋める場合に備えるため、
    全体一致だけでなく断片でも検出できるようにする。

    Args:
        storage_uri: 対象URI。

    Returns:
        list[str]: 資格情報とみなす文字列。無ければ空リスト。
    """
    if not storage_uri:
        return []
    try:
        parts = urlsplit(storage_uri)
    except ValueError:
        return []

    # `//` 有りなら netloc、無ければ path 側に userinfo が入る
    source = parts.netloc or parts.path
    if "@" not in source:
        return []

    userinfo = source.rsplit("@", 1)[0]
    fragments = {userinfo, *userinfo.split(":")}
    return [f for f in fragments if f]


def _scrub_credentials(text: str, storage_uri: str | None) -> str:
    """テキストから storage_uri 由来の資格情報を取り除く。"""
    if not storage_uri:
        return text
    scrubbed = text.replace(storage_uri, redact_storage_uri(storage_uri))
    for fragment in _credential_fragments(storage_uri):
        scrubbed = scrubbed.replace(fragment, "***")
    return scrubbed


def _describe_cause(exc: BaseException, storage_uri: str | None) -> str:
    """原因例外を、資格情報を含まない形で1行に要約する。

    残らず伏せてしまうと運用者が原因を特定できないため、例外型と
    スクラブ済みメッセージは残す。スクラブ後にも資格情報が残っていた場合は
    （想定外の埋め込み方をされたということなので）メッセージ全体を伏せる。

    Args:
        exc: 原因となった例外。
        storage_uri: 資格情報を含みうるURI。

    Returns:
        str: ログ・例外メッセージに埋め込んで安全な要約。
    """
    label = type(exc).__name__
    detail = _scrub_credentials(str(exc), storage_uri)
    fragments = _credential_fragments(storage_uri)
    if any(fragment in detail for fragment in fragments):
        return f"{label}: <原因メッセージに資格情報が含まれるため秘匿>"
    return f"{label}: {detail}"


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
        # 【原因例外を連鎖させない理由】: limits は
        # `unknown storage scheme : <URI全文>` のように**生のURIをメッセージへ
        # 埋め込む**。`raise ... from exc` と `logger.error(..., exc_info=exc)` は
        # その原因例外を運ぶため、メッセージ側だけを秘匿しても
        # __cause__ / 連鎖トレースバック / ログの3経路から資格情報が出てしまう。
        # 本番の RATE_LIMIT_STORAGE_URI は通常パスワードを含むので、
        # 連鎖を断ち、原因はスクラブ済みの1行要約として本文に埋める。
        message = (
            "レート制限ストレージの初期化に失敗しました "
            f"(RATE_LIMIT_STORAGE_URI={redact_storage_uri(storage_uri)})。"
            "RATE_LIMIT_STORAGE_URIのスキームが未対応であるか、"
            "そのスキームが要求する依存パッケージ（例: redis://系スキームには"
            "'redis'パッケージ）がインストールされていない可能性があります。"
            "requirements.txtの内容とインストール状況を確認してください。"
            f" 原因: {_describe_cause(exc, storage_uri)}"
        )
        # exc_info を渡さない（渡すと原因例外のメッセージがログに出る）
        logger.error(message)
        # from None で連鎖を断つ（診断情報は上の「原因:」に含めている）
        raise RateLimitStorageError(message) from None


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
