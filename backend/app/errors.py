"""エラーは型で表現する（ADR-003）。

このモジュールは ``ErrorCode`` と ``SafeError`` の系統しか提供しない。例外のメッセージ
文字列を受け取る引数はどこにも無い。原因例外は *型名* だけを保持する。
"""

from __future__ import annotations

from collections.abc import Mapping
from enum import StrEnum
from types import MappingProxyType
from typing import Final


class ErrorCode(StrEnum):
    """外へ出してよい語彙。足りなければここに足す（自由文字列に戻さない）。"""

    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    AI_API_TIMEOUT = "AI_API_TIMEOUT"
    AI_PROVIDER_ERROR = "AI_PROVIDER_ERROR"
    AI_RATE_LIMIT = "AI_RATE_LIMIT"
    AI_API_ERROR = "AI_API_ERROR"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    CONFIG_INVALID = "CONFIG_INVALID"
    STARTUP_MULTIPLE_WORKERS = "STARTUP_MULTIPLE_WORKERS"
    STARTUP_PROVIDER_INIT_FAILED = "STARTUP_PROVIDER_INIT_FAILED"


HTTP_STATUS: Final[Mapping[ErrorCode, int]] = MappingProxyType(
    {
        ErrorCode.VALIDATION_ERROR: 422,
        ErrorCode.AUTHENTICATION_ERROR: 401,
        ErrorCode.RATE_LIMIT_EXCEEDED: 429,
        ErrorCode.AI_API_TIMEOUT: 504,
        ErrorCode.AI_PROVIDER_ERROR: 503,
        ErrorCode.AI_RATE_LIMIT: 429,
        ErrorCode.AI_API_ERROR: 500,
        ErrorCode.INTERNAL_ERROR: 500,
        ErrorCode.CONFIG_INVALID: 500,
        ErrorCode.STARTUP_MULTIPLE_WORKERS: 500,
        ErrorCode.STARTUP_PROVIDER_INIT_FAILED: 500,
    }
)

# 利用者向け文言。旧実装の外部契約なので変えない（変えるなら tests/contract と一緒に）。
USER_MESSAGE: Final[Mapping[ErrorCode, str]] = MappingProxyType(
    {
        ErrorCode.VALIDATION_ERROR: "入力データが不正です",
        ErrorCode.AUTHENTICATION_ERROR: "Invalid or missing API key.",
        ErrorCode.RATE_LIMIT_EXCEEDED: (
            "リクエスト数が上限に達しました。しばらく待ってから再試行してください。"
        ),
        ErrorCode.AI_API_TIMEOUT: (
            "AI変換APIがタイムアウトしました。しばらく待ってから再度お試しください。"
        ),
        ErrorCode.AI_PROVIDER_ERROR: (
            "AI変換サービスが一時的に利用できません。しばらく待ってから再度お試しください。"
        ),
        ErrorCode.AI_RATE_LIMIT: (
            "AI変換APIのレート制限に達しました。しばらく待ってから再度お試しください。"
        ),
        ErrorCode.AI_API_ERROR: (
            "AI変換APIからのレスポンスに失敗しました。しばらく待ってから再度お試しください。"
        ),
        ErrorCode.INTERNAL_ERROR: "予期しないエラーが発生しました。",
        ErrorCode.CONFIG_INVALID: "設定が不正なため起動できません。",
        ErrorCode.STARTUP_MULTIPLE_WORKERS: (
            "レート制限がプロセス内メモリのため worker は1つでなければなりません（ADR-002）。"
        ),
        ErrorCode.STARTUP_PROVIDER_INIT_FAILED: (
            "AI プロバイダの初期化に失敗したため起動できません。"
        ),
    }
)

# 422 の detail[].msg に載せてよい有限語彙（ADR-003）。pydantic の err["msg"]（自由文）は読まない。
# キーは pydantic / FastAPI の err["type"]。既定は "default"。
VALIDATION_MESSAGE: Final[Mapping[str, str]] = MappingProxyType(
    {
        "missing": "必須項目がありません",
        "string_too_short": "文字数が下限を下回っています",
        "string_too_long": "文字数が上限を超えています",
        "enum": "許可されていない値です",
        "literal_error": "許可されていない値です",
        "value_error": "入力が不正です",
        "json_invalid": "JSON として解釈できません",
        "default": "入力が不正です",
    }
)


class SafeError(Exception):
    """外へ出せる情報だけを持つ例外。

    ``code`` と原因例外の *型名* だけを持つ。メッセージ文字列を受け取る引数は無い。
    ``except`` 節の外で raise すること（``__context__`` に原因例外を残さないため）。
    """

    def __init__(
        self,
        code: ErrorCode,
        *,
        cause: type[BaseException] | None = None,
        retryable: bool = False,
    ) -> None:
        super().__init__(code.value)
        self.code: ErrorCode = code
        self.cause_type: str | None = cause.__name__ if cause is not None else None
        self.retryable: bool = retryable

    def __str__(self) -> str:
        return self.code.value


class RateLimitExceeded(SafeError):  # noqa: N818 -- 名前はインターフェース仕様で固定
    """429 に載せる数値だけを持つ。"""

    def __init__(self, *, retry_after_seconds: int, limit: int) -> None:
        super().__init__(ErrorCode.RATE_LIMIT_EXCEEDED)
        self.retry_after_seconds: int = retry_after_seconds
        self.limit: int = limit


ConfigProblem = tuple[str, str]
"""(設定キー名, 種別)。値は決して含めない。種別は pydantic の error type か "missing"。"""


class ConfigError(SafeError):
    """設定の組み立てに失敗した。全違反を一度に持つ（1件目で止まらない）。"""

    def __init__(self, problems: tuple[ConfigProblem, ...]) -> None:
        super().__init__(ErrorCode.CONFIG_INVALID)
        self.problems: tuple[ConfigProblem, ...] = problems

    def __str__(self) -> str:
        listed = ", ".join(f"{key}({kind})" for key, kind in self.problems)
        return f"{self.code.value}: {listed}"
