# API エンドポイント仕様

## 🔵 信頼性レベル凡例

- 🔵 **青信号**: EARS要件定義書・設計文書を参考にした確実なAPI設計
- 🟡 **黄信号**: EARS要件定義書・設計文書から妥当な推測によるAPI設計
- 🔴 **赤信号**: EARS要件定義書・設計文書にない推測によるAPI設計

## ベースURL

- **開発環境**: `http://localhost:8000`
- **ステージング環境**: `https://staging-api.kotonoha.example.com`
- **本番環境**: `https://api.kotonoha.example.com`

## 共通仕様

### リクエストヘッダー

```http
Content-Type: application/json
Accept: application/json
```

### レスポンスフォーマット

すべてのAPIレスポンスは以下の形式に従います:

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

エラー時:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ",
    "status_code": 400
  }
}
```

### HTTPステータスコード

- `200 OK`: リクエスト成功
- `201 Created`: リソース作成成功
- `400 Bad Request`: リクエストパラメータ不正
- `401 Unauthorized`: 認証失敗
- `403 Forbidden`: 権限不足
- `404 Not Found`: リソースが見つからない
- `422 Unprocessable Entity`: バリデーションエラー
- `429 Too Many Requests`: レート制限超過
- `500 Internal Server Error`: サーバーエラー
- `503 Service Unavailable`: サービス一時停止

### エラーコード一覧

| コード | 説明 |
|--------|------|
| `VALIDATION_ERROR` | バリデーションエラー |
| `AI_API_ERROR` | 外部AI APIエラー |
| `AI_API_TIMEOUT` | AI API タイムアウト |
| `NETWORK_ERROR` | ネットワークエラー |
| `RATE_LIMIT_EXCEEDED` | レート制限超過 |
| `INTERNAL_ERROR` | 内部サーバーエラー |

## API バージョニング

APIバージョンはURLパスに含めます:

- `/api/v1/...`

## エンドポイント一覧

---

## AI変換機能 🔵

### POST /api/v1/ai/convert

短い入力テキストを丁寧で自然な文章に変換します。

**要件**: REQ-901, REQ-902, REQ-903, REQ-904

**パフォーマンス要件**: 平均応答時間3秒以内 (NFR-002)

#### リクエスト

```http
POST /api/v1/ai/convert
Content-Type: application/json
```

```json
{
  "input_text": "水 ぬるく",
  "politeness_level": "normal"
}
```

**パラメータ**:

| フィールド | 型 | 必須 | 説明 | バリデーション |
|-----------|---|------|------|---------------|
| `input_text` | string | ✓ | 変換元テキスト | 2文字以上500文字以下 |
| `politeness_level` | string | ✓ | 丁寧さレベル | `casual`, `normal`, `polite` のいずれか |

#### レスポンス（成功）

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
  "success": true,
  "data": {
    "converted_text": "お水をぬるめでお願いします",
    "original_text": "水 ぬるく",
    "politeness_level": "normal",
    "processing_time_ms": 2500
  },
  "error": null
}
```

**レスポンスフィールド**:

| フィールド | 型 | 説明 |
|-----------|---|------|
| `converted_text` | string | 変換後のテキスト |
| `original_text` | string | 変換元のテキスト（確認用） |
| `politeness_level` | string | 使用した丁寧さレベル |
| `processing_time_ms` | integer | 処理時間（ミリ秒） |

#### レスポンス（エラー）

```http
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
```

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AI_API_ERROR",
    "message": "AI変換APIからのレスポンスに失敗しました。元の文を使用してください。",
    "status_code": 500
  }
}
```

#### エラーケース

| ステータス | エラーコード | 説明 |
|-----------|-------------|------|
| 400 | `VALIDATION_ERROR` | `input_text`が2文字未満または500文字超過 |
| 400 | `VALIDATION_ERROR` | `politeness_level`が不正な値 |
| 500 | `AI_API_ERROR` | 外部AI APIからエラーレスポンス |
| 504 | `AI_API_TIMEOUT` | AI APIタイムアウト（10秒超過） |
| 429 | `RATE_LIMIT_EXCEEDED` | レート制限超過（1分間に10リクエストまで） |

#### 例

**リクエスト例1: カジュアルな変換**

```bash
curl -X POST http://localhost:8000/api/v1/ai/convert \
  -H "Content-Type: application/json" \
  -d '{
    "input_text": "腹減った",
    "politeness_level": "casual"
  }'
