# TASK-0026: 外部AI API連携実装（Claude/GPT プロキシ）- テストケース一覧

## 1. 概要

本文書は、TASK-0026「外部AI API連携実装」のテストケースを定義します。
要件定義書（TASK-0026-requirements.md）に基づき、AIクライアントの単体テスト、統合テスト、E2Eテスト、エッジケーステストを網羅します。

### 参照ドキュメント
- 要件定義書: `/docs/implements/kotonoha/TASK-0026/TASK-0026-requirements.md`
- 設定管理: `/backend/app/core/config.py`
- 既存例外クラス: `/backend/app/utils/exceptions.py`
- 共通スキーマ: `/backend/app/schemas/common.py`

### テストファイル構成（予定）
```
backend/tests/
├── test_utils/
│   └── test_ai_client.py           # AIクライアント単体・統合テスト
├── test_e2e/
│   └── test_ai_client_e2e.py       # E2Eテスト（実APIキー必要）
└── conftest.py                      # 既存テスト設定
```

---

## 2. 単体テスト

### 2.1 AIClient初期化テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| UT-001 | test_ai_client_initialization | なし（デフォルトコンストラクタ） | AIClientインスタンスが正常に生成される | 設定値が正しく読み込まれることを確認 |
| UT-002 | test_ai_client_with_anthropic_key_set | ANTHROPIC_API_KEY="test-key" | _anthropic_clientがNoneでない | 環境変数モック使用 |
| UT-003 | test_ai_client_with_openai_key_set | OPENAI_API_KEY="test-key" | _openai_clientがNoneでない | 環境変数モック使用 |
| UT-004 | test_ai_client_without_api_keys | ANTHROPIC_API_KEY=None, OPENAI_API_KEY=None | 両クライアントがNone | APIキー未設定時の初期化 |

### 2.2 丁寧さレベルプロンプト生成テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| UT-101 | test_get_politeness_instruction_casual | PolitenessLevel.CASUAL | "カジュアルで親しみやすい表現に変換してください。" を含む文字列 | |
| UT-102 | test_get_politeness_instruction_normal | PolitenessLevel.NORMAL | "標準的な丁寧さの表現に変換してください。" を含む文字列 | |
| UT-103 | test_get_politeness_instruction_polite | PolitenessLevel.POLITE | "非常に丁寧で敬意を込めた表現に変換してください。" を含む文字列 | |
| UT-104 | test_get_politeness_instruction_all_levels | 全PolitenessLevelを順次テスト | 各レベルに対応する異なる指示文が返される | 重複がないことを確認 |

### 2.3 プロバイダー自動選択テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| UT-201 | test_select_provider_explicit_anthropic | provider="anthropic" | anthropicプロバイダーが選択される | |
| UT-202 | test_select_provider_explicit_openai | provider="openai" | openaiプロバイダーが選択される | |
| UT-203 | test_select_provider_default_anthropic | provider=None, DEFAULT_AI_PROVIDER="anthropic" | anthropicプロバイダーが選択される | |
| UT-204 | test_select_provider_default_openai | provider=None, DEFAULT_AI_PROVIDER="openai" | openaiプロバイダーが選択される | 環境変数モック使用 |
| UT-205 | test_select_provider_invalid | provider="invalid_provider" | AIProviderExceptionがスローされる | 不正なプロバイダー名 |

### 2.4 処理時間測定テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| UT-301 | test_processing_time_measurement | モック応答（遅延100ms） | processing_time_ms >= 100 | ミリ秒単位の精度確認 |
| UT-302 | test_processing_time_positive | モック応答 | processing_time_ms > 0 | 処理時間が正の値 |
| UT-303 | test_processing_time_type | モック応答 | processing_time_msがint型 | 型チェック |

---

## 3. 統合テスト（モック使用）

