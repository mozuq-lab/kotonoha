"""
AI変換ログCRUD操作モジュール

TASK-0027: AI変換エンドポイント実装
【機能概要】: AI変換ログの作成・取得操作を提供
【実装方針】: 入力テキストはSHA-256でハッシュ化して保存（プライバシー保護）
"""

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ai_conversion_logs import AIConversionLog


async def create_conversion_log(
    db: AsyncSession,
    input_text: str,
    output_text: str,
    politeness_level: str,
    conversion_time_ms: int | None = None,
    ai_provider: str = "anthropic",
    session_id: uuid.UUID | None = None,
    is_success: bool = True,
    error_message: str | None = None,
) -> AIConversionLog:
    """
    AI変換ログを作成する

    【機能概要】: AI変換の実行結果をログとしてデータベースに保存
    【実装方針】: 入力テキストはSHA-256でハッシュ化し、プライバシーを保護

    Args:
        db: データベースセッション
        input_text: 元の入力テキスト（ハッシュ化前）
        output_text: 変換後テキスト（文字数のみ保存）
        politeness_level: 丁寧さレベル（casual/normal/polite）
        conversion_time_ms: 変換処理時間（ミリ秒）
        ai_provider: AIプロバイダー名（デフォルト: "anthropic"）
        session_id: セッションID（省略時は自動生成）
        is_success: 成功フラグ（デフォルト: True）
        error_message: エラーメッセージ（失敗時のみ）

    Returns:
        AIConversionLog: 作成されたログエントリ

    Raises:
        ValueError: politeness_levelが無効な値の場合
    """
    # モデルのcreate_logメソッドを使用してログエントリを作成
    log = AIConversionLog.create_log(
        input_text=input_text,
        output_text=output_text,
        politeness_level=politeness_level,
        conversion_time_ms=conversion_time_ms,
        ai_provider=ai_provider,
        session_id=session_id,
        is_success=is_success,
        error_message=error_message,
    )

    # データベースに追加
    db.add(log)
    await db.commit()
    await db.refresh(log)

    return log


async def create_conversion_history(
    db: AsyncSession,
    input_text: str,
    output_text: str,
    politeness_level: str,
    conversion_time_ms: int | None = None,
    ai_provider: str = "anthropic",
) -> AIConversionLog:
    """
    AI変換履歴を作成する（成功時のみ使用する簡易版）

    【機能概要】: 正常完了したAI変換の履歴を作成
    【実装方針】: create_conversion_logの簡易ラッパー

    Args:
        db: データベースセッション
        input_text: 元の入力テキスト
        output_text: 変換後テキスト
        politeness_level: 丁寧さレベル
        conversion_time_ms: 変換処理時間（ミリ秒）
        ai_provider: AIプロバイダー名

    Returns:
        AIConversionLog: 作成された履歴エントリ
    """
    return await create_conversion_log(
        db=db,
        input_text=input_text,
        output_text=output_text,
        politeness_level=politeness_level,
        conversion_time_ms=conversion_time_ms,
        ai_provider=ai_provider,
        is_success=True,
    )
