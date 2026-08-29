#!/usr/bin/env python3
"""負債ゲートの入口。

    python3 -m scripts.debt_gate.cli check     # 裁定する（CI が呼ぶ）
    python3 -m scripts.debt_gate.cli seed      # いまの状態から許可リストを起こす
    python3 -m scripts.debt_gate.cli show      # いまの状態を並べる
    python3 -m scripts.debt_gate.cli selftest  # 検査自身の検査

リポジトリルートから実行すること。**`PostToolUse` フックは置かない**（ADR-008）。
ブロックしないフックは、編集のたびに読まれない出力を積むだけになる。
"""

from __future__ import annotations

import argparse
import os
import sys

from .allowlist import ALLOWLIST_PATH
from .allowlist import save as save_allowlist
from .errors import SnapshotError
from .gate import run
from .report import render, render_annotations
from .snapshot import SNAPSHOTS


#: selftest が集めるべきテストの下限。増やしたら上げること。
MINIMUM_TESTS = 30


def repo_root() -> str:
    return os.getcwd()


def cmd_check(_args: argparse.Namespace) -> int:
    result = run(repo_root())
    annotations = render_annotations(result)
    if annotations:
        print(annotations)
        print("")
    print(render(result))
    if result.blocking:
        return 1
    print("✅ 許可リストに無い面は無い")
    return 0


def cmd_seed(args: argparse.Namespace) -> int:
    """いまの状態を経過措置として許可リストに書き出す。**初回のみ。**

    既に許可リストがあるときは拒否する。再実行を許すと、赤を1コマンドで
    緑にする手段になる——新しく足した面が「Phase 1 以前から存在」という
    **事実に反する理由**つきで経過措置に化ける（独立レビューの指摘）。
    敵対的な回避者でなく、CLI のヘルプに従った実装担当がゲートを無効化できてしまう。

    また、許可リストが「無い」ことと「壊れている」ことを区別する。
    壊れた許可リストを seed で上書きすると、破損の検出そのものが消える。
    """
    root = repo_root()
    path = os.path.join(root, ALLOWLIST_PATH)
    if os.path.exists(path):
        sys.stderr.write(
            "許可リストが既にある: {0}\n"
            "seed は初回のみのコマンドである。面を1つ足したなら、その1行を手で書くこと:\n"
            '  "<識別子>": {{"adr": "ADR-00X", "why": "なぜ許可するか1行"}}\n'
            "決定が無いなら、実装をやめて ADR を1本作る（tsumiki:adr-rubber-duck）。\n".format(ALLOWLIST_PATH)
        )
        return 1
    entries: dict = {}

    added = 0
    for kind, _label, snapshot in SNAPSHOTS:
        items = snapshot(root)  # 失敗したら例外で落ちる（緑にしない）
        bucket = entries.setdefault(kind, {})
        for item, _detail in items:
            if item in bucket:
                continue
            bucket[item] = {
                "adr": None,
                "grandfathered": True,
                "why": args.why,
            }
            added += 1
    path = save_allowlist(root, entries)
    print("{0} に {1} 件を経過措置として記録した".format(path, added))
    return 0


def cmd_show(_args: argparse.Namespace) -> int:
    root = repo_root()
    for kind, label, snapshot in SNAPSHOTS:
        try:
            items = snapshot(root)
        except SnapshotError as exc:
            print("{0}: 取得失敗 — {1}".format(label, exc))
            continue
        print("{0} ({1} 件)".format(label, len(items)))
        for item, detail in sorted(items):
            print("  {0:48s} {1}".format(item, detail))
    return 0


def cmd_selftest(_args: argparse.Namespace) -> int:
    import unittest

    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(here))
    suite = unittest.TestLoader().discover(os.path.join(here, "tests"), top_level_dir=root)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    # **本数の下限を置く。** テストが1本も集まらなくても unittest は緑を返すので、
    # ファイルを消す・名前を変えるだけで「ゲート自身の検査」が空振りになる。
    if result.testsRun < MINIMUM_TESTS:
        sys.stderr.write(
            "テストが {0} 件しか集まらなかった（下限 {1}）。"
            "収集漏れかファイルの削除を疑うこと\n".format(result.testsRun, MINIMUM_TESTS)
        )
        return 1
    return 0 if result.wasSuccessful() else 1


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(description="負債ゲート（ADR-008）")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check").set_defaults(func=cmd_check)
    seed = sub.add_parser("seed")
    seed.add_argument("--why", default="Phase 1 以前から存在。決定の記録なし")
    seed.set_defaults(func=cmd_seed)
    sub.add_parser("show").set_defaults(func=cmd_show)
    sub.add_parser("selftest").set_defaults(func=cmd_selftest)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
