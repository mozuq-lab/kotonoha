"""AST ゲートの陽性・陰性 fixture 検査。

完了条件（是正計画 §6 Phase 1）が名指しで要求している検査。
「ゲートが存在すること」と「ゲートが機能すること」は別なので、
検査自体をテストする。
"""

from __future__ import annotations

import os
import unittest

from scripts.debt_gate.ast_globals import (
    find_dart_top_level_mutables,
    find_python_module_globals,
)

FIXTURES = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "fixtures")


def read(kind: str, name: str) -> str:
    with open(os.path.join(FIXTURES, kind, name), "r", encoding="utf-8") as handle:
        return handle.read()


class PositivePythonFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.findings = find_python_module_globals(
            read("positive", "module_globals.py"), "fixtures/positive/module_globals.py"
        )
        self.excerpts = [f.excerpt for f in self.findings]

    def test_detects_import_time_side_effect_call(self) -> None:
        """代入を伴わない呼び出し（独立レビューの反例）を拾う。"""
        self.assertIn("setup_logging()", self.excerpts)

    def test_detects_module_level_resource_creation(self) -> None:
        self.assertIn("client = Client()", self.excerpts)
        self.assertIn("settings = Config()", self.excerpts)

    def test_detects_plain_mutable_global(self) -> None:
        self.assertIn('current_environment = "development"', self.excerpts)

    def test_detects_tuple_and_augmented_assignment(self) -> None:
        self.assertIn('first_url, second_url = "a", "b"', self.excerpts)
        self.assertIn("counter += 1", self.excerpts)

    def test_detects_inside_if_and_try(self) -> None:
        """条件付き・try 配下のモジュールレベル代入も見る。"""
        self.assertIn("fallback_client = Client()", self.excerpts)
        self.assertIn("optional_client = Client()", self.excerpts)

    def test_every_finding_cites_an_adr(self) -> None:
        for finding in self.findings:
            self.assertEqual(finding.adr, "ADR-004", finding.excerpt)


class NegativePythonFixture(unittest.TestCase):
    def test_no_false_positives(self) -> None:
        """偽陽性はゲートを迂回する習慣を作るので、真の見逃しより高くつく。"""
        findings = find_python_module_globals(
            read("negative", "module_globals.py"), "fixtures/negative/module_globals.py"
        )
        self.assertEqual([f.excerpt for f in findings], [])


class DartFixtures(unittest.TestCase):
    def test_positive(self) -> None:
        findings = find_dart_top_level_mutables(
            read("positive", "top_level_mutable.dart"), "fixtures/positive/top_level_mutable.dart"
        )
        excerpts = [f.excerpt for f in findings]
        self.assertIn("var currentUserName = 'unset';", excerpts)
        self.assertIn("late String cachedPhrase;", excerpts)

    def test_negative(self) -> None:
        findings = find_dart_top_level_mutables(
            read("negative", "top_level_mutable.dart"), "fixtures/negative/top_level_mutable.dart"
        )
        self.assertEqual([f.excerpt for f in findings], [])


class SyntaxErrorIsNotAGateFailure(unittest.TestCase):
    def test_unparseable_source_yields_nothing(self) -> None:
        """ゲートは構文検査ではない。壊れたソースで落ちない。"""
        self.assertEqual(find_python_module_globals("def (:", "broken.py"), [])


if __name__ == "__main__":
    unittest.main()
