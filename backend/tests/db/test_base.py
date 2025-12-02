"""
TC-CV-003: db/base.py テストケース

【テスト対象】: app/db/base.py
【テスト数】: 3ケース
【推定工数】: 0.5時間
【目的】: DB基底クラスのインポート・継承テスト
"""

import pytest
from sqlalchemy import Column, Integer, String

from app.db.base import Base


class TestBaseModel:
    """Baseモデルクラステスト"""

    def test_tc_cv_003_001_base_import(self):
        """
        TC-CV-003-001: Baseモデルのインポートテスト
        【説明】: Baseクラスが正しくインポートされることを確認
        【期待結果】: Baseクラスがインポート可能
        """
        # Arrange & Act & Assert
        assert Base is not None
        assert hasattr(Base, "__tablename__")
        # Baseはas_declarative()デコレータで作成されている
        assert hasattr(Base, "metadata")

    def test_tc_cv_003_002_metadata_import(self):
        """
        TC-CV-003-002: メタデータのインポートテスト
        【説明】: metadataが正しくインポートされることを確認
        【期待結果】: metadataオブジェクトが存在
        """
        # Arrange & Act
        metadata = Base.metadata

        # Assert
        assert metadata is not None
        # SQLAlchemy MetaDataオブジェクトであることを確認
        assert hasattr(metadata, "tables")
        assert hasattr(metadata, "create_all")
        assert hasattr(metadata, "drop_all")

    def test_tc_cv_003_003_base_inheritance(self):
        """
        TC-CV-003-003: Baseクラスの継承テスト
        【説明】: 他のモデルがBaseを継承できることを確認
        【期待結果】: Baseを継承した新しいモデルクラスが作成できる
        """
        # Arrange
        class TestModel(Base):
            """テスト用モデルクラス"""

            __tablename__ = "test_model"

            id = Column(Integer, primary_key=True, index=True)
            name = Column(String(100), nullable=False)

        # Act & Assert
        assert issubclass(TestModel, Base)
        assert TestModel.__tablename__ == "test_model"
        assert hasattr(TestModel, "id")
        assert hasattr(TestModel, "name")
        # metadataにテーブルが登録されている
        assert "test_model" in Base.metadata.tables