```

**レスポンス例1**:

```json
{
  "success": true,
  "data": {
    "converted_text": "お腹すいた",
    "original_text": "腹減った",
    "politeness_level": "casual",
    "processing_time_ms": 1800
  },
  "error": null
}
```

**リクエスト例2: 丁寧な変換**

```bash
curl -X POST http://localhost:8000/api/v1/ai/convert \
  -H "Content-Type: application/json" \
  -d '{
    "input_text": "痛い 腰",
    "politeness_level": "polite"
  }'
```

**レスポンス例2**:

```json
{
  "success": true,
  "data": {
    "converted_text": "腰が痛いです",
    "original_text": "痛い 腰",
    "politeness_level": "polite",
    "processing_time_ms": 2200
  },
  "error": null
}
```

---

### POST /api/v1/ai/regenerate

AI変換結果を再生成します（ユーザーが「再生成」ボタンを押した場合）。

**要件**: REQ-904

#### リクエスト

```http
POST /api/v1/ai/regenerate
Content-Type: application/json
```

```json
{
  "input_text": "水 ぬるく",
  "politeness_level": "normal",
  "previous_result": "お水をぬるめでお願いします"
}
```

**パラメータ**:

| フィールド | 型 | 必須 | 説明 |
|-----------|---|------|------|
| `input_text` | string | ✓ | 変換元テキスト |
| `politeness_level` | string | ✓ | 丁寧さレベル |
| `previous_result` | string | ✓ | 前回の変換結果（重複回避用） |

#### レスポンス（成功）

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
  "success": true,
  "data": {
    "converted_text": "お水をぬるめにしてください",
    "original_text": "水 ぬるく",
    "politeness_level": "normal",
    "processing_time_ms": 2700
  },
  "error": null
}
```

---

## ヘルスチェック 🟡

### GET /api/v1/health

APIサーバーの稼働状況を確認します。

#### リクエスト

```http
GET /api/v1/health
```

#### レスポンス（成功）

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-11-19T12:34:56Z"
}
```

#### レスポンス（異常）

```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json
```

```json
{
  "status": "error",
  "version": "1.0.0",
  "timestamp": "2025-11-19T12:34:56Z",
  "error": "Database connection failed"
}
```

---

## 将来的な拡張用エンドポイント（MVP範囲外） 🔴

以下のエンドポイントはMVP範囲外ですが、将来的な拡張として検討:

### 認証・ユーザー管理

```
POST /api/v1/auth/login        # ログイン
POST /api/v1/auth/logout       # ログアウト
POST /api/v1/auth/refresh      # トークンリフレッシュ
POST /api/v1/users/register    # ユーザー登録
GET  /api/v1/users/me          # 現在のユーザー情報取得
PUT  /api/v1/users/me          # ユーザー情報更新
```

### 定型文同期

```
GET    /api/v1/presets         # 定型文一覧取得（クラウド）
POST   /api/v1/presets         # 定型文作成
PUT    /api/v1/presets/:id     # 定型文更新
DELETE /api/v1/presets/:id     # 定型文削除
POST   /api/v1/presets/sync    # ローカル⇔クラウド同期
```

### お気に入り同期

```
GET    /api/v1/favorites       # お気に入り一覧取得（クラウド）
POST   /api/v1/favorites       # お気に入り作成
DELETE /api/v1/favorites/:id   # お気に入り削除
POST   /api/v1/favorites/sync  # ローカル⇔クラウド同期
```

### 統計・分析

```
GET /api/v1/stats/usage        # 利用統計取得
GET /api/v1/stats/ai-conversion # AI変換統計取得
```

---

## レート制限 🟡

API呼び出しのレート制限を設定します（過負荷防止、コスト管理）。

### AI変換エンドポイント

- **制限**: 1分間に10リクエスト / IPアドレス
- **超過時**: HTTP 429 Too Many Requests

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "リクエスト数が上限に達しました。1分後に再試行してください。",
    "status_code": 429,
    "retry_after": 60
  }
}
```

**レスポンスヘッダー**:

```http
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1637334896
Retry-After: 60
```

---

## セキュリティ 🔵

### HTTPS/TLS

- すべてのAPI通信はHTTPS/TLS 1.2+で暗号化 (NFR-104)
- 本番環境ではHTTP通信を拒否

### CORS設定

Flutter WebアプリからのアクセスをCORS設定で許可:

