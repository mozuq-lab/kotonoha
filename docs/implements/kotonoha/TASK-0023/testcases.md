# TASK-0023 テストケース一覧

## 概要

Pydanticスキーマ定義（AI変換リクエスト・レスポンス）のテストケース一覧。
要件定義書およびAPI仕様書に基づいて作成。

**関連ファイル**:
- 要件定義書: `docs/implements/kotonoha/TASK-0023/requirements.md`
- API仕様書: `docs/design/kotonoha/api-endpoints.md`

**テスト対象スキーマ**:
- `app/schemas/common.py`: PolitenessLevel, ErrorDetail, ApiResponse
- `app/schemas/ai_conversion.py`: AIConversionRequest, AIConversionResponse, AIRegenerateRequest
- `app/schemas/health.py`: HealthCheckResponse

---

## A. PolitenessLevel列挙型テスト

### TC-A01: casual値の定義
- **ID**: TC-A01
- **説明**: PolitenessLevel列挙型のcasual値が正しく定義されていることを確認
- **入力**: `PolitenessLevel.CASUAL`
- **期待結果**:
  - `PolitenessLevel.CASUAL.value == "casual"`
  - 文字列として"casual"にシリアライズされる
- **関連要件**: FR-1

### TC-A02: normal値の定義
- **ID**: TC-A02
- **説明**: PolitenessLevel列挙型のnormal値が正しく定義されていることを確認
- **入力**: `PolitenessLevel.NORMAL`
- **期待結果**:
  - `PolitenessLevel.NORMAL.value == "normal"`
  - 文字列として"normal"にシリアライズされる
- **関連要件**: FR-1

### TC-A03: polite値の定義
- **ID**: TC-A03
- **説明**: PolitenessLevel列挙型のpolite値が正しく定義されていることを確認
- **入力**: `PolitenessLevel.POLITE`
- **期待結果**:
  - `PolitenessLevel.POLITE.value == "polite"`
  - 文字列として"polite"にシリアライズされる
- **関連要件**: FR-1

### TC-A04: 不正な値の拒否
- **ID**: TC-A04
- **説明**: PolitenessLevelとして定義されていない値が拒否されることを確認
- **入力**:
  - `"invalid"`
  - `"CASUAL"` (大文字)
  - `"formal"`
  - `123`
  - `None`
- **期待結果**: ValueError または ValidationError が発生
- **関連要件**: VR-2

### TC-A05: 文字列からの変換
- **ID**: TC-A05
- **説明**: 文字列"casual", "normal", "polite"から列挙型への変換が正しく動作する
- **入力**: `"casual"`, `"normal"`, `"polite"`
- **期待結果**: 対応するPolitenessLevel列挙型に変換される
- **関連要件**: FR-1

---

## B. AIConversionRequestバリデーションテスト

### TC-B01: 正常なリクエスト（通常文字列）
- **ID**: TC-B01
- **説明**: 正常なパラメータでAIConversionRequestが生成できることを確認
- **入力**:
  ```python
  {
      "input_text": "水 ぬるく",
      "politeness_level": "normal"
  }
  ```
- **期待結果**:
  - インスタンスが正常に生成される
  - `input_text == "水 ぬるく"`
  - `politeness_level == PolitenessLevel.NORMAL`
- **関連要件**: FR-2

