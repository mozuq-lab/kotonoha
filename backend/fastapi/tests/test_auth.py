from __future__ import annotations

import hmac

import pytest

from app.auth import is_valid_api_key, require_api_key
from app.errors import ErrorCode, SafeError


def test_ascii_match_and_mismatch() -> None:
    allowed = (b"k%40@#=/+!?", b"second")
    assert is_valid_api_key("k%40@#=/+!?", allowed) is True
    assert is_valid_api_key("second", allowed) is True
    assert is_valid_api_key("third", allowed) is False
    assert is_valid_api_key("", allowed) is False and is_valid_api_key(None, allowed) is False


def test_non_ascii_candidate_is_false_not_error() -> None:
    assert is_valid_api_key("ｋｅｙ", (b"key",)) is False


def test_all_keys_are_compared_without_short_circuit(monkeypatch: pytest.MonkeyPatch) -> None:
    """一致しても走査を続ける（一致位置による時間差を作らない）。hmac.compare_digest（stdlib 境界）の呼び出し回数で見る。"""
    calls: list[bytes] = []
    real = hmac.compare_digest

    def counting(a: bytes, b: bytes) -> bool:
        calls.append(b)
        return real(a, b)

    monkeypatch.setattr(hmac, "compare_digest", counting)
    assert is_valid_api_key("first", (b"first", b"second", b"third")) is True
    assert calls == [b"first", b"second", b"third"]


@pytest.mark.parametrize("candidate", [None, "", "x", "ｋ"])
def test_require_api_key_rejects_missing_and_wrong_key(candidate: str | None) -> None:
    with pytest.raises(SafeError) as info:
        require_api_key(candidate, (b"k",))
    assert info.value.code is ErrorCode.AUTHENTICATION_ERROR


def test_require_api_key_accepts_a_configured_key() -> None:
    require_api_key("k", (b"k",))


def test_require_api_key_with_no_keys_lets_requests_through() -> None:
    require_api_key(None, ())
