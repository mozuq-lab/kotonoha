"""
DBスキーマ整合性テスト（PR6: データ整合性/マイグレーション）

- politeness_level ENUM がテーブル間で小文字に統一されていること
- is_success にサーバーデフォルトが設定されていること（モデル/マイグレーション一致）
"""

import pytest
from sqlalchemy import text

from app.models.ai_conversion_logs import AIConversionLog


class TestServerDefaults:
    def test_is_success_has_server_default(self):
        """is_success に server_default が設定されている（マイグレーションと一致）。"""
        column = AIConversionLog.__table__.c.is_success
        assert column.server_default is not None


class TestPolitenessEnumLowercase:
    @pytest.mark.asyncio
    async def test_enum_labels_are_lowercase(self, db_session):
        """politeness_level_enum のラベルが小文字（casual/normal/polite）であること。

        モデルの values_callable により、create_all/マイグレーションのいずれでも
        小文字で型が作成されることを検証する（ai_conversion_logs の小文字Stringと統一）。
        """
        result = await db_session.execute(
            text(
                "SELECT enumlabel FROM pg_enum e "
                "JOIN pg_type t ON e.enumtypid = t.oid "
                "WHERE t.typname = 'politeness_level_enum' "
                "ORDER BY e.enumsortorder"
            )
        )
        labels = [row[0] for row in result.fetchall()]
        assert labels == ["casual", "normal", "polite"]
