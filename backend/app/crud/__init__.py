"""
CRUD操作モジュール

【機能概要】: データベースのCreate, Read, Update, Delete操作を提供
【実装方針】: 各モデルに対応するCRUD操作を提供
"""

from app.crud.crud_ai_conversion import create_conversion_history, create_conversion_log

__all__ = [
    "create_conversion_log",
    "create_conversion_history",
]
