from __future__ import annotations

import hmac

import pytest
from fastapi import Depends, FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.auth import build_require_api_key, is_valid_api_key
from app.errors import SafeError


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


def _app(allowed: tuple[bytes, ...]) -> TestClient:
    app = FastAPI()

    @app.exception_handler(SafeError)
    async def handler(_: Request, exc: SafeError) -> JSONResponse:
        return JSONResponse(status_code=401, content={"code": exc.code.value})

    @app.get("/p", dependencies=[Depends(build_require_api_key(allowed))])
    async def protected() -> dict[str, bool]:
        return {"ok": True}

    return TestClient(app)


def test_dependency_rejects_missing_and_wrong_key() -> None:
    client = _app((b"k",))
    assert client.get("/p").status_code == 401
    assert client.get("/p", headers={"X-API-Key": "x"}).json() == {"code": "AUTHENTICATION_ERROR"}
    assert client.get("/p", headers={"X-API-Key": "k"}).status_code == 200


def test_dependency_with_no_keys_lets_requests_through() -> None:
    assert _app(()).get("/p").status_code == 200


def test_openapi_declares_api_key_header() -> None:
    spec = _app((b"k",)).app.openapi()
    assert "APIKeyHeader" in spec["components"]["securitySchemes"]
