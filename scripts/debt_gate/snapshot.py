"""いまのリポジトリの「状態」を、正規のパーサで読んで集合にする。

**ここが健全さの根拠である。** 各関数はフォーマットの正規パーサ（PyYAML / plistlib /
ElementTree）で読むので、書き方——indent 幅・タグの改行・行順・コメント・引用符——を
変えても返る集合は変わらない。差分の行は一切見ない。

読めなかったときは `SnapshotError` を送出する。**空集合を返してはならない**——
取得失敗を「何も無い」と区別できなくなり、初回実装の fail-open が再発する。
"""

from __future__ import annotations

import os
import plistlib
import re
import xml.etree.ElementTree as ET
from typing import Dict, List, Tuple

from .errors import SnapshotError

#: 状態の1件。id は許可リストのキー、detail は報告用の補足。
Item = Tuple[str, str]

ANDROID_NAME = "{http://schemas.android.com/apk/res/android}name"

#: iOS で「端末データへの到達面」を表すキー。
IOS_PRIVACY_EXTRA = frozenset({"UIBackgroundModes", "NSAppTransportSecurity"})


def _read(path: str, kind: str) -> bytes:
    if not os.path.isfile(path):
        raise SnapshotError(kind, path, "ファイルが存在しない")
    try:
        with open(path, "rb") as handle:
            return handle.read()
    except OSError as exc:
        raise SnapshotError(kind, path, "読み込みに失敗: {0}".format(type(exc).__name__))


# --------------------------------------------------------------------------
# 依存
# --------------------------------------------------------------------------

PUBSPEC_SECTIONS = ("dependencies", "dev_dependencies", "dependency_overrides")


def dart_dependencies(repo_root: str) -> List[Item]:
    """`pubspec.yaml` の宣言依存。**YAML パーサで読む**ので indent 幅に依存しない。"""
    kind = "dart_dependencies"
    path = os.path.join(repo_root, "frontend", "kotonoha_app", "pubspec.yaml")
    raw = _read(path, kind)
    try:
        import yaml
    except ImportError:
        raise SnapshotError(kind, path, "PyYAML が無い。ゲートを緑にせず落とす")
    try:
        doc = yaml.safe_load(raw.decode("utf-8"))
    except Exception as exc:
        raise SnapshotError(kind, path, "YAML として解釈できない: {0}".format(type(exc).__name__))
    if not isinstance(doc, dict):
        raise SnapshotError(kind, path, "最上位がマッピングでない")

    items: List[Item] = []
    for section in PUBSPEC_SECTIONS:
        block = doc.get(section)
        if block is None:
            continue
        if not isinstance(block, dict):
            raise SnapshotError(kind, path, "{0} がマッピングでない".format(section))
        for name in block:
            items.append((str(name), section))
    return items


REQ_NAME = re.compile(r"^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s*(?:\[[^\]]*\])?\s*(?:[=<>~!;@]|$)")
REQ_INCLUDE = re.compile(r"^\s*-r\s+(\S+)")


