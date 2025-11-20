"""
CORS設定テスト

カテゴリC: CORS設定

【テストファイル目的】: CORS（Cross-Origin Resource Sharing）設定が正しく機能することを検証
【テストファイル内容】: 許可されたオリジンからのアクセス、プリフライトリクエスト、不正なオリジンの拒否
【期待されるカバレッジ】: CORS設定の全シナリオを網羅
🔵 backend-health-api-testcases.md カテゴリC（line 343-422）に基づく実装
"""

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


# ================================================================================
# カテゴリC: CORS設定
# ================================================================================


@pytest.mark.asyncio
async def test_cors_allows_localhost_3000_origin():
    """
    【テスト目的】: 許可されたオリジン（http://localhost:3000）からのリクエストに対してCORSヘッダーが設定されることを確認
    【テスト内容】: http://localhost:3000からのリクエストに対してAccess-Control-Allow-Originヘッダーが返されることを検証
    【期待される動作】: Access-Control-Allow-Originヘッダーが設定される
    🔵 testcases.md C-1（line 345-356）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動し、CORS設定が有効
    - When: Origin: http://localhost:3000 を含むGET /リクエストを送信
    - Then: Access-Control-Allow-Origin: http://localhost:3000 が設定される
    """
    # 【テストデータ準備】: HTTPクライアントを作成し、Originヘッダーを設定
    # 【初期条件設定】: Flutter Webアプリからのアクセス（開発環境）を想定
    # 🔵 testcases.md C-1（line 348-352）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: Originヘッダーを含むリクエストを送信
        # 【処理内容】: Flutter Webアプリからの安全なアクセスを可能にするCORS設定を検証
        response = await client.get("/", headers={"Origin": "http://localhost:3000"})

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: 正常に応答していることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: Access-Control-Allow-Originヘッダーが設定されていることを確認
        # 【期待値確認】: CORS設定が正しく機能し、許可されたオリジンを返すことを検証
        # NOTE: 現在の実装にはCORS設定がないため、このテストは失敗する
        assert "access-control-allow-origin" in response.headers  # 【確認内容】: CORSヘッダーが存在する 🔵
        assert response.headers["access-control-allow-origin"] == "http://localhost:3000"  # 【確認内容】: 許可されたオリジンが返される 🔵


@pytest.mark.asyncio
async def test_cors_handles_preflight_request():
    """
    【テスト目的】: プリフライトリクエスト（OPTIONS）に対して正しく応答することを確認
    【テスト内容】: OPTIONSメソッドでプリフライトリクエストが正しく処理されることを検証
    【期待される動作】: ステータスコード200、Access-Control-Allow-Methodsヘッダーが設定される
    🔵 testcases.md C-2（line 358-373）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動し、CORS設定が有効
    - When: OPTIONS /にプリフライトリクエストを送信
    - Then: HTTPステータスコード200、CORSヘッダー（Allow-Origin, Allow-Methods, Allow-Headers）が設定される
    """
    # 【テストデータ準備】: HTTPクライアントを作成し、プリフライトリクエストを準備
    # 【初期条件設定】: ブラウザがクロスオリジンリクエスト前に送信するプリフライトリクエストを想定
    # 🔵 testcases.md C-2（line 361-370）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: OPTIONSメソッドでプリフライトリクエストを送信
        # 【処理内容】: ブラウザのプリフライトリクエストを正しく処理するかを検証
        response = await client.options(
            "/",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "content-type",
            },
        )

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: プリフライトリクエストが正常に処理されることを検証
        # NOTE: 現在の実装にはCORS設定がないため、このテストは失敗する
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: CORSヘッダーが設定されていることを確認
        # 【期待値確認】: プリフライトリクエストに対する適切なCORSヘッダーを検証
        assert "access-control-allow-origin" in response.headers  # 【確認内容】: Access-Control-Allow-Originヘッダーが存在する 🔵
        assert "access-control-allow-methods" in response.headers  # 【確認内容】: Access-Control-Allow-Methodsヘッダーが存在する 🔵
        assert "access-control-allow-headers" in response.headers  # 【確認内容】: Access-Control-Allow-Headersヘッダーが存在する 🔵


