"""**書き方を変えても結果が変わらないこと**を固定する。

これがこのゲートの存在理由である。初回実装（revert 済み）は差分の行を
パターン照合しており、2系統の独立レビューが有効な別表記での素通しを
7項目中6項目で検出した。同じ形を再生産しないための検査。

テストは「同じ意味・違う書き方」を2通り用意し、**両方から同じ集合が出ること**を見る。
"""

from __future__ import annotations

import os
import shutil
import tempfile
import unittest

from scripts.debt_gate import snapshot

PLIST_HEADER = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
    '"http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0">'
)


class Fixture:
    """最小のリポジトリ形をテンポラリに作る。"""

    def __init__(self) -> None:
        self.root = tempfile.mkdtemp(prefix="debtgate-")

    def write(self, relative: str, content: str) -> None:
        path = os.path.join(self.root, relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(content)

    def cleanup(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)


class DartDependencySpelling(unittest.TestCase):
    """pubspec.yaml の書き方を変えても、依存の集合は同じでなければならない。"""

    SPELLINGS = {
        "2スペース": "name: a\ndependencies:\n  flutter:\n    sdk: flutter\n  dio: ^5.0.0\n",
        "4スペース": "name: a\ndependencies:\n    flutter:\n        sdk: flutter\n    dio: ^5.0.0\n",
        "順序を入れ替え": "name: a\ndependencies:\n  dio: ^5.0.0\n  flutter:\n    sdk: flutter\n",
        "コメント混在": "name: a\ndependencies:\n  # HTTP\n  dio: ^5.0.0\n\n  flutter:\n    sdk: flutter\n",
        "引用符つき": "name: a\ndependencies:\n  'dio': '^5.0.0'\n  flutter:\n    sdk: flutter\n",
        "フロー形式": "name: a\ndependencies: {dio: ^5.0.0, flutter: {sdk: flutter}}\n",
    }

    def test_every_spelling_yields_the_same_set(self) -> None:
        results = {}
        for label, text in self.SPELLINGS.items():
            fx = Fixture()
            try:
                fx.write("frontend/kotonoha_app/pubspec.yaml", text)
                results[label] = {name for name, _ in snapshot.dart_dependencies(fx.root)}
            finally:
                fx.cleanup()
        for label, names in results.items():
            self.assertEqual(names, {"dio", "flutter"}, "書き方「{0}」で結果が変わった".format(label))


class IosPlistSpelling(unittest.TestCase):
    """Info.plist のタグの書き方を変えても、権限キーの集合は同じでなければならない。"""

    SPELLINGS = {
        "1行": "<dict><key>NSMicrophoneUsageDescription</key><string>x</string></dict>",
        "タグ改行": "<dict><key\n>NSMicrophoneUsageDescription</key><string>x</string></dict>",
        "整形": (
            "<dict>\n  <key>NSMicrophoneUsageDescription</key>\n  <string>x</string>\n</dict>"
        ),
    }

    def test_every_spelling_yields_the_same_set(self) -> None:
        for label, body in self.SPELLINGS.items():
            fx = Fixture()
            try:
                fx.write("frontend/kotonoha_app/ios/Runner/Info.plist",
                         PLIST_HEADER + body + "</plist>")
                keys = {k for k, _ in snapshot.ios_privacy_keys(fx.root)}
            finally:
                fx.cleanup()
            self.assertEqual(
                keys, {"NSMicrophoneUsageDescription"}, "書き方「{0}」で結果が変わった".format(label)
            )


class AndroidManifestSpelling(unittest.TestCase):
    SPELLINGS = {
        "1行": ('<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
                '<uses-permission android:name="android.permission.CAMERA"/></manifest>'),
        "属性を改行": ('<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
                   '<uses-permission\n    android:name="android.permission.CAMERA"\n/></manifest>'),
        "単一引用符": ("<manifest xmlns:android='http://schemas.android.com/apk/res/android'>"
                  "<uses-permission android:name='android.permission.CAMERA'/></manifest>"),
    }

    def test_every_spelling_yields_the_same_set(self) -> None:
        for label, text in self.SPELLINGS.items():
            fx = Fixture()
            try:
                fx.write("frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml", text)
                names = {n for n, _ in snapshot.android_permissions(fx.root)}
            finally:
                fx.cleanup()
            self.assertEqual(
                names, {"android.permission.CAMERA"}, "書き方「{0}」で結果が変わった".format(label)
            )


class PythonDependencySpelling(unittest.TestCase):
    SPELLINGS = {
        "素": "fastapi==0.124.0\nredis==8.0.1\n",
        "extras つき": "fastapi[all]==0.124.0\nredis==8.0.1\n",
        "範囲指定": "fastapi>=0.124,<0.130\nredis~=8.0\n",
        "空白と大文字": "  FastAPI == 0.124.0\n\nRedis==8.0.1\n",
        "環境マーカー": "fastapi==0.124.0; python_version>='3.10'\nredis==8.0.1\n",
    }

    def test_every_spelling_yields_the_same_set(self) -> None:
        for label, text in self.SPELLINGS.items():
            fx = Fixture()
            try:
                fx.write("backend/requirements.txt", text)
                names = {n for n, _ in snapshot.python_dependencies(fx.root)}
            finally:
                fx.cleanup()
            self.assertEqual(names, {"fastapi", "redis"}, "書き方「{0}」で結果が変わった".format(label))


class VersionBumpIsNotANewSurface(unittest.TestCase):
    """バージョン更新は状態を変えない。dependabot の PR を毎回落とさないため。"""

    def test_python_version_bump(self) -> None:
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt", "fastapi==0.124.0\n")
            before = {n for n, _ in snapshot.python_dependencies(fx.root)}
            fx.write("backend/requirements.txt", "fastapi==0.128.6\n")
            after = {n for n, _ in snapshot.python_dependencies(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(before, after)

    def test_dart_version_bump(self) -> None:
        fx = Fixture()
        try:
            fx.write("frontend/kotonoha_app/pubspec.yaml", "dependencies:\n  go_router: ^17.0.1\n")
            before = {n for n, _ in snapshot.dart_dependencies(fx.root)}
            fx.write("frontend/kotonoha_app/pubspec.yaml", "dependencies:\n  go_router: ^17.1.0\n")
            after = {n for n, _ in snapshot.dart_dependencies(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(before, after)


class SecretKeyNamesAreNotJudged(unittest.TestCase):
    """`.env.example` は全キーを見る。名前で「秘密らしさ」を判定しない。

    判定を挟むと `URI` / `URL` / `DSN` を落とす。初回実装は
    `RATE_LIMIT_STORAGE_URI=redis://u:pass@h/0` を素通しした。
    """

    def test_uri_shaped_key_is_captured(self) -> None:
        fx = Fixture()
        try:
            fx.write(".env.example", "LOG_LEVEL=INFO\nRATE_LIMIT_STORAGE_URI=\nDATABASE_URL=\n")
            keys = {k for k, _ in snapshot.env_example_keys(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(keys, {"LOG_LEVEL", "RATE_LIMIT_STORAGE_URI", "DATABASE_URL"})


if __name__ == "__main__":
    unittest.main()
