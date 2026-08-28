# TASK-0026: 外部AI API連携実装（Claude/GPT プロキシ）- TDD要件定義書

## 1. 機能の概要

### 1.1 機能説明

外部AI API連携機能は、ユーザーが入力した短いテキストを、指定された丁寧さレベルに応じて自然な文章に変換するためのAIプロバイダー連携クライアントです。

- **何をする機能か**: Anthropic Claude APIまたはOpenAI GPT APIを使用して、入力テキストを丁寧さレベル（casual/normal/polite）に応じた文章に変換する
- **どのような問題を解決するか**:
  - 発話困難者が短いキーワードや単語の組み合わせから、状況に応じた適切な丁寧さの文章を生成できる
  - 複数のAIプロバイダー（Claude/GPT）をサポートし、可用性と柔軟性を確保
  - 外部API呼び出しの統一的なエラーハンドリングとリトライ機構を提供
- **想定されるユーザー**: kotonohaアプリを利用する発話困難者（アプリのフロントエンドを通じてAPIを呼び出す）
- **システム内での位置づけ**: FastAPIバックエンドのユーティリティ層に配置され、AI変換エンドポイントから呼び出される

**参照したEARS要件**: REQ-901, REQ-902, REQ-903, NFR-002
**参照した設計文書**: api-endpoints.md（AI変換機能セクション）, architecture.md

### 1.2 ユーザーストーリー

```
利用者として、
短いキーワード（例: 「水 ぬるく」）を入力し、
状況に応じた丁寧さレベルを選択することで、
自然で適切な文章（例: 「お水をぬるめでお願いします」）を生成したい、
そうすることで、相手に失礼なく自分の意思を伝えられる。

支援者として、
AI変換機能が安定して動作することを期待する、
そうすることで、利用者がスムーズにコミュニケーションを取れる。
```

## 2. 入力・出力の仕様

### 2.1 入力パラメータ

AIクライアントは以下のパラメータを受け取ります:

| パラメータ | 型 | 必須 | 説明 | バリデーション |
|-----------|---|------|------|---------------|
| `input_text` | string | Yes | 変換元テキスト | 2文字以上500文字以下 |
| `politeness_level` | PolitenessLevel | Yes | 丁寧さレベル | `casual`, `normal`, `polite` のいずれか |
| `provider` | string | No | AIプロバイダー指定 | `anthropic`, `openai`（省略時はデフォルト設定を使用） |

**設定パラメータ**:

| 設定項目 | 環境変数 | デフォルト値 | 説明 |
|---------|---------|------------|------|
| Anthropic APIキー | `ANTHROPIC_API_KEY` | None | Claude API認証キー |
| OpenAI APIキー | `OPENAI_API_KEY` | None | GPT API認証キー |
| デフォルトプロバイダー | `DEFAULT_AI_PROVIDER` | `anthropic` | 優先使用するプロバイダー |
| APIタイムアウト | `AI_API_TIMEOUT` | 30秒 | API呼び出しのタイムアウト |
| 最大リトライ回数 | `AI_MAX_RETRIES` | 3回 | エラー時のリトライ回数 |

**参照した設計文書**: config.py（既存設定）, api-endpoints.md

### 2.2 出力値

#### 正常時

| フィールド | 型 | 説明 |
|-----------|---|------|
| `converted_text` | string | 変換後のテキスト |
| `processing_time_ms` | integer | 変換処理時間（ミリ秒） |

**例**:
```python
converted_text, processing_time_ms = await ai_client.convert_text(
    input_text="水 ぬるく",
    politeness_level="polite"
)
# converted_text: "お水をぬるめでお願いします"
# processing_time_ms: 2500
```

#### エラー時

各種例外クラスがスローされます:

| 例外クラス | 説明 | 発生条件 |
|-----------|------|---------|
| `AIConversionException` | AI変換エラー基底クラス | 変換処理中の一般的なエラー |
| `AITimeoutException` | タイムアウトエラー | API呼び出しが30秒を超過 |
| `AIRateLimitException` | レート制限エラー | AIプロバイダー側のレート制限超過 |
| `AIProviderException` | プロバイダーエラー | APIキー未設定、認証失敗、サービス障害 |

**参照したEARS要件**: EDGE-002, NFR-301

### 2.3 データフロー

