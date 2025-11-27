"""
AI変換履歴モデルモジュール

【機能概要】: AI変換履歴を保存するSQLAlchemyモデルと丁寧さレベルEnum
【実装方針】: PostgreSQLのai_conversion_historyテーブルとマッピングし、AI変換機能の履歴管理を実現
【セキュリティ】: NOT NULL制約とEnum制約により、データ整合性を保証
【パフォーマンス】: created_atとuser_session_idにインデックスを設定（Alembicマイグレーションで作成）
【テスト対応】: 28テストケースすべてを通すための完全な実装
🔵 この実装は要件定義書（line 52-66）とdatabase-schema.sql、NFR-304に基づく

Example:
    モデルインスタンスの作成と保存:
    ```python
    from uuid import uuid4
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # モデルインスタンスの作成
    history = AIConversionHistory(
        input_text="水 ぬるく",
        converted_text="お水をぬるめでお願いします",
        politeness_level=PolitenessLevel.NORMAL,
        conversion_time_ms=2500,
        user_session_id=uuid4()
    )

    # データベースへの保存
    async with async_session_maker() as session:
        session.add(history)
        await session.commit()
        await session.refresh(history)  # IDと created_at を取得
        print(f"保存完了: ID={history.id}")
    ```
"""

import enum
from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, Enum, Index, Integer, Text
from sqlalchemy.dialects.postgresql import UUID as PostgreSQL_UUID  # noqa: N811
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base_class import Base


class PolitenessLevel(str, enum.Enum):
    """
    【機能概要】: 丁寧さレベルを表すEnum型
    【実装方針】: Python標準のenumを使用し、SQLAlchemyのEnumカラムで使用
    【テスト対応】: カテゴリB-4～B-6（Enum値テスト）、カテゴリE-1（不正なEnum値テスト）を通すための実装
    🔵 要件定義書（line 57）に基づくEnum定義
    """

    # 【Enum値定義】: データベーススキーマと一致する3つの値を定義
    # 🔵 database-schema.sql（line 44）に基づく定義
    CASUAL = "casual"  # 【カジュアル】: フランクな文体
    NORMAL = "normal"  # 【通常】: 標準的な丁寧さ
    POLITE = "polite"  # 【丁寧】: より丁寧な文体