def _parse_requirements(path: str, kind: str, seen: Dict[str, str]) -> None:
    raw = _read(path, kind)
    directory = os.path.dirname(path)
    for line in raw.decode("utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        include = REQ_INCLUDE.match(stripped)
        if include:
            _parse_requirements(os.path.join(directory, include.group(1)), kind, seen)
            continue
        if stripped.startswith("-"):
            continue  # -e / --index-url 等
        match = REQ_NAME.match(stripped)
        if match:
            seen.setdefault(match.group(1).lower(), os.path.basename(path))


def python_dependencies(repo_root: str) -> List[Item]:
    """`backend/requirements*.txt` のパッケージ名。バージョンは見ない。

    バージョンを状態に含めると dependabot の更新で毎回発火し、ゲートを外す圧力になる。
    見張っているのは「**新しい外部の面**が増えたか」であって版数ではない。
    """
    kind = "python_dependencies"
    backend = os.path.join(repo_root, "backend")
    if not os.path.isdir(backend):
        raise SnapshotError(kind, backend, "backend/ が存在しない")
    seen: Dict[str, str] = {}
    found_any = False
    for name in sorted(os.listdir(backend)):
        if name.startswith("requirements") and name.endswith(".txt"):
            found_any = True
            _parse_requirements(os.path.join(backend, name), kind, seen)
    if not found_any:
        raise SnapshotError(kind, backend, "requirements*.txt が1つも無い")
    return sorted(seen.items())


# --------------------------------------------------------------------------
# モバイル権限
# --------------------------------------------------------------------------


def android_permissions(repo_root: str) -> List[Item]:
    """`AndroidManifest.xml` の権限。**XML パーサで読む**ので属性の書き方に依存しない。"""
    kind = "android_permissions"
    base = os.path.join(repo_root, "frontend", "kotonoha_app", "android")
    if not os.path.isdir(base):
        raise SnapshotError(kind, base, "android/ が存在しない")
    manifests = []
    for root, _dirs, files in os.walk(base):
        if "build" in root.split(os.sep):
            continue
        if "AndroidManifest.xml" in files:
            manifests.append(os.path.join(root, "AndroidManifest.xml"))
    if not manifests:
        raise SnapshotError(kind, base, "AndroidManifest.xml が1つも無い")

    items: List[Item] = []
    for path in sorted(manifests):
        raw = _read(path, kind)
        try:
            root_el = ET.fromstring(raw)
        except ET.ParseError as exc:
            raise SnapshotError(kind, path, "XML として解釈できない: {0}".format(exc))
        flavor = os.path.basename(os.path.dirname(path))
        for tag in ("uses-permission", "uses-permission-sdk-23", "uses-feature"):
            for element in root_el.iter(tag):
                name = element.get(ANDROID_NAME)
                if name:
                    items.append((name, "{0} / {1}".format(tag, flavor)))
    return items


def ios_privacy_keys(repo_root: str) -> List[Item]:
    """`Info.plist` の権限系キー。**plist パーサで読む**のでタグの改行に依存しない。"""
    kind = "ios_privacy_keys"
    path = os.path.join(repo_root, "frontend", "kotonoha_app", "ios", "Runner", "Info.plist")
    raw = _read(path, kind)
    try:
        doc = plistlib.loads(raw)
    except Exception as exc:
        raise SnapshotError(kind, path, "plist として解釈できない: {0}".format(type(exc).__name__))
    items: List[Item] = []
    for key in doc:
        if key.endswith("UsageDescription") or key in IOS_PRIVACY_EXTRA:
            items.append((key, "Info.plist"))
    return items


# --------------------------------------------------------------------------
# 設定キー
# --------------------------------------------------------------------------

ENV_KEY = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\s*=")


def env_example_keys(repo_root: str) -> List[Item]:
    """`.env.example` の**全キー**。「秘密かどうか」の名前判定はしない。

    判定を挟むと `URI` / `URL` / `DSN` を落とす（初回実装は
    `RATE_LIMIT_STORAGE_URI=redis://u:pass@h/0` を素通しした）。
    **全キーを許可リストで持つ方が、狭くて漏れる判定より良い**（ADR-008）。
    """
    kind = "env_example_keys"
    candidates = [
        os.path.join(repo_root, ".env.example"),
        os.path.join(repo_root, "backend", ".env.example"),
    ]
    present = [p for p in candidates if os.path.isfile(p)]
    if not present:
        raise SnapshotError(kind, ".env.example", "1つも存在しない")
    items: List[Item] = []
    for path in present:
        raw = _read(path, kind)
        label = os.path.relpath(path, repo_root)
        for line in raw.decode("utf-8", errors="replace").splitlines():
            match = ENV_KEY.match(line)
            if match:
                items.append((match.group(1), label))
    return items


#: ブロックする検査の一覧。Phase 2・3 で openapi_paths / import_side_effects /
#: hive_schema を足す（ADR-008 の表）。
SNAPSHOTS = [
    ("dart_dependencies", "Dart の依存", dart_dependencies),
    ("python_dependencies", "Python の依存", python_dependencies),
    ("android_permissions", "Android の権限", android_permissions),
    ("ios_privacy_keys", "iOS の権限キー", ios_privacy_keys),
    ("env_example_keys", "設定キー（.env.example）", env_example_keys),
]
