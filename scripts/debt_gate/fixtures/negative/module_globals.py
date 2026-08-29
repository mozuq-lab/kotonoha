"""陰性 fixture — ここに書かれた形は1件も検出されてはならない。

偽陽性は「ゲートを迂回する習慣」を作るので、真の見逃しより高くつく。
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import TYPE_CHECKING, Final, Literal, TypeVar

from fastapi import APIRouter, Depends

if TYPE_CHECKING:
    from collections.abc import Mapping

# 定数（大文字）は値に呼び出しを含んでいても通す。
# ここを厳しくすると定数表で毎回発火し、偽陽性がゲートを空洞化させる。
MAX_RETRIES = 3
TIMEOUT_SECONDS: Final[float] = 3.0
ERROR_DEFINITIONS = {"a": Path("/tmp"), "b": Path("/var")}
_INTERNAL_PATTERN = re.compile(r"^x")

# 型エイリアス
EnvironmentName = Literal["development", "test", "staging", "production"]
PolitenessLevel = Literal["casual", "normal", "polite"]
T = TypeVar("T")

# allowlist に載せた callee
logger = logging.getLogger(__name__)
router = APIRouter()
dependency = Depends(lambda: None)

__all__ = ["router", "logger"]


def build_client() -> str:
    """関数の中は見ない（モジュールレベルではないため）。"""
    inner_mutable = "not a global"
    return inner_mutable


class Service:
    """クラス本体も見ない。"""

    attribute = "not a module global"

    def run(self) -> str:
        local = "fine"
        return local


if __name__ == "__main__":
    entry_point = build_client()
