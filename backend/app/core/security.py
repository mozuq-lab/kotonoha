"""
セキュリティモジュール

【機能概要】: 端末APIキー認証（AI変換APIの保護）に必要な検証機能を提供
【実装方針】: MVPはアカウント管理を持たないため、端末発行の共有シークレットを
              タイミング攻撃に強い比較で照合するだけの最小構成とする。
              JWT・パスワードハッシュ化はMVP範囲外（クラウド同期・アカウント管理は
              実装しない）のため、本モジュールには置かない。
"""

import hmac

from app.core.config import settings


def is_valid_api_key(api_key: str | None) -> bool:
    """
    【機能概要】: 端末APIキーが有効かどうかを検証する
    【実装方針】: 設定された許可リストとタイミング攻撃に強い比較（hmac.compare_digest）で照合。
                  hmac.compare_digest は非ASCII文字を含む str 同士の比較で TypeError を送出する
                  ため、必ず bytes にエンコードしてから比較する（未処理の500応答を防ぐ）。

    Args:
        api_key: リクエストから受け取ったAPIキー（未指定の場合None）

    Returns:
        bool: いずれかの許可キーと一致する場合True。型不一致・エンコード不能な入力はFalse。
    """
    if not api_key or not isinstance(api_key, str):
        return False
    try:
        candidate = api_key.encode("utf-8")
    except (UnicodeEncodeError, AttributeError):
        return False
    # 設定された全キーと定数時間・bytes比較し、短絡評価による時間差や型起因の例外を避ける
    valid = False
    for allowed in settings.API_KEYS_LIST:
        try:
            allowed_bytes = allowed.encode("utf-8")
        except (UnicodeEncodeError, AttributeError):
            continue
        if hmac.compare_digest(candidate, allowed_bytes):
            valid = True
    return valid
