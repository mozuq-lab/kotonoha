# TASK-0023 要件定義書

## 概要

AI変換機能のためのPydanticスキーマ定義を実装するタスク。FastAPIエンドポイントで使用するリクエスト/レスポンスのデータ構造を定義し、入力バリデーションとOpenAPI（Swagger）ドキュメント自動生成を可能にする。

**タスクタイプ**: TDD（テスト駆動開発）

**推定工数**: 8時間

**依存タスク**: TASK-0022（データベース接続プール・セッション管理実装）

## 機能要件

### FR-1: PolitenessLevel列挙型の定義
- `casual`（カジュアル）、`normal`（普通）、`polite`（丁寧）の3段階を定義すること
- 文字列型の列挙型（str, Enum）として実装すること
- 関連要件: REQ-902, REQ-903

### FR-2: AIConversionRequestスキーマの定義
- `input_text`: 変換元テキスト（必須）
- `politeness_level`: 丁寧さレベル（必須）
- 入力バリデーションを実装すること
- 関連要件: REQ-901

### FR-3: AIConversionResponseスキーマの定義
- `converted_text`: 変換後テキスト
- `original_text`: 元のテキスト（確認用）
- `politeness_level`: 使用した丁寧さレベル
- `processing_time_ms`: 処理時間（ミリ秒、整数）
- 関連要件: REQ-901

### FR-4: AIRegenerateRequestスキーマの定義
- `input_text`: 変換元テキスト（必須）
- `politeness_level`: 丁寧さレベル（必須）
- `previous_result`: 前回の変換結果（必須、重複回避用）
- 関連要件: REQ-904

### FR-5: 共通レスポンススキーマの定義
- `ApiResponse`: 統一レスポンス形式（success, data, error）
- `ErrorDetail`: エラー詳細（code, message, status_code）
- 関連要件: NFR-504

### FR-6: ヘルスチェックレスポンススキーマの定義
- `status`: サービス状態
- `version`: APIバージョン
- `timestamp`: タイムスタンプ

## 非機能要件

### NFR-1: OpenAPI（Swagger UI）ドキュメント自動生成
- すべてのスキーマがSwagger UIで正しく表示されること
- スキーマの説明（description）と例（example）が含まれること
- 関連要件: NFR-504

### NFR-2: 型安全性
- Pydantic v2の型ヒントを活用すること
- 実行時の型チェックが有効であること

### NFR-3: JSONシリアライズ/デシリアライズ
- Pydanticの自動変換機能を活用すること
- `from_attributes = True`でORMモデルからの変換をサポートすること

## バリデーション要件

### VR-1: input_textのバリデーション
- 最小文字数: 2文字（API仕様書に基づく）
- 最大文字数: 500文字（API仕様書に基づく）
- 空白のみの入力は拒否すること
- 前後の空白はトリムすること
- エラーコード: `VALIDATION_ERROR`

### VR-2: politeness_levelのバリデーション
- `casual`、`normal`、`polite`以外の値は拒否すること
- 大文字小文字を区別すること（小文字のみ受け入れ）
- エラーコード: `VALIDATION_ERROR`

### VR-3: previous_resultのバリデーション（再生成リクエスト）
- 空文字列は拒否すること
- 前回の変換結果として妥当な値であること

### VR-4: 境界値バリデーション
- 1文字の入力: エラー（2文字未満）
- 2文字の入力: 正常
- 500文字の入力: 正常
- 501文字の入力: エラー（500文字超過）

## エラーレスポンス要件

### ER-1: バリデーションエラーレスポンス
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力文字列は2文字以上500文字以下にしてください",
    "status_code": 400
  }
}
```

### ER-2: 不正な丁寧さレベルエラー
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "丁寧さレベルはcasual、normal、politeのいずれかを指定してください",
    "status_code": 400
  }
}
```

## 実装するスキーマファイル

### 1. app/schemas/common.py
- `PolitenessLevel`: 丁寧さレベル列挙型
- `ErrorDetail`: エラー詳細スキーマ
- `ApiResponse`: 統一APIレスポンススキーマ

