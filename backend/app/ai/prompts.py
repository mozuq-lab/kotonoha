"""丁寧さレベルとプロンプト。"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import Final


class PolitenessLevel(StrEnum):
    CASUAL = "casual"
    NORMAL = "normal"
    POLITE = "polite"


# 利用者は発話で訂正できない（守る約束 ③）。
# 意味を守る決まりは system に置き、変換にも再生成にも効かせる
SYSTEM_PROMPT: Final = (
    "あなたは、発話が難しい人（本人）が文字盤で打った短い言葉を、"
    "本人に代わって相手（家族・介護者・医療者など）に伝える文に整えます。"
    "入力は、ひらがなや単語を並べただけのことがあります。次を必ず守ってください。\n"
    "- 本人が相手に言う文として書く。相手の様子を尋ねる文や、相手を主語にした文に変えない。\n"
    "- 意味を変えない。否定（〜ない・〜ないで）、過去か未来か、数・時刻、名前、左右、"
    "体の部位は入力のとおりに残す。\n"
    "- 入力に無い内容を足さない。"
    "丁寧さのための言い回しは足してよいが、理由や気持ちや状況は足さない。\n"
    "- お願い・訴え・質問・報告の区別を変えない。\n"
    "- 自分の動作に尊敬語を使わない。自分の動作には謙譲語か丁寧語、相手の動作には尊敬語を使う。\n"
    "- ひらがなの語が複数の意味に読めるときは、体の症状や訴え、お願いとしての読みを優先する"
    "（例: 「はきそう」は「吐きそう」）。\n"
    "- 変換後の文を1つだけ出力する。説明、かぎかっこ、記号、候補の列挙は付けない。"
)

_INSTRUCTIONS: Final[dict[PolitenessLevel, str]] = {
    PolitenessLevel.CASUAL: "家族や親しい人に話すような、くだけた言い方にしてください。",
    PolitenessLevel.NORMAL: "「です・ます」の、標準的な丁寧さにしてください。",
    PolitenessLevel.POLITE: (
        "目上の人や初対面の人に話すような、丁寧な敬語にしてください。"
        "「〜いただけますか」「〜でございます」「〜しております」など、"
        "「です・ます」より一段丁寧な言い方を使います。大げさな言い回しは避けます。"
    ),
}


@dataclass(frozen=True, slots=True)
class Prompt:
    system: str
    user: str
    temperature: float
    # 変換結果は短い文。1 回の費用の上限を抑える（上限で切れたら provider が失敗にする）
    max_tokens: int = 256


def conversion_prompt(input_text: str, level: PolitenessLevel) -> Prompt:
    user = f"{_INSTRUCTIONS[level]}\n\n入力: {input_text}"
    return Prompt(system=SYSTEM_PROMPT, user=user, temperature=0.7)


def regeneration_prompt(input_text: str, level: PolitenessLevel, previous_result: str) -> Prompt:
    user = (
        f"{_INSTRUCTIONS[level]}\n\n入力: {input_text}\n前回の結果: {previous_result}\n\n"
        "前回とは違う言い回しにしてください。前回と同じ文は出さず、意味は変えません。"
    )
    return Prompt(system=SYSTEM_PROMPT, user=user, temperature=0.9)
