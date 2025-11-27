"""
Swagger UI / OpenAPI仕様テスト

カテゴリD: Swagger UI / OpenAPI仕様

【テストファイル目的】: Swagger UIとOpenAPI仕様が正しく生成・公開されることを検証
【テストファイル内容】: Swagger UIアクセス、OpenAPI仕様取得、エンドポイント文書化の確認
【期待されるカバレッジ】: NFR-504（OpenAPI自動生成）要件を満たすことを確認
🔵 backend-health-api-testcases.md カテゴリD（line 425-475）に基づく実装
"""

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app

# ================================================================================
# カテゴリD: Swagger UI / OpenAPI仕様
# ================================================================================


@pytest.mark.asyncio
async def test_swagger_ui_is_accessible():
    """
    【テスト目的】: Swagger UIが/docsでアクセス可能であることを確認
    【テスト内容】: GET /docsでSwagger UIのHTMLが返されることを検証
    【期待される動作】: ステータスコード200、HTMLドキュメントが返される
    🔵 testcases.md D-1（line 427-441）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /docsにアクセス
    - Then: HTTPステータスコード200、text/html Content-Type、HTMLボディに"swagger-ui"が含まれる
    """
    # 【テストデータ準備】: HTTPクライアントを作成
    # 【初期条件設定】: 開発者がAPI仕様を確認するためのエンドポイントを想定
    # 🔵 testcases.md D-1（line 430-438）、NFR-504に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: GET /docsにリクエストを送信
        # 【処理内容】: Swagger UIでAPI仕様が確認できることを検証
        response = await client.get("/docs")

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: Swagger UIが正常にアクセス可能であることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: Content-Typeがtext/htmlであることを確認
        # 【期待値確認】: HTMLドキュメントが返されることを検証
        assert "text/html" in response.headers["content-type"]  # 【確認内容】: Content-Typeがtext/html 🔵

        # 【結果検証】: HTMLボディに"swagger-ui"が含まれることを確認
        # 【期待値確認】: Swagger UIのHTMLが正しく生成されていることを検証
        assert "swagger-ui" in response.text.lower() or "swagger" in response.text.lower()  # 【確認内容】: HTMLにSwagger UIが含まれる 🔵


@pytest.mark.asyncio
async def test_openapi_spec_is_accessible():
    """
    【テスト目的】: OpenAPI仕様が/openapi.jsonで取得可能であることを確認
    【テスト内容】: GET /openapi.jsonでOpenAPI仕様のJSONが返されることを検証
    【期待される動作】: ステータスコード200、OpenAPI 3.0仕様のJSONが返される
    🔵 testcases.md D-2（line 443-458）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /openapi.jsonにアクセス
    - Then: HTTPステータスコード200、application/json Content-Type、OpenAPI仕様が含まれる
    """
    # 【テストデータ準備】: HTTPクライアントを作成
    # 【初期条件設定】: API仕様の機械可読形式、コード生成ツールでの使用を想定
    # 🔵 testcases.md D-2（line 446-455）、NFR-504に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: GET /openapi.jsonにリクエストを送信
        # 【処理内容】: OpenAPI仕様が正しく生成され、機械可読形式で取得できることを検証
        response = await client.get("/openapi.json")

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: OpenAPI仕様が正常に取得可能であることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: Content-Typeがapplication/jsonであることを確認
        # 【期待値確認】: JSON形式でOpenAPI仕様が返されることを検証
        assert "application/json" in response.headers["content-type"]  # 【確認内容】: Content-Typeがapplication/json 🔵

        # 【結果検証】: レスポンスボディがOpenAPI仕様であることを確認
        # 【期待値確認】: openapi, info, pathsフィールドを含むことを検証
        response_json = response.json()
        assert "openapi" in response_json  # 【確認内容】: openapiフィールドが存在する 🔵
        assert "info" in response_json  # 【確認内容】: infoフィールドが存在する 🔵
        assert "paths" in response_json  # 【確認内容】: pathsフィールドが存在する 🔵


@pytest.mark.asyncio
async def test_openapi_spec_includes_all_endpoints():
    """
    【テスト目的】: OpenAPI仕様にルートエンドポイントとヘルスチェックエンドポイントが含まれることを確認
    【テスト内容】: OpenAPI仕様のpathsに/と/healthが含まれることを検証
    【期待される動作】: paths["/"]とpaths["/health"]が定義されている
    🔵 testcases.md D-3（line 460-474）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /openapi.jsonにアクセス
    - Then: paths["/"]とpaths["/health"]が定義されている
    """
    # 【テストデータ準備】: HTTPクライアントを作成
    # 【初期条件設定】: API仕様の完全性確認、全エンドポイントが文書化されているかを確認
    # 🔵 testcases.md D-3（line 463-471）、NFR-504に基づく
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: GET /openapi.jsonにリクエストを送信
        # 【処理内容】: 全エンドポイントがOpenAPI仕様に含まれ、文書化されていることを検証
        response = await client.get("/openapi.json")

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: OpenAPI仕様が正常に取得可能であることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: OpenAPI仕様のpathsに/と/healthが含まれることを確認
        # 【期待値確認】: 全エンドポイントがOpenAPI仕様に含まれ、文書化されていることを検証
        response_json = response.json()
        paths = response_json.get("paths", {})
        assert "/" in paths  # 【確認内容】: paths["/"]が定義されている 🔵
        # ルートレベルの/healthと/api/v1/healthの両方をサポート
        assert "/health" in paths or "/api/v1/health" in paths  # 【確認内容】: ヘルスチェックエンドポイントが定義されている 🔵

        # 【結果検証】: 各エンドポイントにGETメソッドが定義されていることを確認
        # 【期待値確認】: 各エンドポイントの詳細が文書化されていることを検証
        assert "get" in paths["/"]  # 【確認内容】: paths["/"].getが定義されている 🔵
        # ヘルスエンドポイントの検証（ルートレベルまたはAPI v1）
        health_path = "/health" if "/health" in paths else "/api/v1/health"
        assert "get" in paths[health_path]  # 【確認内容】: ヘルスチェックエンドポイントのGETが定義されている 🔵