```
[AI変換リクエスト]
    |
    v
[AIClient.convert_text()]
    |
    +--> [プロバイダー選択]
    |        |
    |        +--> provider指定あり: 指定されたプロバイダーを使用
    |        |
    |        +--> provider指定なし: DEFAULT_AI_PROVIDERを使用
    |
    +--> [丁寧さレベルに応じたプロンプト生成]
    |        |
    |        +--> casual: "カジュアルで親しみやすい表現に変換"
    |        |
    |        +--> normal: "標準的な丁寧さの表現に変換"
    |        |
    |        +--> polite: "非常に丁寧で敬意を込めた表現に変換"
    |
    +--> [API呼び出し]
    |        |
    |        +--> [Anthropic Claude API] または [OpenAI GPT API]
    |        |
    |        +--> [タイムアウト監視 (30秒)]
    |        |
    |        +--> [リトライ処理 (最大3回)]
    |
    +--> [レスポンス処理]
    |        |
    |        +--> 成功: (converted_text, processing_time_ms) を返却
    |        |
    |        +--> 失敗: 適切な例外をスロー
    |
    v
[結果返却]
```

## 3. 制約条件

### 3.1 パフォーマンス要件

| 要件 | 値 | 根拠 |
|-----|---|------|
| 平均応答時間 | 3秒以内 | NFR-002 |
| 最大応答時間 | 30秒（タイムアウト） | AI_API_TIMEOUT設定 |
| 処理時間測定精度 | ミリ秒単位 | api-endpoints.md（processing_time_ms） |

**参照したEARS要件**: NFR-002

### 3.2 セキュリティ要件

| 要件 | 説明 | 根拠 |
|-----|------|------|
| APIキー管理 | 環境変数で管理、ハードコード禁止 | NFR-105 |
| 通信暗号化 | HTTPS/TLS 1.2+で外部API通信 | NFR-104 |
| ログ出力制御 | ユーザー入力テキストのログ出力は開発環境のみ | NFR-101 |

**参照したEARS要件**: NFR-101, NFR-104, NFR-105

### 3.3 互換性要件

| 要件 | 説明 |
|-----|------|
| Python互換 | Python 3.10+ |
| 非同期対応 | asyncio互換（FastAPIとの統合） |
| Anthropic SDK | anthropic==0.39.0 |
| OpenAI SDK | openai==1.59.5 |

**参照した設計文書**: tech-stack.md, kotonoha-phase2.md

### 3.4 AIプロバイダー仕様

#### Anthropic Claude API

| 項目 | 値 |
|-----|---|
| モデル | claude-3-5-sonnet-20241022 |
| 最大トークン | 1024 |
| SDK | AsyncAnthropic |

#### OpenAI GPT API

| 項目 | 値 |
|-----|---|
| モデル | gpt-4o-mini |
| 最大トークン | 1024 |
| Temperature | 0.7 |
| SDK | AsyncOpenAI |
| システムプロンプト | "あなたは日本語の文章を適切な丁寧さレベルに変換する専門家です。" |

**参照した設計文書**: kotonoha-phase2.md（TASK-0026実装詳細）

## 4. 想定される使用例

### 4.1 基本的な使用パターン

#### ユースケース1: カジュアルな変換

```python
# 入力
input_text = "腹減った"
politeness_level = "casual"

# 期待される出力
converted_text = "お腹すいた"
processing_time_ms = 1800
```

#### ユースケース2: 標準的な変換

```python
# 入力
input_text = "水 ぬるく"
politeness_level = "normal"

# 期待される出力
converted_text = "お水をぬるめでお願いします"
processing_time_ms = 2500
```

#### ユースケース3: 丁寧な変換

```python
# 入力
input_text = "痛い 腰"
politeness_level = "polite"

# 期待される出力
converted_text = "腰が痛いです。診ていただけますでしょうか"
processing_time_ms = 2200
```

**参照したEARS要件**: REQ-901, REQ-902, REQ-903

### 4.2 エッジケース

#### エッジケース1: プロバイダー指定

```python
# Anthropic指定
converted_text, _ = await ai_client.convert_text(
    input_text="ありがとう",
    politeness_level="polite",
    provider="anthropic"
)

# OpenAI指定
converted_text, _ = await ai_client.convert_text(
    input_text="ありがとう",
    politeness_level="polite",
    provider="openai"
)
```

#### エッジケース2: APIキー未設定時

```python
# ANTHROPIC_API_KEY未設定でanthropicプロバイダー指定
# → AIProviderException("Anthropic API key is not configured")
```

#### エッジケース3: 長い入力テキスト

```python
# 500文字の入力テキスト
input_text = "あ" * 500
# → 正常に変換される（入力バリデーションはスキーマ層で実施済み）
```

### 4.3 エラーケース

#### エラーケース1: タイムアウト

```python
# API応答が30秒を超過
# → AITimeoutException("AI API request timed out")
```

#### エラーケース2: AIプロバイダー側レート制限

```python
# Claude/GPT側でレート制限
# → AIRateLimitException("AI provider rate limit exceeded")
```

#### エラーケース3: 認証エラー

```python
# 無効なAPIキー
# → AIProviderException("Authentication failed")
```

#### エラーケース4: サービス障害

```python
# Claude/GPTサービス障害
# → AIProviderException("AI service temporarily unavailable")
```

