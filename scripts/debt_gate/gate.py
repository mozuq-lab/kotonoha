"""検出結果を「ADR の引用があるか」で裁定し、報告文を組み立てる。

ゲートは負債行為を禁止しない。**決定を要求する。** 引用があれば通す。
該当する ADR が無いなら、それはその領域の決定が存在しないということなので、
実装ではなく決定から始める（AGENTS.md「改修に着手する前に」）。
"""

from __future__ import annotations

import re
from typing import Dict, Iterable, List, Optional, Tuple

from .detectors import ChangedFile, RULE_LABELS, run_detectors
from .finding import Finding

CITATION = re.compile(r"ADR-\d{3}")

GATE_DOC = "docs/plans/2026-08-29-architecture-remediation.md の Phase 1"

#: 検査しないパス。
#: fixtures は「ゲートが発火すること」を確かめるために意図的に負債の形を書いた
#: 教材なので、ここを除外しないと自分自身で永久に落ちる。
#: **除外はこの1件だけに保つこと。** 除外が増え始めたら、それは検出器の偽陽性が
#: 高いという症状であって、除外で対処すべきものではない（Phase 4 の棚卸しで点検する）。
EXCLUDED_PATH_PREFIXES = ("scripts/debt_gate/fixtures/",)


def is_excluded(path: str) -> bool:
    return path.startswith(EXCLUDED_PATH_PREFIXES)


def find_citations(text: str) -> List[str]:
    seen: List[str] = []
    for match in CITATION.findall(text or ""):
        if match not in seen:
            seen.append(match)
    return seen


def evaluate(
    files: Iterable[ChangedFile], extra_citation_text: str = ""
) -> Tuple[List[Finding], List[Finding], Dict[str, List[str]]]:
    """検出し、ファイル単位で ADR 引用を照合する。

    Returns:
        (引用の無い検出, 引用で通した検出, ファイルごとの引用一覧)
    """
    extra = find_citations(extra_citation_text)
    unresolved: List[Finding] = []
    resolved: List[Finding] = []
    citations: Dict[str, List[str]] = {}

    for changed in files:
        if is_excluded(changed.path):
            continue
        findings = run_detectors(changed)
        if not findings:
            continue
        added_text = "\n".join(text for _, text in changed.added)
        cited = find_citations(added_text) + [a for a in extra if a not in find_citations(added_text)]
        citations[changed.path] = cited
        if cited:
            resolved.extend(findings)
        else:
            unresolved.extend(findings)
    return unresolved, resolved, citations


def _adr_hint(finding: Finding) -> str:
    if finding.adr:
        return "  引用すべき決定: {0}（docs/adr/ を読むこと）".format(finding.adr)
    return (
        "  該当する ADR が見当たらない。"
        "**その領域の決定が存在しない**ということなので、実装ではなく決定から始めること"
    )


def render_text_report(unresolved: List[Finding], resolved: List[Finding]) -> str:
    """人／エージェント向けの報告文。"""
    lines: List[str] = []
    lines.append("負債ゲートが {0} 件の「決定が要る変更」を検出した。".format(len(unresolved)))
    lines.append("")
    by_rule: Dict[str, List[Finding]] = {}
    for finding in unresolved:
        by_rule.setdefault(finding.rule, []).append(finding)
    for rule, group in by_rule.items():
        lines.append("■ {0}".format(RULE_LABELS.get(rule, rule)))
        for finding in group:
            lines.append("  {0}".format(finding.location()))
            lines.append("    {0}".format(finding.excerpt[:160]))
            lines.append("    なぜ負債の入口か: {0}".format(finding.why))
            lines.append(_adr_hint(finding))
        lines.append("")
    lines.append("通し方は2つ。どちらも「決定してから書く」に戻す手段である。")
    lines.append("  1. 該当 ADR を読み、追加した行の近くに `ADR-00X` を引用する（コメント可）")
    lines.append("  2. 決定が無いなら、実装をやめて ADR を1本作る（tsumiki:adr-rubber-duck）")
    if resolved:
        lines.append("")
        lines.append("（ADR 引用済みで通した検出: {0} 件）".format(len(resolved)))
    lines.append("")
    lines.append("ゲートの定義: {0}".format(GATE_DOC))
    return "\n".join(lines)


def render_github_annotations(unresolved: List[Finding]) -> str:
    """GitHub Actions のアノテーション行。"""
    lines: List[str] = []
    for finding in unresolved:
        message = "[{0}] {1} / {2}".format(
            RULE_LABELS.get(finding.rule, finding.rule),
            finding.why,
            "引用すべき決定: {0}".format(finding.adr) if finding.adr else "該当 ADR 無し（決定から始めること）",
        )
        message = message.replace("\n", " ").replace("%", "%25")
        if finding.line:
            lines.append(
                "::error file={0},line={1}::{2}".format(finding.path, finding.line, message)
            )
        else:
            lines.append("::error file={0}::{1}".format(finding.path, message))
    return "\n".join(lines)
