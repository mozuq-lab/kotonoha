"""`docs/adr/` に実在する ADR 番号。

引用の検査を「3桁の数字を含む文字列」ではなく「**実在する決定**」にするために使う。
初回実装は `ADR-999` でも `ADR-000` でも通した。
"""

from __future__ import annotations

import os
import re
from typing import Set

ADR_FILENAME = re.compile(r"^(ADR-\d{3})-.+\.md$")


def known_adrs(repo_root: str) -> Set[str]:
    """`docs/adr/ADR-NNN-*.md` から実在する番号を集める。"""
    directory = os.path.join(repo_root, "docs", "adr")
    found = set()
    if not os.path.isdir(directory):
        return found
    for name in os.listdir(directory):
        match = ADR_FILENAME.match(name)
        if match:
            found.add(match.group(1))
    return found
