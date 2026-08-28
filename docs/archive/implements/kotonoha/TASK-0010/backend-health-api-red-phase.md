# TASK-0010: バックエンドヘルスチェック・基本APIエンドポイント実装 - Redフェーズ設計書

## 生成情報

- **生成日**: 2025-11-20
- **タスクID**: TASK-0010
- **フェーズ**: Red（失敗するテスト作成）
- **総テストケース数**: 17個（24個中17個を実装）
- **失敗テスト数**: 8個（期待通り）
- **成功テスト数**: 9個（既存実装で動作）

---

## テストファイル構成

### 1. test_health_endpoints.py

**パス**: `backend/tests/test_api/test_health_endpoints.py`

**目的**: ルートエンドポイント（GET /）とヘルスチェックエンドポイント（GET /health）の動作検証

**テストケース数**: 9個

#### カテゴリA: ルートエンドポイント（GET /）

1. `test_root_endpoint_returns_success`
   - **目的**: ルートエンドポイントが正常に応答することを確認
   - **検証項目**: HTTPステータスコード200、message、versionフィールド
   - **期待結果**: FAILED（versionフィールドが未実装）
   - **信頼性レベル**: 🔵 testcases.md A-1（line 70-87）

2. `test_root_endpoint_sets_correct_content_type`
   - **目的**: Content-Typeヘッダーが正しく設定されることを確認
   - **検証項目**: Content-Type: application/json
   - **期待結果**: PASSED（FastAPIのデフォルト動作）
   - **信頼性レベル**: 🔵 testcases.md A-2（line 89-100）

3. `test_root_endpoint_responds_within_100ms`
   - **目的**: パフォーマンス要件（NFR-003）を満たすことを確認
   - **検証項目**: レスポンス時間 < 100ms
   - **期待結果**: PASSED（データベースアクセスなし、軽量エンドポイント）
   - **信頼性レベル**: 🔵 testcases.md A-3（line 102-113）

#### カテゴリB: ヘルスチェックエンドポイント（GET /health）

4. `test_health_endpoint_returns_database_connected`
   - **目的**: データベース接続を確認して正常に応答することを確認
   - **検証項目**: status=ok、database=connected、version、timestamp
   - **期待結果**: FAILED（database、version、timestampフィールドが未実装）
   - **信頼性レベル**: 🔵 testcases.md B-1（line 164-183）

5. `test_health_endpoint_returns_iso8601_timestamp`
   - **目的**: ISO 8601形式のタイムスタンプを返すことを確認
   - **検証項目**: timestamp（ISO 8601形式）
   - **期待結果**: FAILED（timestampフィールドが未実装）
   - **信頼性レベル**: 🔵 testcases.md B-2（line 185-196）

6. `test_health_endpoint_responds_within_1_second`
   - **目的**: パフォーマンス要件（NFR-002）を満たすことを確認
   - **検証項目**: レスポンス時間 < 1000ms
   - **期待結果**: PASSED（軽量なSELECT 1クエリを想定）
   - **信頼性レベル**: 🔵 testcases.md B-3（line 198-209）

7. `test_health_endpoint_returns_correct_version`
   - **目的**: versionフィールドを正しく返すことを確認
   - **検証項目**: version="1.0.0"
   - **期待結果**: FAILED（versionフィールドが未実装）
   - **信頼性レベル**: 🔵 testcases.md B-4（line 211-222）

8. `test_health_endpoint_database_connection_failure_returns_500`
   - **目的**: データベース接続失敗時に500エラーを返すことを確認
   - **検証項目**: HTTPステータスコード500、status=error、database=disconnected、errorフィールド
   - **期待結果**: FAILED（エラーハンドリングが未実装）
   - **信頼性レベル**: 🔵 testcases.md B-5（line 224-246）

9. `test_health_endpoint_handles_multiple_requests`
   - **目的**: 同時アクセス（10リクエスト）に対応できることを確認
   - **検証項目**: 全リクエストがHTTPステータスコード200で応答
   - **期待結果**: PASSED（接続プールが適切に動作）
   - **信頼性レベル**: 🔵 testcases.md B-10（line 326-339）

---

### 2. test_cors.py

**パス**: `backend/tests/test_api/test_cors.py`

**目的**: CORS（Cross-Origin Resource Sharing）設定が正しく機能することを検証

**テストケース数**: 5個

#### カテゴリC: CORS設定

