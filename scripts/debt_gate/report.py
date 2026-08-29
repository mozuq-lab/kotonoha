"""裁定結果を人・エージェント・GitHub Actions 向けに組み立てる。"""

from __future__ import annotations

from typing import List

from .gate import Result
from .snapshot import SNAPSHOTS

LABELS = {kind: label for kind, label, _ in SNAPSHOTS}

WHY = {
    "dart_dependencies": "新しい外部の面が増える。今回の DB も Redis もここから入った",
    "python_dependencies": "新しい外部の面が増える。今回の DB も Redis もここから入った",
    "android_permissions": "端末データへの到達面が増える。プライバシー優先のこの製品では依存追加と同格の負債",
    "ios_privacy_keys": "端末データへの到達面が増える。プライバシー優先のこの製品では依存追加と同格の負債",
    "env_example_keys": "設定キーが増えると、秘密が到達しうる面も増える",
}

ADR_HINT = {
    "dart_dependencies": None,
    "python_dependencies": "ADR-001（DB 系）/ ADR-002（Redis 系）が該当することがある",
    "android_permissions": None,
    "ios_privacy_keys": None,
    "env_example_keys": "ADR-004（設定は不変）",
}


def render(result: Result) -> str:
    lines: List[str] = []

    if result.errors:
        lines.append("■ 状態を取得できなかった（緑にしない）")
        for err in result.errors:
            lines.append("  {0}".format(err))
        lines.append("")
        lines.append("  取得失敗を「変化なし」と区別するための挙動である。")
        lines.append("  初回実装はここを空集合に潰し、CI を静かに緑にしていた。")
        lines.append("")

    if result.invalid:
        lines.append("■ 許可リスト自身に問題がある")
        for kind, item, problem in result.invalid:
            lines.append("  {0} / {1}: {2}".format(LABELS.get(kind, kind), item, problem))
        lines.append("")

    if result.unlisted:
        lines.append("■ 許可リストに無い面がある（決定が要る）")
        for kind, item, detail in result.unlisted:
            lines.append("  [{0}] {1}".format(LABELS.get(kind, kind), item))
            lines.append("      出どころ: {0}".format(detail))
            lines.append("      なぜ負債の入口か: {0}".format(WHY.get(kind, "")))
            hint = ADR_HINT.get(kind)
            if hint:
                lines.append("      参考: {0}".format(hint))
        lines.append("")
        lines.append("通し方は2つ。どちらも「決定してから書く」に戻す手段である。")
        lines.append("  1. 該当 ADR を読み、.debt-gate/allowlist.json に足す:")
        lines.append('       "<名前>": {"adr": "ADR-00X", "why": "なぜ許可するか1行"}')
        lines.append("     adr は docs/adr/ に実在する番号のみ通る（ADR-999 は通らない）")
        lines.append("  2. 決定が無いなら、実装をやめて ADR を1本作る（tsumiki:adr-rubber-duck）")
        lines.append("")

    if result.stale:
        lines.append("ℹ️  許可リストに残っているが実体が無い（掃除できる。落とさない）")
        for kind, item in result.stale:
            lines.append("  {0} / {1}".format(LABELS.get(kind, kind), item))
        lines.append("")

    lines.append(
        "通過: 決定に基づくもの {0} 件 / 経過措置 {1} 件".format(result.decided, result.grandfathered)
    )
    lines.append("ゲートの設計: docs/adr/ADR-008-debt-gate-state-comparison.md")
    return "\n".join(lines)


def render_annotations(result: Result) -> str:
    """GitHub Actions のアノテーション。"""
    out: List[str] = []
    for err in result.errors:
        out.append("::error::負債ゲート: {0}".format(str(err).replace("%", "%25")))
    for kind, item, problem in result.invalid:
        out.append(
            "::error file={0}::[{1}] {2}: {3}".format(
                ".debt-gate/allowlist.json", LABELS.get(kind, kind), item, problem
            )
        )
    for kind, item, _detail in result.unlisted:
        out.append(
            "::error file={0}::[{1}] {2} が許可リストに無い。ADR を引用して追加すること".format(
                ".debt-gate/allowlist.json", LABELS.get(kind, kind), item
            )
        )
    return "\n".join(out)
