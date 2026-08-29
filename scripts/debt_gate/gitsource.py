"""git から「何が追加されたか」を取り出す。

差分のパースはハンクではなく ``difflib`` で行う。旧内容・新内容を丸ごと持てるので、
「このパッケージ名は元から居たか」「このホストは元から書かれていたか」という
**追加かどうかの判定**が素直に書ける。ハンクだけを見ていると、
バージョン更新と新規追加を区別できない。
"""

from __future__ import annotations

import difflib
import os
import subprocess
from typing import List, Optional, Sequence

from .detectors import ChangedFile

#: これより大きいファイルは走査しない（生成物・データファイルを踏まないため）
MAX_BYTES = 1_000_000


def run_git(args: Sequence[str], cwd: Optional[str] = None) -> str:
    """git を実行して標準出力を返す。失敗したら空文字列。"""
    try:
        completed = subprocess.run(
            ["git"] + list(args),
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except OSError:
        return ""
    if completed.returncode != 0:
        return ""
    return completed.stdout.decode("utf-8", errors="replace")


def repo_root(start: Optional[str] = None) -> str:
    out = run_git(["rev-parse", "--show-toplevel"], cwd=start).strip()
    return out or (start or os.getcwd())


def _blob(ref: str, path: str, cwd: str) -> Optional[str]:
    """``ref:path`` の内容。存在しなければ None。"""
    try:
        completed = subprocess.run(
            ["git", "show", "{0}:{1}".format(ref, path)],
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except OSError:
        return None
    if completed.returncode != 0:
        return None
    if len(completed.stdout) > MAX_BYTES:
        return None
    return completed.stdout.decode("utf-8", errors="replace")


def added_lines(old: Optional[str], new: Optional[str]) -> List:
    """新しい側だけに現れる行を (行番号, 内容) で返す。"""
    old_lines = (old or "").splitlines()
    new_lines = (new or "").splitlines()
    matcher = difflib.SequenceMatcher(a=old_lines, b=new_lines, autojunk=False)
    result = []
    for tag, _i1, _i2, j1, j2 in matcher.get_opcodes():
        if tag in ("insert", "replace"):
            for index in range(j1, j2):
                result.append((index + 1, new_lines[index]))
    return result


def build_changed_file(path: str, old: Optional[str], new: Optional[str]) -> ChangedFile:
    return ChangedFile(path=path, old_content=old, new_content=new, added=added_lines(old, new))


def changed_files_in_range(base: str, head: str, cwd: str) -> List[ChangedFile]:
    """``base...head`` で変更されたファイルを集める。削除されたファイルは含めない。"""
    listing = run_git(["diff", "--name-status", "--diff-filter=ACMRT", "{0}...{1}".format(base, head)], cwd=cwd)
    files: List[ChangedFile] = []
    for line in listing.splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        status = parts[0]
        path = parts[-1]
        old_path = parts[1] if status.startswith("R") and len(parts) >= 3 else path
        old = None if status.startswith("A") else _blob(base, old_path, cwd)
        new = _blob(head, path, cwd)
        if new is None:
            continue
        files.append(build_changed_file(path, old, new))
    return files


def changed_file_from_worktree(path: str, cwd: str) -> Optional[ChangedFile]:
    """作業ツリー上の1ファイルを HEAD と比べる（フック用）。"""
    absolute = path if os.path.isabs(path) else os.path.join(cwd, path)
    if not os.path.isfile(absolute):
        return None
    if os.path.getsize(absolute) > MAX_BYTES:
        return None
    try:
        with open(absolute, "rb") as handle:
            raw = handle.read()
    except OSError:
        return None
    if b"\x00" in raw[:4096]:
        return None  # バイナリ
    new = raw.decode("utf-8", errors="replace")
    relative = os.path.relpath(absolute, cwd).replace(os.sep, "/")
    old = _blob("HEAD", relative, cwd)
    return build_changed_file(relative, old, new)


def tracked_files_under(prefix: str, cwd: str) -> List[str]:
    """``git ls-files`` で追跡されているファイルを列挙する。"""
    out = run_git(["ls-files", "--", prefix], cwd=cwd)
    return [line for line in out.splitlines() if line.strip()]