1. `test_cors_allows_localhost_3000_origin`
   - **目的**: 許可されたオリジン（http://localhost:3000）からのリクエストに対してCORSヘッダーが設定されることを確認
   - **検証項目**: Access-Control-Allow-Origin: http://localhost:3000
   - **期待結果**: FAILED（CORS設定が未実装）
   - **信頼性レベル**: 🔵 testcases.md C-1（line 345-356）

2. `test_cors_handles_preflight_request`
   - **目的**: プリフライトリクエスト（OPTIONS）に対して正しく応答することを確認
   - **検証項目**: HTTPステータスコード200、CORSヘッダー（Allow-Origin, Allow-Methods, Allow-Headers）
   - **期待結果**: FAILED（CORS設定が未実装、OPTIONSメソッドが405エラー）
   - **信頼性レベル**: 🔵 testcases.md C-2（line 358-373）

3. `test_cors_allows_multiple_origins`
   - **目的**: 複数の許可されたオリジン（http://localhost:5173）からのリクエストに対応することを確認
   - **検証項目**: Access-Control-Allow-Origin: http://localhost:5173
   - **期待結果**: FAILED（CORS設定が未実装）
   - **信頼性レベル**: 🔵 testcases.md C-3（line 375-386）

4. `test_cors_rejects_unauthorized_origin`
   - **目的**: 許可されていないオリジンからのリクエストを拒否することを確認
   - **検証項目**: Access-Control-Allow-Originヘッダーが設定されない
   - **期待結果**: PASSED（CORS未設定のため、不正オリジンが拒否される）
   - **信頼性レベル**: 🔵 testcases.md C-4（line 388-403）

5. `test_cors_handles_requests_without_origin_header`
   - **目的**: Originヘッダーがない場合でも正常に応答することを確認
   - **検証項目**: HTTPステータスコード200、通常のレスポンス
   - **期待結果**: PASSED（Originヘッダーなしでも正常動作）
   - **信頼性レベル**: 🟡 testcases.md C-5（line 405-421）

---

### 3. test_openapi.py

**パス**: `backend/tests/test_api/test_openapi.py`

**目的**: Swagger UIとOpenAPI仕様が正しく生成・公開されることを検証

**テストケース数**: 3個

#### カテゴリD: Swagger UI / OpenAPI仕様

1. `test_swagger_ui_is_accessible`
   - **目的**: Swagger UIが/docsでアクセス可能であることを確認
   - **検証項目**: HTTPステータスコード200、text/html Content-Type、"swagger-ui"を含むHTML
   - **期待結果**: PASSED（FastAPIのデフォルト機能）
   - **信頼性レベル**: 🔵 testcases.md D-1（line 427-441）

2. `test_openapi_spec_is_accessible`
   - **目的**: OpenAPI仕様が/openapi.jsonで取得可能であることを確認
   - **検証項目**: HTTPステータスコード200、application/json Content-Type、OpenAPI仕様
   - **期待結果**: PASSED（FastAPIの自動生成機能）
   - **信頼性レベル**: 🔵 testcases.md D-2（line 443-458）

3. `test_openapi_spec_includes_all_endpoints`
   - **目的**: OpenAPI仕様にルートエンドポイントとヘルスチェックエンドポイントが含まれることを確認
   - **検証項目**: paths["/"]とpaths["/health"]が定義されている
   - **期待結果**: PASSED（FastAPIの自動生成機能）
   - **信頼性レベル**: 🔵 testcases.md D-3（line 460-474）

---

## テスト実行結果サマリー

```bash
$ pytest tests/test_api/ -v --tb=no

総テストケース数: 17個
失敗: 8個 (期待通り)
成功: 9個 (既存実装で動作する部分)
```

### 失敗したテスト（Greenフェーズで実装が必要）

1. `test_cors_allows_localhost_3000_origin` - CORS設定が未実装
2. `test_cors_handles_preflight_request` - CORS設定が未実装
3. `test_cors_allows_multiple_origins` - CORS設定が未実装
4. `test_root_endpoint_returns_success` - versionフィールドが未実装
5. `test_health_endpoint_returns_database_connected` - データベース接続確認が未実装
6. `test_health_endpoint_returns_iso8601_timestamp` - timestampフィールドが未実装
7. `test_health_endpoint_returns_correct_version` - versionフィールドが未実装
8. `test_health_endpoint_database_connection_failure_returns_500` - エラーハンドリングが未実装

