"""
【機能概要】: SQLAlchemyのベースモデルクラス定義
【実装方針】: すべてのORM model clássがこのBaseクラスを継承し、共通の機能を提供する
【テスト対応】: test_models.pyのすべてのテストケースを通すための基盤
🔵 この実装は要件定義書（line 45-50）とSQLAlchemy 2.x公式ドキュメントに基づく
"""

from typing import Any

from sqlalchemy.orm import as_declarative, declared_attr


@as_declarative()
class Base:
    """
    【機能概要】: すべてのORM モデルクラスの基底クラス
    【実装方針】: SQLAlchemy 2.x の as_declarative() デコレータを使用して宣言的基底クラスを定義
    【テスト対応】: カテゴリA（ベースモデルクラステスト）を通すための実装
    🔵 SQLAlchemy 2.x の標準的な実装パターンに従う
    """

    id: Any
    __name__: str

    # 【テーブル名自動生成】: クラス名を小文字に変換してテーブル名とする
    # 【実装方針】: 明示的に__tablename__を指定しない場合、自動的に生成される
    # 🔵 要件定義書（line 45-50）に基づく実装
    @declared_attr.directive
    def __tablename__(cls) -> str:
        """
        【機能概要】: クラス名からテーブル名を自動生成
        【実装方針】: クラス名を小文字に変換（例: AIConversionHistory -> ai_conversion_history）
        【テスト対応】: モデルクラスがテーブル名を自動的に持つことを保証
        🔵 SQLAlchemy 2.x の標準機能
        """
        # 【テーブル名変換ロジック】: クラス名をスネークケースに変換
        # 【注意】: 実際のテーブル名は各モデルクラスで明示的に指定することを推奨
        return cls.__name__.lower()