class AIConversionHistory(Base):
    """
    【機能概要】: AI変換履歴を保存するORMモデル
    【実装方針】: SQLAlchemy 2.x のMapped型を使用し、型安全なモデル定義を実現
    【テスト対応】: 全テストケース（28件）を通すための完全な実装
    🔵 要件定義書（line 52-66）とdatabase-schema.sql（line 36-68）に基づく
    """

    # 【テーブル名指定】: データベーススキーマと一致するテーブル名を明示的に指定
    # 🔵 database-schema.sqlのテーブル名に基づく
    __tablename__ = "ai_conversion_history"

    # 【インデックス定義】: パフォーマンス最適化のためのインデックスを定義
    # 【実装方針】: SQLAlchemyの__table_args__を使用してインデックスを定義し、Alembicのautogenerateで自動生成可能にする
    # 【idx_ai_conversion_created_at】: 時系列検索用インデックス（created_at DESC）
    # 【idx_ai_conversion_session】: セッション絞り込み用インデックス（user_session_id）
    # 【リファクタリング理由】: Greenフェーズではマイグレーションファイルに手動でインデックスを追加したが、
    #                          モデル定義にインデックスを含めることで、今後のマイグレーション自動生成で一貫性を保つ
    # 🔵 この実装はdatabase-schema.sql（line 54-68）に基づく
    __table_args__ = (
        # 【created_at降順インデックス】: 履歴を新しい順に取得するための最適化
        # 【パフォーマンス】: 時系列検索クエリ（ORDER BY created_at DESC）の高速化
        # 🔵 database-schema.sql（line 54-60）に基づくインデックス定義
        Index(
            "idx_ai_conversion_created_at",
            "created_at",
            postgresql_ops={"created_at": "DESC"},
        ),
        # 【user_session_idインデックス】: セッションごとの履歴取得の最適化
        # 【パフォーマンス】: WHERE user_session_id = ?クエリの高速化
        # 🔵 database-schema.sql（line 62-68）に基づくインデックス定義
        Index("idx_ai_conversion_session", "user_session_id"),
    )

    # 【主キー】: 自動生成される整数型のID
    # 【実装方針】: PostgreSQLのSERIAL型として自動インクリメント
    # 【テスト対応】: C-2（レコード作成テスト）でid自動生成を検証
    # 🔵 要件定義書（line 54）に基づく
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # 【必須フィールド】: 変換元テキスト（NOT NULL制約）
    # 【実装方針】: PostgreSQLのText型として無制限の文字列を保存
    # 【テスト対応】: B-1（必須フィールドテスト）、D-4（NOT NULL制約違反テスト）を検証
    # 🔵 要件定義書（line 54）、database-schema.sql（line 37）に基づく
    input_text: Mapped[str] = mapped_column(Text, nullable=False)

    # 【必須フィールド】: 変換後テキスト（NOT NULL制約）
    # 【実装方針】: PostgreSQLのText型として無制限の文字列を保存
    # 【テスト対応】: B-1（必須フィールドテスト）、エラーハンドリングテストを検証
    # 🔵 要件定義書（line 55）、database-schema.sql（line 38）に基づく
    converted_text: Mapped[str] = mapped_column(Text, nullable=False)

    # 【必須フィールド】: 丁寧さレベル（NOT NULL制約、Enum型）
    # 【実装方針】: Python EnumとSQLAlchemy Enumカラムを使用
    # 【テスト対応】: B-4～B-6（Enum値テスト）、E-1（不正なEnum値テスト）を検証
    # 🔵 要件定義書（line 57）、database-schema.sql（line 39-44）に基づく
    politeness_level: Mapped[PolitenessLevel] = mapped_column(
        Enum(PolitenessLevel, name="politeness_level_enum", create_constraint=True),
        nullable=False,
    )

    # 【自動生成フィールド】: レコード作成日時（タイムスタンプ）
    # 【実装方針】: PostgreSQLのCURRENT_TIMESTAMPをデフォルト値として設定
    # 【テスト対応】: C-2（レコード作成テスト）でcreated_at自動生成を検証
    # 🔵 要件定義書（line 58）、database-schema.sql（line 45-47）に基づく
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.current_timestamp(),
    )

    # 【オプションフィールド】: AI変換処理時間（ミリ秒、NULL許可）
    # 【実装方針】: Integer型、NULL許可フィールド
    # 【テスト対応】: B-3（NULL許可フィールドテスト）、E-4～E-6（境界値テスト）を検証
    # 🔵 要件定義書（line 59）、database-schema.sql（line 48-49）に基づく
    conversion_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # 【オプションフィールド】: ユーザーセッションID（UUID、NULL許可）
    # 【実装方針】: PostgreSQLのUUID型、NULL許可フィールド
    # 【テスト対応】: B-3（NULL許可フィールドテスト）、C-4（セッションID絞り込みテスト）を検証
    # 🔵 要件定義書（line 60）、database-schema.sql（line 50-51）に基づく
    user_session_id: Mapped[UUID | None] = mapped_column(
        PostgreSQL_UUID(as_uuid=True), nullable=True
    )

    def __repr__(self) -> str:
        """
        【機能概要】: モデルインスタンスの文字列表現を返す
        【実装方針】: デバッグ用にidとinput_textを含む文字列を返す
        🟡 デバッグ用の補助機能（要件定義書には明記されていないが、開発時に有用）
        """
        # 【文字列表現】: モデルの主要情報を含む文字列を生成
        return f"<AIConversionHistory(id={self.id}, input_text='{self.input_text[:20]}...')>"
