# TASK-0027: AI変換エンドポイント実装（POST /api/v1/ai/convert）

## TDD要件定義フェーズ

**タスクID**: TASK-0027
**タスク名**: AI変換エンドポイント実装（POST /api/v1/ai/convert）
**タスクタイプ**: TDD
**依存タスク**: TASK-0026（外部AI API連携実装 - 完了済み）

---

## 関連要件

| 要件ID | 内容 | 信頼性 |
|--------|------|--------|
| REQ-901 | 入力文字列を指定の丁寧さレベルでAI変換 | 🔵 |
| REQ-902 | 3段階の丁寧さレベル選択（casual/normal/polite） | 🔵 |
| REQ-903 | AI変換の丁寧さレベルを選択可能 | 🔵 |
| NFR-002 | AI変換の応答時間を平均3秒以内 | 🟡 |
| NFR-101 | レート制限（1リクエスト/10秒/IP） | 🔵 |
| NFR-102 | AI変換時のプライバシー保護（ログはハッシュ化） | 🔵 |
| EDGE-002 | AI変換APIエラー時のフォールバック処理 | 🔵 |

---

## 1. 機能要件一覧

### 1.1 エンドポイント基本仕様

| 項目 | 値 |
|------|-----|
| メソッド | POST |
| パス | /api/v1/ai/convert |
| 認証 | 不要（MVP範囲） |
| レート制限 | 10秒に1回/IP |

### 1.2 機能要件詳細

#### FR-001: テキスト変換機能
- 入力テキストを指定された丁寧さレベルでAI変換する
- AIクライアント（`ai_client.convert_text`）を使用して変換を実行
- 変換結果と処理時間をレスポンスに含める

#### FR-002: 丁寧さレベル選択
- 3段階の丁寧さレベルをサポート:
  - `casual`: カジュアルな表現（タメ口）
  - `normal`: 普通の丁寧さ（です・ます調）
  - `polite`: 丁寧な表現（敬語）

#### FR-003: 入力バリデーション
- 入力テキストの文字数制限: 2文字以上500文字以下
- 丁寧さレベルは `casual`, `normal`, `polite` のいずれか
- 空白のみの入力は拒否（トリム後にバリデーション）

#### FR-004: レスポンス形式
- 成功時: 変換後テキスト、元テキスト、丁寧さレベル、処理時間を返す
- 失敗時: エラーコード、エラーメッセージ、HTTPステータスコードを返す

#### FR-005: ログ記録機能
- 変換成功時: AIConversionLogを作成（入力テキストはハッシュ化）
- 変換失敗時: エラー情報を含むAIConversionLogを作成
- セッションIDを生成して記録

---

## 2. 非機能要件一覧

### 2.1 パフォーマンス要件

| 要件ID | 内容 | 目標値 |
|--------|------|--------|
| NFR-P01 | AI変換応答時間 | 平均3秒以内 |
| NFR-P02 | タイムアウト時間 | 30秒（AI_API_TIMEOUT設定値） |

### 2.2 セキュリティ要件

| 要件ID | 内容 |
|--------|------|
| NFR-S01 | 入力テキストはログにSHA-256ハッシュ化して保存 |
| NFR-S02 | 変換結果（converted_text）はログに保存しない |
| NFR-S03 | セッションIDはUUIDを使用 |

### 2.3 レート制限要件

| 要件ID | 内容 | 設定値 |
|--------|------|--------|
| NFR-R01 | リクエスト制限 | 10秒に1回/IP |
| NFR-R02 | 制限超過時のレスポンスコード | 429 Too Many Requests |
| NFR-R03 | Retry-Afterヘッダー | 10秒 |

---

## 3. 入力/出力仕様

### 3.1 リクエスト仕様

#### リクエストボディ（AIConversionRequest）

```json
{
  "input_text": "水 ぬるく",
  "politeness_level": "normal"
}
```

| フィールド | 型 | 必須 | バリデーション |
|-----------|---|------|---------------|
| input_text | string | ✓ | 2文字以上500文字以下、空白のみ不可 |
| politeness_level | string | ✓ | `casual`, `normal`, `polite` のいずれか |

### 3.2 レスポンス仕様

#### 成功レスポンス（200 OK）

```json
{
  "converted_text": "お水をぬるめでお願いします",
  "original_text": "水 ぬるく",
  "politeness_level": "normal",
  "processing_time_ms": 2500
}
```

| フィールド | 型 | 説明 |
|-----------|---|------|
| converted_text | string | 変換後のテキスト |
| original_text | string | 変換元のテキスト |
| politeness_level | string | 適用された丁寧さレベル |
| processing_time_ms | integer | 処理時間（ミリ秒） |

#### レスポンスヘッダー（成功時）

```http
X-RateLimit-Limit: 1
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 10
```

---

## 4. エラー処理仕様

### 4.1 エラーコード一覧

