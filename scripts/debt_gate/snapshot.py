"""いまのリポジトリの「状態」を、正規のパーサで読んで集合にする。

**ここが健全さの根拠である。** 各関数はフォーマットの正規パーサ
（PyYAML / packaging / plistlib / ElementTree）で読むので、書き方——indent 幅・
タグの改行・行順・コメント・引用符・`export` 前置き——を変えても返る集合は変わらない。
差分の行は見ないし、git も使わない。

設計上の3つの規律（いずれも2系統レビューの指摘で入った）:

1. **読めなかったら `SnapshotError`。空集合を返してはならない。** 取得失敗を
   「何も無い」と区別できなくなり、fail-open が再発する。**解釈できない行が1行でも
   あればエラーにする**——初回の再実装は未解釈行を黙って捨て、
   `git+https://...` や `redis-om (>=0.2)` を素通しさせた
2. **監視対象はパスを列挙せず、探索する。** ハードコードの列挙は「ファイルパスの
   列挙ゲーム」になる。実際、追跡済みの `frontend/kotonoha_app/web/.env.example` が
   完全に不可視だった
3. **識別子は名前だけにしない。** `dev_dependencies` の依存を `dependencies` へ
   昇格させる、`debug` の権限を `main` へ移す、といった「既存名のまま面が広がる」
   変更を捕まえるため、**出どころを識別子に含める**
"""

from __future__ import annotations

import os
import plistlib
import re
import xml.etree.ElementTree as ET
from typing import Callable, Dict, List, Tuple

from .errors import SnapshotError

#: 状態の1件。id は許可リストのキー、detail は報告用の補足。
Item = Tuple[str, str]

ANDROID_NAME = "{http://schemas.android.com/apk/res/android}name"

#: iOS で「端末データへの到達面」を表す、UsageDescription 以外のキー。
IOS_PRIVACY_EXTRA = frozenset({"UIBackgroundModes", "NSAppTransportSecurity"})

#: 探索から除くディレクトリ。生成物・依存キャッシュ・VCS。
SKIP_DIRS = frozenset({
    "build", ".dart_tool", ".git", "node_modules", ".venv", "venv",
    "__pycache__", ".pub-cache", "Pods", ".idea", ".vscode", "htmlcov",
})


def discover(repo_root: str, matcher: Callable[[str], bool]) -> List[str]:
    """条件に合うファイルをリポジトリ全体から探す。

    パスをハードコードしない。列挙は必ず漏れる（`web/.env.example` の前例）。
    """
    found: List[str] = []
    for root, dirs, files in os.walk(repo_root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".claude")]
        for name in files:
            if matcher(name):
                found.append(os.path.join(root, name))
    return sorted(found)


def _rel(repo_root: str, path: str) -> str:
    return os.path.relpath(path, repo_root).replace(os.sep, "/")


def _read(path: str, kind: str) -> bytes:
    try:
        with open(path, "rb") as handle:
            return handle.read()
    except OSError as exc:
        raise SnapshotError(kind, path, "読み込みに失敗: {0}".format(type(exc).__name__))


def _require(paths: List[str], kind: str, what: str) -> None:
    if not paths:
        raise SnapshotError(kind, what, "対象ファイルが1つも見つからない")


# --------------------------------------------------------------------------
# 依存（Dart）
# --------------------------------------------------------------------------

PUBSPEC_SECTIONS = ("dependencies", "dev_dependencies", "dependency_overrides")


def _dart_source_kind(spec: object) -> str:
    """依存の供給元の形。`hosted` / `git` / `path` / `sdk`。

    供給元を差し替える変更（`dio: ^5.0.0` → `dio: {git: <任意のURL>}`）は
    パッケージ名が変わらないので、名前だけを見ていると素通しする。
    """
    if spec is None or isinstance(spec, str):
        return "hosted"
    if isinstance(spec, dict):
        for key in ("git", "path", "sdk", "hosted"):
            if key in spec:
                return key
    return "unknown"


