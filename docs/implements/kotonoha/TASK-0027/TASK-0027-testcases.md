# TASK-0027: AI変換エンドポイント テストケース一覧

## TDDテストケースフェーズ

**タスクID**: TASK-0027
**タスク名**: AI変換エンドポイント実装（POST /api/v1/ai/convert）
**テストファイル**: `backend/tests/test_api/test_ai_convert.py`
**依存タスク**: TASK-0026（外部AI API連携実装 - 完了済み）

---

## モック戦略

### AIClientのモック方針

TASK-0027のテストでは、外部AI APIに依存しないテストを実現するため、以下のモック戦略を採用します。

#### 1. AIClientのモック

```python
from unittest.mock import AsyncMock, patch

# 方法1: ai_clientインスタンスのconvert_textメソッドをモック
@patch("app.api.v1.endpoints.ai.ai_client")
async def test_convert_success(mock_ai_client, test_client):
    mock_ai_client.convert_text = AsyncMock(
        return_value=("変換されたテキスト", 1500)
    )
    # テスト実行...

# 方法2: AIClientクラス全体をモック
@patch("app.utils.ai_client.AIClient")
async def test_convert_with_mock_class(MockAIClient):
    mock_instance = MockAIClient.return_value
    mock_instance.convert_text = AsyncMock(
        return_value=("変換されたテキスト", 1500)
    )
```

#### 2. 例外発生のモック

```python
from app.utils.exceptions import (
    AIConversionException,
    AITimeoutException,
    AIProviderException,
    AIRateLimitException,
)

# タイムアウト例外をモック
mock_ai_client.convert_text = AsyncMock(
    side_effect=AITimeoutException("AI API timeout")
)

# プロバイダーエラーをモック
mock_ai_client.convert_text = AsyncMock(
    side_effect=AIProviderException("Anthropic API key is not configured")
)
```

#### 3. データベースセッションのモック

```python
# conftest.pyで定義されたtest_client_with_dbフィクスチャを使用
# テスト用DBに接続し、トランザクションはロールバックされる
```

---

## テストケース一覧

### カテゴリA: 正常系テストケース

| テストID | テスト名 | 受け入れ基準 |
|----------|----------|--------------|
| TC-001 | 基本的なAI変換成功テスト | AC-001 |
| TC-002 | 丁寧さレベル「casual」変換テスト | AC-002 |
| TC-003 | 丁寧さレベル「normal」変換テスト | AC-001 |
| TC-004 | 丁寧さレベル「polite」変換テスト | AC-003 |
| TC-005 | レスポンスヘッダー検証テスト | AC-004 |
| TC-006 | processing_time_ms正値検証テスト | AC-001 |
| TC-007 | original_textトリム検証テスト | AC-107 |

### カテゴリB: 入力バリデーションテストケース

| テストID | テスト名 | 受け入れ基準 |
|----------|----------|--------------|
| TC-101 | 最小文字数（2文字）成功テスト | AC-101 |
| TC-102 | 最大文字数（500文字）成功テスト | AC-102 |
| TC-103 | 文字数不足（1文字）エラーテスト | AC-103 |
| TC-104 | 文字数超過（501文字）エラーテスト | AC-104 |
| TC-105 | 空白のみ入力エラーテスト | AC-105 |
| TC-106 | 空文字列入力エラーテスト | AC-105 |
| TC-107 | 不正な丁寧さレベルエラーテスト | AC-106 |
| TC-108 | input_text未指定エラーテスト | - |
| TC-109 | politeness_level未指定エラーテスト | - |

### カテゴリC: レート制限テストケース

| テストID | テスト名 | 受け入れ基準 |
|----------|----------|--------------|
| TC-201 | レート制限超過（429）テスト | AC-201 |
| TC-202 | Retry-Afterヘッダー検証テスト | AC-201 |
| TC-203 | レート制限リセット後成功テスト | AC-202 |

### カテゴリD: エラーハンドリングテストケース