```python
# FastAPI CORS middleware設定例
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://kotonoha.example.com",  # 本番環境
        "http://localhost:3000",          # 開発環境
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

### 入力バリデーション

- すべてのリクエストパラメータをPydanticでバリデーション
- SQLインジェクション対策: SQLAlchemy ORMを使用
- XSS対策: 適切なエスケープ処理

### プライバシー

- AI変換で送信されるテキストはログに平文保存しない (NFR-102)
- ログにはハッシュ化したテキストのみ保存
- ユーザーの同意を得た上でAI変換機能を利用

---

## パフォーマンス要件 🔵

### AI変換エンドポイント

- **平均応答時間**: 3秒以内 (NFR-002)
- **タイムアウト**: 10秒
- **3秒超過時**: クライアント側でローディング表示 (REQ-2006)

### 監視・メトリクス

以下のメトリクスを監視:

- API応答時間（p50, p95, p99）
- エラーレート
- レート制限超過回数
- 外部AI APIの応答時間・エラーレート

---

## API ドキュメント自動生成 🔵

FastAPIの自動ドキュメント生成機能を使用 (NFR-504):

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

---

## サンプルコード

### Dart/Flutter クライアント実装例

```dart
import 'package:dio/dio.dart';

class AIConversionAPI {
  final Dio _dio;
  final String baseUrl;

  AIConversionAPI({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  Future<AIConversionResponse> convert({
    required String inputText,
    required PolitenessLevel politenessLevel,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/ai/convert',
        data: {
          'input_text': inputText,
          'politeness_level': politenessLevel.name,
        },
      );

      if (response.data['success'] == true) {
        return AIConversionResponse.fromJson(response.data);
      } else {
        throw AIConversionException(
          code: response.data['error']['code'],
          message: response.data['error']['message'],
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AIConversionException(
          code: 'AI_API_TIMEOUT',
          message: 'AI変換APIがタイムアウトしました。再試行してください。',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw AIConversionException(
          code: 'NETWORK_ERROR',
          message: 'ネットワーク接続を確認してください。',
        );
      } else {
        rethrow;
      }
    }
  }
}

class AIConversionException implements Exception {
  final String code;
  final String message;

  AIConversionException({required this.code, required this.message});

  @override
  String toString() => 'AIConversionException: $code - $message';
}
```

### Python/FastAPI サーバー実装例

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, validator
from enum import Enum
import time

app = FastAPI(title="kotonoha API", version="1.0.0")

class PolitenessLevel(str, Enum):
    casual = "casual"
    normal = "normal"
    polite = "polite"

class AIConversionRequest(BaseModel):
    input_text: str = Field(..., min_length=2, max_length=500)
    politeness_level: PolitenessLevel

    @validator('input_text')
    def validate_input_text(cls, v):
        if len(v.strip()) < 2:
            raise ValueError('input_text must be at least 2 characters')
        return v.strip()

class AIConversionResponse(BaseModel):
    converted_text: str
    original_text: str
    politeness_level: PolitenessLevel
    processing_time_ms: int

class ApiResponse(BaseModel):
    success: bool
    data: AIConversionResponse | None = None
    error: dict | None = None

@app.post("/api/v1/ai/convert", response_model=ApiResponse)
async def convert_text(request: AIConversionRequest):
    start_time = time.time()

    try:
        # 外部AI APIを呼び出し（例: Claude API）
        converted_text = await call_external_ai_api(
            input_text=request.input_text,
            politeness_level=request.politeness_level
        )

        processing_time_ms = int((time.time() - start_time) * 1000)

        return ApiResponse(
            success=True,
            data=AIConversionResponse(
                converted_text=converted_text,
                original_text=request.input_text,
                politeness_level=request.politeness_level,
                processing_time_ms=processing_time_ms,
            ),
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "code": "AI_API_ERROR",
                "message": "AI変換APIからのレスポンスに失敗しました。",
            },
        )

async def call_external_ai_api(input_text: str, politeness_level: PolitenessLevel) -> str:
    # 実際の外部AI API呼び出し処理
    # （Claude API、OpenAI API等を使用）
    pass
```

---

## テスト用モックレスポンス

開発環境でのテスト用に、モックレスポンスを返すエンドポイントを用意:

### GET /api/v1/mock/ai/convert

```http
GET /api/v1/mock/ai/convert?input_text=水%20ぬるく&politeness_level=normal
```

**レスポンス**:

```json
{
  "success": true,
  "data": {
    "converted_text": "お水をぬるめでお願いします",
    "original_text": "水 ぬるく",
    "politeness_level": "normal",
    "processing_time_ms": 100
  },
  "error": null
}
```

このモックエンドポイントを使用することで、外部AI APIに依存せずにフロントエンド開発を進められます。
