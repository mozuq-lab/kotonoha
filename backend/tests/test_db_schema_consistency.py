"""
DBスキーマ整合性テスト（PR6: データ整合性/マイグレーション）

- is_success にサーバーデフォルトが設定されていること（モデル/マイグレーション一致）

注: politeness_level_enum の小文字検証は、enum を使う唯一のテーブル
ai_conversion_history を廃止（review #5）したため削除した。
"""

from app.models.ai_conversion_logs import AIConversionLog


class TestServerDefaults:
    def test_is_success_has_server_default(self):
        """is_success に server_default が設定されている（マイグレーションと一致）。"""
        column = AIConversionLog.__table__.c.is_success
        assert column.server_default is not None
