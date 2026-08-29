"""陽性 fixture — ここに書かれた形はすべて検出されなければならない。

「ゲートが存在すること」と「ゲートが機能すること」は別である
（是正計画 §6 Phase 1 の但し書き）。この fixture が緑であることが後者の証拠になる。

期待件数は tests/test_ast_globals.py が固定している。行を足すときはテストも直すこと。
"""

import logging
from dataclasses import dataclass


def setup_logging() -> None:
    """副作用のある初期化。"""


class Client:
    """外部資源を握るクライアント。"""


@dataclass
class Config:
    value: int = 0


# 1. import しただけで走る副作用（代入を伴わない形。独立レビューの反例）
setup_logging()

# 2. モジュールレベルでの資源生成
client = Client()

# 3. 設定の import 時組み立て（ADR-004 が消す形）
settings = Config()

# 4. 呼び出しを含まない可変グローバル
current_environment = "development"

# 5. 複数代入でも1件として数える
first_url, second_url = "a", "b"

# 6. 累積代入
counter = 0
counter += 1

# 7. 条件付きモジュールレベル代入も見る
if logging.getLogger("x").level == 0:
    fallback_client = Client()

# 8. try 配下も見る
try:
    optional_client = Client()
except ImportError:
    optional_client = None
