"""許可リスト — 「この面が存在してよい」という決定の記録。

JSON にしてあるのは標準ライブラリだけで読めるようにするため（ゲート自身が依存を
足したら本末転倒になる）。

各エントリは次のどちらかである。

- `{"adr": "ADR-001", "why": "…"}` — **決定に基づいて許可した**もの
- `{"adr": null, "grandfathered": true, "why": "…"}` — **Phase 1 以前から存在**し、
  決定の記録が無いもの。既存を一斉に止めないための経過措置

`grandfathered` を新しい行に書けば検査は通る。**これは意図した挙動である**——
ゲートは敵対的な回避者を止めるものではなく（ADR-008 の制約条件）、
「決定が要る場面」を**目立つ差分として可視化する**もの。`grandfathered: true` を
自分で書き足す行は、レビューで最も目に付く形になる。
"""

from __future__ import annotations

import json
import os
from typing import Dict, List, Tuple

from .errors import SnapshotError

ALLOWLIST_PATH = os.path.join(".debt-gate", "allowlist.json")

SCHEMA_NOTE = (
    "負債ゲートの許可リスト。詳細は docs/adr/ADR-008-debt-gate-state-comparison.md。"
    "新しい面を足すときは adr に docs/adr/ の実在番号を書き、why に理由を1行で書くこと。"
)


def load(repo_root: str) -> Dict[str, Dict[str, dict]]:
    """許可リストを読む。読めなければ `SnapshotError`（緑にしない）。"""
    path = os.path.join(repo_root, ALLOWLIST_PATH)
    if not os.path.isfile(path):
        raise SnapshotError("allowlist", ALLOWLIST_PATH, "許可リストが存在しない")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            doc = json.load(handle)
    except (OSError, ValueError) as exc:
        raise SnapshotError("allowlist", ALLOWLIST_PATH, "JSON として読めない: {0}".format(exc))
    entries = doc.get("entries")
    if not isinstance(entries, dict):
        raise SnapshotError("allowlist", ALLOWLIST_PATH, "entries がオブジェクトでない")
    return entries


def save(repo_root: str, entries: Dict[str, Dict[str, dict]]) -> str:
    path = os.path.join(repo_root, ALLOWLIST_PATH)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    payload = {"_note": SCHEMA_NOTE, "entries": entries}
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")
    return path


def validate_entries(
    entries: Dict[str, Dict[str, dict]], known_adr: set
) -> List[Tuple[str, str, str]]:
    """許可リスト自身の妥当性を検査する。

    引用が**実在する ADR か**をここで見る。初回実装は `ADR-999` でも通した。

    Returns:
        (kind, item, 問題) の一覧。空なら健全。
    """
    problems: List[Tuple[str, str, str]] = []
    for kind, items in sorted(entries.items()):
        if not isinstance(items, dict):
            problems.append((kind, "-", "エントリがオブジェクトでない"))
            continue
        for item, meta in sorted(items.items()):
            if not isinstance(meta, dict):
                problems.append((kind, item, "エントリがオブジェクトでない"))
                continue
            adr = meta.get("adr")
            why = meta.get("why")
            if not isinstance(why, str) or not why.strip():
                problems.append((kind, item, "why が空。なぜ許可したのかを1行で書くこと"))
            if meta.get("grandfathered") is True:
                if adr is not None:
                    problems.append((kind, item, "grandfathered なのに adr が入っている"))
                continue
            if not isinstance(adr, str):
                problems.append((kind, item, "adr が無い。決定が無いなら実装ではなく決定から始めること"))
            elif adr not in known_adr:
                problems.append(
                    (kind, item, "{0} は docs/adr/ に存在しない".format(adr))
                )
    return problems
