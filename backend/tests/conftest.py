"""新 backend のテスト土台。設定は必ず明示して組む（環境や .env に依存しない）。"""

from __future__ import annotations

from typing import Any

from app.config import RuntimeConfig


def make_config(**overrides: Any) -> RuntimeConfig:
    """テスト用の RuntimeConfig。.env を読まず、環境変数より overrides を優先する。"""
    values: dict[str, Any] = {
        "ENVIRONMENT": "test",
        "API_KEYS": "test-key-A,test-key-B",
        "ANTHROPIC_API_KEY": "sk-test-anthropic",
        "DEFAULT_AI_PROVIDER": "anthropic",
        "RATE_LIMIT_TIMES": 1,
        "RATE_LIMIT_SECONDS": 1,
        "TRUSTED_PROXY_COUNT": 1,
        "AI_MAX_RETRIES": 0,
        "AI_API_TIMEOUT": 1.0,
        "AI_CALL_DEADLINE_SECONDS": 2.0,
        "LOG_LEVEL": "INFO",
    }
    values.update(overrides)
    return RuntimeConfig(_env_file=None, **values)
