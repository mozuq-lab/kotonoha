"""丁寧さレベルとプロンプト。旧実装の文言をそのまま引き継ぐ。"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import Final


class PolitenessLevel(StrEnum):
    CASUAL = "casual"
    NORMAL = "normal"
    POLITE = "polite"


SYSTEM_PROMPT: Final = "あなたは日本語の文章を適切な丁寧さレベルに変換する専門家です。"

_INSTRUCTIONS: Final[dict[PolitenessLevel, str]] = {
    PolitenessLevel.CASUAL: (
        "カジュアルで親しみやすい表現に変換してください。タメ口や砕けた言い回しを使用します。"
    ),
    PolitenessLevel.NORMAL: "標準的な丁寧さの「です・ます」調の表現に変換してください。",
    PolitenessLevel.POLITE: (
        "非常に丁寧で敬意を込めた敬語表現に変換してください。尊敬語・謙譲語を適切に使用します。"
    ),
}

_TAIL: Final = "変換後の文のみを出力してください。説明や追加情報は不要です。"


@dataclass(frozen=True, slots=True)
class Prompt:
    system: str
    user: str
    temperature: float
    max_tokens: int = 1024


def conversion_prompt(input_text: str, level: PolitenessLevel) -> Prompt:
    user = f"以下の日本語文を{_INSTRUCTIONS[level]}\n\n入力文: {input_text}\n\n{_TAIL}"
    return Prompt(system=SYSTEM_PROMPT, user=user, temperature=0.7)


def regeneration_prompt(input_text: str, level: PolitenessLevel, previous_result: str) -> Prompt:
    user = (
        f"以下の日本語文を{_INSTRUCTIONS[level]}\n\n"
        f"元の入力文: {input_text}\n前回の変換結果: {previous_result}\n\n"
        "前回と**異なる表現**で変換してください。意味は同じでも、言い回しを変えてください。\n"
        f"{_TAIL}"
    )
    return Prompt(system=SYSTEM_PROMPT, user=user, temperature=0.9)
