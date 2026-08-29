"""7項目の検出器の振る舞いを固定する。

**特に重要なのは「発火しないこと」の側**である。

- 削除で発火すると Phase 2（DB 依存の削除）と Phase 3（isFavorite 削除）を塞ぐ
- バージョン更新で発火すると dependabot の PR が毎回落ち、ゲートを外す圧力になる

どちらもゲート自身を殺す経路なので、テストで固定しておく。
"""

from __future__ import annotations

import unittest

from scripts.debt_gate.detectors import ChangedFile, run_detectors
from scripts.debt_gate.gitsource import build_changed_file


def rules(old: str, new: str, path: str) -> list:
    return sorted({f.rule for f in run_detectors(build_changed_file(path, old, new))})


def findings(old: str, new: str, path: str) -> list:
    return run_detectors(build_changed_file(path, old, new))


class Dependency(unittest.TestCase):
    PATH = "backend/requirements.txt"
    BASE = "fastapi==0.124.0\nhttpx==0.28.1\n"

    def test_new_package_fires(self) -> None:
        result = findings(self.BASE, self.BASE + "redis==8.0.1\n", self.PATH)
        self.assertEqual([f.rule for f in result], ["dependency"])
        self.assertEqual(result[0].adr, "ADR-002")

    def test_db_package_points_at_adr_001(self) -> None:
        result = findings(self.BASE, self.BASE + "sqlalchemy==2.0.44\n", self.PATH)
        self.assertEqual(result[0].adr, "ADR-001")

    def test_version_bump_does_not_fire(self) -> None:
        """dependabot の PR を毎回落とすと、ゲートを外す圧力になる。"""
        bumped = self.BASE.replace("0.124.0", "0.128.6")
        self.assertEqual(rules(self.BASE, bumped, self.PATH), [])

    def test_removal_does_not_fire(self) -> None:
        """Phase 2 は requirements.txt から5行消す。削除で落ちてはならない。"""
        reduced = "fastapi==0.124.0\n"
        self.assertEqual(rules(self.BASE, reduced, self.PATH), [])

    def test_extras_and_comments(self) -> None:
        added = self.BASE + "# redis==8.0.1  ここはコメント\nuvicorn[standard]==0.40.0\n"
        result = findings(self.BASE, added, self.PATH)
        self.assertEqual([f.excerpt for f in result], ["uvicorn[standard]==0.40.0"])


class PubspecDependency(unittest.TestCase):
    PATH = "frontend/kotonoha_app/pubspec.yaml"
    BASE = (
        "name: kotonoha_app\n"
        "environment:\n"
        "  sdk: '>=3.0.0 <4.0.0'\n"
        "dependencies:\n"
        "  flutter:\n"
        "    sdk: flutter\n"
        "  hive: ^2.2.3\n"
    )

    def test_new_dependency_fires(self) -> None:
        result = findings(self.BASE, self.BASE + "  dio: ^5.0.0\n", self.PATH)
        self.assertEqual([f.excerpt for f in result], ["dio: ^5.0.0"])

    def test_version_bump_does_not_fire(self) -> None:
        self.assertEqual(rules(self.BASE, self.BASE.replace("^2.2.3", "^2.2.4"), self.PATH), [])

    def test_non_dependency_section_does_not_fire(self) -> None:
        """environment: 配下の 2 スペースキーを依存と誤認しない。"""
        changed = self.BASE.replace(
            "environment:\n  sdk: '>=3.0.0 <4.0.0'\n",
            "environment:\n  sdk: '>=3.0.0 <4.0.0'\n  flutter: '>=3.38.0'\n",
        )
        self.assertEqual(rules(self.BASE, changed, self.PATH), [])


class Persistence(unittest.TestCase):
    def test_hive_field_fires(self) -> None:
        old = "class Item {\n  final String id;\n}\n"
        new = "class Item {\n  final String id;\n  @HiveField(3)\n  bool isFavorite = false;\n}\n"
        result = findings(old, new, "frontend/kotonoha_app/lib/features/x/item.dart")
        self.assertIn("persistence", [f.rule for f in result])
        self.assertEqual(result[0].adr, "ADR-005")

    def test_sqlalchemy_table_fires(self) -> None:
        old = "x = 1\n"
        new = 'x = 1\nclass Log(Base):\n    __tablename__ = "logs"\n'
        self.assertIn("persistence", rules(old, new, "backend/app/models/log.py"))

    def test_removing_a_hive_field_does_not_fire(self) -> None:
        """Phase 3 は isFavorite を Hive migration で消す。削除で落ちてはならない。"""
        old = "class Item {\n  @HiveField(3)\n  bool isFavorite = false;\n}\n"
        new = "class Item {\n}\n"
        self.assertEqual(rules(old, new, "frontend/kotonoha_app/lib/features/x/item.dart"), [])


