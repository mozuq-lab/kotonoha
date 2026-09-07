"""設定は不変（ADR-004）。環境判定はこのモジュールの1箇所だけ。

秘密は ``SecretStr``。DSN は存在しない（ADR-001）。``RATE_LIMIT_STORAGE_URI`` は
作らない（ADR-002）。pydantic の ``ValidationError`` は失敗した入力値を ``str()`` に含むため、
このモジュールの外へ出さない——キー名と種別だけを ``ConfigError`` に載せ替える。
"""

from __future__ import annotations

import os
from collections.abc import Mapping
from pathlib import Path
from typing import Final, Literal

from dotenv import dotenv_values
from pydantic import Field, SecretStr, ValidationError, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.errors import ConfigError, ConfigProblem
from app.logging import LogLevel, RemovedSettingIgnored, log_event

Environment = Literal["development", "test", "staging", "production"]
ProviderName = Literal["anthropic", "openai"]

API_PREFIX: Final = "/api/v1"

# 廃止した設定キーが残っていても起動を止めず、警告だけ出す。
REMOVED_SETTINGS: Final[frozenset[str]] = frozenset(
    {
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
        "POSTGRES_DB",
        "POSTGRES_HOST",
        "POSTGRES_PORT",
        "DATABASE_URL",
        "TEST_DATABASE_URL",
        "SECRET_KEY",
        "API_HOST",
        "API_PORT",
        "API_V1_STR",
        "ACCESS_TOKEN_EXPIRE_MINUTES",
        "SESSION_EXPIRE_MINUTES",
        "RATE_LIMIT_STORAGE_URI",
        "LOG_FILE_PATH",
    }
)


def _is_header_safe(value: str) -> bool:
    """HTTP ヘッダーに載せられる値か（印字可能 ASCII のみ）。

    非 ASCII は SDK が送信時に落とす（実測）。
    """
    return all(0x20 <= ord(ch) <= 0x7E for ch in value)


class RuntimeConfig(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
        frozen=True,
    )

    ENVIRONMENT: Environment = "development"
    PROJECT_NAME: str = "kotonoha API"
    VERSION: str = "1.0.0"
    LOG_LEVEL: LogLevel = "INFO"

    # 端末 API キー（カンマ区切り）。空なら development / test に限り認証を省略する
    API_KEYS: SecretStr = SecretStr("")
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # レート制限（ADR-002: 単一送信元の burst 抑制。カウンタはプロセス内メモリ）
    RATE_LIMIT_TIMES: int = Field(default=1, ge=1)
    RATE_LIMIT_SECONDS: int = Field(default=10, ge=1)
    TRUSTED_PROXY_COUNT: int = Field(default=0, ge=0)

    # AI プロバイダ
    DEFAULT_AI_PROVIDER: ProviderName = "anthropic"
    ANTHROPIC_API_KEY: SecretStr | None = None
    ANTHROPIC_MODEL: str = "claude-sonnet-4-6"
    OPENAI_API_KEY: SecretStr | None = None
    OPENAI_MODEL: str = "gpt-4o-mini"
    AI_API_TIMEOUT: float = Field(default=8.0, gt=0)
    AI_MAX_RETRIES: int = Field(default=1, ge=0)
    AI_CALL_DEADLINE_SECONDS: float = Field(default=10.0, gt=0)

    @field_validator("ANTHROPIC_API_KEY", "OPENAI_API_KEY", mode="after")
    @classmethod
    def _provider_key(cls, value: SecretStr | None) -> SecretStr | None:
        if value is None or value.get_secret_value() == "":
            return None
        if not _is_header_safe(value.get_secret_value()):
            raise ValueError("must be printable ASCII")  # 値は書かない
        return value

    @field_validator("API_KEYS", mode="after")
    @classmethod
    def _api_keys(cls, value: SecretStr) -> SecretStr:
        if not _is_header_safe(value.get_secret_value()):
            raise ValueError("must be printable ASCII")
        return value

    # 環境による機能の切り替えはここで一元管理する。
    @property
    def is_local(self) -> bool:
        return self.ENVIRONMENT in ("development", "test")

    @property
    def docs_enabled(self) -> bool:
        return self.is_local

    @property
    def auth_optional(self) -> bool:
        return self.is_local

    # ---- 派生値 ----
    def api_keys(self) -> tuple[bytes, ...]:
        raw = self.API_KEYS.get_secret_value()
        return tuple(key.strip().encode("ascii") for key in raw.split(",") if key.strip())

    def cors_origins(self) -> tuple[str, ...]:
        return tuple(origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip())

    def provider_api_key(self, name: ProviderName) -> SecretStr | None:
        return self.ANTHROPIC_API_KEY if name == "anthropic" else self.OPENAI_API_KEY

    def startup_problems(self) -> tuple[ConfigProblem, ...]:
        """本番ゲート。全違反を一度に返す（1件目で止まらない）。"""
        if self.is_local:
            return ()
        problems: list[ConfigProblem] = []
        if not self.api_keys():
            problems.append(("API_KEYS", "missing"))
        if self.provider_api_key(self.DEFAULT_AI_PROVIDER) is None:
            problems.append((f"{self.DEFAULT_AI_PROVIDER.upper()}_API_KEY", "missing"))
        return tuple(problems)


def _warn_removed_settings(env_file: Path | None, environ: Mapping[str, str]) -> None:
    present: set[str] = set(environ)
    if env_file is not None and env_file.is_file():
        # 権威（python-dotenv）の出力を消費する。文法は書かない
        present |= set(dotenv_values(env_file))
    for key in sorted(present & REMOVED_SETTINGS):
        log_event(RemovedSettingIgnored(key=key), level="WARNING")


def load_config(env_file: str | Path | None = ".env") -> RuntimeConfig:
    """環境変数と .env から不変の設定を組み立てる。失敗は ``ConfigError``（キー名と種別のみ）。"""
    problems: tuple[ConfigProblem, ...] = ()
    config: RuntimeConfig | None = None
    try:
        config = RuntimeConfig(_env_file=env_file)
    except ValidationError as exc:
        problems = tuple(
            (".".join(str(part) for part in err["loc"]), err["type"])
            for err in exc.errors(include_input=False, include_url=False)
        )
    if config is None:
        raise ConfigError(problems)  # except の外で raise → __context__ を残さない
    _warn_removed_settings(Path(env_file) if env_file is not None else None, os.environ)
    startup = config.startup_problems()
    if startup:
        raise ConfigError(startup)
    return config
