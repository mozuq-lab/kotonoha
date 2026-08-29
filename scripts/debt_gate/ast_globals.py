"""ゲート項目4「モジュールレベルの可変グローバル・副作用の追加」の検出器。

7項目のうちこの項目だけ AST ベースにしている。grep では

- ``@router.post`` や ``logger = getLogger(__name__)`` を誤検知する
- ``client = X()`` のような代入を伴う資源生成を見逃す
- 代入を伴わない ``register_x()`` 形（独立レビューの反例）を拾えない

が避けられないため（是正計画 §5 Phase 1）。

Dart 側にはこのプロセスから使える AST パーサが無いので、トップレベル可変変数のみを
行ベースで拾う保守的な実装にしてある。厳密な検査は Phase 3 の Dart analyzer ルールが担う。
"""

from __future__ import annotations

import ast
import re
from typing import List, Optional, Set

from .finding import Finding

#: 呼び出しても「可変グローバル資源を作った」とは見なさない callee。
#: ここに載っていない呼び出しの結果をモジュールレベルへ束縛すると発火する。
ALLOWED_CALL_FACTORIES: Set[str] = {
    # ロガーの取得は logging 設定そのものではない（出力先は logging 側で決まる）
    "logging.getLogger",
    "getLogger",
    "structlog.get_logger",
    "get_logger",  # 本プロジェクトの logging ラッパ
    # FastAPI のルータ／セキュリティスキームはモジュールレベルが標準の置き方
    "APIRouter",
    "fastapi.APIRouter",
    "Depends",
    "fastapi.Depends",
    "APIKeyHeader",
    "HTTPBearer",
    # 不変値を作る呼び出し
    "frozenset",
    "tuple",
    "re.compile",
    "Path",
    "pathlib.Path",
    # 型システム上の宣言
    "TypeVar",
    "typing.TypeVar",
    "NewType",
    "typing.NewType",
    "namedtuple",
    "collections.namedtuple",
}

#: 代入を伴わないモジュールレベルの呼び出しで、副作用と見なさないもの。
#: 既定では空。「import しただけで資源を作る」を作らないため、原則すべて発火させる。
ALLOWED_BARE_CALLS: Set[str] = set()

#: 値に呼び出しを含まない代入のうち、定数と見なす名前の形。
_CONST_NAME = re.compile(r"^_?[A-Z][A-Z0-9_]*$")

#: 型エイリアス（``X = Literal[...]``）の右辺に現れる typing 構成子。
TYPING_CONSTRUCTORS = frozenset(
    {
        "Literal",
        "Union",
        "Optional",
        "Annotated",
        "Callable",
        "Final",
        "ClassVar",
        "Dict",
        "List",
        "Tuple",
        "Set",
        "Type",
        "Sequence",
        "Mapping",
        "Iterable",
    }
)

_WHY_GLOBAL = "モジュールレベルの可変グローバルは split-brain の入口になる（環境判定が3ファイルに散った前例）"
_WHY_RESOURCE = "import しただけで資源を作ると、設定の差し替えもテストの分離もできなくなる"
_WHY_SIDE_EFFECT = "代入を伴わないモジュールレベルの呼び出しは、import が副作用を持つことを意味する"


def _callee_name(node: ast.AST) -> Optional[str]:
    """呼び出しの callee をドット区切りの名前にする。解決できなければ None。"""
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        base = _callee_name(node.value)
        if base is None:
            return node.attr
        return "{0}.{1}".format(base, node.attr)
    return None


def _first_call(node: ast.AST) -> Optional[ast.Call]:
    """式の中に現れる最初の呼び出しを返す。"""
    for sub in ast.walk(node):
        if isinstance(sub, ast.Call):
            return sub
    return None


def _is_final_annotation(node: ast.AST) -> bool:
    name = _callee_name(node)
    if name in ("Final", "typing.Final"):
        return True
    if isinstance(node, ast.Subscript):
        return _is_final_annotation(node.value)
    return False


def _is_type_alias(node: Optional[ast.AST]) -> bool:
    """右辺が typing 構成子の subscript なら型エイリアスと見なす。"""
    if not isinstance(node, ast.Subscript):
        return False
    base = _callee_name(node.value)
    if base is None:
        return False
    return base.split(".")[-1] in TYPING_CONSTRUCTORS


def _target_names(node: ast.AST) -> List[str]:
    names: List[str] = []
    for sub in ast.walk(node):
        if isinstance(sub, ast.Name):
            names.append(sub.id)
    return names


def _is_dunder(names: List[str]) -> bool:
    return all(n.startswith("__") and n.endswith("__") for n in names) and bool(names)


def _is_main_guard(node: ast.If) -> bool:
    src = ast.dump(node.test)
    return "'__main__'" in src or '"__main__"' in src


def _is_type_checking_guard(node: ast.If) -> bool:
    return "TYPE_CHECKING" in ast.dump(node.test)


def _line(source_lines: List[str], lineno: int) -> str:
    if 1 <= lineno <= len(source_lines):
        return source_lines[lineno - 1].strip()
    return ""


