"""旧・新の両実装に同じ契約テストを当てるための土台。

どちらを試験しているかを知るのは build_app() だけ。旧実装は import 時に設定を読むため、
環境変数は import より前に（session fixture で）置く。
"""

from __future__ import annotations

import itertools
from collections.abc import Iterator

import httpx
import pytest
import respx
from fastapi import FastAPI
from fastapi.testclient import TestClient

CONTRACT_ENV: dict[str, str] = {
    "ENVIRONMENT": "test",
    "API_KEYS": "contract-key-A,contract-key-B",
    "ANTHROPIC_API_KEY": "sk-contract-anthropic",
    "OPENAI_API_KEY": "",
    "DEFAULT_AI_PROVIDER": "anthropic",
    "CORS_ORIGINS": "http://localhost:3000,http://localhost:5173",
    "RATE_LIMIT_TIMES": "1",
    "RATE_LIMIT_SECONDS": "1",
    "TRUSTED_PROXY_COUNT": "1",  # テストごとに X-Forwarded-For で送信元を分け、カウンタを独立させる
    "AI_MAX_RETRIES": "0",
    "AI_API_TIMEOUT": "10",
    "AI_CALL_DEADLINE_SECONDS": "4",
    "LOG_LEVEL": "WARNING",
}

ANTHROPIC_MESSAGES_URL = "https://api.anthropic.com/v1/messages"

ANTHROPIC_OK: dict[str, object] = {
    "id": "msg_contract",
    "type": "message",
    "role": "assistant",
    "model": "claude-contract",
    "content": [{"type": "text", "text": "お水をぬるめでお願いします"}],
    "stop_reason": "end_turn",
    "stop_sequence": None,
    "usage": {"input_tokens": 1, "output_tokens": 1},
}

_ip_counter = itertools.count(1)


def fresh_ip() -> str:
    """テストごとに別の送信元 IP。レート制限のカウンタを共有しないため。"""
    n = next(_ip_counter)
    return f"10.{(n >> 16) & 255}.{(n >> 8) & 255}.{n & 255}"


def anthropic_success(text: str) -> httpx.Response:
    body = dict(ANTHROPIC_OK)
    body["content"] = [{"type": "text", "text": text}]
    return httpx.Response(200, json=body)


def build_app() -> FastAPI:
    import app.main as main_module

    factory = getattr(main_module, "create_app", None)
    if factory is not None:
        return factory()  # 新: Application Factory（環境変数から設定を組む）
    return main_module.app  # 旧: モジュールレベルの app


@pytest.fixture(scope="session")
def contract_env() -> Iterator[None]:
    with pytest.MonkeyPatch.context() as mp:
        for key, value in CONTRACT_ENV.items():
            mp.setenv(key, value)
        yield


@pytest.fixture(scope="session")
def app(contract_env: None) -> FastAPI:
    return build_app()


@pytest.fixture(scope="session")
def client(app: FastAPI) -> Iterator[TestClient]:
    # セッションスコープ: 旧実装は AI クライアントの httpx.AsyncClient と DB の
    # AsyncEngine をどちらもモジュールインポート時に単一生成し、その内部の
    # 接続プール・ロックは最初に使われたイベントループへ暗黙に紐付く
    # （ADR-004 が新実装で禁じている「import 時に資源を作る」形そのもの）。
    # client をテストごとに function scope で作ると、TestClient の with ブロックが
    # テストのたびに新しいイベントループを起動し、2件目以降のリクエストで
    # 「different loop」「Event loop is closed」を起こして 500 に化ける
    # （外部契約とは無関係な、テストハーネス側のイベントループ不整合）。
    # 実運用の uvicorn は単一プロセス・単一イベントループでアプリを動かし続けるため、
    # ここでもセッション全体で1つの TestClient（=1つのイベントループ）を共有し、
    # 実運用の起動状態に合わせる。
    with TestClient(app, raise_server_exceptions=False) as test_client:
        yield test_client


@pytest.fixture
def provider_http() -> Iterator[respx.MockRouter]:
    """AI プロバイダの HTTP 境界。ここより内側（SDK・自分の関数）はモックしない。"""
    with respx.mock(assert_all_called=False, assert_all_mocked=True) as router:
        router.post(ANTHROPIC_MESSAGES_URL).mock(
            return_value=anthropic_success("お水をぬるめでお願いします")
        )
        yield router


@pytest.fixture
def headers() -> dict[str, str]:
    return {"X-API-Key": "contract-key-A", "X-Forwarded-For": fresh_ip()}