**参照したEARS要件**: EDGE-001, EDGE-002, NFR-301

## 5. EARS要件・設計文書との対応関係

### 5.1 参照したユーザストーリー
- kotonoha-user-stories.md: AI変換機能に関するストーリー

### 5.2 参照した機能要件
- **REQ-901**: 短い入力（キーワードまたは短文）をより丁寧で自然な文章に変換する候補を生成
- **REQ-902**: AI変換結果を自動的に表示し、ユーザーが採用・却下を選択できる
- **REQ-903**: AI変換の丁寧さレベルを「カジュアル」「普通」「丁寧」の3段階から選択可能
- **REQ-904**: AI変換結果が気に入らない場合、再生成または元の文のまま使用できる

### 5.3 参照した非機能要件
- **NFR-002**: AI変換の応答時間を平均3秒以内
- **NFR-101**: 利用者の会話内容を端末内にのみ保存（AIクライアントログのプライバシー配慮）
- **NFR-104**: HTTPS通信、API通信を暗号化
- **NFR-105**: 環境変数をアプリ内にハードコードせず、安全に管理
- **NFR-301**: 重大なエラーが発生しても基本機能を継続利用可能

### 5.4 参照したEdgeケース
- **EDGE-001**: ネットワークタイムアウト時のエラーメッセージ表示
- **EDGE-002**: AI変換APIエラー時のフォールバック処理

### 5.5 参照した受け入れ基準
- AI変換の応答時間が平均3秒以内
- 丁寧さレベルに応じた適切な変換結果
- エラー時の適切な例外処理

### 5.6 参照した設計文書

| 文書 | 該当セクション |
|-----|--------------|
| api-endpoints.md | AI変換機能、パフォーマンス要件 |
| architecture.md | エラーハンドリング戦略 |
| tech-stack.md | バックエンド技術スタック |
| kotonoha-phase2.md | TASK-0026実装詳細 |

## 6. 技術的実装方針

### 6.1 使用ライブラリ

```
# requirements.txt追加
anthropic==0.39.0
openai==1.59.5
```

**選択理由**:
- 公式SDK使用による安定性と最新機能へのアクセス
- 非同期APIサポート（AsyncAnthropic, AsyncOpenAI）
- 型ヒント完備

### 6.2 実装ファイル構成

```
backend/
├── app/
│   ├── core/
│   │   └── config.py          # AI設定（既存、確認済み）
│   ├── utils/
│   │   ├── ai_client.py       # AIクライアント実装（新規）
│   │   └── exceptions.py      # 例外クラス追加（既存ファイルに追加）
│   └── schemas/
│       └── common.py          # PolitenessLevel（既存、確認済み）
├── tests/
│   └── test_utils/
│       └── test_ai_client.py  # AIクライアントテスト（新規）
└── requirements.txt           # anthropic, openai追加
```

### 6.3 実装詳細

#### AIClient クラス

```python
class AIClient:
    """AI API クライアント（Claude/GPT統合）"""

    def __init__(self):
        # クライアント初期化
        ...

    def _get_politeness_instruction(self, level: PolitenessLevel) -> str:
        """丁寧さレベルに応じたプロンプト生成"""
        ...

    async def convert_text_anthropic(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
    ) -> tuple[str, int]:
        """Claude APIで文字列変換"""
        ...

    async def convert_text_openai(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
    ) -> tuple[str, int]:
        """OpenAI GPT APIで文字列変換"""
        ...

    async def convert_text(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
        provider: str | None = None,
    ) -> tuple[str, int]:
        """AI変換（プロバイダー自動選択）"""
        ...
```

#### 例外クラス

```python
class AIConversionException(AppException):
    """AI変換エラー基底クラス"""
    def __init__(self, message: str = "AI conversion error"):
        super().__init__(message, status_code=503)


class AITimeoutException(AIConversionException):
    """AI APIタイムアウト"""
    def __init__(self, message: str = "AI API request timed out"):
        super().__init__(message)
        self.status_code = 504


class AIRateLimitException(AIConversionException):
    """AI APIレート制限"""
    def __init__(self, message: str = "AI provider rate limit exceeded"):
        super().__init__(message)
        self.status_code = 429


class AIProviderException(AIConversionException):
    """AI プロバイダーエラー"""
    def __init__(self, message: str = "AI provider error"):
        super().__init__(message)
        self.status_code = 503
```

### 6.4 プロンプト設計

#### 丁寧さレベル別プロンプト

| レベル | 指示文 |
|-------|-------|
| casual | "カジュアルで親しみやすい表現に変換してください。" |
| normal | "標準的な丁寧さの表現に変換してください。" |
| polite | "非常に丁寧で敬意を込めた表現に変換してください。" |

#### プロンプトテンプレート

