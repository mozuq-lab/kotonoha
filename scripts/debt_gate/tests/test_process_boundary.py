"""**プロセスの終了コード**を検査する。戻り値ではなく。

`docs/verification-principles.md:39`:

> 検証は最も外側の境界で行う——プロセスの stdout/stderr、実際の DB 行、
> HTTP レスポンスボディ、描画されたウィジェット。**戻り値だけを見るテストは、
> その関数が正しいことしか言わない。**

初回の再実装のテストは全部 `gate.run()` の戻り値を見ており、
`cmd_check` を常に 0 にする変異が22テストを素通しした（独立レビューの指摘）。
CI との唯一の契約は終了コードなので、ここを直接叩く。
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

PLIST = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
    '"http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict></dict></plist>'
)
MANIFEST = '<manifest xmlns:android="http://schemas.android.com/apk/res/android"></manifest>'


class Sandbox:
    """ゲートを実際に走らせられる最小リポジトリ。"""

    def __init__(self) -> None:
        self.root = tempfile.mkdtemp(prefix="debtgate-proc-")
        shutil.copytree(
            os.path.join(REPO_ROOT, "scripts"), os.path.join(self.root, "scripts"),
            ignore=shutil.ignore_patterns("__pycache__"),
        )
        self.write("docs/adr/ADR-001-backend-stateless.md", "# ADR-001\n")
        self.write("frontend/kotonoha_app/pubspec.yaml", "dependencies:\n  dio: ^5.0.0\n")
        self.write("backend/requirements.txt", "fastapi==0.124.0\n")
        self.write("frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml", MANIFEST)
        self.write("frontend/kotonoha_app/ios/Runner/Info.plist", PLIST)
        self.write(".env.example", "LOG_LEVEL=INFO\n")

    def write(self, relative: str, content: str) -> None:
        path = os.path.join(self.root, relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(content)

    def run(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, "-m", "scripts.debt_gate.cli"] + list(args),
            cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )

    def allowlist(self) -> dict:
        with open(os.path.join(self.root, ".debt-gate", "allowlist.json"), encoding="utf-8") as h:
            return json.load(h)["entries"]

    def cleanup(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)


class Base(unittest.TestCase):
    def setUp(self) -> None:
        self.box = Sandbox()

    def tearDown(self) -> None:
        self.box.cleanup()


class ExitCodes(Base):
    def test_missing_allowlist_exits_nonzero(self) -> None:
        self.assertEqual(self.box.run("check").returncode, 1)

    def test_seeded_repo_exits_zero(self) -> None:
        self.assertEqual(self.box.run("seed").returncode, 0)
        result = self.box.run("check")
        self.assertEqual(result.returncode, 0, result.stdout.decode())

    def test_new_surface_exits_nonzero(self) -> None:
        self.box.run("seed")
        self.box.write("frontend/kotonoha_app/pubspec.yaml",
                       "dependencies:\n  dio: ^5.0.0\n  firebase: ^1.0.0\n")
        result = self.box.run("check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("firebase", result.stdout.decode())


class SeedIsFirstRunOnly(Base):
    def test_second_seed_is_refused(self) -> None:
        """赤を1コマンドで緑にする手段を残さない。"""
        self.assertEqual(self.box.run("seed").returncode, 0)
        self.box.write("backend/requirements.txt", "fastapi==0.124.0\nstripe==9.0.0\n")
        self.assertEqual(self.box.run("check").returncode, 1)
        second = self.box.run("seed")
        self.assertEqual(second.returncode, 1)
        self.assertIn("初回のみ", second.stdout.decode())
        self.assertEqual(self.box.run("check").returncode, 1, "seed 後も赤のままであること")

    def test_seed_does_not_overwrite_a_broken_allowlist(self) -> None:
        """壊れた許可リストを seed で上書きすると、破損の検出が消える。"""
        os.makedirs(os.path.join(self.box.root, ".debt-gate"), exist_ok=True)
        self.box.write(".debt-gate/allowlist.json", "{ 壊れている")
        self.assertEqual(self.box.run("seed").returncode, 1)
        self.assertEqual(self.box.run("check").returncode, 1)


class StaleBlocksReintroduction(Base):
    def test_removing_a_surface_requires_removing_the_permission(self) -> None:
        """許可だけ残すと、あとで ADR 無しで戻せてしまう。"""
        self.box.run("seed")
        self.box.write("backend/requirements.txt", "")
        removed = self.box.run("check")
        self.assertEqual(removed.returncode, 1)
        self.assertIn("実体が無い", removed.stdout.decode())

    def test_cleaning_the_allowlist_makes_it_green(self) -> None:
        """直し方は許可リストから1行消すだけ。削除作業を止める負担にはしない。"""
        self.box.run("seed")
        self.box.write("backend/requirements.txt", "")
        entries = self.box.allowlist()
        entries["python_dependencies"] = {}
        with open(os.path.join(self.box.root, ".debt-gate", "allowlist.json"), "w",
                  encoding="utf-8") as handle:
            json.dump({"entries": entries}, handle, ensure_ascii=False)
        self.assertEqual(self.box.run("check").returncode, 0)

    def test_reintroduction_after_cleanup_needs_a_decision(self) -> None:
        """削除 → 掃除 → 再導入 の一巡で、再導入時に決定を要求する。"""
        self.box.run("seed")
        self.box.write("backend/requirements.txt", "")
        entries = self.box.allowlist()
        entries["python_dependencies"] = {}
        with open(os.path.join(self.box.root, ".debt-gate", "allowlist.json"), "w",
                  encoding="utf-8") as handle:
            json.dump({"entries": entries}, handle, ensure_ascii=False)
        self.box.write("backend/requirements.txt", "fastapi==0.124.0\n")
        result = self.box.run("check")
        self.assertEqual(result.returncode, 1, "経過措置が消えているので決定が要る")


class SelftestHasAFloor(Base):
    def test_selftest_fails_when_tests_vanish(self) -> None:
        """テストが集まらなくても unittest は緑を返す。下限で捕まえる。"""
        tests = os.path.join(self.box.root, "scripts", "debt_gate", "tests")
        for name in os.listdir(tests):
            if name.startswith("test_"):
                os.remove(os.path.join(tests, name))
        result = self.box.run("selftest")
        self.assertEqual(result.returncode, 1)
        self.assertIn("下限", result.stdout.decode())


if __name__ == "__main__":
    unittest.main()
