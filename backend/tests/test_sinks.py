"""ADR-003 の完了条件: 例外境界ごとに canary を注入し、stdout / stderr / HTTP ボディに現れないことを観測する。

境界: (1) プロバイダ SDK の HTTP 応答、(2) 入力検証、(3) 想定外例外、(4) 設定の失敗。
観測面 × 発火経路の表を、テストで1セルずつ埋める（verification-principles）。
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from app.ai.prompts import Prompt
from app.config import ProviderName
from app.errors import VALIDATION_MESSAGE, ErrorCode, SafeError
from app.main import create_app
from tests.conftest import make_config
from tests.test_startup import _base_env, _free_port, _spawn, _stop, _wait_for

BACKEND = Path(__file__).resolve().parents[1]
CONVERT = "/api/v1/ai/convert"
HEADERS = {"X-API-Key": "test-key-A", "X-Forwarded-For": "3.3.3.3"}
CANARY = "CANARY-7f3a9c"


def _assert_absent(canary: str, *surfaces: str) -> None:
    for surface in surfaces:
        assert canary not in surface


@pytest.mark.parametrize(
    "response",
    [
        httpx.Response(
            500, json={"type": "error", "error": {"type": "api_error", "message": CANARY}}
        ),
        httpx.Response(
            429, json={"type": "error", "error": {"type": "rate_limit_error", "message": CANARY}}
        ),
        httpx.Response(
            400,
            json={"type": "error", "error": {"type": "invalid_request_error", "message": CANARY}},
        ),
        httpx.Response(200, content=f"<html>{CANARY}</html>".encode()),
    ],
)
def test_provider_boundary(capsys: pytest.CaptureFixture[str], response: httpx.Response) -> None:
    with respx.mock(assert_all_mocked=True) as http:
        http.post("https://api.anthropic.com/v1/messages").mock(return_value=response)
        with TestClient(
            create_app(make_config(), environ={}, argv=[]), raise_server_exceptions=False
        ) as client:
            reply = client.post(
                CONVERT,
                json={"input_text": "水 ぬるく", "politeness_level": "normal"},
                headers=HEADERS,
            )
    out, err = capsys.readouterr()
    assert reply.status_code in {429, 500}
    _assert_absent(CANARY, reply.text, out, err)
    assert '"outcome": "error"' in out  # 観測面に何かが流れたことを確かめる（空振り防止）


def test_validation_boundary(capsys: pytest.CaptureFixture[str]) -> None:
    with TestClient(
        create_app(make_config(), provider_factory=lambda _c: None, environ={}, argv=[])
    ) as client:
        reply = client.post(
            CONVERT, json={"input_text": CANARY * 60, "politeness_level": CANARY}, headers=HEADERS
        )
    out, err = capsys.readouterr()
    assert reply.status_code == 422
    _assert_absent(CANARY, reply.text, out, err)
    detail = reply.json()["detail"]
    assert detail  # 空振り防止
    allowed_messages = set(VALIDATION_MESSAGE.values())
    assert all(err["msg"] in allowed_messages for err in detail)


class ExplodingProvider:
    name: ProviderName = "anthropic"

    async def complete(self, prompt: Prompt) -> str:
        raise KeyError(CANARY)

    async def aclose(self) -> None:
        return None


def test_unexpected_exception_boundary(capsys: pytest.CaptureFixture[str]) -> None:
    app = create_app(
        make_config(), provider_factory=lambda _c: ExplodingProvider(), environ={}, argv=[]
    )
    with TestClient(app, raise_server_exceptions=False) as client:
        reply = client.post(
            CONVERT, json={"input_text": "水 ぬるく", "politeness_level": "normal"}, headers=HEADERS
        )
    out, err = capsys.readouterr()
    assert reply.status_code == 500 and reply.json()["error"]["code"] == "INTERNAL_ERROR"
    _assert_absent(CANARY, reply.text, out, err)
    assert '"cause_type": "KeyError"' in out


def test_config_boundary_in_a_real_process(tmp_path: Path) -> None:
    """設定失敗はプロセスの stdout / stderr 全体で観測する（8周で唯一破られなかった検証法）。"""
    (tmp_path / ".env").write_text(
        f"ANTHROPIC_API_KEY=sk-{CANARY}-é\nRATE_LIMIT_TIMES={CANARY}\n", encoding="utf-8"
    )
    proc = subprocess.run(  # noqa: S603 -- 固定引数のみ。外部入力は無い
        [sys.executable, "-c", "from app.main import create_app; create_app()"],
        cwd=tmp_path,
        env={"PATH": "", "PYTHONPATH": str(BACKEND), "ENVIRONMENT": "production", "API_KEYS": "k"},
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert proc.returncode != 0
    _assert_absent(CANARY, proc.stdout, proc.stderr)
    assert (
        "CONFIG_INVALID" in proc.stderr
        and "ANTHROPIC_API_KEY" in proc.stderr
        and "RATE_LIMIT_TIMES" in proc.stderr
    )


def test_provider_init_boundary_in_a_real_process() -> None:
    """provider 生成（SDK の httpx.AsyncClient 構築）失敗が lifespan の境界で SafeError に
    変換され、第三者ライブラリの自由文・設定値が stdout/stderr に出ないことをプロセス全体で見る。
    """
    port = _free_port()
    env = _base_env(
        ENVIRONMENT="development",
        API_KEYS="k",
        ANTHROPIC_API_KEY="sk-x",
        HTTPS_PROXY=f"foo://{CANARY}-PROXY-USER:{CANARY}-PROXY-PASS@proxy.invalid",
    )
    proc = _spawn(port, env)
    try:
        assert not _wait_for(port, seconds=6)
    finally:
        out, err = _stop(proc)
    assert proc.returncode is not None and proc.returncode != 0
    assert "STARTUP_PROVIDER_INIT_FAILED" in err
    _assert_absent(CANARY, out, err)


def test_provider_init_boundary_raises_safe_error_in_process(
    capsys: pytest.CaptureFixture[str],
) -> None:
    def _exploding_factory(_config: object) -> None:
        raise RuntimeError(f"{CANARY}-provider-init")

    app = create_app(make_config(), provider_factory=_exploding_factory, environ={}, argv=[])
    with pytest.raises(SafeError) as info:
        with TestClient(app):
            pass
    assert info.value.code is ErrorCode.STARTUP_PROVIDER_INIT_FAILED
    assert info.value.__context__ is None
    out, err = capsys.readouterr()
    _assert_absent(CANARY, out, err)
