"""
セキュリティモジュール

【機能概要】: JWT認証、パスワードハッシュ化など認証・認可機能を提供
【実装方針】: jose, passlib を使用した標準的なセキュリティ実装
"""

from datetime import datetime, timedelta, timezone
from typing import Any

from jose import jwt
from passlib.context import CryptContext

from app.core.config import settings

# パスワードハッシュ化コンテキスト
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT暗号化アルゴリズム
ALGORITHM = "HS256"


def create_access_token(
    subject: str | Any, expires_delta: timedelta | None = None
) -> str:
    """
    【機能概要】: アクセストークンを生成する
    【実装方針】: JWTトークンを生成し、有効期限を設定

    Args:
        subject: トークンのサブジェクト（通常はユーザーID）
        expires_delta: トークンの有効期限。Noneの場合はデフォルト値を使用

    Returns:
        str: 生成されたJWTトークン
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    【機能概要】: プレーンテキストパスワードとハッシュ化パスワードを比較検証
    【実装方針】: bcryptアルゴリズムを使用した安全な比較

    Args:
        plain_password: 検証するプレーンテキストパスワード
        hashed_password: 保存されているハッシュ化パスワード

    Returns:
        bool: パスワードが一致する場合True
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """
    【機能概要】: パスワードをハッシュ化する
    【実装方針】: bcryptアルゴリズムを使用した安全なハッシュ化

    Args:
        password: ハッシュ化するプレーンテキストパスワード

    Returns:
        str: ハッシュ化されたパスワード
    """
    return pwd_context.hash(password)