| テストID | テスト名 | 受け入れ基準 |
|----------|----------|--------------|
| TC-301 | AIタイムアウトエラー（504）テスト | AC-301 |
| TC-302 | AIプロバイダーエラー（503）テスト | AC-302 |
| TC-303 | AI変換一般エラー（500）テスト | AC-303 |
| TC-304 | AIレート制限エラー（429）テスト | - |
| TC-305 | エラーレスポンス形式検証テスト | AC-301-303 |

### カテゴリE: ログ記録テストケース

| テストID | テスト名 | 受け入れ基準 |
|----------|----------|--------------|
| TC-401 | 成功時ログ記録テスト | AC-401 |
| TC-402 | 失敗時ログ記録テスト | AC-402 |
| TC-403 | ログのハッシュ化検証テスト | AC-403 |
| TC-404 | セッションID生成検証テスト | AC-401 |
| TC-405 | converted_text未保存検証テスト | AC-403 |

---

## 詳細テストケース定義

### TC-001: 基本的なAI変換成功テスト

**テストID**: TC-001
**テスト名**: 基本的なAI変換成功テスト
**テスト対象**: POST /api/v1/ai/convert エンドポイント
**関連する受け入れ基準**: AC-001

**前提条件**:
- AIClientのconvert_textメソッドがモックされている
- モックは正常な変換結果を返す設定

