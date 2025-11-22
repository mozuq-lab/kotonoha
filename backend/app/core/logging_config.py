"""
ロギング設定モジュール

【機能概要】: アプリケーション全体のロギング設定を管理
【実装方針】: 標準ライブラリのloggingを使用し、コンソールとファイル出力に対応
"""

import logging
import sys
from pathlib import Path

from app.core.config import settings


def setup_logging() -> None:
    """
    【機能概要】: アプリケーションのロギングを初期化
    【実装方針】: コンソール出力とファイル出力を設定

    - LOG_LEVELに基づいてログレベルを設定
    - コンソール（stdout）への出力を有効化
    - LOG_FILE_PATHが設定されている場合、ファイル出力も有効化
    """
    log_level = getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO)

    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stdout)]

    if settings.LOG_FILE_PATH:
        log_path = Path(settings.LOG_FILE_PATH)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        handlers.append(logging.FileHandler(log_path))

    logging.basicConfig(
        level=log_level,
        format=log_format,
        handlers=handlers,
    )


def get_logger(name: str) -> logging.Logger:
    """
    【機能概要】: 指定された名前のロガーを取得
    【実装方針】: Pythonの標準loggingモジュールを使用

    Args:
        name: ロガーの名前（通常は__name__を使用）

    Returns:
        logging.Logger: 設定されたロガーインスタンス
    """
    return logging.getLogger(name)
