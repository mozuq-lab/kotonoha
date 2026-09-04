"""GET /api/v1/health と、test 環境での /docs・/openapi.json 公開。"""

from __future__ import annotations

from datetime import datetime

from fastapi.testclient import TestClient

HEALTH = "/api/v1/health"


def test_health_is_ok_without_auth(client: TestClient) -> None:
    response = client.get(HEALTH)
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["ai_provider"] in {"anthropic", "openai", "none"}
    assert body["version"] == "1.0.0"
    assert body["timestamp"].endswith("Z")
    datetime.strptime(body["timestamp"], "%Y-%m-%dT%H:%M:%SZ")


def test_health_is_not_rate_limited(client: TestClient) -> None:
    for _ in range(3):
        assert client.get(HEALTH).status_code == 200


def test_docs_are_published_in_test_environment(client: TestClient) -> None:
    assert client.get("/docs").status_code == 200
    assert "text/html" in client.get("/docs").headers["content-type"]
    spec = client.get("/openapi.json")
    assert spec.status_code == 200
    assert {"openapi", "info", "paths"} <= set(spec.json())