**テスト手順**:
1. 有効なリクエストボディを作成
   ```json
   {
     "input_text": "水 ぬるく",
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信
3. レスポンスを検証

**期待結果**:
- HTTPステータスコード: 200 OK
- レスポンスボディに以下が含まれる:
  - `converted_text`: 空でない文字列
  - `original_text`: "水 ぬるく"
  - `politeness_level`: "normal"
  - `processing_time_ms`: 正の整数

---

### TC-002: 丁寧さレベル「casual」変換テスト

**テストID**: TC-002
**テスト名**: 丁寧さレベル「casual」変換テスト
**テスト対象**: POST /api/v1/ai/convert エンドポイント
**関連する受け入れ基準**: AC-002

**前提条件**:
- AIClientのconvert_textメソッドがモックされている
- モックはカジュアルな変換結果を返す設定

**テスト手順**:
1. リクエストボディを作成
   ```json
   {
     "input_text": "ありがとう",
     "politeness_level": "casual"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信
3. レスポンスを検証

**期待結果**:
- HTTPステータスコード: 200 OK
- `politeness_level`: "casual"
- `converted_text`: 空でない文字列

---

### TC-003: 丁寧さレベル「normal」変換テスト

**テストID**: TC-003
**テスト名**: 丁寧さレベル「normal」変換テスト
**テスト対象**: POST /api/v1/ai/convert エンドポイント
**関連する受け入れ基準**: AC-001

**前提条件**:
- AIClientのconvert_textメソッドがモックされている

**テスト手順**:
1. リクエストボディを作成（politeness_level: "normal"）
2. POST /api/v1/ai/convert にリクエスト送信
3. レスポンスを検証

**期待結果**:
- HTTPステータスコード: 200 OK
- `politeness_level`: "normal"

---

### TC-004: 丁寧さレベル「polite」変換テスト

**テストID**: TC-004
**テスト名**: 丁寧さレベル「polite」変換テスト
**テスト対象**: POST /api/v1/ai/convert エンドポイント
**関連する受け入れ基準**: AC-003

**前提条件**:
- AIClientのconvert_textメソッドがモックされている
- モックは丁寧な変換結果を返す設定

**テスト手順**:
1. リクエストボディを作成
   ```json
   {
     "input_text": "ありがとう",
     "politeness_level": "polite"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信
3. レスポンスを検証

**期待結果**:
- HTTPステータスコード: 200 OK
- `politeness_level`: "polite"
- `converted_text`: 空でない文字列

---

### TC-005: レスポンスヘッダー検証テスト

**テストID**: TC-005
**テスト名**: レスポンスヘッダー検証テスト
**テスト対象**: POST /api/v1/ai/convert レスポンスヘッダー
**関連する受け入れ基準**: AC-004

**前提条件**:
- 正常なリクエストが処理される状態

**テスト手順**:
1. 有効なリクエストを送信
2. レスポンスヘッダーを検証

**期待結果**:
- `X-RateLimit-Limit` ヘッダーが存在
- `X-RateLimit-Remaining` ヘッダーが存在
- `X-RateLimit-Reset` ヘッダーが存在
- `X-RateLimit-Limit` の値が "1"
- `X-RateLimit-Remaining` の値が "0"（リクエスト後）

---

### TC-006: processing_time_ms正値検証テスト

**テストID**: TC-006
**テスト名**: processing_time_ms正値検証テスト
**テスト対象**: レスポンスのprocessing_time_msフィールド
**関連する受け入れ基準**: AC-001

**前提条件**:
- AIClientが処理時間を計測してモック値を返す

**テスト手順**:
1. 有効なリクエストを送信
2. レスポンスのprocessing_time_msを検証

**期待結果**:
- `processing_time_ms` >= 0
- `processing_time_ms` が整数型

---

### TC-007: original_textトリム検証テスト

**テストID**: TC-007
**テスト名**: original_textトリム検証テスト
**テスト対象**: 入力テキストの前後空白トリム処理
**関連する受け入れ基準**: AC-107

**前提条件**:
- AIClientがモックされている

**テスト手順**:
1. 前後に空白を含むリクエストを作成
   ```json
   {
     "input_text": "  こんにちは  ",
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信
3. レスポンスを検証

**期待結果**:
- HTTPステータスコード: 200 OK
- `original_text`: "こんにちは"（トリム済み）

---

### TC-101: 最小文字数（2文字）成功テスト

**テストID**: TC-101
**テスト名**: 最小文字数（2文字）成功テスト
**テスト対象**: 入力バリデーション - 最小文字数
**関連する受け入れ基準**: AC-101

**前提条件**:
- AIClientがモックされている

**テスト手順**:
1. 2文字の入力テキストでリクエスト
   ```json
   {
     "input_text": "こん",
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 200 OK
- 変換が成功する

---

### TC-102: 最大文字数（500文字）成功テスト

**テストID**: TC-102
**テスト名**: 最大文字数（500文字）成功テスト
**テスト対象**: 入力バリデーション - 最大文字数
**関連する受け入れ基準**: AC-102

**前提条件**:
- AIClientがモックされている

**テスト手順**:
1. 500文字の入力テキストでリクエスト
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 200 OK
- 変換が成功する

---

### TC-103: 文字数不足（1文字）エラーテスト

**テストID**: TC-103
**テスト名**: 文字数不足（1文字）エラーテスト
**テスト対象**: 入力バリデーション - 最小文字数違反
**関連する受け入れ基準**: AC-103

**前提条件**:
- なし（バリデーションでエラーになる）

**テスト手順**:
1. 1文字の入力テキストでリクエスト
   ```json
   {
     "input_text": "あ",
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity
- エラーメッセージに文字数制限の説明が含まれる

---

### TC-104: 文字数超過（501文字）エラーテスト

**テストID**: TC-104
**テスト名**: 文字数超過（501文字）エラーテスト
**テスト対象**: 入力バリデーション - 最大文字数違反
**関連する受け入れ基準**: AC-104

**前提条件**:
- なし

**テスト手順**:
1. 501文字の入力テキストでリクエスト
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity
- エラーメッセージが含まれる

---

### TC-105: 空白のみ入力エラーテスト

**テストID**: TC-105
**テスト名**: 空白のみ入力エラーテスト
**テスト対象**: 入力バリデーション - 空白のみ入力
**関連する受け入れ基準**: AC-105

**前提条件**:
- なし

**テスト手順**:
1. 空白のみの入力テキストでリクエスト
   ```json
   {
     "input_text": "   ",
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity

---

### TC-106: 空文字列入力エラーテスト

**テストID**: TC-106
**テスト名**: 空文字列入力エラーテスト
**テスト対象**: 入力バリデーション - 空文字列
**関連する受け入れ基準**: AC-105

**前提条件**:
- なし

**テスト手順**:
1. 空文字列の入力テキストでリクエスト
   ```json
   {
     "input_text": "",
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity

---

### TC-107: 不正な丁寧さレベルエラーテスト

**テストID**: TC-107
**テスト名**: 不正な丁寧さレベルエラーテスト
**テスト対象**: 入力バリデーション - 丁寧さレベル
**関連する受け入れ基準**: AC-106

**前提条件**:
- なし

**テスト手順**:
1. 不正な丁寧さレベルでリクエスト
   ```json
   {
     "input_text": "こんにちは",
     "politeness_level": "invalid"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity
- エラーメッセージが丁寧さレベルに関するものである

---

### TC-108: input_text未指定エラーテスト

**テストID**: TC-108
**テスト名**: input_text未指定エラーテスト
**テスト対象**: 入力バリデーション - 必須フィールド
**関連する受け入れ基準**: -

**前提条件**:
- なし

**テスト手順**:
1. input_textを含まないリクエスト
   ```json
   {
     "politeness_level": "normal"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity

---

### TC-109: politeness_level未指定エラーテスト

**テストID**: TC-109
**テスト名**: politeness_level未指定エラーテスト
**テスト対象**: 入力バリデーション - 必須フィールド
**関連する受け入れ基準**: -

**前提条件**:
- なし

**テスト手順**:
1. politeness_levelを含まないリクエスト
   ```json
   {
     "input_text": "こんにちは"
   }
   ```
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 422 Unprocessable Entity

---

### TC-201: レート制限超過（429）テスト

**テストID**: TC-201
**テスト名**: レート制限超過（429）テスト
**テスト対象**: レート制限ミドルウェア
**関連する受け入れ基準**: AC-201

**前提条件**:
- レート制限がリセットされた状態

**テスト手順**:
1. 1回目のリクエストを送信（成功）
2. 即座に2回目のリクエストを送信

**期待結果**:
- 1回目: HTTPステータスコード 200 OK
- 2回目: HTTPステータスコード 429 Too Many Requests

---

### TC-202: Retry-Afterヘッダー検証テスト

**テストID**: TC-202
**テスト名**: Retry-Afterヘッダー検証テスト
**テスト対象**: レート制限レスポンスヘッダー
**関連する受け入れ基準**: AC-201

**前提条件**:
- レート制限超過状態

**テスト手順**:
1. レート制限を超過させる
2. 429レスポンスのヘッダーを検証

**期待結果**:
- `Retry-After` ヘッダーが存在
- 値が1-10秒の範囲内

---

### TC-203: レート制限リセット後成功テスト

**テストID**: TC-203
**テスト名**: レート制限リセット後成功テスト
**テスト対象**: レート制限リセット動作
**関連する受け入れ基準**: AC-202

**前提条件**:
- レート制限を手動でリセット可能なモック環境

**テスト手順**:
1. 1回目のリクエストを送信（成功）
2. リミッターをリセット（10秒経過をシミュレート）
3. 2回目のリクエストを送信

**期待結果**:
- 2回目: HTTPステータスコード 200 OK

---

### TC-301: AIタイムアウトエラー（504）テスト

**テストID**: TC-301
**テスト名**: AIタイムアウトエラー（504）テスト
**テスト対象**: エラーハンドリング - タイムアウト
**関連する受け入れ基準**: AC-301

**前提条件**:
- AIClientがAITimeoutExceptionをスローするようモック

**テスト手順**:
1. AIClientのconvert_textがAITimeoutExceptionをスローするよう設定
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 504 Gateway Timeout
- エラーコード: "AI_API_TIMEOUT"
- エラーメッセージが含まれる

---

### TC-302: AIプロバイダーエラー（503）テスト

**テストID**: TC-302
**テスト名**: AIプロバイダーエラー（503）テスト
**テスト対象**: エラーハンドリング - プロバイダーエラー
**関連する受け入れ基準**: AC-302

**前提条件**:
- AIClientがAIProviderExceptionをスローするようモック

**テスト手順**:
1. AIClientのconvert_textがAIProviderExceptionをスローするよう設定
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 503 Service Unavailable
- エラーコード: "AI_PROVIDER_ERROR"

---

### TC-303: AI変換一般エラー（500）テスト

**テストID**: TC-303
**テスト名**: AI変換一般エラー（500）テスト
**テスト対象**: エラーハンドリング - 一般エラー
**関連する受け入れ基準**: AC-303

**前提条件**:
- AIClientがAIConversionExceptionをスローするようモック

**テスト手順**:
1. AIClientのconvert_textがAIConversionExceptionをスローするよう設定
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 500 Internal Server Error
- エラーコード: "AI_API_ERROR"
- エラーメッセージ: 「AI変換APIからのレスポンスに失敗しました」を含む

---

### TC-304: AIレート制限エラー（429）テスト

**テストID**: TC-304
**テスト名**: AIレート制限エラー（429）テスト
**テスト対象**: エラーハンドリング - AIレート制限
**関連する受け入れ基準**: -

**前提条件**:
- AIClientがAIRateLimitExceptionをスローするようモック

**テスト手順**:
1. AIClientのconvert_textがAIRateLimitExceptionをスローするよう設定
2. POST /api/v1/ai/convert にリクエスト送信

**期待結果**:
- HTTPステータスコード: 429 Too Many Requests
- エラーコード: "AI_RATE_LIMIT"

---

### TC-305: エラーレスポンス形式検証テスト

**テストID**: TC-305
**テスト名**: エラーレスポンス形式検証テスト
**テスト対象**: エラーレスポンスJSON形式
**関連する受け入れ基準**: AC-301, AC-302, AC-303

**前提条件**:
- AIClientがエラーをスローするようモック

**テスト手順**:
1. エラー状態を作成
2. エラーレスポンスの形式を検証

**期待結果**:
- レスポンスJSONに以下が含まれる:
  ```json
  {
    "success": false,
    "data": null,
    "error": {
      "code": "<エラーコード>",
      "message": "<エラーメッセージ>",
      "status_code": <ステータスコード>
    }
  }
  ```

---

### TC-401: 成功時ログ記録テスト

**テストID**: TC-401
**テスト名**: 成功時ログ記録テスト
**テスト対象**: AIConversionLogの作成（成功時）
**関連する受け入れ基準**: AC-401

**前提条件**:
- テスト用データベースに接続
- AIClientがモックされている

**テスト手順**:
1. 有効なリクエストを送信（成功）
2. データベースからAIConversionLogを検索

**期待結果**:
- AIConversionLogレコードが作成されている
- `is_success` が True
- `input_text_hash` がSHA-256ハッシュ値（64文字）
- `session_id` がUUID形式
- `politeness_level` が指定された値
- `conversion_time_ms` が正の整数

---

### TC-402: 失敗時ログ記録テスト

**テストID**: TC-402
**テスト名**: 失敗時ログ記録テスト
**テスト対象**: AIConversionLogの作成（失敗時）
**関連する受け入れ基準**: AC-402

**前提条件**:
- テスト用データベースに接続
- AIClientがエラーをスローするようモック

**テスト手順**:
1. AIClientがエラーをスローするよう設定
2. リクエストを送信（失敗）
3. データベースからAIConversionLogを検索

**期待結果**:
- AIConversionLogレコードが作成されている
- `is_success` が False
- `error_message` にエラー内容が記録されている

---

### TC-403: ログのハッシュ化検証テスト

**テストID**: TC-403
**テスト名**: ログのハッシュ化検証テスト
**テスト対象**: 入力テキストのハッシュ化
**関連する受け入れ基準**: AC-403

**前提条件**:
- テスト用データベースに接続

**テスト手順**:
1. 入力テキスト「秘密の情報」でリクエスト
2. データベースからAIConversionLogを検索
3. input_text_hashを検証

**期待結果**:
- `input_text_hash` が64文字のSHA-256ハッシュ値
- `input_text_hash` から元のテキストを復元不可能
- 同じ入力テキストは同じハッシュ値を生成

---

### TC-404: セッションID生成検証テスト

**テストID**: TC-404
**テスト名**: セッションID生成検証テスト
**テスト対象**: セッションIDの自動生成
**関連する受け入れ基準**: AC-401

**前提条件**:
- テスト用データベースに接続

**テスト手順**:
1. リクエストを送信
2. ログのsession_idを検証

**期待結果**:
- `session_id` がUUID形式（36文字、ハイフン区切り）
- 各リクエストで一意のsession_idが生成される

---

### TC-405: converted_text未保存検証テスト

**テストID**: TC-405
**テスト名**: converted_text未保存検証テスト
**テスト対象**: プライバシー保護 - 変換結果の非保存
**関連する受け入れ基準**: AC-403

**前提条件**:
- テスト用データベースに接続

**テスト手順**:
1. リクエストを送信（成功）
2. AIConversionLogモデルのカラムを確認

**期待結果**:
- AIConversionLogテーブルに `converted_text` カラムが存在しない
- 出力は `output_length`（文字数）のみ保存

---

## テストファイル構成

```
backend/tests/
├── test_api/
│   └── test_ai_convert.py          # TASK-0027テストファイル（新規作成）
├── conftest.py                      # テストフィクスチャ（既存）
└── ...
```

### test_ai_convert.py 構成案

```python
"""
AI変換エンドポイントテスト

TASK-0027: AI変換エンドポイント実装（POST /api/v1/ai/convert）
"""

import pytest
from unittest.mock import AsyncMock, patch
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.core.rate_limit import limiter
from app.utils.exceptions import (
    AIConversionException,
    AITimeoutException,
    AIProviderException,
    AIRateLimitException,
)


@pytest.fixture(autouse=True)
def reset_limiter():
    """各テスト前にリミッターをリセット"""
    limiter.reset()
    yield
    limiter.reset()


# ================================================================================
# カテゴリA: 正常系テストケース
# ================================================================================

class TestAIConvertSuccess:
    """AI変換正常系テスト"""

    @pytest.mark.asyncio
    async def test_tc001_基本的なai変換成功テスト(self):
        """TC-001: 基本的なAI変換成功テスト"""
        ...

    # ... 他のテストケース


# ================================================================================
# カテゴリB: 入力バリデーションテストケース
# ================================================================================

class TestAIConvertValidation:
    """AI変換入力バリデーションテスト"""
    ...


# ================================================================================
# カテゴリC: レート制限テストケース
# ================================================================================

class TestAIConvertRateLimit:
    """AI変換レート制限テスト"""
    ...


# ================================================================================
# カテゴリD: エラーハンドリングテストケース
# ================================================================================

class TestAIConvertErrorHandling:
    """AI変換エラーハンドリングテスト"""
    ...


# ================================================================================
# カテゴリE: ログ記録テストケース
# ================================================================================

class TestAIConvertLogging:
    """AI変換ログ記録テスト"""
    ...
```

---

## 実行コマンド

```bash
# TASK-0027テストのみ実行
pytest backend/tests/test_api/test_ai_convert.py -v

# カバレッジ付きで実行
pytest backend/tests/test_api/test_ai_convert.py --cov=app.api.v1.endpoints.ai --cov-report=term-missing

# 特定のテストクラスのみ実行
pytest backend/tests/test_api/test_ai_convert.py::TestAIConvertSuccess -v

# 特定のテストケースのみ実行
pytest backend/tests/test_api/test_ai_convert.py::TestAIConvertSuccess::test_tc001_基本的なai変換成功テスト -v
```

---

## 変更履歴

| 日付 | 変更者 | 内容 |
|------|--------|------|
| 2025-11-22 | Claude | 初版作成（TDDテストケースフェーズ） |
