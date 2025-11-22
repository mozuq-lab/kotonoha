"""
AI変換ログモデルモジュール

【機能概要】: AI変換機能の使用状況をログとして保存するSQLAlchemyモデル
【実装方針】: PostgreSQLのai_conversion_logsテーブルとマッピングし、AI変換のログ管理を実現
【セキュリティ】: 入力テキストはSHA-256でハッシュ化して保存し、プライバシーを保護
【パフォーマンス】: created_at、input_text_hash、session_idにインデックスを設定
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base_class import Base
from app.utils.hash_utils import hash_text as _hash_text


class AIConversionLog(Base):
    """
    【機能概要】: AI変換ログを保存するORMモデル
    【実装方針】: SQLAlchemy 2.x のMapped型を使用し、型安全なモデル定義を実現
    【セキュリティ】: input_text_hashにはSHA-256ハッシュ化されたテキストのみを保存
    """

    # 【テーブル名指定】: データベーススキーマと一致するテーブル名を明示的に指定
    __tablename__ = "ai_conversion_logs"

    # 【テーブル制約・インデックス定義】
    __table_args__ = (
        # 【丁寧さレベル制約】: casual, normal, polite のみ許可
        CheckConstraint(
            "politeness_level IN ('casual', 'normal', 'polite')",
            name="check_politeness_level",
        ),
        # 【created_at降順インデックス】: 時系列検索用インデックス
        Index(
            "idx_ai_conversion_logs_created_at",
            "created_at",
            postgresql_ops={"created_at": "DESC"},
        ),
        # 【input_text_hashインデックス】: ハッシュ検索用インデックス
        Index("idx_ai_conversion_logs_hash", "input_text_hash"),
        # 【session_idインデックス】: セッションごとのログ取得用インデックス
        Index("idx_ai_conversion_logs_session", "session_id"),
    )

    # 【主キー】: 自動生成される整数型のID
    # 【実装方針】: init=False でインスタンス作成時にidを指定不要、デフォルトはNone
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # 【必須フィールド】: 入力テキストのSHA-256ハッシュ値（64文字）
    input_text_hash: Mapped[str] = mapped_column(String(64), nullable=False)

    # 【必須フィールド】: 入力テキストの文字数（統計用）
    input_length: Mapped[int] = mapped_column(Integer, nullable=False)

    # 【必須フィールド】: 出力テキストの文字数（統計用）
    output_length: Mapped[int] = mapped_column(Integer, nullable=False)

    # 【必須フィールド】: 丁寧さレベル（casual/normal/polite）
    politeness_level: Mapped[str] = mapped_column(String(20), nullable=False)

    # 【オプションフィールド】: 変換処理時間（ミリ秒）
    conversion_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # 【オプションフィールド】: AIプロバイダー名（デフォルト: "anthropic"）
    ai_provider: Mapped[str | None] = mapped_column(String(50), nullable=True, default="anthropic")

    # 【必須フィールド】: 成功・失敗フラグ（デフォルト: True）
    is_success: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    # 【オプションフィールド】: エラーメッセージ（失敗時のみ）
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)

    # 【必須フィールド】: セッションID（UUID）
    session_id: Mapped[uuid.UUID] = mapped_column(PG_UUID(as_uuid=True), nullable=False)

    # 【自動生成フィールド】: レコード作成日時（タイムスタンプ）
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.current_timestamp(),
    )

    @staticmethod
    def hash_text(text: str) -> str:
        """
        テキストをSHA-256でハッシュ化する

        【機能概要】: 入力テキストをSHA-256アルゴリズムでハッシュ化
        【セキュリティ】: 元のテキストを復元不可能にし、プライバシーを保護

        Args:
            text: ハッシュ化する入力テキスト

        Returns:
            64文字の16進数文字列（SHA-256ハッシュ値）
        """
        return _hash_text(text)

    # 【定数定義】: 有効な丁寧さレベルの値
    VALID_POLITENESS_LEVELS = ("casual", "normal", "polite")

    @classmethod
    def create_log(
        cls,
        input_text: str,
        output_text: str,
        politeness_level: str,
        conversion_time_ms: int | None = None,
        ai_provider: str = "anthropic",
        session_id: uuid.UUID | None = None,
        is_success: bool = True,
        error_message: str | None = None,
    ) -> "AIConversionLog":
        """
        ログエントリを作成する

        【機能概要】: AI変換のログエントリを作成
        【実装方針】: 入力テキストを自動的にハッシュ化し、文字数を計算

        Args:
            input_text: 元の入力テキスト（ハッシュ化前）
            output_text: 変換後テキスト
            politeness_level: 丁寧さレベル（casual/normal/polite）
            conversion_time_ms: 変換処理時間（ミリ秒）
            ai_provider: AIプロバイダー名（デフォルト: "anthropic"）
            session_id: セッションID（省略時は自動生成）
            is_success: 成功フラグ（デフォルト: True）
            error_message: エラーメッセージ（失敗時のみ）

        Returns:
            AIConversionLogインスタンス

        Raises:
            ValueError: politeness_levelが無効な値の場合
        """
        # 丁寧さレベルのバリデーション
        if politeness_level not in cls.VALID_POLITENESS_LEVELS:
            raise ValueError(
                f"Invalid politeness_level: {politeness_level}. "
                f"Must be one of: {cls.VALID_POLITENESS_LEVELS}"
            )

        return cls(
            input_text_hash=cls.hash_text(input_text),
            input_length=len(input_text),
            output_length=len(output_text),
            politeness_level=politeness_level,
            conversion_time_ms=conversion_time_ms,
            ai_provider=ai_provider,
            session_id=session_id if session_id is not None else uuid.uuid4(),
            is_success=is_success,
            error_message=error_message,
        )

    def __repr__(self) -> str:
        """モデルインスタンスの文字列表現を返す"""
        return (
            f"<AIConversionLog(id={self.id}, "
            f"politeness_level='{self.politeness_level}', "
            f"is_success={self.is_success})>"
        )