```
以下の日本語文を{丁寧さ指示}

入力文: {input_text}

変換後の文のみを出力してください。説明や追加情報は不要です。
```

## 7. テストケース概要

### 7.1 単体テスト

| テストID | テスト名 | 説明 |
|---------|--------|------|
| TC-001 | 丁寧さレベルプロンプト生成テスト | 各丁寧さレベルに対応する指示文が正しく生成される |
| TC-002 | プロバイダー選択テスト | プロバイダー指定時に正しいAPIが選択される |
| TC-003 | デフォルトプロバイダーテスト | 未指定時にDEFAULT_AI_PROVIDERが使用される |
| TC-004 | APIキー未設定エラーテスト | APIキー未設定時にAIProviderExceptionがスローされる |
| TC-005 | 処理時間測定テスト | processing_time_msが正確に測定される |

### 7.2 統合テスト（モック使用）

| テストID | テスト名 | 説明 |
|---------|--------|------|
| TC-101 | Claude API変換テスト | モックを使用したClaude API呼び出しテスト |
| TC-102 | OpenAI API変換テスト | モックを使用したOpenAI API呼び出しテスト |
| TC-103 | タイムアウトテスト | タイムアウト発生時のAITimeoutException |
| TC-104 | レート制限テスト | レート制限発生時のAIRateLimitException |
| TC-105 | 認証エラーテスト | 認証失敗時のAIProviderException |

### 7.3 E2Eテスト（実APIキー必要、CI/CD ではスキップ）

| テストID | テスト名 | 説明 |
|---------|--------|------|
| TC-201 | Claude API実変換テスト | 実際のClaude APIを使用した変換テスト |
| TC-202 | OpenAI API実変換テスト | 実際のOpenAI APIを使用した変換テスト |
| TC-203 | 応答時間検証テスト | 平均応答時間が3秒以内であることを確認 |

### 7.4 エッジケーステスト

| テストID | テスト名 | 説明 |
|---------|--------|------|
| TC-301 | 長文入力テスト | 500文字の入力テキストが正常に処理される |
| TC-302 | 特殊文字入力テスト | 絵文字・記号を含む入力が処理される |
| TC-303 | 日本語以外入力テスト | 英数字のみの入力が処理される |

## 8. 完了条件

### 8.1 機能完了条件

- [ ] anthropic==0.39.0がrequirements.txtに追加されている
- [ ] openai==1.59.5がrequirements.txtに追加されている
- [ ] app/utils/ai_client.pyが実装されている
- [ ] AIClientクラスが実装されている
- [ ] convert_text_anthropicメソッドが実装されている
- [ ] convert_text_openaiメソッドが実装されている
- [ ] convert_textメソッド（プロバイダー自動選択）が実装されている
- [ ] 丁寧さレベル別プロンプト生成が実装されている
- [ ] app/utils/exceptions.pyにAI関連例外クラスが追加されている

### 8.2 テスト完了条件

- [ ] 丁寧さレベルプロンプト生成テストが成功する
- [ ] プロバイダー選択テストが成功する
- [ ] APIキー未設定エラーテストが成功する
- [ ] モックを使用したAPI呼び出しテストが成功する
- [ ] 例外ハンドリングテストが成功する
- [ ] テストカバレッジが90%以上（NFR-502準拠）

### 8.3 品質完了条件

- [ ] Ruff + Blackによる静的解析がパスする
- [ ] 型ヒントが全ての関数に付与されている
- [ ] docstringがGoogle Styleで記述されている
- [ ] ログ出力がプライバシーに配慮されている

## 9. 品質判定

### 判定結果: 高品質

```
要件の曖昧さ: なし
- AIプロバイダー仕様、プロンプト設計、エラーハンドリングが明確に定義
- TASK-0026の実装詳細に基づく具体的な仕様

入出力定義: 完全
- 入力パラメータ、出力値、例外クラスが詳細に定義
- 設定パラメータ（既存config.py）との整合性確認済み

制約条件: 明確
- パフォーマンス要件（3秒以内）、タイムアウト（30秒）が具体的に定義
- セキュリティ要件（APIキー管理、ログ出力制御）が明確

実装可能性: 確実
- 公式SDKを使用した実装方針が明確
- 既存の例外クラス構造との統合方法が定義
- 依存タスク（TASK-0025）完了済み
```

## 10. 信頼性レベル

- **青信号**: EARS要件定義書・設計文書を参考にした確実な要件（REQ-901〜904, NFR-002等）
- **黄信号**: 設計文書から妥当な推測による要件（リトライ処理、ログ出力制御）
- **赤信号**: なし

## 11. 更新履歴

| 日付 | バージョン | 変更内容 |
|-----|----------|---------|
| 2025-11-22 | 1.0.0 | 初版作成（TDD要件定義フェーズ） |

---

次のステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
