#!/usr/bin/env python3
"""負債ゲートの入口。フックと CI が同じ検出器を使う。

    python3 -m scripts.debt_gate.cli hook            # PostToolUse フック（stdin に JSON）
    python3 -m scripts.debt_gate.cli ci --base X --head Y
    python3 -m scripts.debt_gate.cli openspec-check  # openspec/changes/ の tracked 禁止
    python3 -m scripts.debt_gate.cli inventory PATH… # 差分ではなく全体を走査（棚卸し用）
    python3 -m scripts.debt_gate.cli selftest        # 陽性・陰性 fixture の検査

リポジトリルートから実行すること（相対 import のため）。

**フックは主、CI は二重の網。** フックは編集のたびに発火し、書いた本人にその場で返す。
CI は PR 時に発火し、フックを持たない経路（別ツール・手作業）を拾う。

フックは内部エラーで作業を止めない（exit 0 にする）。ゲート自身の不具合で
開発が止まると、真っ先に外される。CI 側は内部エラーでも落とす。
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import traceback

from .detectors import ChangedFile, run_detectors
from .gate import evaluate, render_github_annotations, render_text_report
from .gitsource import (
    changed_file_from_worktree,
    changed_files_in_range,
    repo_root,
    run_git,
    tracked_files_under,
)

#: フックが監視するファイル。ここに当たらない編集は検出器を通さない（無駄な発火を避ける）。
WATCHED_SUFFIXES = (
    ".py",
    ".dart",
    ".txt",
    ".yaml",
    ".yml",
    ".xml",
    ".plist",
    ".env.example",
)


def _extract_paths(payload: dict) -> list:
    tool_input = payload.get("tool_input") or {}
    paths = []
    for key in ("file_path", "notebook_path", "path"):
        value = tool_input.get(key)
        if isinstance(value, str) and value:
            paths.append(value)
    for edit in tool_input.get("edits") or []:
        if isinstance(edit, dict) and isinstance(edit.get("file_path"), str):
            paths.append(edit["file_path"])
    return paths


def cmd_hook(_args: argparse.Namespace) -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    if payload.get("tool_name") not in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        return 0

    paths = _extract_paths(payload)
    if not paths:
        return 0

    cwd = payload.get("cwd") or os.getcwd()
    root = repo_root(cwd)

    files = []
    for path in paths:
        if not path.endswith(WATCHED_SUFFIXES):
            continue
        changed = changed_file_from_worktree(path, root)
        if changed is not None:
            files.append(changed)
    if not files:
        return 0

    unresolved, resolved, _ = evaluate(files)
    if not unresolved:
        return 0

    sys.stderr.write(render_text_report(unresolved, resolved) + "\n")
    return 2


def _commit_messages(base: str, head: str, root: str) -> str:
    return run_git(["log", "--format=%B", "{0}..{1}".format(base, head)], cwd=root)


def cmd_ci(args: argparse.Namespace) -> int:
    root = repo_root(os.getcwd())
    files = changed_files_in_range(args.base, args.head, root)
    if not files:
        print("負債ゲート: 変更ファイルなし")
        return 0

    extra = _commit_messages(args.base, args.head, root)
    if args.pr_body_file and os.path.isfile(args.pr_body_file):
        with open(args.pr_body_file, "r", encoding="utf-8", errors="replace") as handle:
            extra += "\n" + handle.read()

    unresolved, resolved, citations = evaluate(files, extra)

    print("負債ゲート: {0} ファイルを検査".format(len(files)))
    if resolved:
        cited = sorted({a for adrs in citations.values() for a in adrs})
        print("ADR 引用で通した検出: {0} 件（引用: {1}）".format(len(resolved), ", ".join(cited)))
    if not unresolved:
        print("✅ 引用の無い負債行為は検出されなかった")
        return 0

    print(render_github_annotations(unresolved))
    print("")
    print(render_text_report(unresolved, resolved))
    return 1


def cmd_openspec_check(_args: argparse.Namespace) -> int:
    """``openspec/changes/`` 配下に追跡ファイルが無いことを確認する。

    恒久成果物は ``openspec/specs/`` だけにする（是正計画 §5「OpenSpec を使う条件」条件1）。
    ここを曖昧にすると、299 ファイルの工程記録が名前を変えて再生産される。
    """
    root = repo_root(os.getcwd())
    tracked = tracked_files_under("openspec/changes", root)
    if not tracked:
        print("✅ openspec/changes/ に追跡ファイルは無い")
        return 0
    for path in tracked:
        print("::error file={0}::openspec/changes/ 配下は追跡しない。恒久成果物は openspec/specs/ のみ".format(path))
    print("")
    print("openspec/changes/ に追跡ファイルが {0} 件ある。".format(len(tracked)))
    print("change は工程記録である。archive はツール上『changes/archive/ への保存』であって削除ではないため、")
    print("ここで追跡を禁止して初めて『捨てる』が実行可能になる（是正計画 §5 条件1）。")
    return 1


def cmd_inventory(args: argparse.Namespace) -> int:
    """差分ではなくファイル全体を走査する。棚卸し（Phase 4）と較正用。"""
    root = repo_root(os.getcwd())
    total = 0
    for path in args.paths:
        absolute = os.path.join(root, path)
        if not os.path.isfile(absolute):
            continue
        with open(absolute, "r", encoding="utf-8", errors="replace") as handle:
            content = handle.read()
        changed = ChangedFile(
            path=path,
            old_content=None,
            new_content=content,
            added=[(i, line) for i, line in enumerate(content.splitlines(), start=1)],
        )
        for finding in run_detectors(changed):
            total += 1
            print("{0}\t{1}\t{2}".format(finding.rule, finding.location(), finding.excerpt[:100]))
    print("--- {0} 件".format(total))
    return 0


def cmd_selftest(_args: argparse.Namespace) -> int:
    import unittest

    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(here))  # リポジトリルート
    loader = unittest.TestLoader()
    suite = loader.discover(os.path.join(here, "tests"), top_level_dir=root)
    runner = unittest.TextTestRunner(verbosity=2)
    return 0 if runner.run(suite).wasSuccessful() else 1


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(description="負債ゲート")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("hook").set_defaults(func=cmd_hook)

    ci = sub.add_parser("ci")
    ci.add_argument("--base", required=True)
    ci.add_argument("--head", required=True)
    ci.add_argument("--pr-body-file", default=None)
    ci.set_defaults(func=cmd_ci)

    sub.add_parser("openspec-check").set_defaults(func=cmd_openspec_check)

    inventory = sub.add_parser("inventory")
    inventory.add_argument("paths", nargs="+")
    inventory.set_defaults(func=cmd_inventory)

    sub.add_parser("selftest").set_defaults(func=cmd_selftest)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except SystemExit:
        raise
    except Exception:
        # フックはゲート自身の不具合で作業を止めない。CI（二重の網）が拾う。
        if len(sys.argv) > 1 and sys.argv[1] == "hook":
            sys.stderr.write("負債ゲート: 内部エラーのため検査をスキップした\n")
            traceback.print_exc(file=sys.stderr)
            sys.exit(0)
        raise
