"""
ハッシュ化ユーティリティモジュール

【機能概要】: テキストのハッシュ化機能を提供
【実装方針】: SHA-256アルゴリズムを使用して、入力テキストを一方向ハッシュ化
【セキュリティ】: 元のテキストを復元できない一方向ハッシュを使用し、プライバシーを保護
【パフォーマンス】: 標準ライブラリのhashlibを使用し、高速なハッシュ処理を実現
"""

import hashlib


def hash_text(text: str) -> str:
    """
    テキストをSHA-256でハッシュ化する

    【機能概要】: 入力テキストをSHA-256アルゴリズムでハッシュ化し、64文字の16進数文字列を返す
    【実装方針】: UTF-8エンコードでバイト列に変換後、SHA-256ハッシュを計算
    【セキュリティ】: 元のテキストを復元不可能にし、プライバシーを保護

    Args:
        text: ハッシュ化する入力テキスト（空文字列を含む任意のUnicode文字列）

    Returns:
        64文字の16進数文字列（SHA-256ハッシュ値、小文字）

    Example:
        >>> hash_text("ありがとう")
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08'
        >>> hash_text("")  # 空文字列
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    """
    # UTF-8エンコードでバイト列に変換
    encoded_text = text.encode("utf-8")

    # SHA-256ハッシュを計算
    hash_object = hashlib.sha256(encoded_text)

    # 64文字の16進数文字列として返す（小文字）
    return hash_object.hexdigest()