### 成功したテスト（既存実装で動作）

1. `test_root_endpoint_sets_correct_content_type` - FastAPIのデフォルト動作
2. `test_root_endpoint_responds_within_100ms` - パフォーマンス要件を満たす
3. `test_health_endpoint_responds_within_1_second` - パフォーマンス要件を満たす
4. `test_health_endpoint_handles_multiple_requests` - 同時アクセスに対応
5. `test_cors_rejects_unauthorized_origin` - CORS未設定のため不正オリジンが拒否される
6. `test_cors_handles_requests_without_origin_header` - Originヘッダーなしで正常動作
7. `test_swagger_ui_is_accessible` - FastAPIのデフォルト機能
8. `test_openapi_spec_is_accessible` - FastAPIのデフォルト機能
9. `test_openapi_spec_includes_all_endpoints` - FastAPIの自動生成機能

---

## Greenフェーズへの実装要件

Greenフェーズ（最小実装）で以下を実装する必要がある：

### 1. ルートエンドポイント改善

**ファイル**: `backend/app/main.py`

**実装内容**:
- versionフィールドの追加
- Pydanticスキーマ（RootResponse）の使用

**期待されるレスポンス**:
```json
{
    "message": "kotonoha API is running",
    "version": "1.0.0"
}
```

### 2. ヘルスチェックエンドポイント拡張

**ファイル**: `backend/app/main.py`

**実装内容**:
- データベース接続確認（SQLAlchemy sessionを使用）
- databaseフィールド（"connected" / "disconnected"）の追加
- timestampフィールド（ISO 8601形式）の追加
- versionフィールドの追加
- データベース接続失敗時のエラーハンドリング（500エラー）

**期待されるレスポンス（正常時）**:
```json
{
    "status": "ok",
    "database": "connected",
    "version": "1.0.0",
    "timestamp": "2025-11-20T12:34:56Z"
}
```

**期待されるレスポンス（異常時）**:
```json
{
    "status": "error",
    "database": "disconnected",
    "error": "connection timeout",
    "version": "1.0.0",
    "timestamp": "2025-11-20T12:34:56Z"
}
```

### 3. CORS設定

**ファイル**: `backend/app/main.py`

**実装内容**:
- CORSMiddlewareの追加
- 許可オリジンの設定（http://localhost:3000, http://localhost:5173）
- 許可メソッドの設定（GET, POST, PUT, DELETE）
- 許可ヘッダーの設定（*）

**参照**: `app/core/config.py`（line 29）のCORS_ORIGINS設定

### 4. Pydanticスキーマ定義

**ファイル**: `backend/app/schemas/health.py`（新規作成）

**実装内容**:
- `RootResponse`: ルートエンドポイントレスポンススキーマ
- `HealthResponse`: ヘルスチェックレスポンススキーマ（正常時）
- `HealthErrorResponse`: ヘルスチェックレスポンススキーマ（異常時）

**スキーマ例**:
```python
from pydantic import BaseModel
from datetime import datetime

class RootResponse(BaseModel):
    message: str
    version: str

class HealthResponse(BaseModel):
    status: str
    database: str
    version: str
    timestamp: str

class HealthErrorResponse(BaseModel):
    status: str
    database: str
    error: str
    version: str
    timestamp: str
```

---

## 品質評価

### テストコード品質

✅ **高品質**:
- テスト実行: 全テストが実行可能で、期待通り失敗する
- 期待値: 明確で具体的（testcases.mdに基づく）
- アサーション: 適切（HTTPステータスコード、レスポンスボディの各フィールドを検証）
- 実装方針: 明確（Greenフェーズで何を実装すべきか明確）
- 日本語コメント: 詳細で分かりやすい（Given-When-Thenパターン）

### 信頼性レベル評価

- **カテゴリA（ルートエンドポイント）**: 🔵 100%（testcases.mdに基づく）
- **カテゴリB（ヘルスチェック）**: 🔵 100%（testcases.mdに基づく）
- **カテゴリC（CORS設定）**: 🔵 80%、🟡 20%（testcases.mdとCORS仕様に基づく）
- **カテゴリD（Swagger UI）**: 🔵 100%（testcases.mdとFastAPI仕様に基づく）

### 全体評価

✅ **高品質**: Redフェーズの要件を全て満たし、Greenフェーズへの実装要件が明確になっている。

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-green` でGreenフェーズ（最小実装）を開始します。