def dart_dependencies(repo_root: str) -> List[Item]:
    """`pubspec.yaml` / `pubspec_overrides.yaml` の宣言依存。

    **YAML パーサで読む**ので indent 幅・行順・コメント・フロー形式に依存しない。
    識別子は ``<ファイル>:<セクション>/<名前>@<供給元>``。
    """
    kind = "dart_dependencies"
    paths = discover(repo_root, lambda n: n in ("pubspec.yaml", "pubspec_overrides.yaml"))
    _require(paths, kind, "pubspec*.yaml")
    try:
        import yaml
    except ImportError:
        raise SnapshotError(kind, "PyYAML", "PyYAML が無い。ゲートを緑にせず落とす")

    items: List[Item] = []
    for path in paths:
        raw = _read(path, kind)
        label = _rel(repo_root, path)
        try:
            # **BaseLoader を使う。** safe_load は引用符の無い yes/no/on/off を
            # 真偽値へ解決してしまい、`"yes":` と `yes:` で集合が変わる
            # （＝意味を変えない整形で CI が止まる。独立レビューの指摘）。
            # BaseLoader は全スカラーを文字列のまま返すので、綴りが保たれる。
            doc = yaml.load(raw.decode("utf-8"), Loader=yaml.BaseLoader)
        except Exception as exc:
            raise SnapshotError(kind, label, "YAML として解釈できない: {0}".format(type(exc).__name__))
        if doc is None:
            continue
        if not isinstance(doc, dict):
            raise SnapshotError(kind, label, "最上位がマッピングでない")
        for section in PUBSPEC_SECTIONS:
            block = doc.get(section)
            if block is None:
                continue
            if not isinstance(block, dict):
                raise SnapshotError(kind, label, "{0} がマッピングでない".format(section))
            for name, spec in block.items():
                text = str(name)
                items.append((
                    "{0}:{1}/{2}@{3}".format(label, section, text, _dart_source_kind(spec)),
                    "{0} の {1}".format(label, section),
                ))
    return items


# --------------------------------------------------------------------------
# 依存（Python）
# --------------------------------------------------------------------------

#: pip の requirements 行のうち、依存を表さないオプション。
_REQ_NON_DEP_OPTIONS = (
    "--index-url", "-i", "--extra-index-url", "--find-links", "-f",
    "--no-index", "--trusted-host", "--pre", "--constraint", "-c",
    "--only-binary", "--no-binary", "--require-hashes", "--hash",
)
_REQ_INCLUDE = re.compile(r"^\s*(?:-r|--requirement)[\s=]+(\S+)")
_REQ_EDITABLE = re.compile(r"^\s*(?:-e|--editable)[\s=]+(\S+)")
_EGG_FRAGMENT = re.compile(r"[#&]egg=([A-Za-z0-9._-]+)")


def _name_from_url(spec: str) -> str:
    """直 URL / VCS 指定からパッケージ名を取る。取れなければ URL そのものを名前にする。

    名前が確定できなくても**面としては存在する**ので、集合に入れる。
    捨てると素通しになる（初回の再実装は `git+https://…` を捨てていた）。
    """
    egg = _EGG_FRAGMENT.search(spec)
    if egg:
        return egg.group(1).lower()
    tail = spec.split("#", 1)[0].rstrip("/").rsplit("/", 1)[-1]
    for suffix in (".git", ".whl", ".tar.gz", ".zip"):
        if tail.endswith(suffix):
            tail = tail[: -len(suffix)]
            break
    return (tail or spec).lower()


def _parse_requirements(path: str, label: str, kind: str, out: Dict[str, str],
                        seen_files: set, repo_root: str) -> None:
    from packaging.requirements import InvalidRequirement, Requirement

    real = os.path.realpath(path)
    if real in seen_files:
        return
    seen_files.add(real)
    raw = _read(path, kind)
    directory = os.path.dirname(path)

    # 行継続（バックスラッシュ）を畳んでから解釈する
    text = raw.decode("utf-8", errors="replace").replace("\\\n", " ")
    for lineno, line in enumerate(text.splitlines(), start=1):
        stripped = line.split(" #", 1)[0].strip()
        if not stripped or stripped.startswith("#"):
            continue

        include = _REQ_INCLUDE.match(stripped)
        if include:
            nested = os.path.join(directory, include.group(1))
            if not os.path.isfile(nested):
                raise SnapshotError(kind, label, "{0} 行目の include 先が無い".format(lineno))
            _parse_requirements(nested, _rel(repo_root, nested), kind, out, seen_files, repo_root)
            continue

        editable = _REQ_EDITABLE.match(stripped)
        if editable:
            out.setdefault("{0}/{1}@editable".format(label, _name_from_url(editable.group(1))), label)
            continue

        if stripped.startswith(_REQ_NON_DEP_OPTIONS):
            continue
        if stripped.startswith("-"):
            raise SnapshotError(kind, label, "{0} 行目の未知のオプション: {1}".format(lineno, stripped[:40]))

        if "://" in stripped and not stripped[0].isalnum():
            raise SnapshotError(kind, label, "{0} 行目を解釈できない".format(lineno))
        if "://" in stripped.split(";")[0] and "@" not in stripped.split("://")[0]:
            out.setdefault("{0}/{1}@url".format(label, _name_from_url(stripped)), label)
            continue

        try:
            requirement = Requirement(stripped)
        except InvalidRequirement:
            # **捨てない。** 解釈できない行があること自体が取得失敗である。
            raise SnapshotError(kind, label, "{0} 行目を解釈できない: {1}".format(lineno, stripped[:40]))
        source = "url" if requirement.url else "index"
        out.setdefault("{0}/{1}@{2}".format(label, requirement.name.lower(), source), label)