### 2. app/schemas/ai_conversion.py
- `AIConversionRequest`: AI変換リクエストスキーマ
- `AIConversionResponse`: AI変換レスポンススキーマ
- `AIConversionData`: AI変換データスキーマ（ApiResponseのdata部分）
- `AIRegenerateRequest`: AI再変換リクエストスキーマ
- `AIConversionHistoryResponse`: 変換履歴レスポンススキーマ

### 3. app/schemas/health.py
- `HealthCheckResponse`: ヘルスチェックレスポンススキーマ

## 受け入れ基準

### AC-1: スキーマ定義の完全性
- [ ] PolitenessLevel列挙型が正しく定義されている
- [ ] AIConversionRequestスキーマが定義されている
- [ ] AIConversionResponseスキーマが定義されている
- [ ] AIRegenerateRequestスキーマが定義されている
- [ ] 共通レスポンススキーマ（ApiResponse、ErrorDetail）が定義されている
- [ ] ヘルスチェックレスポンススキーマが定義されている

### AC-2: バリデーション機能
- [ ] input_textの最小文字数（2文字）バリデーションが動作する
- [ ] input_textの最大文字数（500文字）バリデーションが動作する
- [ ] 空白のみの入力が拒否される
- [ ] 前後の空白がトリムされる
- [ ] 不正なpoliteness_levelが拒否される

### AC-3: OpenAPIドキュメント
- [ ] Swagger UI（/docs）でスキーマが表示される
- [ ] 各フィールドにdescriptionが設定されている
- [ ] 各スキーマにexampleが設定されている

### AC-4: テストカバレッジ
- [ ] 正常系テストが全て成功する
- [ ] 異常系テスト（バリデーションエラー）が全て成功する
- [ ] 境界値テストが全て成功する
- [ ] テストカバレッジ90%以上

### AC-5: コード品質
- [ ] Ruff + Black準拠
- [ ] 型ヒントが正しく設定されている
- [ ] docstringがGoogle Styleで記述されている

## テストケース概要

### 正常系テスト
1. 有効なAIConversionRequestの生成
2. 有効なAIConversionResponseの生成
3. 有効なAIRegenerateRequestの生成
4. 各PolitenessLevelでのリクエスト生成
5. 空白トリム機能の確認

### 異常系テスト
1. 空文字列のinput_text
2. 1文字のinput_text（最小文字数未満）
3. 501文字のinput_text（最大文字数超過）
4. 空白のみのinput_text
5. 不正なpoliteness_level値
6. 必須フィールドの欠落

### 境界値テスト
1. 2文字のinput_text（最小境界）
2. 500文字のinput_text（最大境界）
3. 日本語文字列のバリデーション
4. 混合文字列（日本語+英数字）のバリデーション

## 信頼性レベル

**評価: 青信号**

**根拠**:
- API仕様書（`docs/design/kotonoha/api-endpoints.md`）にリクエスト/レスポンス形式が明確に定義されている
- 文字数制限（2-500文字）がAPI仕様書に明記されている
- 丁寧さレベル（casual/normal/polite）が要件定義書（REQ-902, REQ-903）で定義されている
- エラーコード一覧がAPI仕様書に明記されている
- タスク詳細（`docs/tasks/kotonoha-phase2.md`）に実装例が含まれている

**注意点**:
- タスクファイルでは最大文字数が1000文字と記載されているが、API仕様書では500文字と定義されているため、API仕様書の500文字を採用する
- AIRegenerateRequestのフィールド名は、API仕様書の`previous_result`を採用する（タスクファイルの`previous_text`ではなく）

## 参考資料

- API仕様書: `/Volumes/external/dev/kotonoha/docs/design/kotonoha/api-endpoints.md`
- タスク詳細: `/Volumes/external/dev/kotonoha/docs/tasks/kotonoha-phase2.md`
- 要件定義書: `/Volumes/external/dev/kotonoha/docs/spec/kotonoha-requirements.md`
- 受け入れ基準: `/Volumes/external/dev/kotonoha/docs/spec/kotonoha-acceptance-criteria.md`
