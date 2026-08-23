"""
TC-CV-001: core/security.py テストケース

【テスト対象】: app/core/security.py
【目的】: 端末APIキー検証（is_valid_api_key）のテスト

【注記】: JWT生成・パスワードハッシュ化のテストは、対応する実装
          （create_access_token / verify_password / get_password_hash）が
          アプリから一度も使われないデッドコードだったため、実装ごと削除した。
          MVPはアカウント管理を持たず、認証は端末APIキーのみ。
"""

from app.core.config import settings
from app.core.security import is_valid_api_key


class TestIsValidApiKey:
    """is_valid_api_key: 端末APIキー検証テスト（bytes比較による非ASCII安全性を含む）"""

    def test_returns_true_for_matching_key(self, monkeypatch):
        """許可リストに含まれるキーはTrueを返す"""
        monkeypatch.setattr(settings, "API_KEYS", "device-key-aaaa,device-key-bbbb")
        assert is_valid_api_key("device-key-aaaa") is True
        assert is_valid_api_key("device-key-bbbb") is True

    def test_returns_false_for_non_matching_key(self, monkeypatch):
        """許可リストに含まれないキーはFalseを返す"""
        monkeypatch.setattr(settings, "API_KEYS", "device-key-aaaa")
        assert is_valid_api_key("device-key-zzzz") is False

    def test_returns_false_for_none(self, monkeypatch):
        """未指定（None）はFalseを返す"""
        monkeypatch.setattr(settings, "API_KEYS", "device-key-aaaa")
        assert is_valid_api_key(None) is False

    def test_returns_false_for_empty_string(self, monkeypatch):
        """空文字列はFalseを返す"""
        monkeypatch.setattr(settings, "API_KEYS", "device-key-aaaa")
        assert is_valid_api_key("") is False

    def test_non_ascii_key_returns_false_without_raising(self, monkeypatch):
        """
        非ASCII文字を含むAPIキーはTypeErrorを送出せずFalseを返す。

        hmac.compare_digest は非ASCII文字を含む str 同士の比較で TypeError を
        送出するため、bytes化してから比較する実装になっていることを確認する。
        """
        monkeypatch.setattr(settings, "API_KEYS", "device-key-aaaa")
        assert is_valid_api_key("日本語キー不正") is False

    def test_non_ascii_key_matches_when_registered(self, monkeypatch):
        """許可リスト自体に非ASCII文字が含まれていても正しく一致判定できる"""
        monkeypatch.setattr(settings, "API_KEYS", "日本語キー,device-key-aaaa")
        assert is_valid_api_key("日本語キー") is True

    def test_returns_false_when_no_keys_configured(self, monkeypatch):
        """許可リストが空の場合は常にFalseを返す"""
        monkeypatch.setattr(settings, "API_KEYS", "")
        assert is_valid_api_key("any-key") is False