| HTTPステータス | エラーコード | 説明 | 発生条件 |
|---------------|-------------|------|----------|
| 400 | VALIDATION_ERROR | バリデーションエラー | 入力値不正 |
| 422 | VALIDATION_ERROR | バリデーションエラー | Pydanticバリデーション失敗 |
| 429 | RATE_LIMIT_EXCEEDED | レート制限超過 | 10秒以内の再リクエスト |
| 500 | AI_API_ERROR | AI APIエラー | AIConversionException |
| 503 | AI_PROVIDER_ERROR | AIプロバイダーエラー | AIProviderException |
| 504 | AI_API_TIMEOUT | AI APIタイムアウト | AITimeoutException |

### 4.2 エラーレスポンス形式

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

### 4.3 例外ハンドリングマッピング

| 例外クラス | HTTPステータス | エラーコード |
|-----------|---------------|-------------|
| AITimeoutException | 504 | AI_API_TIMEOUT |
| AIRateLimitException | 429 | AI_RATE_LIMIT |
| AIProviderException | 503 | AI_PROVIDER_ERROR |
| AIConversionException | 500 | AI_API_ERROR |
| ValidationError (Pydantic) | 422 | VALIDATION_ERROR |

---

## 5. テスト可能な受け入れ基準

### 5.1 正常系テスト

#### AC-001: 基本的なAI変換
- **Given**: 有効な入力テキスト「水 ぬるく」と丁寧さレベル「normal」
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKと変換結果を含むレスポンスが返される
- **And**: processing_time_msが正の整数である

#### AC-002: 丁寧さレベル「casual」での変換
- **Given**: 入力テキスト「ありがとう」と丁寧さレベル「casual」
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKとカジュアルな変換結果が返される

#### AC-003: 丁寧さレベル「polite」での変換
- **Given**: 入力テキスト「ありがとう」と丁寧さレベル「polite」
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKと丁寧な変換結果が返される

#### AC-004: レスポンスヘッダーの検証
- **Given**: 有効なリクエスト
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Resetヘッダーが含まれる

### 5.2 入力バリデーションテスト

#### AC-101: 最小文字数（2文字）の入力
- **Given**: 入力テキスト「こん」（2文字）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKで変換が成功する

#### AC-102: 最大文字数（500文字）の入力
- **Given**: 入力テキスト（500文字）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKで変換が成功する

#### AC-103: 文字数不足（1文字以下）のエラー
- **Given**: 入力テキスト「あ」（1文字）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 422 Unprocessable Entityが返される
- **And**: エラーメッセージに文字数制限の説明が含まれる

#### AC-104: 文字数超過（501文字以上）のエラー
- **Given**: 入力テキスト（501文字）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 422 Unprocessable Entityが返される

#### AC-105: 空白のみの入力エラー
- **Given**: 入力テキスト「   」（空白のみ）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 422 Unprocessable Entityが返される

#### AC-106: 不正な丁寧さレベルのエラー
- **Given**: 丁寧さレベル「invalid」
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 422 Unprocessable Entityが返される

#### AC-107: 入力テキストの前後空白トリム
- **Given**: 入力テキスト「  こんにちは  」（前後に空白）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKが返され、original_textが「こんにちは」（トリム済み）

### 5.3 レート制限テスト

#### AC-201: レート制限超過エラー
- **Given**: 10秒以内に2回目のリクエスト
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 429 Too Many Requestsが返される
- **And**: Retry-Afterヘッダーが10秒を示す

#### AC-202: レート制限リセット後の成功
- **Given**: 前回リクエストから10秒以上経過
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 200 OKで変換が成功する

### 5.4 エラーハンドリングテスト

#### AC-301: AIタイムアウトエラー
- **Given**: AI APIがタイムアウトする状況（モック）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 504 Gateway Timeoutが返される
- **And**: エラーコードが「AI_API_TIMEOUT」

#### AC-302: AIプロバイダーエラー
- **Given**: AIプロバイダーが利用不可（APIキー未設定等）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 503 Service Unavailableが返される
- **And**: エラーコードが「AI_PROVIDER_ERROR」

#### AC-303: AI変換エラー（一般）
- **Given**: AI APIが変換エラーを返す状況（モック）
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: 500 Internal Server Errorが返される
- **And**: エラーコードが「AI_API_ERROR」

### 5.5 ログ記録テスト

#### AC-401: 成功時のログ記録
- **Given**: 有効なリクエスト
- **When**: POST /api/v1/ai/convert にリクエスト（成功）
- **Then**: AIConversionLogが作成される
- **And**: is_successがTrue
- **And**: input_text_hashがSHA-256ハッシュ値（64文字）

#### AC-402: 失敗時のログ記録
- **Given**: AI APIがエラーを返す状況
- **When**: POST /api/v1/ai/convert にリクエスト（失敗）
- **Then**: AIConversionLogが作成される
- **And**: is_successがFalse
- **And**: error_messageにエラー内容が記録される

