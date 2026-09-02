"""旧・新の正規化 OpenAPI diff が、廃止リストを除いて空であること（完了条件）。identity は (パス, メソッド)。"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import FastAPI

from tests.contract.dump_openapi import Normalized, normalize_openapi

BASELINE = Path(__file__).with_name("openapi_baseline.json")

# 廃止リスト（計画書「廃止リスト」と1対1）。新実装にだけ適用する。
REMOVED_OPERATIONS: frozenset[str] = frozenset({"GET /", "GET /health"})
CHANGED_OPERATIONS: dict[str, dict[str, Any]] = {
    "GET /api/v1/health": {
        "responses": ["200"],
        "security": [],
        "request": None,
        "response_200": {
            "required": ["ai_provider", "status", "timestamp", "version"],
            "properties": ["ai_provider", "status", "timestamp", "version"],
        },
    },
}


def _is_legacy(app: FastAPI) -> bool:
    import app.main as main_module

    return not hasattr(main_module, "create_app")


def _expected(baseline: Normalized, legacy: bool) -> Normalized:
    if legacy:
        return baseline
    kept = {k: v for k, v in baseline.items() if k not in REMOVED_OPERATIONS}
    kept.update(CHANGED_OPERATIONS)
    return kept


def test_normalized_openapi_matches_baseline(app: FastAPI) -> None:
    baseline: Normalized = json.loads(BASELINE.read_text(encoding="utf-8"))
    current = normalize_openapi(app.openapi())
    expected = _expected(baseline, _is_legacy(app))
    assert current == expected, {
        "missing": sorted(set(expected) - set(current)),
        "unexpected": sorted(set(current) - set(expected)),
        "different": sorted(k for k in expected if k in current and current[k] != expected[k]),
    }
