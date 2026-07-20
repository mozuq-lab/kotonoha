"""
TC-CV-001: core/security.py テストケース

【テスト対象】: app/core/security.py
【テスト数】: 8ケース
【推定工数】: 1.5時間
【目的】: JWT認証・パスワードハッシュ化機能のテスト
"""

from datetime import datetime, timedelta, timezone

import pytest
from jose import ExpiredSignatureError, JWTError, jwt

from app.core.config import settings
from app.core.security import (
    ALGORITHM,
    create_access_token,
    get_password_hash,
    is_valid_api_key,
    verify_password,
)


class TestPasswordHashing:
    """パスワードハッシュ化テスト"""

    def test_tc_cv_001_001_password_hash_and_verify_success(self):
        """
        TC-CV-001-001: パスワードハッシュ化テスト
        【説明】: パスワードをハッシュ化し、正しく検証できることを確認
        【期待結果】: ハッシュ化されたパスワードが元のパスワードで検証成功
        """
        # Arrange
        plain_password = "test_password_123"  # noqa: S105

        # Act
        hashed_password = get_password_hash(plain_password)

        # Assert
        assert hashed_password != plain_password  # ハッシュ化されている
        assert hashed_password.startswith("$2b$")  # bcryptのハッシュ形式
        assert verify_password(plain_password, hashed_password) is True

    def test_tc_cv_001_002_password_verify_failure(self):
        """
        TC-CV-001-002: パスワード検証失敗テスト
        【説明】: 不正なパスワードでの検証が失敗することを確認
        【期待結果】: 異なるパスワードで検証失敗
        """
        # Arrange
        correct_password = "correct_password"  # noqa: S105
        wrong_password = "wrong_password"  # noqa: S105
        hashed_password = get_password_hash(correct_password)

        # Act
        result = verify_password(wrong_password, hashed_password)

        # Assert
        assert result is False


class TestJWTToken:
    """JWTトークン生成・検証テスト"""

    def test_tc_cv_001_003_create_access_token_success(self):
        """
        TC-CV-001-003: JWTトークン生成テスト
        【説明】: JWTトークンが正しく生成されることを確認
        【期待結果】: 有効なJWTトークンが生成される
        """
        # Arrange
        subject = "test_user_id"

        # Act
        token = create_access_token(subject=subject)

        # Assert
        assert isinstance(token, str)
        assert len(token) > 0
        # トークンをデコードして検証
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        assert decoded["sub"] == subject
        assert "exp" in decoded

    def test_tc_cv_001_004_verify_jwt_token_success(self):
        """
        TC-CV-001-004: JWTトークン検証テスト
        【説明】: トークンのデコードと有効期限チェックが正しく動作することを確認
        【期待結果】: 有効なトークンがデコードできる
        """
        # Arrange
        subject = "user_123"
        expires_delta = timedelta(minutes=30)
        token = create_access_token(subject=subject, expires_delta=expires_delta)

        # Act
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])

        # Assert
        assert decoded["sub"] == subject
        assert "exp" in decoded
        # 有効期限が未来であることを確認
        exp_timestamp = decoded["exp"]
        current_timestamp = datetime.now(timezone.utc).timestamp()
        assert exp_timestamp > current_timestamp

    def test_tc_cv_001_005_jwt_token_expired(self):
        """
        TC-CV-001-005: JWTトークン期限切れテスト
        【説明】: 期限切れトークンの検証が失敗することを確認
        【期待結果】: ExpiredSignatureError例外が発生
        """
        # Arrange
        subject = "user_456"
        # 過去の時間を設定（既に期限切れ）
        expires_delta = timedelta(seconds=-10)
        token = create_access_token(subject=subject, expires_delta=expires_delta)

        # Act & Assert
        with pytest.raises(ExpiredSignatureError):
            jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])

    def test_tc_cv_001_006_invalid_jwt_token(self):
        """
        TC-CV-001-006: 不正なJWTトークンテスト
        【説明】: 改ざんされたトークンの検証が失敗することを確認
        【期待結果】: JWTError例外が発生
        """
        # Arrange
        invalid_token = "invalid.jwt.token"  # noqa: S105

        # Act & Assert
        with pytest.raises(JWTError):
            jwt.decode(invalid_token, settings.SECRET_KEY, algorithms=[ALGORITHM])

    def test_tc_cv_001_007_custom_claims_token(self):
        """
        TC-CV-001-007: カスタムクレーム付きトークン
        【説明】: 追加データを含むトークンが生成できることを確認
        【期待結果】: カスタムクレームを含むトークンが生成される
        【注意】: 現在の実装はsubjectとexpのみ対応、将来的な拡張を想定
        """
        # Arrange
        subject = {"user_id": "123", "role": "admin"}  # dict型のsubject

        # Act
        token = create_access_token(subject=subject)

        # Assert
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        # subjectは文字列化されるため、JSON文字列として格納される
        assert "sub" in decoded
        assert "exp" in decoded

    def test_tc_cv_001_008_empty_subject_token(self):
        """
        TC-CV-001-008: 空データでのトークン生成
        【説明】: エッジケース：空文字列でのトークン生成が可能か確認
        【期待結果】: 空文字列でもトークンが生成される
        """
        # Arrange
        subject = ""

        # Act
        token = create_access_token(subject=subject)

        # Assert
        assert isinstance(token, str)
        assert len(token) > 0
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        assert decoded["sub"] == ""


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
