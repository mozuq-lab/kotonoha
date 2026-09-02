"""stdout への構造化ログ（ADR-001 / ADR-003）。

stdlib ``logging`` を import してよいのはこのモジュールだけ。受け口は型付きイベントで、
自由文字列を受け取る関数は無い。利用者由来の内容（入力・変換結果・長さ・ハッシュ）は
どのイベントにも載らない。``exc_info`` は決して渡さない。
"""

from __future__ import annotations

import json
import logging
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Literal

LOGGER_NAME = "kotonoha"
LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]


@dataclass(frozen=True, slots=True)
class ConversionCompleted:
    route: Literal["convert", "regenerate"]
    provider: str
    outcome: Literal["success", "error"]
    latency_ms: int
    error_code: str | None = None
    cause_type: str | None = None


@dataclass(frozen=True, slots=True)
class RequestFailed:
    route: str
    error_code: str
    cause_type: str | None = None


@dataclass(frozen=True, slots=True)
class RemovedSettingIgnored:
    key: str


@dataclass(frozen=True, slots=True)
class AuthenticationSkipped:
    environment: str


@dataclass(frozen=True, slots=True)
class ProviderConfigured:
    provider: str


LogEvent = (
    ConversionCompleted
    | RequestFailed
    | RemovedSettingIgnored
    | AuthenticationSkipped
    | ProviderConfigured
)


class _JsonLineFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "ts": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(
                timespec="milliseconds"
            ),
            "level": record.levelname,
            "event": getattr(record, "event", record.name),
        }
        fields = getattr(record, "fields", None)
        if isinstance(fields, dict):
            payload.update(fields)
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: LogLevel) -> None:
    """stdout に JSON Lines を出す。ファイル出力は持たない（ADR-001）。"""
    logger = logging.getLogger(LOGGER_NAME)
    for handler in list(logger.handlers):
        logger.removeHandler(handler)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(_JsonLineFormatter())
    logger.addHandler(handler)
    logger.setLevel(level)
    logger.propagate = False


def log_event(event: LogEvent, *, level: LogLevel = "INFO") -> None:
    """型付きイベントを1行の JSON として stdout へ書く。"""
    fields = asdict(event)  # dataclass 以外（自由文字列）は TypeError で落ちる
    logging.getLogger(LOGGER_NAME).log(
        logging.getLevelNamesMapping()[level],
        "",
        extra={"event": type(event).__name__, "fields": fields},
    )