def find_python_module_globals(source: str, path: str) -> List[Finding]:
    """Python ソースのモジュールレベル代入・副作用呼び出しを列挙する。

    構文エラーのソースは空リストを返す（ゲートは構文検査ではない）。
    """
    try:
        tree = ast.parse(source, filename=path)
    except SyntaxError:
        return []

    lines = source.splitlines()
    findings: List[Finding] = []

    def visit_body(body: List[ast.stmt]) -> None:
        for node in body:
            if isinstance(
                node,
                (
                    ast.Import,
                    ast.ImportFrom,
                    ast.FunctionDef,
                    ast.AsyncFunctionDef,
                    ast.ClassDef,
                    ast.Pass,
                ),
            ):
                continue

            # 条件付き・try 付きのモジュールレベル文も本体を見る
            if isinstance(node, ast.If):
                if _is_main_guard(node) or _is_type_checking_guard(node):
                    continue
                visit_body(node.body)
                visit_body(node.orelse)
                continue
            if isinstance(node, ast.Try):
                visit_body(node.body)
                for handler in node.handlers:
                    visit_body(handler.body)
                visit_body(node.orelse)
                visit_body(node.finalbody)
                continue
            if isinstance(node, ast.With):
                visit_body(node.body)
                continue

            if isinstance(node, ast.Expr):
                value = node.value
                if isinstance(value, ast.Constant) and isinstance(value.value, str):
                    continue  # docstring
                if isinstance(value, ast.Call):
                    callee = _callee_name(value.func) or "<unknown>"
                    if callee in ALLOWED_BARE_CALLS:
                        continue
                    findings.append(
                        Finding(
                            rule="module_global",
                            path=path,
                            line=node.lineno,
                            excerpt=_line(lines, node.lineno),
                            why=_WHY_SIDE_EFFECT,
                            adr="ADR-004",
                        )
                    )
                continue

            if isinstance(node, ast.AugAssign):
                findings.append(
                    Finding(
                        rule="module_global",
                        path=path,
                        line=node.lineno,
                        excerpt=_line(lines, node.lineno),
                        why=_WHY_GLOBAL,
                        adr="ADR-004",
                    )
                )
                continue

            if isinstance(node, (ast.Assign, ast.AnnAssign)):
                if isinstance(node, ast.Assign):
                    targets = node.targets
                    annotation = None
                else:
                    targets = [node.target]
                    annotation = node.annotation
                names: List[str] = []
                for target in targets:
                    names.extend(_target_names(target))
                if _is_dunder(names):
                    continue

                value = node.value
                # 定数名（大文字）・Final 注釈・型エイリアスは、右辺に呼び出しを含んでいても通す。
                # ここを厳しくすると ERROR_DEFINITIONS のような定数表で毎回発火し、
                # 偽陽性が「ゲートを迂回する習慣」を作る。資源生成の見逃しは
                # 項目6（外部送信先）と項目2（永続化面）が重なって拾う。
                if annotation is not None and _is_final_annotation(annotation):
                    continue
                if _is_type_alias(value):
                    continue
                if names and all(_CONST_NAME.match(n) for n in names):
                    continue

                call = _first_call(value) if value is not None else None
                if call is not None:
                    callee = _callee_name(call.func) or "<unknown>"
                    if callee in ALLOWED_CALL_FACTORIES:
                        continue
                    findings.append(
                        Finding(
                            rule="module_global",
                            path=path,
                            line=node.lineno,
                            excerpt=_line(lines, node.lineno),
                            why=_WHY_RESOURCE,
                            adr="ADR-004",
                        )
                    )
                    continue

                # 呼び出しを含まない、定数でも型エイリアスでもない代入
                findings.append(
                    Finding(
                        rule="module_global",
                        path=path,
                        line=node.lineno,
                        excerpt=_line(lines, node.lineno),
                        why=_WHY_GLOBAL,
                        adr="ADR-004",
                    )
                )

    visit_body(tree.body)
    return findings


#: Dart のトップレベル可変変数。列0から始まる `var` / `late`（final を伴わない）のみを見る。
#: メソッド内・クラス内はインデントされるので拾わない。
_DART_TOP_LEVEL_MUTABLE = re.compile(
    r"^(?:var\s+\w+|late\s+(?!final\b)[\w<>,?\s]+\s+\w+)\s*(?:=|;)"
)


def find_dart_top_level_mutables(source: str, path: str) -> List[Finding]:
    """Dart のトップレベル可変変数を行ベースで拾う。

    AST ではないため、これは「既知の形を拾う補助」であって網羅ではない。
    厳密な検査は Phase 3 の Dart analyzer ルールが担う（是正計画 Phase 3）。
    """
    findings: List[Finding] = []
    for index, raw in enumerate(source.splitlines(), start=1):
        if _DART_TOP_LEVEL_MUTABLE.match(raw):
            findings.append(
                Finding(
                    rule="module_global",
                    path=path,
                    line=index,
                    excerpt=raw.strip(),
                    why="Dart のトップレベル可変変数は1概念1真実を壊す（お気に入りが4箇所に散った前例）",
                    adr="ADR-005",
                )
            )
    return findings
