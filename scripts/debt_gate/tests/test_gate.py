"""裁定と fail-closed を固定する。

初回実装（revert 済み）の2つの P0 に対応する検査:

- **git の失敗が「変更ファイルなし」に畳まれ CI が緑になった** → 取得失敗は落とす
- **`ADR-999` で通った** → 実在する ADR のみ受理する
"""

from __future__ import annotations

import json
import os
import shutil
import tempfile
import unittest

from scripts.debt_gate import allowlist, gate

PLIST = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
    '"http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0">'
    "<dict></dict></plist>"
)
MANIFEST = '<manifest xmlns:android="http://schemas.android.com/apk/res/android"></manifest>'


class Repo:
    """ゲートが読む面をひととおり備えた最小リポジトリ。"""

    def __init__(self) -> None:
        self.root = tempfile.mkdtemp(prefix="debtgate-")
        self.write("docs/adr/ADR-001-backend-stateless.md", "# ADR-001\n")
        self.write("docs/adr/ADR-004-config-immutable.md", "# ADR-004\n")
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

    def allow(self, entries: dict) -> None:
        allowlist.save(self.root, entries)

    #: 識別子は「出どころ込み」。名前だけを鍵にすると、dev→runtime の昇格や
    #: 供給元の差し替えを見逃す（独立レビューの指摘）。
    DIO = "frontend/kotonoha_app/pubspec.yaml:dependencies/dio@hosted"
    FASTAPI = "backend/requirements.txt/fastapi@index"
    LOG_LEVEL = ".env.example:LOG_LEVEL"

    def allow_everything(self, **overrides) -> None:
        grand = {"adr": None, "grandfathered": True, "why": "既存"}
        entries = {
            "dart_dependencies": {self.DIO: dict(grand)},
            "python_dependencies": {self.FASTAPI: dict(grand)},
            "android_permissions": {},
            "ios_privacy_keys": {},
            "env_example_keys": {self.LOG_LEVEL: dict(grand)},
        }
        entries.update(overrides)
        self.allow(entries)

    def cleanup(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)


class Base(unittest.TestCase):
    def setUp(self) -> None:
        self.repo = Repo()

    def tearDown(self) -> None:
        self.repo.cleanup()


class FailClosed(Base):
    def test_missing_allowlist_blocks(self) -> None:
        """許可リストが無いのを「許可が0件」と読んで緑にしない。"""
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertTrue(result.errors)

    def test_unreadable_allowlist_blocks(self) -> None:
        path = os.path.join(self.repo.root, allowlist.ALLOWLIST_PATH)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("{ これは JSON ではない")
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertTrue(result.errors)

    def test_missing_source_file_blocks(self) -> None:
        """状態が取れないことを「面が0件」と読まない。ここが初回実装の fail-open。"""
        self.repo.allow_everything()
        os.remove(os.path.join(self.repo.root, "frontend/kotonoha_app/pubspec.yaml"))
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertEqual([e.kind for e in result.errors], ["dart_dependencies"])

    def test_unparseable_source_blocks(self) -> None:
        self.repo.allow_everything()
        self.repo.write("frontend/kotonoha_app/ios/Runner/Info.plist", "これは plist ではない")
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertEqual([e.kind for e in result.errors], ["ios_privacy_keys"])


class Citation(Base):
    def test_nonexistent_adr_is_rejected(self) -> None:
        """`ADR-999` で通らない。初回実装は通した。"""
        self.repo.allow_everything(
            dart_dependencies={Repo.DIO: {"adr": "ADR-999", "why": "存在しない決定"}}
        )
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertIn("docs/adr/ に存在しない", " ".join(p[2] for p in result.invalid))

    def test_existing_adr_is_accepted(self) -> None:
        self.repo.allow_everything(
            dart_dependencies={Repo.DIO: {"adr": "ADR-001", "why": "AI 変換の HTTP 呼び出しに要る"}}
        )
        result = gate.run(self.repo.root)
        self.assertFalse(result.blocking)
        self.assertEqual(result.decided, 1)

    def test_empty_reason_is_rejected(self) -> None:
        self.repo.allow_everything(
            dart_dependencies={Repo.DIO: {"adr": "ADR-001", "why": "   "}}
        )
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)

    def test_grandfathered_must_not_carry_an_adr(self) -> None:
        self.repo.allow_everything(
            dart_dependencies={Repo.DIO: {"adr": "ADR-001", "grandfathered": True, "why": "既存"}}
        )
        self.assertTrue(gate.run(self.repo.root).blocking)