### 3.1 Claude API変換テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| IT-001 | test_convert_text_anthropic_success | input_text="水 ぬるく", politeness_level=POLITE | 変換後テキストと処理時間のタプルが返される | AsyncAnthropic.messages.createをモック |
| IT-002 | test_convert_text_anthropic_casual | input_text="腹減った", politeness_level=CASUAL | カジュアルな変換結果 | |
| IT-003 | test_convert_text_anthropic_normal | input_text="ありがとう", politeness_level=NORMAL | 標準的な変換結果 | |
| IT-004 | test_convert_text_anthropic_model_used | 任意入力 | claude-3-5-sonnet-20241022モデルが使用される | モック呼び出し引数を検証 |
| IT-005 | test_convert_text_anthropic_max_tokens | 任意入力 | max_tokens=1024で呼び出される | モック呼び出し引数を検証 |

### 3.2 OpenAI API変換テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| IT-101 | test_convert_text_openai_success | input_text="水 ぬるく", politeness_level=POLITE | 変換後テキストと処理時間のタプルが返される | AsyncOpenAI.chat.completions.createをモック |
| IT-102 | test_convert_text_openai_casual | input_text="腹減った", politeness_level=CASUAL | カジュアルな変換結果 | |
| IT-103 | test_convert_text_openai_normal | input_text="ありがとう", politeness_level=NORMAL | 標準的な変換結果 | |
| IT-104 | test_convert_text_openai_model_used | 任意入力 | gpt-4o-miniモデルが使用される | モック呼び出し引数を検証 |
| IT-105 | test_convert_text_openai_system_prompt | 任意入力 | システムプロンプトに"あなたは日本語の文章を適切な丁寧さレベルに変換する専門家です。"を含む | |
| IT-106 | test_convert_text_openai_temperature | 任意入力 | temperature=0.7で呼び出される | モック呼び出し引数を検証 |

### 3.3 タイムアウト処理テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| IT-201 | test_anthropic_timeout_exception | モック: asyncio.TimeoutError発生 | AITimeoutExceptionがスローされる | status_code=504 |
| IT-202 | test_openai_timeout_exception | モック: asyncio.TimeoutError発生 | AITimeoutExceptionがスローされる | status_code=504 |
| IT-203 | test_timeout_message_content | モック: タイムアウト発生 | メッセージに"timed out"を含む | |
| IT-204 | test_timeout_duration_setting | AI_API_TIMEOUT=10 | 10秒でタイムアウト設定される | 設定値の反映確認 |

### 3.4 リトライ処理テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| IT-301 | test_retry_on_transient_error | モック: 2回失敗後成功 | 成功結果が返される | AI_MAX_RETRIES=3 |
| IT-302 | test_retry_exhausted | モック: 全3回失敗 | AIProviderExceptionがスローされる | リトライ回数上限 |
| IT-303 | test_no_retry_on_auth_error | モック: 認証エラー | 即座にAIProviderExceptionがスローされる | リトライ不要なエラー |
| IT-304 | test_retry_count_setting | AI_MAX_RETRIES=5 | 5回までリトライ | 設定値の反映確認 |
| IT-305 | test_retry_with_exponential_backoff | モック: 2回失敗後成功 | リトライ間隔が増加する | バックオフ確認（実装による） |

### 3.5 エラーレスポンス処理テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| IT-401 | test_anthropic_rate_limit_error | モック: RateLimitError発生 | AIRateLimitExceptionがスローされる | status_code=429 |
| IT-402 | test_openai_rate_limit_error | モック: RateLimitError発生 | AIRateLimitExceptionがスローされる | status_code=429 |
| IT-403 | test_anthropic_auth_error | モック: AuthenticationError発生 | AIProviderException("Authentication failed")がスローされる | |
| IT-404 | test_openai_auth_error | モック: AuthenticationError発生 | AIProviderException("Authentication failed")がスローされる | |
| IT-405 | test_anthropic_service_unavailable | モック: ServiceUnavailableError発生 | AIProviderException("AI service temporarily unavailable")がスローされる | |
| IT-406 | test_openai_service_unavailable | モック: ServiceUnavailableError発生 | AIProviderException("AI service temporarily unavailable")がスローされる | |
| IT-407 | test_anthropic_api_error_generic | モック: APIError発生 | AIConversionExceptionがスローされる | 一般的なAPIエラー |
| IT-408 | test_openai_api_error_generic | モック: APIError発生 | AIConversionExceptionがスローされる | 一般的なAPIエラー |