@pytest.mark.asyncio
async def test_cors_allows_multiple_origins():
    """
    【テスト目的】: 複数の許可されたオリジンからのリクエストに対応することを確認
    【テスト内容】: http://localhost:5173からのリクエストにも対応することを検証
    【期待される動作】: Access-Control-Allow-Originヘッダーが設定される
    🔵 testcases.md C-3（line 375-386）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動し、CORS設定が有効
    - When: Origin: http://localhost:5173 を含むGET /リクエストを送信
    - Then: Access-Control-Allow-Origin: http://localhost:5173 が設定される
    """
    # 【テストデータ準備】: HTTPクライアントを作成し、別のオリジンを設定
    # 【初期条件設定】: Vite開発サーバーからのアクセス（Flutter Webの別ポート）を想定
    # 🔵 testcases.md C-3（line 378-383）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: 別のオリジンからのリクエストを送信
        # 【処理内容】: 複数の開発環境ポートからのアクセスを許可することを検証
        response = await client.get("/", headers={"Origin": "http://localhost:5173"})

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: 正常に応答していることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: Access-Control-Allow-Originヘッダーが設定されていることを確認
        # 【期待値確認】: 複数の許可されたオリジンに対応することを検証
        # NOTE: 現在の実装にはCORS設定がないため、このテストは失敗する
        assert "access-control-allow-origin" in response.headers  # 【確認内容】: CORSヘッダーが存在する 🔵
        assert response.headers["access-control-allow-origin"] == "http://localhost:5173"  # 【確認内容】: 許可されたオリジンが返される 🔵


@pytest.mark.asyncio
async def test_cors_rejects_unauthorized_origin():
    """
    【テスト目的】: 許可されていないオリジンからのリクエストを拒否することを確認
    【テスト内容】: 許可リストにないオリジンからのアクセスを拒否することを検証
    【期待される動作】: CORSエラー（Access-Control-Allow-Originヘッダーが設定されない）
    🔵 testcases.md C-4（line 388-403）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動し、CORS設定が有効
    - When: Origin: http://malicious-site.com を含むGET /リクエストを送信
    - Then: Access-Control-Allow-Originヘッダーが設定されない（またはCORSエラー）
    """
    # 【テストデータ準備】: HTTPクライアントを作成し、不正なオリジンを設定
    # 【初期条件設定】: 許可リストに含まれていないオリジンからのアクセスを想定
    # 🔵 testcases.md C-4（line 391-398）、NFR-104に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: 不正なオリジンからのリクエストを送信
        # 【処理内容】: セキュリティ要件（NFR-104）を満たし、不正なオリジンを拒否することを検証
        response = await client.get("/", headers={"Origin": "http://malicious-site.com"})

        # 【結果検証】: CORSヘッダーが設定されていないことを確認
        # 【期待値確認】: 不正なオリジンからのアクセスをブロックすることを検証
        # NOTE: 現在の実装にはCORS設定がないため、このテストは失敗する
        # CORS設定後は、不正なオリジンに対してAccess-Control-Allow-Originヘッダーが設定されない
        # または、FastAPIのCORSMiddlewareが403 Forbiddenを返す可能性がある
        if "access-control-allow-origin" in response.headers:
            # CORSヘッダーが設定されている場合、不正なオリジンでないことを確認
            assert response.headers["access-control-allow-origin"] != "http://malicious-site.com"  # 【確認内容】: 不正なオリジンが許可されていない 🔵
        else:
            # CORSヘッダーが設定されていない場合は正常（ブラウザがCORSエラーを表示）
            assert True  # 【確認内容】: CORSヘッダーが設定されていない 🔵


@pytest.mark.asyncio
async def test_cors_handles_requests_without_origin_header():
    """
    【テスト目的】: Originヘッダーがない場合でも正常に応答することを確認
    【テスト内容】: 同一オリジンリクエスト、またはOriginヘッダーなしのリクエストでも動作することを検証
    【期待される動作】: HTTPステータスコード200、通常のレスポンスを返す
    🟡 testcases.md C-5（line 405-421）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: OriginヘッダーなしでGET /リクエストを送信
    - Then: HTTPステータスコード200、通常のレスポンスを返す
    """
    # 【テストデータ準備】: HTTPクライアントを作成し、Originヘッダーなしでリクエスト
    # 【初期条件設定】: curlコマンド、Postman、サーバー間通信を想定
    # 🟡 testcases.md C-5（line 408-413）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: Originヘッダーなしでリクエストを送信
        # 【処理内容】: Originヘッダーの有無に関わらずサービス継続することを検証
        response = await client.get("/")

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: Originヘッダーなしでも正常に動作することを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🟡

        # 【結果検証】: 通常のレスポンスボディが返されることを確認
        # 【期待値確認】: 同一オリジンリクエスト、サーバー間通信でも利用可能であることを検証
        response_json = response.json()
        assert "message" in response_json  # 【確認内容】: 通常のレスポンスボディが返される 🟡
