"""負債ゲート7項目のうち、AST 以外の6項目の検出器。

いずれも **追加行だけ** を見る。削除で発火させると、Phase 2（DB 依存の削除）や
Phase 3（`isFavorite` の削除）という計画自身の作業を塞いでしまう。

このゲートは既知の入口を検出する補助であって、負債の網羅ではない。
既存送信先への payload 追加・既存ルートの認証弱体化・破壊的 migration のような
「意味的な変更」は素通しする（是正計画 Phase 1）。それらは層1（前段の影響範囲）と
層3（差分レビュー）が担う。
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Callable, List, Optional, Set, Tuple

from .ast_globals import find_dart_top_level_mutables, find_python_module_globals
from .finding import Finding


@dataclass
class ChangedFile:
    """1ファイルの変更。追加行は (新しい側の行番号, 行の内容)。"""

    path: str
    old_content: Optional[str] = None
    new_content: Optional[str] = None
    added: List[Tuple[int, str]] = field(default_factory=list)

    @property
    def is_new(self) -> bool:
        return self.old_content is None


def _is_comment_only(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("#") or stripped.startswith("//") or not stripped


def _added_code_lines(changed: ChangedFile) -> List[Tuple[int, str]]:
    return [(n, t) for n, t in changed.added if not _is_comment_only(t)]


# --------------------------------------------------------------------------
# 1. 依存の追加
# --------------------------------------------------------------------------

_REQ_NAME = re.compile(r"^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s*(?:\[[^\]]*\])?\s*(?:[=<>~!@]|$)")
_PUBSPEC_TOP = re.compile(r"^([a-z_][a-z0-9_]*):")
_PUBSPEC_DEP = re.compile(r"^  ([a-z_][a-z0-9_]*):")
_PUBSPEC_DEP_SECTIONS = frozenset({"dependencies", "dev_dependencies", "dependency_overrides"})

_WHY_DEPENDENCY = "新しい外部の面が増える。今回の DB も Redis もここから入った"


def _requirements_names(content: Optional[str]) -> Set[str]:
    names: Set[str] = set()
    for line in (content or "").splitlines():
        if _is_comment_only(line):
            continue
        match = _REQ_NAME.match(line)
        if match:
            names.add(match.group(1).lower())
    return names


def _pubspec_names(content: Optional[str]) -> Set[str]:
    names: Set[str] = set()
    section: Optional[str] = None
    for line in (content or "").splitlines():
        top = _PUBSPEC_TOP.match(line)
        if top:
            section = top.group(1)
            continue
        if section in _PUBSPEC_DEP_SECTIONS:
            dep = _PUBSPEC_DEP.match(line)
            if dep:
                names.add(dep.group(1).lower())
    return names


def _pubspec_section_of_line(content: Optional[str], lineno: int) -> Optional[str]:
    section: Optional[str] = None
    for index, line in enumerate((content or "").splitlines(), start=1):
        top = _PUBSPEC_TOP.match(line)
        if top:
            section = top.group(1)
        if index == lineno:
            return section
    return None


def detect_dependency(changed: ChangedFile) -> List[Finding]:
    """依存の追加。**新しいパッケージ名だけ**を見る。

    バージョン更新（``sqlalchemy==2.0.44`` → ``2.0.46``）では発火しない。
    ここで発火させると dependabot の PR が毎回落ち、ゲートを止める圧力になる。
    """
    path = changed.path
    findings: List[Finding] = []

    if re.search(r"(^|/)requirements[^/]*\.txt$", path):
        known = _requirements_names(changed.old_content)
        for lineno, text in _added_code_lines(changed):
            match = _REQ_NAME.match(text)
            if not match:
                continue
            name = match.group(1).lower()
            if name in known:
                continue
            adr = None
            if name in {"sqlalchemy", "alembic", "asyncpg", "psycopg2-binary", "psycopg", "aiosqlite"}:
                adr = "ADR-001"
            elif name in {"redis", "aioredis", "hiredis"}:
                adr = "ADR-002"
            findings.append(
                Finding("dependency", path, lineno, text.strip(), _WHY_DEPENDENCY, adr)
            )
        return findings

    if path.endswith("pubspec.yaml"):
        known = _pubspec_names(changed.old_content)
        for lineno, text in _added_code_lines(changed):
            dep = _PUBSPEC_DEP.match(text)
            if not dep:
                continue
            if _pubspec_section_of_line(changed.new_content, lineno) not in _PUBSPEC_DEP_SECTIONS:
                continue
            name = dep.group(1).lower()
            if name in known:
                continue
            findings.append(
                Finding("dependency", path, lineno, text.strip(), _WHY_DEPENDENCY, None)
            )
    return findings


# --------------------------------------------------------------------------
# 2. 永続化面の追加
# --------------------------------------------------------------------------

_PERSISTENCE_DART = [
    (re.compile(r"@HiveType\s*\("), "ADR-005"),
    (re.compile(r"@HiveField\s*\("), "ADR-005"),
    (re.compile(r"extends\s+TypeAdapter\b"), "ADR-005"),
    (re.compile(r"registerAdapter\s*\("), "ADR-005"),
    (re.compile(r"\bopenBox(?:<[^>]*>)?\s*\("), "ADR-005"),
    (re.compile(r"\.writeAsString\s*\(|\.writeAsBytes\s*\("), None),
    (re.compile(r"getApplicationDocumentsDirectory\s*\(|getApplicationSupportDirectory\s*\("), None),
]

_PERSISTENCE_PY = [
    (re.compile(r"__tablename__\s*="), "ADR-001"),
    (re.compile(r"\bmapped_column\s*\(|(?<![\w.])Column\s*\("), "ADR-001"),
    (re.compile(r"\bop\.(create_table|add_column|create_index)\s*\("), "ADR-001"),
    (re.compile(r"^\s*class\s+\w+\s*\([^)]*\bBase\b[^)]*\)\s*:"), "ADR-001"),
    (re.compile(r"\bopen\s*\([^)]*[\"'][arwx]\+?b?[\"']"), None),
    (re.compile(r"\.write_text\s*\(|\.write_bytes\s*\("), None),
]

_WHY_PERSISTENCE = "一度書いたら消えないものが増える。プライバシー契約に直結する"


def detect_persistence(changed: ChangedFile) -> List[Finding]:
    """永続化面（Hive・DB テーブル・ファイル出力先）の追加。"""
    path = changed.path
    if path.endswith(".dart"):
        rules = _PERSISTENCE_DART
    elif path.endswith(".py"):
        rules = _PERSISTENCE_PY
    else:
        return []

    findings: List[Finding] = []
    for lineno, text in _added_code_lines(changed):
        for pattern, adr in rules:
            if pattern.search(text):
                findings.append(
                    Finding("persistence", path, lineno, text.strip(), _WHY_PERSISTENCE, adr)
                )
                break
    return findings


# --------------------------------------------------------------------------
# 3. 秘密を持つ設定キーの追加
# --------------------------------------------------------------------------

_SECRET_WORD = re.compile(
    r"(SECRET|PASSWORD|PASSPHRASE|TOKEN|API_?KEY|APIKEY|CREDENTIAL|PRIVATE_KEY|ACCESS_KEY)",
    re.IGNORECASE,
)
_ENV_KEY = re.compile(r"^\s*#?\s*([A-Z][A-Z0-9_]*)\s*=")
_WHY_SECRET = "秘密が到達しうる面が増える。秘匿は『漏らさないよう注意する』ではなく『渡す先が無い』にする"


def detect_secret_config(changed: ChangedFile) -> List[Finding]:
    """``SecretStr`` フィールドと ``.env.example`` の秘密キーの追加。"""
    path = changed.path
    findings: List[Finding] = []

    if path.endswith(".env.example") or path.endswith("/.env.example") or path == ".env.example":
        existing = set()
        for line in (changed.old_content or "").splitlines():
            match = _ENV_KEY.match(line)
            if match:
                existing.add(match.group(1))
        for lineno, text in changed.added:
            match = _ENV_KEY.match(text)
            if not match:
                continue
            key = match.group(1)
            if key in existing or not _SECRET_WORD.search(key):
                continue
            findings.append(
                Finding("secret_config", path, lineno, text.strip(), _WHY_SECRET, "ADR-004")
            )
        return findings

    if path.endswith(".py"):
        for lineno, text in _added_code_lines(changed):
            if "SecretStr" in text:
                findings.append(
                    Finding("secret_config", path, lineno, text.strip(), _WHY_SECRET, "ADR-004")
                )
    return findings


# --------------------------------------------------------------------------
# 4. モジュールレベルの可変グローバル・副作用（AST）
# --------------------------------------------------------------------------


def detect_module_global(changed: ChangedFile) -> List[Finding]:
    """AST（Python）／行ベース（Dart）で検出し、追加行に載るものだけ残す。"""
    if changed.new_content is None:
        return []
    if changed.path.endswith(".py"):
        candidates = find_python_module_globals(changed.new_content, changed.path)
    elif changed.path.endswith(".dart"):
        candidates = find_dart_top_level_mutables(changed.new_content, changed.path)
    else:
        return []

    added_lines = {n for n, _ in changed.added}
    return [f for f in candidates if f.line in added_lines]


# --------------------------------------------------------------------------
# 5. 公開ルート（HTTP 面）の追加
# --------------------------------------------------------------------------

_ROUTE_PATTERNS = [
    re.compile(r"@\s*\w+\.(get|post|put|patch|delete|head|options|api_route|websocket)\s*\("),
    re.compile(r"\badd_api_route\s*\(|\badd_websocket_route\s*\("),
    re.compile(r"\binclude_router\s*\("),
    re.compile(r"\.mount\s*\("),
]
_WHY_ROUTE = "漏えいシンクの4つ目『HTTP レスポンス』がここから増える。GET /debug/config は他の項目に一切触れずに書ける"


def detect_http_route(changed: ChangedFile) -> List[Finding]:
    """公開ルートの追加。"""
    if not changed.path.endswith(".py"):
        return []
    findings: List[Finding] = []
    for lineno, text in _added_code_lines(changed):
        for pattern in _ROUTE_PATTERNS:
            if pattern.search(text):
                findings.append(
                    Finding("http_route", changed.path, lineno, text.strip(), _WHY_ROUTE, "ADR-001")
                )
                break
    return findings


# --------------------------------------------------------------------------
# 6. 外部送信先の追加
# --------------------------------------------------------------------------

_URL_LITERAL = re.compile(r"[\"'`](https?)://([^/\s\"'`)]+)")
_HTTP_CLIENT = re.compile(
    r"\bhttpx\.|\brequests\.|\baiohttp\.|\burllib\.request\b|\bDio\s*\(|\bHttpClient\s*\("
    r"|\bhttp\.(get|post|put|patch|delete)\s*\(|\bWebSocket\s*\("
)
#: 送信先として数えないホスト。ローカル・スキーマ URI・プレースホルダのみ。
ALLOWED_HOSTS = frozenset(
    {
        "localhost",
        "localhost:8000",
        "127.0.0.1",
        "127.0.0.1:8000",
        "0.0.0.0",
        "example.com",
        "example.org",
        "www.w3.org",
        "schemas.android.com",
        "schemas.microsoft.com",
        "www.apple.com",
    }
)
_WHY_EGRESS = "ユーザーテキストが外へ出る面。既存依存で書けるため依存ゲートでは捕まらない"


def _hosts_in(content: Optional[str]) -> Set[str]:
    return {m.group(2).lower() for m in _URL_LITERAL.finditer(content or "")}


def detect_egress(changed: ChangedFile) -> List[Finding]:
    """新しい URL リテラルと HTTP クライアント呼び出しの追加。"""
    path = changed.path
    if not (path.endswith(".py") or path.endswith(".dart") or path.endswith(".ts")):
        return []
    if "/tests/" in path or path.endswith("_test.dart") or "/test/" in path:
        return []

    known_hosts = _hosts_in(changed.old_content)
    had_client = bool(_HTTP_CLIENT.search(changed.old_content or ""))
    findings: List[Finding] = []
    reported_client = False

    for lineno, text in _added_code_lines(changed):
        for match in _URL_LITERAL.finditer(text):
            host = match.group(2).lower()
            if host in ALLOWED_HOSTS or host in known_hosts:
                continue
            if host.startswith("localhost:") or host.startswith("127.0.0.1:"):
                continue
            findings.append(
                Finding("egress", path, lineno, text.strip(), _WHY_EGRESS, "ADR-001")
            )
            break
        if not had_client and not reported_client and _HTTP_CLIENT.search(text):
            reported_client = True
            findings.append(
                Finding(
                    "egress",
                    path,
                    lineno,
                    text.strip(),
                    "このファイルに HTTP クライアント呼び出しが新しく現れた（外部送信の面が1つ増える）",
                    "ADR-001",
                )
            )
    return findings


# --------------------------------------------------------------------------
# 7. モバイル権限の追加
# --------------------------------------------------------------------------

_ANDROID_PERMISSION = re.compile(r"<uses-permission|<uses-feature")
_IOS_PRIVACY_KEY = re.compile(r"<key>\s*(NS\w*UsageDescription|UIBackgroundModes|NSAppTransportSecurity)\s*</key>")
_WHY_PERMISSION = "端末データへの到達面が増える。プライバシー優先のこの製品では依存追加と同格の負債"


def detect_mobile_permission(changed: ChangedFile) -> List[Finding]:
    """``AndroidManifest.xml`` / ``Info.plist`` の権限キーの追加。"""
    path = changed.path
    if path.endswith("AndroidManifest.xml"):
        pattern = _ANDROID_PERMISSION
    elif path.endswith("Info.plist"):
        pattern = _IOS_PRIVACY_KEY
    else:
        return []

    findings: List[Finding] = []
    for lineno, text in changed.added:
        if pattern.search(text):
            findings.append(
                Finding("mobile_permission", path, lineno, text.strip(), _WHY_PERMISSION, None)
            )
    return findings


#: 7項目。順序は是正計画 Phase 1 の表と揃えている。
DETECTORS: List[Tuple[str, str, Callable[[ChangedFile], List[Finding]]]] = [
    ("dependency", "依存の追加", detect_dependency),
    ("persistence", "永続化面の追加", detect_persistence),
    ("secret_config", "秘密を持つ設定キーの追加", detect_secret_config),
    ("module_global", "モジュールレベルの可変グローバル・副作用の追加", detect_module_global),
    ("http_route", "公開ルート（HTTP 面）の追加", detect_http_route),
    ("egress", "外部送信先の追加", detect_egress),
    ("mobile_permission", "モバイル権限の追加", detect_mobile_permission),
]

RULE_LABELS = {rule: label for rule, label, _ in DETECTORS}


def run_detectors(changed: ChangedFile) -> List[Finding]:
    """1ファイルに7項目すべてを当てる。"""
    findings: List[Finding] = []
    for _, _, detector in DETECTORS:
        findings.extend(detector(changed))
    return findings
