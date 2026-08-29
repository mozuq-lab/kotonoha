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
from scripts.debt_gate.errors import SnapshotError

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
                results[label] = {n.rsplit("/", 1)[1].split("@")[0]
                                  for n, _ in snapshot.dart_dependencies(fx.root)}
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
                keys = {k.split(":")[1] for k, _ in snapshot.ios_privacy_keys(fx.root)}
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
                names = {n.rsplit("/", 1)[1] for n, _ in snapshot.android_permissions(fx.root)}
            finally:
                fx.cleanup()
            self.assertEqual(
                names, {"android.permission.CAMERA"}, "書き方「{0}」で結果が変わった".format(label)
            )


def _req_names(items):
    """`<file>/<name>@<source>` から名前だけ取り出す。"""
    return {i.rsplit("/", 1)[1].split("@")[0] for i, _ in items}


class PythonDependencySpelling(unittest.TestCase):
    """PEP 508 パーサ（packaging）で読むので、有効な表記はすべて同じ名前になる。"""

    SPELLINGS = {
        "素": "fastapi==0.124.0\nredis==8.0.1\n",
        "extras つき": "fastapi[all]==0.124.0\nredis==8.0.1\n",
        "範囲指定": "fastapi>=0.124,<0.130\nredis~=8.0\n",
        "空白と大文字": "  FastAPI == 0.124.0\n\nRedis==8.0.1\n",
        "環境マーカー": "fastapi==0.124.0; python_version>='3.10'\nredis==8.0.1\n",
        "PEP508 の括弧": "fastapi (>=0.124)\nredis (>=8.0)\n",
        "行末コメント": "fastapi==0.124.0  # web\nredis==8.0.1  # cache\n",
        "行継続": "fastapi==0.124.0 \\\n\nredis==8.0.1\n",
    }

    def test_every_spelling_yields_the_same_set(self) -> None:
        for label, text in self.SPELLINGS.items():
            fx = Fixture()
            try:
                fx.write("backend/requirements.txt", text)
                names = _req_names(snapshot.python_dependencies(fx.root))
            finally:
                fx.cleanup()
            self.assertEqual(names, {"fastapi", "redis"}, "書き方「{0}」で結果が変わった".format(label))


class PythonDependencyEscapeHatches(unittest.TestCase):
    """索引以外から入る依存も面として数える。初回の再実装はすべて捨てていた。"""

    def test_vcs_url_is_captured(self) -> None:
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt", "git+https://github.com/psf/requests.git\n")
            names = _req_names(snapshot.python_dependencies(fx.root))
        finally:
            fx.cleanup()
        self.assertEqual(names, {"requests"})

    def test_editable_install_is_captured(self) -> None:
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt", "-e git+https://x/stripe-python.git#egg=stripe\n")
            names = _req_names(snapshot.python_dependencies(fx.root))
        finally:
            fx.cleanup()
        self.assertEqual(names, {"stripe"})

    def test_direct_wheel_url_is_captured(self) -> None:
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt",
                     "https://files.example.com/evil-1.0-py3-none-any.whl\n")
            names = _req_names(snapshot.python_dependencies(fx.root))
        finally:
            fx.cleanup()
        self.assertEqual(names, {"evil-1.0-py3-none-any"})

    def test_unparseable_line_is_an_error_not_a_silent_drop(self) -> None:
        """解釈できない行を捨てると素通しになる。取得失敗として落とす。"""
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt", "this is not a valid requirement !!!\n")
            with self.assertRaises(SnapshotError):
                snapshot.python_dependencies(fx.root)
        finally:
            fx.cleanup()

    def test_long_form_include_is_followed(self) -> None:
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt", "--requirement extra.txt\n")
            fx.write("backend/extra.txt", "redis==8.0.1\n")
            names = _req_names(snapshot.python_dependencies(fx.root))
        finally:
            fx.cleanup()
        self.assertEqual(names, {"redis"})

    def test_missing_include_target_is_an_error(self) -> None:
        fx = Fixture()
        try:
            fx.write("backend/requirements.txt", "-r nowhere.txt\n")
            with self.assertRaises(SnapshotError):
                snapshot.python_dependencies(fx.root)
        finally:
            fx.cleanup()


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


