"""正規化した OpenAPI が、明示した廃止・変更以外は基準と一致すること。identity は (パス, メソッド)。"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import FastAPI

from tests.contract.dump_openapi import Normalized, normalize_openapi

BASELINE = Path(__file__).with_name("openapi_baseline.json")

# 廃止・変更した契約。旧実装との比較では元の基準を使う。
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
