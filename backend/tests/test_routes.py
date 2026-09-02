"""契約テスト（tests/contract）が固定しない挙動。ログの観測は stdout（最も外側）で行う。"""

from __future__ import annotations

import json
from collections.abc import Iterator
from contextlib import contextmanager

import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from app.ai.prompts import Prompt
from app.ai.providers import Provider
from app.config import ProviderName, RuntimeConfig
from app.errors import ErrorCode, SafeError
from app.main import create_app
from tests.conftest import make_config

CONVERT = "/api/v1/ai/convert"
HEADERS = {"X-API-Key": "test-key-A", "X-Forwarded-For": "1.2.3.4"}
BODY = {"input_text": "水 ぬるく CANARY-INPUT", "politeness_level": "normal"}


class FixedProvider:
    name: ProviderName = "anthropic"

    def __init__(self, outcome: str | BaseException) -> None:
        self._outcome = outcome

    async def complete(self, prompt: Prompt) -> str:
        if isinstance(self._outcome, BaseException):
            raise self._outcome
        return self._outcome

    async def aclose(self) -> None:
        return None


@contextmanager
def client_with(provider: Provider | None, **config_overrides: object) -> Iterator[TestClient]:
    app = create_app(
        make_config(**config_overrides), provider_factory=lambda _cfg: provider, environ={}, argv=[]
    )
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def _events(out: str) -> list[dict[str, object]]:
    return [json.loads(line) for line in out.splitlines() if line.startswith("{")]


def test_no_provider_is_503_and_health_says_none() -> None:
    with client_with(None) as client:
        assert client.get("/api/v1/health").json()["ai_provider"] == "none"
        response = client.post(CONVERT, json=BODY, headers=HEADERS)
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "AI_PROVIDER_ERROR"


def test_success_log_has_latency_and_no_user_content(capsys: pytest.CaptureFixture[str]) -> None:
    with client_with(FixedProvider("お水をください CANARY-OUTPUT")) as client:
        assert client.post(CONVERT, json=BODY, headers=HEADERS).status_code == 200
    out = capsys.readouterr().out
    done = [e for e in _events(out) if e["event"] == "ConversionCompleted"]
    assert len(done) == 1
    assert (
        done[0]["outcome"] == "success"
        and done[0]["provider"] == "anthropic"
        and done[0]["route"] == "convert"
    )
    assert isinstance(done[0]["latency_ms"], int)
    assert "CANARY-INPUT" not in out and "CANARY-OUTPUT" not in out


def test_error_log_has_code_and_cause_type_only(capsys: pytest.CaptureFixture[str]) -> None:
    with client_with(
        FixedProvider(SafeError(ErrorCode.AI_API_TIMEOUT, cause=TimeoutError))
    ) as client:
        assert client.post(CONVERT, json=BODY, headers=HEADERS).status_code == 504
    done = [e for e in _events(capsys.readouterr().out) if e["event"] == "ConversionCompleted"]
    assert done[0]["outcome"] == "error" and done[0]["error_code"] == "AI_API_TIMEOUT"
    assert done[0]["cause_type"] == "TimeoutError"


def test_unexpected_exception_is_500_internal_error_without_message() -> None:
    with client_with(FixedProvider(RuntimeError("CANARY-unexpected"))) as client:
        response = client.post(CONVERT, json=BODY, headers=HEADERS)
    assert response.status_code == 500
    assert response.json()["error"]["code"] == "INTERNAL_ERROR"
    assert "CANARY" not in response.text


def test_openai_provider_round_trip_through_http_boundary() -> None:
    config = make_config(DEFAULT_AI_PROVIDER="openai", OPENAI_API_KEY="sk-o")
    body = {
        "id": "c1",
        "object": "chat.completion",
        "created": 1,
        "model": "m",
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": "お水をください"},
                "finish_reason": "stop",
            }
        ],
    }
    with respx.mock(assert_all_mocked=True) as http:
        http.post("https://api.openai.com/v1/chat/completions").mock(
            return_value=httpx.Response(200, json=body)
        )
        with TestClient(create_app(config, environ={}, argv=[])) as client:
            assert client.get("/api/v1/health").json()["ai_provider"] == "openai"
            assert (
                client.post(CONVERT, json=BODY, headers=HEADERS).json()["converted_text"]
                == "お水をください"
            )


def test_docs_hidden_outside_local_environments() -> None:
    with client_with(FixedProvider("x"), ENVIRONMENT="production") as client:
        assert client.get("/docs").status_code == 404
        assert client.get("/openapi.json").status_code == 404


def test_auth_skipped_only_when_local(capsys: pytest.CaptureFixture[str]) -> None:
    with client_with(FixedProvider("x"), API_KEYS="") as client:
        assert (
            client.post(CONVERT, json=BODY, headers={"X-Forwarded-For": "2.2.2.2"}).status_code
            == 200
        )
    assert any(e["event"] == "AuthenticationSkipped" for e in _events(capsys.readouterr().out))
    with pytest.raises(SafeError):
        create_app(
            make_config(ENVIRONMENT="staging", API_KEYS=""),
            provider_factory=lambda _c: None,
            environ={},
            argv=[],
        )


@pytest.mark.parametrize(
    ("environ", "argv", "expected"),
    [
        ({}, [], 1),
        ({"WEB_CONCURRENCY": "2"}, [], 2),
        ({}, ["uvicorn", "app.main:create_app", "--workers", "3"], 3),
        ({}, ["uvicorn", "--workers=4"], 4),
        ({}, ["uvicorn", "-w", "2"], 2),
        ({"WEB_CONCURRENCY": "x"}, ["--workers", "y"], 1),
        ({"WEB_CONCURRENCY": "+2"}, [], 2),
        ({"WEB_CONCURRENCY": " 2 "}, [], 2),
        ({}, ["uvicorn", "--workers=+2"], 2),
        ({}, ["uvicorn", "--workers", " 3"], 3),
        ({"WEB_CONCURRENCY": "0"}, [], 1),
        ({"WEB_CONCURRENCY": "-1"}, [], 1),
    ],
)
def test_configured_worker_count(environ: dict[str, str], argv: list[str], expected: int) -> None:
    from app.main import configured_worker_count

    assert configured_worker_count(environ, argv) == expected


def test_multiple_workers_refuse_to_start() -> None:
    with pytest.raises(SafeError) as info:
        create_app(make_config(), environ={"WEB_CONCURRENCY": "2"}, argv=[])
    assert info.value.code is ErrorCode.STARTUP_MULTIPLE_WORKERS


def test_import_side_effect_free() -> None:
    import app.main as main_module

    assert not hasattr(main_module, "app")
    assert isinstance(RuntimeConfig, type)