### TC-B02: 最小文字数（2文字）の境界値
- **ID**: TC-B02
- **説明**: 最小文字数（2文字）のinput_textが受け入れられることを確認
- **入力**:
  ```python
  {
      "input_text": "水水",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: VR-1, VR-4

### TC-B03: 最大文字数（500文字）の境界値
- **ID**: TC-B03
- **説明**: 最大文字数（500文字）のinput_textが受け入れられることを確認
- **入力**:
  ```python
  {
      "input_text": "あ" * 500,  # 500文字のひらがな
      "politeness_level": "normal"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: VR-1, VR-4

### TC-B04: 最小未満（1文字）はエラー
- **ID**: TC-B04
- **説明**: 1文字のinput_textがバリデーションエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "水",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: ValidationError発生（2文字未満）
- **関連要件**: VR-1, VR-4

### TC-B05: 最大超過（501文字）はエラー
- **ID**: TC-B05
- **説明**: 501文字のinput_textがバリデーションエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "あ" * 501,  # 501文字のひらがな
      "politeness_level": "normal"
  }
  ```
- **期待結果**: ValidationError発生（500文字超過）
- **関連要件**: VR-1, VR-4

### TC-B06: 空文字列はエラー
- **ID**: TC-B06
- **説明**: 空文字列のinput_textがバリデーションエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: ValidationError発生
- **関連要件**: VR-1

### TC-B07: 空白のみはエラー
- **ID**: TC-B07
- **説明**: 空白のみのinput_textがバリデーションエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "   ",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: ValidationError発生（トリム後に2文字未満）
- **関連要件**: VR-1

### TC-B08: 前後空白はトリムされる
- **ID**: TC-B08
- **説明**: 前後の空白がトリムされることを確認
- **入力**:
  ```python
  {
      "input_text": "  水 ぬるく  ",
      "politeness_level": "normal"
  }
  ```
- **期待結果**:
  - インスタンスが正常に生成される
  - `input_text == "水 ぬるく"` （前後の空白がトリムされる）
- **関連要件**: VR-1

### TC-B09: 各丁寧さレベルが受け入れられる
- **ID**: TC-B09
- **説明**: casual, normal, politeの各丁寧さレベルが受け入れられることを確認
- **入力**:
  ```python
  [
      {"input_text": "テスト", "politeness_level": "casual"},
      {"input_text": "テスト", "politeness_level": "normal"},
      {"input_text": "テスト", "politeness_level": "polite"}
  ]
  ```
- **期待結果**: すべてのケースでインスタンスが正常に生成される
- **関連要件**: FR-2, VR-2

### TC-B10: 必須フィールドの欠落（input_text）
- **ID**: TC-B10
- **説明**: input_textが欠落している場合にエラーになることを確認
- **入力**:
  ```python
  {
      "politeness_level": "normal"
  }
  ```
- **期待結果**: ValidationError発生（必須フィールド欠落）
- **関連要件**: FR-2

### TC-B11: 必須フィールドの欠落（politeness_level）
- **ID**: TC-B11
- **説明**: politeness_levelが欠落している場合にエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "テスト"
  }
  ```
- **期待結果**: ValidationError発生（必須フィールド欠落）
- **関連要件**: FR-2

