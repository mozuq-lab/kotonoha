"""ADR-003: SafeError は code と原因の型名しか持たない。"""

from __future__ import annotations

import pytest

from app.errors import (
    HTTP_STATUS,
    USER_MESSAGE,
    ConfigError,
    ErrorCode,
    RateLimitExceeded,
    SafeError,
)


def test_every_code_has_status_and_message() -> None:
    for code in ErrorCode:
        assert code in HTTP_STATUS
        assert code in USER_MESSAGE


def test_safe_error_str_is_the_code_only() -> None:
    err = SafeError(ErrorCode.AI_API_ERROR, cause=ValueError)
    assert str(err) == "AI_API_ERROR"
    assert err.cause_type == "ValueError"
    assert err.retryable is False


def test_safe_error_has_no_message_parameter() -> None:
    with pytest.raises(TypeError):
        SafeError(ErrorCode.AI_API_ERROR, "CANARY-free-text")  # type: ignore[misc]


def test_raising_outside_except_leaves_no_context() -> None:
    cause: type[BaseException] | None = None
    try:
        raise ValueError("CANARY-secret")
    except ValueError as exc:
        cause = type(exc)
    with pytest.raises(SafeError) as info:
        raise SafeError(ErrorCode.INTERNAL_ERROR, cause=cause)
    assert info.value.__context__ is None
    assert "CANARY-secret" not in repr(info.value)


def test_rate_limit_exceeded_carries_numbers() -> None:
    err = RateLimitExceeded(retry_after_seconds=7, limit=1)
    assert err.code is ErrorCode.RATE_LIMIT_EXCEEDED
    assert (err.retry_after_seconds, err.limit) == (7, 1)


def test_config_error_lists_keys_and_kinds_only() -> None:
    err = ConfigError((("API_KEYS", "missing"), ("RATE_LIMIT_TIMES", "int_parsing")))
    text = str(err)
    assert text.startswith("CONFIG_INVALID")
    assert "API_KEYS" in text and "int_parsing" in text
