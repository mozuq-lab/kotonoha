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

# 【モデルインポート】: すべてのORMモデルクラスをインポート
# 【重要】: Alembicがメタデータを認識するため、すべてのモデルをここでインポートする必要がある
# 【実装方針】: 新しいモデルを追加する際は、必ずこのファイルにインポート文を追加する
# 🔵 要件定義書（line 437-440）に基づく実装

# 【AI変換履歴モデル】: AI変換機能の履歴を保存するモデル
# 🔵 database-schema.sql（line 36-68）のai_conversion_historyテーブルに対応
from app.models.ai_conversion_history import AIConversionHistory  # noqa: F401

# 【将来の拡張】: 新しいモデルを追加する場合、ここにインポート文を追加
# 例:
# from app.models.user import User  # noqa: F401
# from app.models.setting import Setting  # noqa: F401