def python_dependencies(repo_root: str) -> List[Item]:
    """`requirements*.txt` のパッケージ名。**PEP 508 パーサ（packaging）で読む。**

    バージョンは見ない。バージョンを状態に含めると dependabot の更新で毎回発火し、
    ゲートを外す圧力になる。見張っているのは「新しい外部の面」であって版数ではない。
    """
    kind = "python_dependencies"
    paths = discover(
        repo_root,
        lambda n: n.startswith("requirements") and n.endswith(".txt"),
    )
    _require(paths, kind, "requirements*.txt")
    out: Dict[str, str] = {}
    seen: set = set()
    for path in paths:
        _parse_requirements(path, _rel(repo_root, path), kind, out, seen, repo_root)
    return sorted(out.items())


# --------------------------------------------------------------------------
# モバイル権限
# --------------------------------------------------------------------------


def android_permissions(repo_root: str) -> List[Item]:
    """`AndroidManifest.xml` の権限。**XML パーサで読む。**

    識別子に flavor（main / debug / profile）を含める。`debug` にしか無かった権限が
    `main` へ移る変更は、名前だけを見ていると素通しする。
    """
    kind = "android_permissions"
    paths = discover(repo_root, lambda n: n == "AndroidManifest.xml")
    _require(paths, kind, "AndroidManifest.xml")
    items: List[Item] = []
    for path in paths:
        label = _rel(repo_root, path)
        try:
            root_el = ET.fromstring(_read(path, kind))
        except ET.ParseError as exc:
            raise SnapshotError(kind, label, "XML として解釈できない: {0}".format(exc))
        for tag in ("uses-permission", "uses-permission-sdk-23", "uses-feature"):
            for element in root_el.iter(tag):
                name = element.get(ANDROID_NAME)
                if name:
                    items.append(("{0}:{1}/{2}".format(label, tag, name), label))
    return items


def ios_privacy_keys(repo_root: str) -> List[Item]:
    """`Info.plist` の権限系キー。**plist パーサで読む**のでタグの改行に依存しない。"""
    kind = "ios_privacy_keys"
    paths = discover(repo_root, lambda n: n == "Info.plist")
    _require(paths, kind, "Info.plist")
    items: List[Item] = []
    for path in paths:
        label = _rel(repo_root, path)
        try:
            doc = plistlib.loads(_read(path, kind))
        except Exception as exc:
            raise SnapshotError(kind, label, "plist として解釈できない: {0}".format(type(exc).__name__))
        if not isinstance(doc, dict):
            raise SnapshotError(kind, label, "最上位が辞書でない")
        for key in doc:
            if key.endswith("UsageDescription") or key in IOS_PRIVACY_EXTRA:
                items.append(("{0}:{1}".format(label, key), label))
    return items


# --------------------------------------------------------------------------
# 設定キー
# --------------------------------------------------------------------------

#: dotenv の代入行。`export` 前置き・小文字・先頭アンダースコアを受ける。
ENV_ASSIGNMENT = re.compile(r"^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=")


def env_example_keys(repo_root: str) -> List[Item]:
    """`*.env.example` の**全キー**。「秘密かどうか」の名前判定はしない。

    判定を挟むと `URI` / `URL` / `DSN` を落とす（初回実装は
    `RATE_LIMIT_STORAGE_URI=redis://u:pass@h/0` を素通しした）。
    構文による除外もしない——`export KEY=` も小文字キーも dotenv の有効表記である。
    **代入行として解釈できない行があればエラーにする**（黙って捨てない）。
    """
    kind = "env_example_keys"
    paths = discover(repo_root, lambda n: n == ".env.example" or n.endswith(".env.example"))
    _require(paths, kind, "*.env.example")
    items: List[Item] = []
    for path in paths:
        label = _rel(repo_root, path)
        raw = _read(path, kind)
        for lineno, line in enumerate(raw.decode("utf-8", errors="replace").splitlines(), start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            match = ENV_ASSIGNMENT.match(line)
            if not match:
                raise SnapshotError(kind, label, "{0} 行目を代入として解釈できない".format(lineno))
            items.append(("{0}:{1}".format(label, match.group(1)), label))
    return items


#: ブロックする検査。Phase 2 で openapi_operations / import_side_effects、
#: Phase 3 で hive_schema を足す（ADR-008 の表）。
SNAPSHOTS = [
    ("dart_dependencies", "Dart の依存", dart_dependencies),
    ("python_dependencies", "Python の依存", python_dependencies),
    ("android_permissions", "Android の権限", android_permissions),
    ("ios_privacy_keys", "iOS の権限キー", ios_privacy_keys),
    ("env_example_keys", "設定キー（.env.example）", env_example_keys),
]