class SecretConfig(unittest.TestCase):
    def test_secretstr_field_fires(self) -> None:
        old = "class Config:\n    pass\n"
        new = "class Config:\n    ANTHROPIC_API_KEY: SecretStr\n"
        result = findings(old, new, "backend/app/core/config.py")
        self.assertEqual([f.rule for f in result], ["secret_config"])

    def test_new_secret_key_in_env_example_fires(self) -> None:
        old = "API_BASE_URL=http://localhost:8000\n"
        new = old + "STRIPE_SECRET_KEY=\n"
        self.assertEqual(rules(old, new, "backend/.env.example"), ["secret_config"])

    def test_non_secret_key_does_not_fire(self) -> None:
        old = "API_BASE_URL=http://localhost:8000\n"
        new = old + "LOG_LEVEL=INFO\n"
        self.assertEqual(rules(old, new, "backend/.env.example"), [])


class HttpRoute(unittest.TestCase):
    def test_new_route_fires(self) -> None:
        old = "from fastapi import APIRouter\nrouter = APIRouter()\n"
        new = old + '@router.get("/debug/config")\nasync def debug_config():\n    return {}\n'
        result = findings(old, new, "backend/app/api/v1/endpoints/debug.py")
        self.assertIn("http_route", [f.rule for f in result])

    def test_commented_out_route_does_not_fire(self) -> None:
        old = "from fastapi import APIRouter\nrouter = APIRouter()\n"
        new = old + '# @router.get("/debug/config")\n'
        self.assertEqual(rules(old, new, "backend/app/api/v1/endpoints/debug.py"), [])


class Egress(unittest.TestCase):
    PATH = "backend/app/utils/ai_client.py"

    def test_new_host_fires(self) -> None:
        old = 'BASE = "https://api.anthropic.com"\n'
        new = old + 'ANALYTICS = "https://telemetry.example.net/collect"\n'
        self.assertEqual(rules(old, new, self.PATH), ["egress"])

    def test_existing_host_does_not_fire(self) -> None:
        old = 'BASE = "https://api.anthropic.com"\n'
        new = old + 'ALT = "https://api.anthropic.com/v1/messages"\n'
        self.assertEqual(rules(old, new, self.PATH), [])

    def test_localhost_does_not_fire(self) -> None:
        old = "x = 1\n"
        new = old + 'DEV = "http://localhost:8000"\n'
        self.assertEqual(rules(old, new, self.PATH), [])

    def test_http_client_appearing_in_a_new_file_fires(self) -> None:
        """既存依存で書けるため、依存ゲートでは捕まらない面。"""
        old = "def send(payload):\n    return payload\n"
        new = "import httpx\n\n\ndef send(payload):\n    return httpx.post('https://x.invalid', json=payload)\n"
        self.assertEqual(rules(old, new, "backend/app/utils/reporter.py"), ["egress"])

    def test_tests_are_out_of_scope(self) -> None:
        old = "x = 1\n"
        new = old + 'URL = "https://telemetry.example.net/collect"\n'
        self.assertEqual(rules(old, new, "backend/tests/test_x.py"), [])


class MobilePermission(unittest.TestCase):
    ANDROID = "frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml"
    IOS = "frontend/kotonoha_app/ios/Runner/Info.plist"

    def test_android_permission_fires(self) -> None:
        old = "<manifest>\n</manifest>\n"
        new = '<manifest>\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n</manifest>\n'
        result = findings(old, new, self.ANDROID)
        self.assertEqual([f.rule for f in result], ["mobile_permission"])
        self.assertIsNone(result[0].adr, "モバイル権限の ADR はまだ無い。決定から始めさせる")

    def test_ios_usage_description_fires(self) -> None:
        old = "<dict>\n</dict>\n"
        new = "<dict>\n  <key>NSMicrophoneUsageDescription</key>\n  <string>x</string>\n</dict>\n"
        self.assertEqual(rules(old, new, self.IOS), ["mobile_permission"])

    def test_unrelated_plist_key_does_not_fire(self) -> None:
        old = "<dict>\n</dict>\n"
        new = "<dict>\n  <key>CFBundleName</key>\n  <string>kotonoha</string>\n</dict>\n"
        self.assertEqual(rules(old, new, self.IOS), [])


class ModuleGlobalIsDiffScoped(unittest.TestCase):
    def test_untouched_global_does_not_fire(self) -> None:
        """既存のモジュールグローバルは、そのファイルを触っただけでは発火しない。"""
        old = "settings = Settings()\n"
        new = "settings = Settings()\n\n\ndef helper() -> int:\n    return 1\n"
        self.assertEqual(rules(old, new, "backend/app/core/config.py"), [])

    def test_newly_added_global_fires(self) -> None:
        old = "def helper() -> int:\n    return 1\n"
        new = "cache = {}\n\n\ndef helper() -> int:\n    return 1\n"
        self.assertEqual(rules(old, new, "backend/app/core/config.py"), ["module_global"])


class UnwatchedFilesAreIgnored(unittest.TestCase):
    def test_markdown_is_not_scanned(self) -> None:
        old = ""
        new = "依存を足す: `redis==8.0.1`\n"
        self.assertEqual(rules(old, new, "docs/plans/example.md"), [])


if __name__ == "__main__":
    unittest.main()