class NewSurface(Base):
    def test_new_dependency_blocks(self) -> None:
        self.repo.allow_everything()
        self.repo.write(
            "frontend/kotonoha_app/pubspec.yaml", "dependencies:\n  dio: ^5.0.0\n  firebase: ^1.0.0\n"
        )
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertEqual([k for k, _, _ in result.unlisted], ["dart_dependencies"])
        self.assertIn("firebase", result.unlisted[0][1])

    def test_new_android_permission_blocks(self) -> None:
        self.repo.allow_everything()
        self.repo.write(
            "frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml",
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
            '<uses-permission android:name="android.permission.CAMERA"/></manifest>',
        )
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertTrue(any(k == "android_permissions" and i.endswith("android.permission.CAMERA")
                            for k, i, _ in result.unlisted), result.unlisted)

    def test_new_env_key_blocks_regardless_of_name(self) -> None:
        """名前が「秘密らしい」かは見ない。`URI` 系を落とさないため。"""
        self.repo.allow_everything()
        self.repo.write(".env.example", "LOG_LEVEL=INFO\nRATE_LIMIT_STORAGE_URI=\n")
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertTrue(any(k == "env_example_keys" and i.endswith(":RATE_LIMIT_STORAGE_URI")
                            for k, i, _ in result.unlisted), result.unlisted)

    def test_removing_a_surface_requires_cleaning_the_allowlist(self) -> None:
        """削除は「許可リストの同じ行も消す」ことを要求する。

        許可だけ残すと、あとで ADR 無しで再導入できてしまう（独立レビューの指摘）。
        直し方は1行消すだけなので、Phase 2 の依存削除を止める負担にはならない。
        """
        self.repo.allow_everything()
        self.repo.write("backend/requirements.txt", "")
        result = gate.run(self.repo.root)
        self.assertTrue(result.blocking)
        self.assertEqual(result.stale, [("python_dependencies", Repo.FASTAPI)])

    def test_removing_both_the_surface_and_the_permission_is_green(self) -> None:
        self.repo.allow_everything(python_dependencies={})
        self.repo.write("backend/requirements.txt", "")
        self.assertFalse(gate.run(self.repo.root).blocking)


class Reporting(Base):
    def test_report_names_the_allowlist_and_both_ways_through(self) -> None:
        from scripts.debt_gate.report import render

        self.repo.allow_everything()
        self.repo.write("frontend/kotonoha_app/pubspec.yaml",
                        "dependencies:\n  dio: ^5.0.0\n  firebase: ^1.0.0\n")
        text = render(gate.run(self.repo.root))
        self.assertIn(".debt-gate/allowlist.json", text)
        self.assertIn("ADR-999 は通らない", text)
        self.assertIn("決定が無いなら", text)


class AllowlistRoundTrip(Base):
    def test_save_then_load(self) -> None:
        entries = {"dart_dependencies": {Repo.DIO: {"adr": "ADR-001", "why": "理由"}}}
        allowlist.save(self.repo.root, entries)
        self.assertEqual(allowlist.load(self.repo.root), entries)

    def test_saved_file_is_sorted_and_readable(self) -> None:
        """人が読んでレビューする対象なので、順序が安定していること。"""
        allowlist.save(self.repo.root, {"b": {"y": {"adr": None, "grandfathered": True, "why": "x"}},
                                        "a": {"z": {"adr": None, "grandfathered": True, "why": "x"}}})
        with open(os.path.join(self.repo.root, allowlist.ALLOWLIST_PATH), encoding="utf-8") as h:
            raw = h.read()
        self.assertLess(raw.index('"a"'), raw.index('"b"'))
        json.loads(raw)


if __name__ == "__main__":
    unittest.main()