### 3.6 APIキー未設定テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| IT-501 | test_anthropic_api_key_not_set | ANTHROPIC_API_KEY=None, provider="anthropic" | AIProviderException("Anthropic API key is not configured")がスローされる | |
| IT-502 | test_openai_api_key_not_set | OPENAI_API_KEY=None, provider="openai" | AIProviderException("OpenAI API key is not configured")がスローされる | |
| IT-503 | test_default_provider_key_not_set | DEFAULT_AI_PROVIDER="anthropic", ANTHROPIC_API_KEY=None | AIProviderExceptionがスローされる | デフォルトプロバイダー使用時 |

---

## 4. E2Eテスト（実API使用 - スキップ可能）

**注意**: これらのテストは実際のAPIキーを使用します。CI/CD環境ではスキップされます。
`@pytest.mark.skipif(not os.getenv("ANTHROPIC_API_KEY"), reason="API key not set")`

### 4.1 Claude API実変換テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| E2E-001 | test_real_anthropic_convert_casual | input_text="腹減った", politeness_level=CASUAL | 非空の変換結果文字列 | 実API呼び出し |
| E2E-002 | test_real_anthropic_convert_normal | input_text="水 ぬるく", politeness_level=NORMAL | 非空の変換結果文字列 | |
| E2E-003 | test_real_anthropic_convert_polite | input_text="痛い 腰", politeness_level=POLITE | 非空の変換結果文字列 | |
| E2E-004 | test_real_anthropic_response_time | 任意入力 | processing_time_ms <= 30000 | タイムアウト内で応答 |

### 4.2 OpenAI API実変換テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| E2E-101 | test_real_openai_convert_casual | input_text="腹減った", politeness_level=CASUAL | 非空の変換結果文字列 | 実API呼び出し |
| E2E-102 | test_real_openai_convert_normal | input_text="水 ぬるく", politeness_level=NORMAL | 非空の変換結果文字列 | |
| E2E-103 | test_real_openai_convert_polite | input_text="痛い 腰", politeness_level=POLITE | 非空の変換結果文字列 | |
| E2E-104 | test_real_openai_response_time | 任意入力 | processing_time_ms <= 30000 | タイムアウト内で応答 |

### 4.3 応答時間検証テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| E2E-201 | test_average_response_time_anthropic | 5回の連続リクエスト | 平均処理時間 <= 3000ms | NFR-002準拠 |
| E2E-202 | test_average_response_time_openai | 5回の連続リクエスト | 平均処理時間 <= 3000ms | NFR-002準拠 |
| E2E-203 | test_response_time_under_load | 並行3リクエスト | 全リクエスト30秒以内完了 | 軽い負荷テスト |

---

## 5. エッジケーステスト

### 5.1 入力テキストバリエーション

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| EC-001 | test_minimum_length_input | input_text="あ" (1文字) | 正常に変換される（バリデーションは別層で実施） | AIクライアント層では制限なし |
| EC-002 | test_short_input | input_text="水" (1文字) | 正常に変換される | |
| EC-003 | test_maximum_length_input | input_text="あ" * 500 (500文字) | 正常に変換される | 最大長入力 |
| EC-004 | test_long_japanese_text | input_text=長い日本語文 | 正常に変換される | 実用的な長文 |
| EC-005 | test_empty_string_input | input_text="" | 正常に処理される（AI応答に依存） | 空文字列入力 |

