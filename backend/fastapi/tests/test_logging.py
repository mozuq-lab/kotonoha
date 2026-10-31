"""stdout への JSON Lines。利用者由来の内容を載せる口が無いこと。"""

from __future__ import annotations

import json

import pytest

from app.logging import ConversionCompleted, RemovedSettingIgnored, configure_logging, log_event


def _lines(captured: str) -> list[dict[str, object]]:
    return [json.loads(line) for line in captured.splitlines() if line.strip()]


def test_event_is_one_json_line_on_stdout(capsys: pytest.CaptureFixture[str]) -> None:
    configure_logging("INFO")
    log_event(
        ConversionCompleted(route="convert", provider="anthropic", outcome="success", latency_ms=42)
    )
    out, err = capsys.readouterr()
    assert err == ""
    records = _lines(out)
    assert len(records) == 1
    record = records[0]
    assert record["event"] == "ConversionCompleted"
    assert record["level"] == "INFO"
    assert (
        record["latency_ms"] == 42
        and record["provider"] == "anthropic"
        and record["outcome"] == "success"
    )
    assert "ts" in record


def test_level_filter(capsys: pytest.CaptureFixture[str]) -> None:
    configure_logging("WARNING")
    log_event(
        ConversionCompleted(route="convert", provider="none", outcome="success", latency_ms=1)
    )
    log_event(RemovedSettingIgnored(key="POSTGRES_PASSWORD"), level="WARNING")
    records = _lines(capsys.readouterr().out)
    assert [r["event"] for r in records] == ["RemovedSettingIgnored"]
    assert records[0]["key"] == "POSTGRES_PASSWORD"


def test_events_carry_no_user_content_fields() -> None:
    forbidden = {"input", "input_text", "text", "converted", "hash", "length", "session"}
    for event in (ConversionCompleted, RemovedSettingIgnored):
        names = set(event.__dataclass_fields__)
        assert not any(any(word in name for word in forbidden) for name in names), names


def test_log_event_rejects_free_strings() -> None:
    with pytest.raises((TypeError, AttributeError)):
        log_event("CANARY free text")  # type: ignore[arg-type]
