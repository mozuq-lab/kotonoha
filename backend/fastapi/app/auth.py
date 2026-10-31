"""端末 API キー認証。"""

from __future__ import annotations

import hmac
from collections.abc import Sequence

from fastapi.security import APIKeyHeader

from app.errors import ErrorCode, SafeError

API_KEY_HEADER_NAME = "X-API-Key"

# OpenAPI の securitySchemes に載せる宣言だけ。確かめは require_api_key が行う。資源は作らない
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)


def is_valid_api_key(candidate: str | None, allowed: Sequence[bytes]) -> bool:
    """許可キーのいずれかと一致するか。

    全キーを走査し短絡しない。非 ASCII は不一致（例外にしない）。
    """
    if not candidate:
        return False
    try:
        candidate_bytes = candidate.encode("ascii")
    except UnicodeEncodeError:
        return False
    matched = False
    for key in allowed:
        if hmac.compare_digest(candidate_bytes, key):
            matched = True
    return matched


def require_api_key(candidate: str | None, allowed: tuple[bytes, ...]) -> None:
    """一致しなければ ``AUTHENTICATION_ERROR``。

    空タプルなら認証を省略する。省略してよいかの判定（config.auth_optional）は main が行う。
    呼ぶのは本文を読む前（routes の ``GuardedRoute``）。FastAPI の依存は本文の解析より後に
    解決されるので、依存にはしない。
    """
    if allowed and not is_valid_api_key(candidate, allowed):
        raise SafeError(ErrorCode.AUTHENTICATION_ERROR)