### 5.2 特殊文字入力

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| EC-101 | test_input_with_newlines | input_text="水\nぬるく" | 正常に変換される | 改行を含む入力 |
| EC-102 | test_input_with_tabs | input_text="水\tぬるく" | 正常に変換される | タブを含む入力 |
| EC-103 | test_input_with_special_chars | input_text="水！？。、" | 正常に変換される | 句読点・記号 |
| EC-104 | test_input_with_emoji | input_text="水 😊" | 正常に変換される | 絵文字を含む入力 |
| EC-105 | test_input_with_numbers | input_text="水 2杯" | 正常に変換される | 数字を含む入力 |

### 5.3 言語バリエーション

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| EC-201 | test_hiragana_only_input | input_text="みず ぬるく" | 正常に変換される | ひらがなのみ |
| EC-202 | test_katakana_only_input | input_text="ミズ ヌルク" | 正常に変換される | カタカナのみ |
| EC-203 | test_kanji_only_input | input_text="水 温" | 正常に変換される | 漢字のみ |
| EC-204 | test_mixed_japanese_input | input_text="水をぬるめでネ" | 正常に変換される | 混合入力 |
| EC-205 | test_english_only_input | input_text="water please" | 正常に変換される（日本語変換される可能性あり） | 英語のみ |
| EC-206 | test_mixed_language_input | input_text="water ください" | 正常に変換される | 日英混合 |

### 5.4 空白・フォーマット

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| EC-301 | test_leading_spaces | input_text="  水 ぬるく" | 正常に変換される | 先頭空白 |
| EC-302 | test_trailing_spaces | input_text="水 ぬるく  " | 正常に変換される | 末尾空白 |
| EC-303 | test_multiple_spaces | input_text="水    ぬるく" | 正常に変換される | 複数空白 |
| EC-304 | test_full_width_spaces | input_text="水　ぬるく" | 正常に変換される | 全角スペース |
| EC-305 | test_only_spaces | input_text="   " | 正常に処理される（AI応答に依存） | 空白のみ |

---

## 6. 例外クラステスト

### 6.1 例外クラス属性テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| EX-001 | test_ai_conversion_exception_base | AIConversionException() | status_code=503, message="AI conversion error" | 基底クラス |
| EX-002 | test_ai_conversion_exception_custom_message | AIConversionException("Custom error") | message="Custom error" | カスタムメッセージ |
| EX-003 | test_ai_timeout_exception | AITimeoutException() | status_code=504, message="AI API request timed out" | |
| EX-004 | test_ai_rate_limit_exception | AIRateLimitException() | status_code=429, message="AI provider rate limit exceeded" | |
| EX-005 | test_ai_provider_exception | AIProviderException() | status_code=503, message="AI provider error" | |
| EX-006 | test_ai_provider_exception_custom | AIProviderException("API key invalid") | message="API key invalid" | カスタムメッセージ |

### 6.2 例外継承関係テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| EX-101 | test_timeout_inherits_from_conversion | AITimeoutException() | isinstance(e, AIConversionException) == True | |
| EX-102 | test_rate_limit_inherits_from_conversion | AIRateLimitException() | isinstance(e, AIConversionException) == True | |
| EX-103 | test_provider_inherits_from_conversion | AIProviderException() | isinstance(e, AIConversionException) == True | |
| EX-104 | test_conversion_inherits_from_app | AIConversionException() | isinstance(e, AppException) == True | |

---

## 7. ログ出力テスト

### 7.1 プライバシー配慮テスト

| テストID | テスト名 | 入力 | 期待結果 | 備考 |
|----------|---------|------|---------|------|
| LOG-001 | test_no_input_text_in_production_logs | ENVIRONMENT="production", input_text="秘密情報" | ログに"秘密情報"が出力されない | NFR-101準拠 |
| LOG-002 | test_input_text_in_development_logs | ENVIRONMENT="development", input_text="テスト" | ログに"テスト"が出力される（開発環境のみ） | |
| LOG-003 | test_api_key_not_logged | ANTHROPIC_API_KEY="sk-xxx" | ログにAPIキーが出力されない | |
| LOG-004 | test_error_logged_without_sensitive_data | APIエラー発生 | エラーログにユーザー入力が含まれない | |