### TC-B12: 不正なpoliteness_levelはエラー
- **ID**: TC-B12
- **説明**: 不正なpoliteness_level値がバリデーションエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "テスト",
      "politeness_level": "invalid"
  }
  ```
- **期待結果**: ValidationError発生
- **関連要件**: VR-2

### TC-B13: 日本語文字列のバリデーション
- **ID**: TC-B13
- **説明**: 日本語文字列（ひらがな、カタカナ、漢字）が正しく処理されることを確認
- **入力**:
  ```python
  {
      "input_text": "お腹すいた ご飯食べたい",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: FR-2

### TC-B14: 混合文字列のバリデーション
- **ID**: TC-B14
- **説明**: 日本語と英数字の混合文字列が正しく処理されることを確認
- **入力**:
  ```python
  {
      "input_text": "ABC123テスト あいう",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: FR-2

### TC-B15: 絵文字・特殊文字の処理
- **ID**: TC-B15
- **説明**: 絵文字や特殊文字を含む文字列の処理を確認
- **入力**:
  ```python
  {
      "input_text": "こんにちは！テスト。",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: FR-2

---

## C. AIConversionResponseテスト

### TC-C01: 正常なレスポンス生成
- **ID**: TC-C01
- **説明**: 正常なパラメータでAIConversionResponseが生成できることを確認
- **入力**:
  ```python
  {
      "converted_text": "お水をぬるめでお願いします",
      "original_text": "水 ぬるく",
      "politeness_level": "normal",
      "processing_time_ms": 2500
  }
  ```
- **期待結果**:
  - インスタンスが正常に生成される
  - 各フィールドに正しい値が設定される
- **関連要件**: FR-3

### TC-C02: 変換時間がintegerで保持される
- **ID**: TC-C02
- **説明**: processing_time_msがinteger型で正しく保持されることを確認
- **入力**:
  ```python
  {
      "converted_text": "テスト",
      "original_text": "test",
      "politeness_level": "normal",
      "processing_time_ms": 1234
  }
  ```
- **期待結果**:
  - `processing_time_ms == 1234`
  - 型が`int`である
- **関連要件**: FR-3

### TC-C03: 丁寧さレベルが正しく設定される
- **ID**: TC-C03
- **説明**: 各丁寧さレベルが正しく設定されることを確認
- **入力**:
  ```python
  [
      {"converted_text": "t", "original_text": "o", "politeness_level": "casual", "processing_time_ms": 100},
      {"converted_text": "t", "original_text": "o", "politeness_level": "normal", "processing_time_ms": 100},
      {"converted_text": "t", "original_text": "o", "politeness_level": "polite", "processing_time_ms": 100}
  ]
  ```
- **期待結果**: すべてのケースで正しい丁寧さレベルが設定される
- **関連要件**: FR-3

### TC-C04: JSONシリアライズ
- **ID**: TC-C04
- **説明**: AIConversionResponseがJSON形式に正しくシリアライズされることを確認
- **入力**: 生成されたAIConversionResponseインスタンス
- **期待結果**:
  ```json
  {
      "converted_text": "お水をぬるめでお願いします",
      "original_text": "水 ぬるく",
      "politeness_level": "normal",
      "processing_time_ms": 2500
  }
  ```
- **関連要件**: NFR-3

### TC-C05: processing_time_msが0の場合
- **ID**: TC-C05
- **説明**: processing_time_msが0の場合でも正常に動作することを確認
- **入力**:
  ```python
  {
      "converted_text": "テスト",
      "original_text": "test",
      "politeness_level": "normal",
      "processing_time_ms": 0
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: FR-3

---

## D. AIRegenerateRequestテスト

### TC-D01: 正常なリクエスト
- **ID**: TC-D01
- **説明**: 正常なパラメータでAIRegenerateRequestが生成できることを確認
- **入力**:
  ```python
  {
      "input_text": "水 ぬるく",
      "politeness_level": "normal",
      "previous_result": "お水をぬるめでお願いします"
  }
  ```
- **期待結果**:
  - インスタンスが正常に生成される
  - 各フィールドに正しい値が設定される
- **関連要件**: FR-4

### TC-D02: previous_resultフィールドが必須
- **ID**: TC-D02
- **説明**: previous_resultが欠落している場合にエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "水 ぬるく",
      "politeness_level": "normal"
  }
  ```
- **期待結果**: ValidationError発生（必須フィールド欠落）
- **関連要件**: FR-4, VR-3

### TC-D03: previous_resultが空文字列はエラー
- **ID**: TC-D03
- **説明**: previous_resultが空文字列の場合にエラーになることを確認
- **入力**:
  ```python
  {
      "input_text": "水 ぬるく",
      "politeness_level": "normal",
      "previous_result": ""
  }
  ```
- **期待結果**: ValidationError発生
- **関連要件**: VR-3

### TC-D04: AIConversionRequestと同じバリデーションが適用される
- **ID**: TC-D04
- **説明**: input_textに対してAIConversionRequestと同じバリデーションが適用されることを確認
- **入力**:
  ```python
  {
      "input_text": "水",  # 1文字（最小未満）
      "politeness_level": "normal",
      "previous_result": "前回結果"
  }
  ```
- **期待結果**: ValidationError発生（2文字未満）
- **関連要件**: VR-1

### TC-D05: previous_resultの空白トリム
- **ID**: TC-D05
- **説明**: previous_resultの前後空白がトリムされるか、またはそのまま保持されるかを確認
- **入力**:
  ```python
  {
      "input_text": "テスト",
      "politeness_level": "normal",
      "previous_result": "  前回結果  "
  }
  ```
- **期待結果**: インスタンスが正常に生成される（空白処理の仕様に従う）
- **関連要件**: FR-4

---

## E. ApiResponseラッパーテスト

### TC-E01: 成功レスポンス（success=true）
- **ID**: TC-E01
- **説明**: 成功時のApiResponseが正しく生成されることを確認
- **入力**:
  ```python
  {
      "success": True,
      "data": {
          "converted_text": "お水をぬるめでお願いします",
          "original_text": "水 ぬるく",
          "politeness_level": "normal",
          "processing_time_ms": 2500
      },
      "error": None
  }
  ```
- **期待結果**:
  - `success == True`
  - `data`に変換結果が含まれる
  - `error == None`
- **関連要件**: FR-5

### TC-E02: エラーレスポンス（success=false）
- **ID**: TC-E02
- **説明**: エラー時のApiResponseが正しく生成されることを確認
- **入力**:
  ```python
  {
      "success": False,
      "data": None,
      "error": {
          "code": "VALIDATION_ERROR",
          "message": "入力文字列は2文字以上500文字以下にしてください",
          "status_code": 400
      }
  }
  ```
- **期待結果**:
  - `success == False`
  - `data == None`
  - `error`にエラー詳細が含まれる
- **関連要件**: FR-5, ER-1

### TC-E03: ErrorDetailが正しく設定される
- **ID**: TC-E03
- **説明**: ErrorDetailスキーマが正しく設定されることを確認
- **入力**:
  ```python
  {
      "code": "AI_API_ERROR",
      "message": "AI変換APIからのレスポンスに失敗しました。",
      "status_code": 500
  }
  ```
- **期待結果**:
  - すべてのフィールドが正しく設定される
  - JSONシリアライズが正しく動作する
- **関連要件**: FR-5

### TC-E04: ErrorDetailのcodeがエラーコード一覧に対応
- **ID**: TC-E04
- **説明**: 各エラーコードでErrorDetailが生成できることを確認
- **入力**:
  ```python
  [
      {"code": "VALIDATION_ERROR", "message": "バリデーションエラー", "status_code": 400},
      {"code": "AI_API_ERROR", "message": "AI APIエラー", "status_code": 500},
      {"code": "AI_API_TIMEOUT", "message": "タイムアウト", "status_code": 504},
      {"code": "RATE_LIMIT_EXCEEDED", "message": "レート制限超過", "status_code": 429},
      {"code": "INTERNAL_ERROR", "message": "内部エラー", "status_code": 500}
  ]
  ```
- **期待結果**: すべてのエラーコードでインスタンスが生成される
- **関連要件**: FR-5

### TC-E05: ApiResponseのジェネリック型
- **ID**: TC-E05
- **説明**: ApiResponseがジェネリック型としてさまざまなデータ型をラップできることを確認
- **入力**: AIConversionResponse, HealthCheckResponse などの異なる型
- **期待結果**: 各型のデータを正しくラップできる
- **関連要件**: FR-5

---

## F. OpenAPI/Swagger統合テスト

### TC-F01: スキーマがOpenAPIドキュメントに表示される
- **ID**: TC-F01
- **説明**: 定義したスキーマがSwagger UI（/docs）で正しく表示されることを確認
- **テスト方法**:
  1. サーバーを起動
  2. `http://localhost:8000/openapi.json`にアクセス
  3. スキーマ定義が含まれることを確認
- **期待結果**:
  - `PolitenessLevel`が列挙型として表示される
  - `AIConversionRequest`のフィールドと制約が表示される
  - `AIConversionResponse`のフィールドが表示される
  - `ApiResponse`の構造が表示される
- **関連要件**: NFR-1

### TC-F02: exampleが正しく設定される
- **ID**: TC-F02
- **説明**: 各スキーマにexampleが設定され、Swagger UIで表示されることを確認
- **テスト方法**:
  1. Swagger UI（`/docs`）にアクセス
  2. 各スキーマのexampleを確認
- **期待結果**:
  - `AIConversionRequest`に適切なexampleが設定されている
  - `AIConversionResponse`に適切なexampleが設定されている
- **関連要件**: NFR-1

### TC-F03: descriptionが各フィールドに設定される
- **ID**: TC-F03
- **説明**: 各フィールドにdescription（説明）が設定されていることを確認
- **テスト方法**:
  1. OpenAPI JSON（`/openapi.json`）を取得
  2. 各フィールドにdescriptionが含まれることを確認
- **期待結果**:
  - `input_text`: 「変換元テキスト」などの説明
  - `politeness_level`: 「丁寧さレベル」などの説明
  - `converted_text`: 「変換後テキスト」などの説明
- **関連要件**: NFR-1

---

## G. HealthCheckResponseテスト

### TC-G01: 正常なヘルスチェックレスポンス
- **ID**: TC-G01
- **説明**: HealthCheckResponseが正しく生成されることを確認
- **入力**:
  ```python
  {
      "status": "ok",
      "version": "1.0.0",
      "timestamp": "2025-11-19T12:34:56Z"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: FR-6

### TC-G02: 異常時のヘルスチェックレスポンス
- **ID**: TC-G02
- **説明**: 異常時のHealthCheckResponseが生成できることを確認
- **入力**:
  ```python
  {
      "status": "error",
      "version": "1.0.0",
      "timestamp": "2025-11-19T12:34:56Z"
  }
  ```
- **期待結果**: インスタンスが正常に生成される
- **関連要件**: FR-6

### TC-G03: timestampのISO 8601形式
- **ID**: TC-G03
- **説明**: timestampがISO 8601形式で正しく処理されることを確認
- **入力**:
  ```python
  {
      "status": "ok",
      "version": "1.0.0",
      "timestamp": "2025-11-19T12:34:56.123456Z"
  }
  ```
- **期待結果**: datetime型として正しくパースされる
- **関連要件**: FR-6

---

## H. 型安全性・Pydantic v2機能テスト

### TC-H01: 型ヒントによる実行時チェック
- **ID**: TC-H01
- **説明**: Pydantic v2の型ヒントによる実行時チェックが有効であることを確認
- **入力**: 型が一致しないデータ（例: processing_time_msに文字列を渡す）
- **期待結果**: ValidationError発生
- **関連要件**: NFR-2

### TC-H02: from_attributesによるORMモデル変換
- **ID**: TC-H02
- **説明**: `from_attributes = True`設定でORMモデルからの変換がサポートされることを確認
- **入力**: SQLAlchemy ORMモデルオブジェクト
- **期待結果**: Pydanticスキーマに正しく変換される
- **関連要件**: NFR-3

### TC-H03: model_configの設定確認
- **ID**: TC-H03
- **説明**: Pydantic v2のmodel_configが正しく設定されていることを確認
- **入力**: 各スキーマクラス
- **期待結果**:
  - `from_attributes = True`が設定されている
  - `json_schema_extra`でexampleが設定されている
- **関連要件**: NFR-2, NFR-3

---

## テストケースサマリー

| カテゴリ | テストケース数 | 関連要件 |
|---------|--------------|---------|
| A. PolitenessLevel列挙型 | 5 | FR-1, VR-2 |
| B. AIConversionRequest | 15 | FR-2, VR-1, VR-2, VR-4 |
| C. AIConversionResponse | 5 | FR-3, NFR-3 |
| D. AIRegenerateRequest | 5 | FR-4, VR-3 |
| E. ApiResponseラッパー | 5 | FR-5, ER-1 |
| F. OpenAPI/Swagger統合 | 3 | NFR-1 |
| G. HealthCheckResponse | 3 | FR-6 |
| H. 型安全性・Pydantic v2機能 | 3 | NFR-2, NFR-3 |
| **合計** | **44** | - |

---

## テスト優先度

### P1（必須・最優先）
- TC-B02, TC-B03, TC-B04, TC-B05: 境界値テスト
- TC-B06, TC-B07: 空文字列・空白のみテスト
- TC-B01, TC-B09: 正常系テスト
- TC-A01 - TC-A04: PolitenessLevel基本テスト

### P2（重要）
- TC-B08: トリム機能テスト
- TC-B10, TC-B11, TC-B12: 必須フィールド・バリデーションエラー
- TC-C01 - TC-C03: レスポンス生成テスト
- TC-D01 - TC-D04: 再生成リクエストテスト
- TC-E01 - TC-E03: ApiResponseラッパーテスト

### P3（推奨）
- TC-B13, TC-B14, TC-B15: 文字種テスト
- TC-F01 - TC-F03: OpenAPI統合テスト
- TC-G01 - TC-G03: ヘルスチェックテスト
- TC-H01 - TC-H03: 型安全性テスト
