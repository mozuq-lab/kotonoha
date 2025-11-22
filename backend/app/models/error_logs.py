"""
エラーログモデルモジュール

【機能概要】: アプリケーションのエラー情報をログとして保存するSQLAlchemyモデル
【実装方針】: PostgreSQLのerror_logsテーブルとマッピングし、エラー追跡・分析を実現
【セキュリティ】: スタックトレースは開発環境のみで詳細を保存
【パフォーマンス】: error_type、created_atにインデックスを設定
"""

from datetime import datetime

from sqlalchemy import DateTime, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base_class import Base


class ErrorLog(Base):
    """
    【機能概要】: エラーログを保存するORMモデル
    【実装方針】: SQLAlchemy 2.x のMapped型を使用し、型安全なモデル定義を実現
    【セキュリティ】: 機密情報を含まないエラー情報のみを保存
    """

    # 【テーブル名指定】: データベーススキーマと一致するテーブル名を明示的に指定
    __tablename__ = "error_logs"

    # 【テーブル制約・インデックス定義】
    __table_args__ = (
        # 【error_typeインデックス】: エラータイプ別検索用インデックス
        Index("idx_error_logs_type", "error_type"),
        # 【created_at降順インデックス】: 時系列検索用インデックス
        Index(
            "idx_error_logs_created_at",
            "created_at",
            postgresql_ops={"created_at": "DESC"},
        ),
    )

    # 【主キー】: 自動生成される整数型のID
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # 【必須フィールド】: エラータイプ（例: "NetworkException", "ValidationError"）
    error_type: Mapped[str] = mapped_column(String(100), nullable=False)

    # 【必須フィールド】: エラーメッセージ
    error_message: Mapped[str] = mapped_column(Text, nullable=False)

    # 【オプションフィールド】: エラーコード（例: "AI_001"）
    error_code: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # 【オプションフィールド】: エラー発生エンドポイント
    endpoint: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # 【オプションフィールド】: HTTPメソッド
    http_method: Mapped[str | None] = mapped_column(String(10), nullable=True)

    # 【オプションフィールド】: スタックトレース（開発環境のみ）
    stack_trace: Mapped[str | None] = mapped_column(Text, nullable=True)

    # 【自動生成フィールド】: レコード作成日時（タイムスタンプ）
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.current_timestamp(),
    )

    def __repr__(self) -> str:
        """モデルインスタンスの文字列表現を返す"""
        return (
            f"<ErrorLog(id={self.id}, "
            f"error_type='{self.error_type}', "
            f"error_code='{self.error_code}')>"
        )
