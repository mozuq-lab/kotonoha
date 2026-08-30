"""
テストハーネスのDSN分解テスト

【テスト対象】: tests/conftest.py の postgres_settings_from_dsn()
【目的】: TEST_DATABASE_URL を POSTGRES_* へ分解するとき、percent-encode された
          値（`%40` = `@`、`%25` = `%`）が復号されることを固定する。

過去に「`%` を含むパスワードで DB に接続できない」バグを本番コードで直したが、
同じ誤りがテストハーネス側に残っていた。CI のパスワードが英数字のみのため
この経路は緑のまま通り続ける（潜在）。
"""

import pytest
from sqlalchemy.engine import URL, make_url

from tests.conftest import postgres_settings_from_dsn

# percent-encode が必要な文字を含むパスワード。
# `@` はホスト区切り、`%` は escape 導入文字で、どちらも素通しにすると壊れる。
_RAW_PASSWORD = "p@ss%word"
_ENCODED_DSN = "postgresql+asyncpg://kotonoha_user:p%40ss%25word@localhost:5432/kotonoha_test"


def test_percent_encoded_password_is_decoded():
    """`%40` / `%25` が素の `@` / `%` として取り出されること。

    urlparse / urlsplit は percent-decode しないため、この検証は落ちる。
    """
    parts = postgres_settings_from_dsn(_ENCODED_DSN)

    assert parts["POSTGRES_PASSWORD"] == _RAW_PASSWORD


@pytest.mark.parametrize(
    "dsn",
    [
        # CI/ローカルで実際に使う形（percent-encode 不要）
        "postgresql+asyncpg://kotonoha_user:test_password@localhost:5432/kotonoha_test",
        # percent-encode が必要な文字を含む形
        _ENCODED_DSN,
        # ユーザー名側にも記号が入る形
        "postgresql+asyncpg://user%40corp:pw%231@db.internal:6432/kotonoha_test",
    ],
)
def test_dsn_survives_a_round_trip_through_postgres_settings(dsn: str):
    """分解 → 再構築で元の DSN に戻ること（往復一致）。

    再構築は sqlalchemy.engine.URL に任せる。分解側が percent-decode しないと、
    再構築で二重にエスケープされる（`%40` → `%2540`）ため往復が破れる。
    """
    parts = postgres_settings_from_dsn(dsn)

    rebuilt = URL.create(
        make_url(dsn).drivername,
        username=parts["POSTGRES_USER"],
        password=parts["POSTGRES_PASSWORD"],
        host=parts["POSTGRES_HOST"],
        port=parts["POSTGRES_PORT"],
        database=parts["POSTGRES_DB"],
    ).render_as_string(hide_password=False)

    assert rebuilt == dsn
