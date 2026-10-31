from __future__ import annotations

from fastapi.testclient import TestClient

HEALTH = "/api/v1/health"


def test_allowed_origin_is_echoed(client: TestClient) -> None:
    response = client.get(HEALTH, headers={"Origin": "http://localhost:3000"})
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:3000"
    assert response.headers["access-control-allow-credentials"] == "true"


def test_preflight_is_answered(client: TestClient) -> None:
    response = client.options(
        "/api/v1/ai/convert",
        headers={
            "Origin": "http://localhost:5173",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type,x-api-key",
        },
    )
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:5173"
    assert "POST" in response.headers["access-control-allow-methods"]
    assert "x-api-key" in response.headers["access-control-allow-headers"].lower()


def test_unknown_origin_gets_no_cors_header(client: TestClient) -> None:
    response = client.get(HEALTH, headers={"Origin": "http://malicious.example"})
    assert "access-control-allow-origin" not in response.headers
