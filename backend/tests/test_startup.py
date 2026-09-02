"""B-3-2（記号入りキーで起動し /health 200 ＋ AI 変換1往復）、ADR-004 の import smoke、ADR-002 の起動ガード。

AI 変換の往復は SDK 標準の ANTHROPIC_BASE_URL で偽プロバイダ（このテスト内の HTTP サーバー）へ向ける（計画 D7）。
"""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import threading
import time
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import httpx
import pytest

BACKEND = Path(__file__).resolve().parents[1]
DEVICE_KEY = "k%40@#=/+!?"
PROVIDER_KEY = "sk-p%40@#=/+!?"
ANTHROPIC_OK = {
    "id": "msg_1",
    "type": "message",
    "role": "assistant",
    "model": "m",
    "content": [{"type": "text", "text": "お水をぬるめでお願いします"}],
    "stop_reason": "end_turn",
    "stop_sequence": None,
    "usage": {"input_tokens": 1, "output_tokens": 1},
}


def _free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


class FakeAnthropic(ThreadingHTTPServer):
    seen_api_keys: list[str]


class _Handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802
        server: FakeAnthropic = self.server  # type: ignore[assignment]
        server.seen_api_keys.append(self.headers.get("x-api-key", ""))
        self.rfile.read(int(self.headers.get("content-length", "0")))
        body = json.dumps(ANTHROPIC_OK).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        return None


@pytest.fixture
def fake_provider() -> Iterator[FakeAnthropic]:
    server = FakeAnthropic(("127.0.0.1", 0), _Handler)
    server.seen_api_keys = []
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield server
    finally:
        server.shutdown()


def _base_env(**extra: str) -> dict[str, str]:
    env = {"PATH": os.environ["PATH"], "PYTHONPATH": str(BACKEND), "PYTHONUNBUFFERED": "1"}
    env.update(extra)
    return env


def _spawn(port: int, env: dict[str, str], *args: str) -> subprocess.Popen[str]:
    return subprocess.Popen(  # noqa: S603 -- 固定引数のみ。外部入力は無い
        [
            sys.executable,
            "-m",
            "uvicorn",
            "app.main:create_app",
            "--factory",
            "--port",
            str(port),
            *args,
        ],
        cwd=BACKEND,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def _wait_for(port: int, seconds: float = 15.0) -> bool:
    deadline = time.time() + seconds
    while time.time() < deadline:
        try:
            httpx.get(f"http://127.0.0.1:{port}/api/v1/health", timeout=0.5)
            return True
        except httpx.HTTPError:
            time.sleep(0.2)
    return False


def _stop(proc: subprocess.Popen[str]) -> tuple[str, str]:
    proc.terminate()
    try:
        return proc.communicate(timeout=10)
    except subprocess.TimeoutExpired:
        proc.kill()
        return proc.communicate()


def test_import_has_no_side_effects(tmp_path: Path) -> None:
    (tmp_path / "sitecustomize.py").write_text(
        "import socket\n"
        "def _blocked(*args, **kwargs):\n    raise RuntimeError('network blocked')\n"
        "socket.socket.connect = _blocked\n"
        "socket.socket.bind = _blocked\n",
        encoding="utf-8",
    )
    proc = subprocess.run(  # noqa: S603 -- 固定引数のみ。外部入力は無い
        [sys.executable, "-c", "import app.main"],
        cwd=tmp_path,  # .env が無い場所
        env={"PATH": "", "PYTHONPATH": f"{tmp_path}{os.pathsep}{BACKEND}"},
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert proc.returncode == 0
    assert proc.stdout == "" and proc.stderr == ""


def test_symbol_keys_health_and_conversion_round_trip(fake_provider: FakeAnthropic) -> None:
    port = _free_port()
    env = _base_env(
        ENVIRONMENT="production",
        API_KEYS=DEVICE_KEY,
        ANTHROPIC_API_KEY=PROVIDER_KEY,
        ANTHROPIC_BASE_URL=f"http://127.0.0.1:{fake_provider.server_address[1]}",
        CORS_ORIGINS="http://localhost:3000",
    )
    proc = _spawn(port, env)
    try:
        assert _wait_for(port)
        base = f"http://127.0.0.1:{port}"
        health = httpx.get(f"{base}/api/v1/health")
        assert health.status_code == 200 and health.json()["ai_provider"] == "anthropic"
        assert httpx.get(f"{base}/docs").status_code == 404  # production では非公開
        reply = httpx.post(
            f"{base}/api/v1/ai/convert",
            json={"input_text": "水 ぬるく", "politeness_level": "normal"},
            headers={"X-API-Key": DEVICE_KEY},
        )
        assert reply.status_code == 200
        assert reply.json()["converted_text"] == "お水をぬるめでお願いします"
        assert fake_provider.seen_api_keys == [PROVIDER_KEY]
    finally:
        out, err = _stop(proc)
    assert '"event": "ConversionCompleted"' in out
    assert PROVIDER_KEY not in out + err and DEVICE_KEY not in out + err


@pytest.mark.parametrize("variant", ["argv", "env", "env_plus_prefixed"])
def test_multiple_workers_refuse_to_serve(variant: str) -> None:
    port = _free_port()
    env = _base_env(ENVIRONMENT="development")
    args: tuple[str, ...] = ()
    if variant == "argv":
        args = ("--workers", "2")
    elif variant == "env_plus_prefixed":
        env["WEB_CONCURRENCY"] = "+2"  # uvicorn の int() は受理するが .isdigit() は偽になる値
    else:
        env["WEB_CONCURRENCY"] = "2"
    proc = _spawn(port, env, *args)
    try:
        assert not _wait_for(port, seconds=6)
    finally:
        out, err = _stop(proc)
    assert "STARTUP_MULTIPLE_WORKERS" in err
    assert "Application startup complete" not in err


def test_single_worker_serves() -> None:
    port = _free_port()
    proc = _spawn(port, _base_env(ENVIRONMENT="development"))
    try:
        assert _wait_for(port)
    finally:
        _stop(proc)
