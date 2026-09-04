"""ADR-004。B-3-2（記号入りキー）・B-3-6（全違反を一度に）・B-3-7（削除済みキー）・環境ガード両分岐。"""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.config import REMOVED_SETTINGS, RuntimeConfig, load_config
from app.errors import ConfigError
from tests.conftest import make_config

SYMBOL_KEY = "k%40@#=/+!?"


@pytest.fixture(autouse=True)
def clean_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in list(RuntimeConfig.model_fields) + sorted(REMOVED_SETTINGS):
        monkeypatch.delenv(name, raising=False)


def test_config_is_frozen() -> None:
    config = make_config()
    with pytest.raises(ValidationError):
        config.RATE_LIMIT_TIMES = 5  # type: ignore[misc]


def test_secrets_are_hidden_in_repr() -> None:
    config = make_config(API_KEYS=SYMBOL_KEY, ANTHROPIC_API_KEY="sk-CANARY")
    assert SYMBOL_KEY not in repr(config) and "sk-CANARY" not in repr(config)
    assert config.api_keys() == (SYMBOL_KEY.encode("ascii"),)


def test_api_keys_are_split_and_stripped() -> None:
    assert make_config(API_KEYS=" a , ,b,").api_keys() == (b"a", b"b")


def test_empty_provider_key_means_none() -> None:
    config = make_config(ANTHROPIC_API_KEY="", OPENAI_API_KEY="")
    assert (
        config.provider_api_key("anthropic") is None and config.provider_api_key("openai") is None
    )


@pytest.mark.parametrize("field", ["API_KEYS", "ANTHROPIC_API_KEY", "OPENAI_API_KEY"])
def test_non_ascii_key_is_rejected_at_load_without_echoing_value(
    monkeypatch: pytest.MonkeyPatch, field: str
) -> None:
    monkeypatch.setenv(field, "kéy-CANARY")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert (field, "value_error") in info.value.problems
    assert "CANARY" not in str(info.value) and info.value.__context__ is None


def test_validation_error_never_escapes(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("RATE_LIMIT_TIMES", "CANARY-not-int")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert info.value.problems == (("RATE_LIMIT_TIMES", "int_parsing"),)
    assert "CANARY" not in str(info.value)


@pytest.mark.parametrize("environment", ["development", "test"])
def test_local_environments_relax_auth_and_publish_docs(environment: str) -> None:
    config = make_config(ENVIRONMENT=environment, API_KEYS="")
    assert config.is_local and config.auth_optional and config.docs_enabled
    assert config.startup_problems() == ()


@pytest.mark.parametrize("environment", ["staging", "production"])
def test_non_local_environments_report_all_problems_at_once(environment: str) -> None:
    config = make_config(ENVIRONMENT=environment, API_KEYS="", ANTHROPIC_API_KEY="")
    assert not config.is_local and not config.auth_optional and not config.docs_enabled
    assert set(config.startup_problems()) == {
        ("API_KEYS", "missing"),
        ("ANTHROPIC_API_KEY", "missing"),
    }


def test_non_local_load_fails_with_every_problem(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("DEFAULT_AI_PROVIDER", "openai")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert set(info.value.problems) == {("API_KEYS", "missing"), ("OPENAI_API_KEY", "missing")}


def test_production_with_symbol_keys_loads(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("API_KEYS", SYMBOL_KEY)
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-" + SYMBOL_KEY)
    config = load_config(env_file=None)
    assert config.api_keys() == (SYMBOL_KEY.encode("ascii"),)


def test_unknown_environment_is_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENVIRONMENT", "prod")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert info.value.problems[0][0] == "ENVIRONMENT"


def test_removed_keys_in_dotenv_warn_but_do_not_fail(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    env_file = tmp_path / ".env"
    env_file.write_text(
        "POSTGRES_PASSWORD=p%40ss-CANARY\nRATE_LIMIT_STORAGE_URI=redis://x\nRATE_LIMIT_TIMES=3\n",
        encoding="utf-8",
    )
    from app.logging import configure_logging

    configure_logging("WARNING")
    config = load_config(env_file=env_file)
    assert config.RATE_LIMIT_TIMES == 3
    out = capsys.readouterr().out
    events = [json.loads(line) for line in out.splitlines() if line.strip()]
    assert {e["key"] for e in events if e["event"] == "RemovedSettingIgnored"} == {
        "POSTGRES_PASSWORD",
        "RATE_LIMIT_STORAGE_URI",
    }
    assert "CANARY" not in out


def test_removed_keys_in_environment_warn(
    monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    from app.logging import configure_logging

    configure_logging("WARNING")
    monkeypatch.setenv("SECRET_KEY", "CANARY")
    load_config(env_file=None)
    out = capsys.readouterr().out
    assert '"key": "SECRET_KEY"' in out and "CANARY" not in out


def test_cors_origins_are_split() -> None:
    assert make_config(CORS_ORIGINS=" http://a , http://b ").cors_origins() == (
        "http://a",
        "http://b",
    )