---

## 8. テスト優先順位

### 必須（P0）- TDD Red Phase で最初に実装
1. UT-001 ~ UT-004: AIClient初期化テスト
2. UT-101 ~ UT-104: 丁寧さレベルプロンプト生成テスト
3. UT-201 ~ UT-205: プロバイダー選択テスト
4. IT-001 ~ IT-003: Claude API変換テスト（モック）
5. IT-101 ~ IT-103: OpenAI API変換テスト（モック）
6. IT-501 ~ IT-503: APIキー未設定テスト

### 重要（P1）- 基本機能完成後
1. IT-201 ~ IT-204: タイムアウト処理テスト
2. IT-301 ~ IT-305: リトライ処理テスト
3. IT-401 ~ IT-408: エラーレスポンス処理テスト
4. UT-301 ~ UT-303: 処理時間測定テスト

### 推奨（P2）- 品質向上
1. EC-001 ~ EC-305: エッジケーステスト
2. EX-001 ~ EX-104: 例外クラステスト
3. LOG-001 ~ LOG-004: ログ出力テスト

### オプション（P3）- 実API検証
1. E2E-001 ~ E2E-203: E2Eテスト（実APIキー必要）

---

## 9. テスト実行コマンド

```bash
# 全テスト実行（モックテストのみ）
pytest backend/tests/test_utils/test_ai_client.py -v

# 単体テストのみ
pytest backend/tests/test_utils/test_ai_client.py -v -k "test_" --ignore=backend/tests/test_e2e/

# 統合テストのみ
pytest backend/tests/test_utils/test_ai_client.py -v -k "IT_"

# E2Eテスト（実APIキー設定時）
ANTHROPIC_API_KEY=xxx OPENAI_API_KEY=xxx pytest backend/tests/test_e2e/test_ai_client_e2e.py -v

# カバレッジ付き
pytest backend/tests/test_utils/test_ai_client.py -v --cov=app/utils/ai_client --cov-report=term-missing
```

---

## 10. モック設計

### 10.1 Anthropic APIモック

```python
# AsyncAnthropic.messages.create のモック構造
mock_response = MagicMock()
mock_response.content = [MagicMock(text="変換後のテキスト")]

# 使用例
with patch.object(AsyncAnthropic, "messages", new_callable=AsyncMock) as mock:
    mock.create.return_value = mock_response
```

### 10.2 OpenAI APIモック

```python
# AsyncOpenAI.chat.completions.create のモック構造
mock_response = MagicMock()
mock_response.choices = [MagicMock(message=MagicMock(content="変換後のテキスト"))]

# 使用例
with patch.object(AsyncOpenAI, "chat", new_callable=AsyncMock) as mock:
    mock.completions.create.return_value = mock_response
```

### 10.3 設定モック

```python
# 環境変数のモック
@pytest.fixture
def mock_settings():
    with patch("app.core.config.settings") as mock:
        mock.ANTHROPIC_API_KEY = "test-anthropic-key"
        mock.OPENAI_API_KEY = "test-openai-key"
        mock.DEFAULT_AI_PROVIDER = "anthropic"
        mock.AI_API_TIMEOUT = 30
        mock.AI_MAX_RETRIES = 3
        yield mock
```

---

## 11. 完了条件

### テストケース完了条件
- [ ] 全P0テストケースが文書化されている
- [ ] 全P1テストケースが文書化されている
- [ ] モック設計が定義されている
- [ ] テスト実行コマンドが記載されている

### 次のステップ
`/tsumiki:tdd-red` コマンドでRedフェーズ（失敗するテストの作成）に進みます。

---

## 12. 更新履歴

| 日付 | バージョン | 変更内容 |
|-----|----------|---------|
| 2025-11-22 | 1.0.0 | 初版作成（TDDテストケース洗い出しフェーズ） |