class EnvAssignmentSpelling(unittest.TestCase):
    """dotenv の有効な書き方は、すべて同じキー集合になる。"""

    SPELLINGS = {
        "素": "STRIPE_SECRET_KEY=x\n",
        "export 前置き": "export STRIPE_SECRET_KEY=x\n",
        "空白つき": "  STRIPE_SECRET_KEY = x\n",
    }

    def test_export_prefix_yields_the_same_key(self) -> None:
        for label, text in self.SPELLINGS.items():
            fx = Fixture()
            try:
                fx.write(".env.example", text)
                keys = {k.split(":")[1] for k, _ in snapshot.env_example_keys(fx.root)}
            finally:
                fx.cleanup()
            self.assertEqual(keys, {"STRIPE_SECRET_KEY"}, "書き方「{0}」で結果が変わった".format(label))

    def test_lowercase_key_is_captured(self) -> None:
        fx = Fixture()
        try:
            fx.write(".env.example", "stripe_secret_key=x\n")
            keys = {k.split(":")[1] for k, _ in snapshot.env_example_keys(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(keys, {"stripe_secret_key"})

    def test_unparseable_line_is_an_error(self) -> None:
        fx = Fixture()
        try:
            fx.write(".env.example", "これは代入ではない\n")
            with self.assertRaises(SnapshotError):
                snapshot.env_example_keys(fx.root)
        finally:
            fx.cleanup()


class DiscoveryNotHardcodedPaths(unittest.TestCase):
    """監視対象はパスの列挙ではなく探索で集める。列挙は必ず漏れる。"""

    def test_env_example_anywhere_is_found(self) -> None:
        fx = Fixture()
        try:
            fx.write("frontend/kotonoha_app/web/.env.example", "PUBLIC_URL=x\n")
            keys = {k for k, _ in snapshot.env_example_keys(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(keys, {"frontend/kotonoha_app/web/.env.example:PUBLIC_URL"})

    def test_pubspec_overrides_is_found(self) -> None:
        fx = Fixture()
        try:
            fx.write("frontend/kotonoha_app/pubspec.yaml", "dependencies:\n  dio: ^5.0.0\n")
            fx.write("frontend/kotonoha_app/pubspec_overrides.yaml",
                     "dependency_overrides:\n  firebase: ^1.0.0\n")
            names = {k for k, _ in snapshot.dart_dependencies(fx.root)}
        finally:
            fx.cleanup()
        self.assertTrue(any("pubspec_overrides.yaml" in n and "firebase" in n for n in names), names)

    def test_every_android_manifest_is_found(self) -> None:
        fx = Fixture()
        try:
            for flavor in ("main", "debug"):
                fx.write(
                    "frontend/kotonoha_app/android/app/src/{0}/AndroidManifest.xml".format(flavor),
                    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
                    '<uses-permission android:name="android.permission.CAMERA"/></manifest>',
                )
            names = {k for k, _ in snapshot.android_permissions(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(len(names), 2, "flavor ごとに別の面として数える: {0}".format(names))


class IdentityIncludesProvenance(unittest.TestCase):
    """名前だけを鍵にすると「既存名のまま面が広がる」変更を見逃す。"""

    def test_promoting_a_dev_dependency_changes_the_identity(self) -> None:
        fx = Fixture()
        try:
            fx.write("frontend/kotonoha_app/pubspec.yaml",
                     "dev_dependencies:\n  mocktail: ^1.0.0\n")
            before = {k for k, _ in snapshot.dart_dependencies(fx.root)}
            fx.write("frontend/kotonoha_app/pubspec.yaml",
                     "dependencies:\n  mocktail: ^1.0.0\ndev_dependencies:\n  mocktail: ^1.0.0\n")
            after = {k for k, _ in snapshot.dart_dependencies(fx.root)}
        finally:
            fx.cleanup()
        self.assertTrue(after - before, "dev → runtime の昇格が新しい面として現れること")

    def test_switching_the_supplier_changes_the_identity(self) -> None:
        """供給元を任意の git URL に差し替える変更は、名前だけでは見えない。"""
        fx = Fixture()
        try:
            fx.write("frontend/kotonoha_app/pubspec.yaml", "dependencies:\n  dio: ^5.0.0\n")
            before = {k for k, _ in snapshot.dart_dependencies(fx.root)}
            fx.write("frontend/kotonoha_app/pubspec.yaml",
                     "dependencies:\n  dio:\n    git: https://evil.invalid/dio.git\n")
            after = {k for k, _ in snapshot.dart_dependencies(fx.root)}
        finally:
            fx.cleanup()
        self.assertTrue(after - before, "供給元の差し替えが新しい面として現れること")


class YamlScalarQuirks(unittest.TestCase):
    """YAML は引用符の無い yes/no/on/off を真偽値にする。名前として扱うこと。"""

    def test_quoted_and_unquoted_yes_are_the_same_package(self) -> None:
        results = []
        for text in ('dependencies:\n  "yes": ^1.0.0\n', "dependencies:\n  yes: ^1.0.0\n"):
            fx = Fixture()
            try:
                fx.write("frontend/kotonoha_app/pubspec.yaml", text)
                results.append({k for k, _ in snapshot.dart_dependencies(fx.root)})
            finally:
                fx.cleanup()
        self.assertEqual(results[0], results[1], "引用符の有無で集合が変わってはならない")


class SecretKeyNamesAreNotJudged(unittest.TestCase):
    """`.env.example` は全キーを見る。名前で「秘密らしさ」を判定しない。

    判定を挟むと `URI` / `URL` / `DSN` を落とす。初回実装は
    `RATE_LIMIT_STORAGE_URI=redis://u:pass@h/0` を素通しした。
    """

    def test_uri_shaped_key_is_captured(self) -> None:
        fx = Fixture()
        try:
            fx.write(".env.example", "LOG_LEVEL=INFO\nRATE_LIMIT_STORAGE_URI=\nDATABASE_URL=\n")
            keys = {k.split(":")[1] for k, _ in snapshot.env_example_keys(fx.root)}
        finally:
            fx.cleanup()
        self.assertEqual(keys, {"LOG_LEVEL", "RATE_LIMIT_STORAGE_URI", "DATABASE_URL"})


if __name__ == "__main__":
    unittest.main()
