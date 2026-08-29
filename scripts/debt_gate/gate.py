"""現在の状態と許可リストを突き合わせ、裁定する。

**git を使わない。** 作業ツリーの状態と、コミット済みの許可リストを比べるだけである。
初回実装が抱えた基準ずれ（merge-base 対 base 先端）・force-push・shallow clone・
git 失敗の fail-open は、`before` を取らないので**構造的に発生しない**。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Tuple

from .adr import known_adrs
from .allowlist import load as load_allowlist
from .allowlist import validate_entries
from .errors import SnapshotError
from .snapshot import SNAPSHOTS


@dataclass
class Result:
    #: 許可リストに無い面（決定が要る）。ここが空でなければ落とす。
    unlisted: List[Tuple[str, str, str]] = field(default_factory=list)
    #: 許可リスト自身の問題（実在しない ADR・理由なし）。落とす。
    invalid: List[Tuple[str, str, str]] = field(default_factory=list)
    #: 状態を取得できなかった。**緑にしない。**
    errors: List[SnapshotError] = field(default_factory=list)
    #: 許可リストにあるが実体が無い（掃除できる）。落とさない。
    stale: List[Tuple[str, str]] = field(default_factory=list)
    #: 経過措置で通した件数。
    grandfathered: int = 0
    #: 決定に基づいて通した件数。
    decided: int = 0

    @property
    def blocking(self) -> bool:
        return bool(self.unlisted or self.invalid or self.errors)


def run(repo_root: str) -> Result:
    result = Result()
    adr_set = known_adrs(repo_root)

    try:
        entries = load_allowlist(repo_root)
    except SnapshotError as exc:
        result.errors.append(exc)
        return result

    result.invalid = validate_entries(entries, adr_set)

    for kind, label, snapshot in SNAPSHOTS:
        try:
            items = snapshot(repo_root)
        except SnapshotError as exc:
            # 取得失敗を「変化なし」に畳まない。ここが初回実装の fail-open だった。
            result.errors.append(exc)
            continue

        allowed: Dict[str, dict] = entries.get(kind) or {}
        seen = set()
        for item, detail in items:
            seen.add(item)
            meta = allowed.get(item)
            if meta is None:
                result.unlisted.append((kind, item, detail))
            elif meta.get("grandfathered") is True:
                result.grandfathered += 1
            else:
                result.decided += 1
        for item in sorted(set(allowed) - seen):
            result.stale.append((kind, item))
    return result
