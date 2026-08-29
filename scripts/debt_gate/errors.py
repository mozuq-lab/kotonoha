"""状態が取得できなかったことを、変化が無かったことと区別するための型。

初回実装（revert 済み）は git の失敗を空文字列に潰し、「変更ファイルなし ✅」で
CI を緑にした。**取得失敗と正常な空を同じ値で表すと、必ずこの形になる。**
"""

from __future__ import annotations


class SnapshotError(Exception):
    """状態を取得できなかった。ゲートは緑にせず落ちること。

    Attributes:
        kind: 取得しようとした状態の種類
        source: 読もうとしたファイル
        reason: 取得できなかった理由
    """

    def __init__(self, kind: str, source: str, reason: str) -> None:
        super().__init__("{0}: {1} を読めない（{2}）".format(kind, source, reason))
        self.kind = kind
        self.source = source
        self.reason = reason
