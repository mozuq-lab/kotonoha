"""app.openapi() を (パス, メソッド) を identity に正規化する。権威（FastAPI）の出力を消費するだけで、独自パーサは持たない。

使い方: python -m tests.contract.dump_openapi > tests/contract/openapi_baseline.json
"""

from __future__ import annotations

import json
import sys
from typing import Any

Normalized = dict[str, dict[str, Any]]


def _resolve(spec: dict[str, Any], schema: dict[str, Any] | None) -> dict[str, Any] | None:
    if schema is None:
        return None
    ref = schema.get("$ref")
    if isinstance(ref, str) and ref.startswith("#/components/schemas/"):
        schema = spec["components"]["schemas"][ref.rsplit("/", 1)[1]]
    return {
        "required": sorted(schema.get("required", [])),
        "properties": sorted(schema.get("properties", {})),
    }


def _body_schema(spec: dict[str, Any], holder: dict[str, Any] | None) -> dict[str, Any] | None:
    if not holder:
        return None
    content = holder.get("content", {})
    media = content.get("application/json")
    return _resolve(spec, media.get("schema") if media else None)


def normalize_openapi(spec: dict[str, Any]) -> Normalized:
    out: Normalized = {}
    for path, methods in spec["paths"].items():
        for method, operation in methods.items():
            responses = operation.get("responses", {})
            out[f"{method.upper()} {path}"] = {
                "responses": sorted(responses),
                "security": sorted(sorted(s) for s in operation.get("security", [])),
                "request": _body_schema(spec, operation.get("requestBody")),
                "response_200": _body_schema(spec, responses.get("200")),
            }
    return out


if __name__ == "__main__":
    import os

    from tests.contract.conftest import CONTRACT_ENV, build_app

    os.environ.update(CONTRACT_ENV)
    json.dump(
        normalize_openapi(build_app().openapi()),
        sys.stdout,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    )
    sys.stdout.write("\n")