#### AC-403: ログのプライバシー保護
- **Given**: 入力テキスト「秘密の情報」
- **When**: POST /api/v1/ai/convert にリクエスト
- **Then**: AIConversionLogのinput_text_hashは元テキストから復元不可能
- **And**: 変換後テキストはログに保存されない

---

## 6. 実装対象ファイル

### 6.1 新規作成ファイル

| ファイルパス | 内容 |
|-------------|------|
| `backend/app/crud/crud_ai_conversion.py` | AI変換ログのCRUD操作 |

### 6.2 修正対象ファイル

| ファイルパス | 修正内容 |
|-------------|----------|
| `backend/app/api/v1/endpoints/ai.py` | 仮実装→本実装への変更 |
| `backend/app/crud/__init__.py` | crud_ai_conversionのエクスポート追加 |

---

## 7. 依存コンポーネント（既存実装）

### 7.1 スキーマ（TASK-0023で実装済み）

| ファイル | クラス |
|----------|--------|
| `app/schemas/ai_conversion.py` | AIConversionRequest |
| `app/schemas/ai_conversion.py` | AIConversionResponse |
| `app/schemas/common.py` | PolitenessLevel |
| `app/schemas/common.py` | ErrorDetail |
| `app/schemas/common.py` | ApiResponse |

### 7.2 AIクライアント（TASK-0026で実装済み）

| ファイル | クラス/関数 |
|----------|------------|
| `app/utils/ai_client.py` | AIClient |
| `app/utils/ai_client.py` | ai_client（シングルトンインスタンス） |
| `app/utils/ai_client.py` | convert_text() |

### 7.3 例外クラス（TASK-0026で実装済み）

| ファイル | クラス |
|----------|--------|
| `app/utils/exceptions.py` | AIConversionException |
| `app/utils/exceptions.py` | AITimeoutException |
| `app/utils/exceptions.py` | AIRateLimitException |
| `app/utils/exceptions.py` | AIProviderException |

### 7.4 モデル（TASK-0024で実装済み）

| ファイル | クラス |
|----------|--------|
| `app/models/ai_conversion_logs.py` | AIConversionLog |
| `app/models/ai_conversion_history.py` | AIConversionHistory |

### 7.5 レート制限（TASK-0025で実装済み）

| ファイル | 関数/変数 |
|----------|----------|
| `app/core/rate_limit.py` | limiter |
| `app/core/rate_limit.py` | AI_RATE_LIMIT（"1/10seconds"） |
| `app/core/rate_limit.py` | rate_limit_exceeded_handler |

---

## 8. 設計上の考慮事項

### 8.1 CRUD関数の設計

```python
# crud_ai_conversion.py

async def create_conversion_log(
    db: AsyncSession,
    input_text: str,
    output_text: str,
    politeness_level: str,
    conversion_time_ms: int | None,
    session_id: uuid.UUID,
    is_success: bool = True,
    error_message: str | None = None,
    ai_provider: str = "anthropic",
) -> AIConversionLog:
    """AI変換ログを作成（入力テキストはハッシュ化）"""
    ...
```

### 8.2 エンドポイント実装の流れ

1. リクエストバリデーション（Pydanticスキーマ）
2. セッションID生成
3. AI変換実行（ai_client.convert_text）
4. ログ記録（CRUD関数経由）
5. レスポンス生成

### 8.3 エラーハンドリングの流れ

```
try:
    AI変換実行
    成功ログ記録
    成功レスポンス返却
except AITimeoutException:
    失敗ログ記録
    504レスポンス返却
except AIRateLimitException:
    失敗ログ記録
    429レスポンス返却
except AIProviderException:
    失敗ログ記録
    503レスポンス返却
except AIConversionException:
    失敗ログ記録
    500レスポンス返却
```

---

## 9. 備考

### 9.1 現在の仮実装状態

`backend/app/api/v1/endpoints/ai.py` には仮実装が存在:
- 入力テキストに「（変換済み）」を付加して返すダミー処理
- レート制限は既に適用済み

### 9.2 スキーマの文字数制限について

現在の `AIConversionRequest` スキーマでは:
- `INPUT_TEXT_MAX_LENGTH = 500`（スキーマ定義）

タスク仕様書では「最大入力文字数: 1000文字」と記載があるが、既存スキーマ（500文字）と要件定義書の整合性を確認する必要がある。本実装では既存スキーマの500文字を維持する。

### 9.3 レート制限の仕様差異

- タスク仕様書: 「10秒に1回」
- api-endpoints.md: 「1分間に10リクエスト」

現在の実装（rate_limit.py）は「10秒に1回」で実装済み。

---

## 変更履歴

| 日付 | 変更者 | 内容 |
|------|--------|------|
| 2025-11-22 | Claude | 初版作成（TDD要件定義フェーズ） |
