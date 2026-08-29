"""負債ゲートの検出結果を表す型。

ゲートは「決定を列挙する」のではなく「決定が要る場面を検出する」。
検出したら ADR の引用を要求し、引用があれば通す（是正計画 §5 C層）。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional


@dataclass(frozen=True)
class Finding:
    """負債を作りうる行為を1件検出したことを表す。

    Attributes:
        rule: ゲート項目の識別子（``dependency`` など。7項目に対応）
        path: リポジトリルートからの相対パス
        line: 新しい側の行番号（1始まり）。ファイル単位の検出では 0
        excerpt: 検出した行の内容（前後の空白を落としたもの）
        why: なぜこれが負債の入口なのか
        adr: 引用を求める ADR（``ADR-001`` など）。該当が無ければ None
    """

    rule: str
    path: str
    line: int
    excerpt: str
    why: str
    adr: Optional[str] = None

    def location(self) -> str:
        if self.line:
            return "{0}:{1}".format(self.path, self.line)
        return self.path


@dataclass
class GateResult:
    """1回のゲート実行の結果。"""

    findings: List[Finding] = field(default_factory=list)
    cited_adrs: List[str] = field(default_factory=list)

    @property
    def blocked(self) -> bool:
        """ADR の引用が無いまま負債行為を検出したか。"""
        return bool(self.findings) and not self.cited_adrs
