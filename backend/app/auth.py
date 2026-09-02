"""端末 API キー認証（Issue #86 A / B-3-3 / B-3-4）。"""

from __future__ import annotations

import hmac
from collections.abc import Awaitable, Callable, Sequence

from fastapi import Security
from fastapi.security import APIKeyHeader

from app.errors import ErrorCode, SafeError

API_KEY_HEADER_NAME = "X-API-Key"

# OpenAPI の securitySchemes に載せる宣言。資源は作らない
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)

ApiKeyDependency = Callable[..., Awaitable[None]]


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


def build_require_api_key(allowed: tuple[bytes, ...]) -> ApiKeyDependency:
    """空タプルなら認証を省略する。省略してよいかの判定（config.auth_optional）は main が行う。"""

    async def require_api_key(api_key: str | None = Security(api_key_header)) -> None:
        if not allowed:
            return
        if not is_valid_api_key(api_key, allowed):
            raise SafeError(ErrorCode.AUTHENTICATION_ERROR)

    return require_api_key
