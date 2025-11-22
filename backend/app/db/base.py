"""
【機能概要】: モデル集約ファイル（Alembic自動マイグレーション用）
【実装方針】: すべてのモデルクラスをインポートし、Alembicがメタデータを認識できるようにする
【テスト対応】: TASK-0009（初回マイグレーション実行）で使用される基盤
🔵 この実装は要件定義書（line 437-440）とAlembic公式ドキュメントに基づく
"""

# 【ベースクラスインポート】: すべてのモデルの基底クラス
# 【Alembic要件】: env.pyでtarget_metadataとして使用される
# 🔵 Alembic自動マイグレーション生成のために必須
from app.db.base_class import Base  # noqa: F401

# 【AI変換履歴モデル】: AI変換機能の履歴を保存するモデル
# 🔵 database-schema.sql（line 36-68）のai_conversion_historyテーブルに対応
from app.models.ai_conversion_history import AIConversionHistory  # noqa: F401

# 【AI変換ログモデル】: AI変換機能の使用状況をログとして保存するモデル
# 🔵 TASK-0024: AI変換ログテーブル実装・プライバシー対応
from app.models.ai_conversion_logs import AIConversionLog  # noqa: F401

# 【エラーログモデル】: アプリケーションのエラー情報をログとして保存するモデル
# 🔵 TASK-0024: AI変換ログテーブル実装・プライバシー対応
from app.models.error_logs import ErrorLog  # noqa: F401

# 【エクスポート定義】: モジュールから公開するシンボルを定義
__all__ = ["Base", "AIConversionHistory", "AIConversionLog", "ErrorLog"]
