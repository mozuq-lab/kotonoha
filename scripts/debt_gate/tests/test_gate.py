"""裁定（ADR 引用があれば通す）とレポートの検査。

ゲートは負債行為を禁止しない。**決定を要求する。**
その境目がここで固定される。
"""

from __future__ import annotations

import unittest

from scripts.debt_gate.gate import evaluate, find_citations, is_excluded, render_text_report
from scripts.debt_gate.gitsource import build_changed_file

REQ = "backend/requirements.txt"
BASE = "fastapi==0.124.0\n"


class Citation(unittest.TestCase):
    def test_added_line_citation_lets_it_through(self) -> None:
        changed = build_changed_file(REQ, BASE, BASE + "redis==8.0.1  # ADR-002 で足す判断をした\n")
        unresolved, resolved, citations = evaluate([changed])
        self.assertEqual(unresolved, [])
        self.assertEqual(len(resolved), 1)
        self.assertEqual(citations[REQ], ["ADR-002"])

    def test_without_citation_it_blocks(self) -> None:
        changed = build_changed_file(REQ, BASE, BASE + "redis==8.0.1\n")
        unresolved, resolved, _ = evaluate([changed])
        self.assertEqual(len(unresolved), 1)
        self.assertEqual(resolved, [])

    def test_pr_body_citation_lets_it_through(self) -> None:
        """CI では PR 本文とコミットメッセージも引用として数える。"""
        changed = build_changed_file(REQ, BASE, BASE + "redis==8.0.1\n")
        unresolved, resolved, _ = evaluate([changed], "この変更は ADR-002 の再検討にあたる")
        self.assertEqual(unresolved, [])
        self.assertEqual(len(resolved), 1)

    def test_citation_is_scoped_per_file_when_no_extra_text(self) -> None:
        """別ファイルの引用では通らない（フックはファイル単位で判定する）。"""
        dep = build_changed_file(REQ, BASE, BASE + "redis==8.0.1\n")
        doc = build_changed_file("backend/app/notes.py", "", "# ADR-002\n")
        unresolved, _, _ = evaluate([dep, doc])
        self.assertEqual(len(unresolved), 1)

    def test_citation_pattern_requires_three_digits(self) -> None:
        self.assertEqual(find_citations("ADR-002 と ADR-7 と adr-003"), ["ADR-002"])


class Exclusions(unittest.TestCase):
    def test_only_fixtures_are_excluded(self) -> None:
        self.assertTrue(is_excluded("scripts/debt_gate/fixtures/positive/module_globals.py"))
        self.assertFalse(is_excluded("scripts/debt_gate/detectors.py"))
        self.assertFalse(is_excluded("backend/app/main.py"))

    def test_fixtures_do_not_trip_the_gate(self) -> None:
        """陽性 fixture は意図的に負債の形をしている。除外しないと永久に落ちる。"""
        path = "scripts/debt_gate/fixtures/positive/module_globals.py"
        changed = build_changed_file(path, None, "client = Client()\n")
        unresolved, resolved, _ = evaluate([changed])
        self.assertEqual((unresolved, resolved), ([], []))


class Report(unittest.TestCase):
    def test_report_names_the_adr_and_both_ways_through(self) -> None:
        changed = build_changed_file(REQ, BASE, BASE + "redis==8.0.1\n")
        unresolved, resolved, _ = evaluate([changed])
        text = render_text_report(unresolved, resolved)
        self.assertIn("ADR-002", text)
        self.assertIn("依存の追加", text)
        self.assertIn("決定が無いなら", text)

    def test_report_tells_you_to_start_from_a_decision_when_no_adr_exists(self) -> None:
        path = "frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml"
        changed = build_changed_file(
            path,
            "<manifest>\n</manifest>\n",
            '<manifest>\n  <uses-permission android:name="android.permission.CAMERA"/>\n</manifest>\n',
        )
        unresolved, resolved, _ = evaluate([changed])
        text = render_text_report(unresolved, resolved)
        self.assertIn("その領域の決定が存在しない", text)


if __name__ == "__main__":
    unittest.main()
