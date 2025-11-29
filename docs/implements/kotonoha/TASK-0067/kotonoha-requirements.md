# TASK-0067: AI変換APIクライアント実装（Flutter）要件定義書

## 機能概要

### 信頼性レベル: 🔵 青信号

EARS要件定義書および設計文書に明確に記載されている内容に基づいています。

### 1. 機能の概要

- 🔵 **何をする機能か**: FlutterアプリからバックエンドAI変換API（`/api/v1/ai/convert`、`/api/v1/ai/regenerate`）を呼び出すHTTPクライアント
- 🔵 **どのような問題を解決するか**: ユーザーが入力した短いキーワードや短文を、丁寧で自然な文章に変換して読み上げ可能にする
- 🔵 **想定されるユーザー**: 発話困難な方がタブレットを使ってコミュニケーションする際にAI変換機能を利用
- 🔵 **システム内での位置づけ**: フロントエンド(Flutter) ⇔ バックエンド(FastAPI)間のAPI通信レイヤー

### 参照要件・設計文書

- **参照したEARS要件**: REQ-901, REQ-902, REQ-903, REQ-904, NFR-002, NFR-104
- **参照した設計文書**:
  - `docs/design/kotonoha/api-endpoints.md` (POST /api/v1/ai/convert, POST /api/v1/ai/regenerate)
  - `docs/design/kotonoha/interfaces.dart` (PolitenessLevel, AIConversionRequest, AIConversionResponse)

---

## 2. 入力・出力の仕様

### 入力パラメータ 🔵

#### AI変換リクエスト（convert）
| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `inputText` | String | ✓ | 2文字以上500文字以下 | 変換元テキスト |
| `politenessLevel` | PolitenessLevel | ✓ | casual/normal/polite | 丁寧さレベル |

#### AI再変換リクエスト（regenerate）
| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `inputText` | String | ✓ | 2文字以上500文字以下 | 変換元テキスト |
| `politenessLevel` | PolitenessLevel | ✓ | casual/normal/polite | 丁寧さレベル |
| `previousResult` | String | ✓ | 空文字列不可 | 前回の変換結果 |

### 出力値 🔵

#### 成功レスポンス
| フィールド | 型 | 説明 |
|-----------|---|------|
| `convertedText` | String | 変換後のテキスト |
| `originalText` | String | 変換元のテキスト |
| `politenessLevel` | PolitenessLevel | 使用した丁寧さレベル |
| `processingTimeMs` | int | 処理時間（ミリ秒） |

#### エラーレスポンス
| フィールド | 型 | 説明 |
|-----------|---|------|
| `code` | String | エラーコード |
| `message` | String | エラーメッセージ |

### エラーコード一覧 🔵

| コード | HTTPステータス | 説明 |
|--------|---------------|------|
| `VALIDATION_ERROR` | 400 | バリデーションエラー |
| `AI_API_ERROR` | 500 | 外部AI APIエラー |
| `AI_API_TIMEOUT` | 504 | AI APIタイムアウト |
| `NETWORK_ERROR` | - | ネットワークエラー（接続不可） |
| `RATE_LIMIT_EXCEEDED` | 429 | レート制限超過 |
| `INTERNAL_ERROR` | 500 | 内部サーバーエラー |

---

## 3. 制約条件

### パフォーマンス要件 🔵

- **NFR-002**: AI変換の応答時間は平均3秒以内を目標
- **タイムアウト**: 接続タイムアウト10秒、受信タイムアウト10秒

### セキュリティ要件 🔵

- **NFR-104**: HTTPS通信を使用し、API通信を暗号化
- 環境変数からベースURLを取得（ハードコード禁止）

### API制約 🔵

- **レート制限**: 10秒に1リクエスト（1分間に10リクエスト）
- **入力文字数制限**: 2文字以上500文字以下

### アーキテクチャ制約 🔵

- dioパッケージを使用したHTTPクライアント実装
- エラーハンドリングは専用Exception型で管理
- Riverpod Providerでの状態管理と連携可能な設計

---

## 4. 想定される使用例

### 基本的な使用パターン 🔵

```dart
// AI変換の呼び出し
final response = await aiConversionClient.convert(
  inputText: '水 ぬるく',
  politenessLevel: PolitenessLevel.polite,
);
// response.convertedText => "お水をぬるめでお願いします"
```

### エッジケース 🔵

#### EDGE-001: ネットワークタイムアウト
- 10秒以内にレスポンスがない場合、`AIConversionException`（コード: `AI_API_TIMEOUT`）をスロー
- UI側で再試行オプションを提供

#### EDGE-002: AI変換APIエラー
- 外部AI APIからエラーが返った場合、`AIConversionException`（コード: `AI_API_ERROR`）をスロー
- UI側で元の入力文をそのまま使用可能にするフォールバック

#### ネットワーク接続エラー
- インターネット接続がない場合、`AIConversionException`（コード: `NETWORK_ERROR`）をスロー
- オフライン時はAI変換機能を無効化

#### レート制限超過
- レート制限に達した場合、`AIConversionException`（コード: `RATE_LIMIT_EXCEEDED`）をスロー
- `retry_after`秒後に再試行可能

---

## 5. 実装仕様

### ディレクトリ構造 🔵

```
lib/features/ai_conversion/
├── data/
│   ├── api/
│   │   └── ai_conversion_api_client.dart    # APIクライアント
│   └── models/
│       ├── ai_conversion_request.dart       # リクエストモデル
│       ├── ai_conversion_response.dart      # レスポンスモデル
│       └── ai_conversion_error.dart         # エラーモデル
└── domain/
    ├── models/
    │   └── politeness_level.dart            # 丁寧さレベルEnum
    └── exceptions/
        └── ai_conversion_exception.dart     # 例外クラス
```

### 主要クラス設計 🔵

#### AIConversionApiClient
```dart
class AIConversionApiClient {
  final Dio _dio;
  final String baseUrl;

  AIConversionApiClient({required this.baseUrl});

  /// AI変換を実行
  Future<AIConversionResponse> convert({
    required String inputText,
    required PolitenessLevel politenessLevel,
  });

  /// AI再変換を実行
  Future<AIConversionResponse> regenerate({
    required String inputText,
    required PolitenessLevel politenessLevel,
    required String previousResult,
  });
}
```

#### AIConversionException
```dart
class AIConversionException implements Exception {
  final String code;
  final String message;

  AIConversionException({required this.code, required this.message});
}
```

---

## 6. EARS要件・設計文書との対応関係

### 参照したユーザストーリー
- 発話困難なユーザーが短いキーワードを入力し、丁寧な文章に変換して読み上げる

### 参照した機能要件
- **REQ-901**: 短い入力をより丁寧で自然な文章に変換する候補を生成
- **REQ-902**: AI変換結果を自動的に表示し、採用・却下を選択可能
- **REQ-903**: 丁寧さレベルを3段階から選択可能
- **REQ-904**: 再生成または元の文のまま使用可能

### 参照した非機能要件
- **NFR-002**: AI変換の応答時間を平均3秒以内
- **NFR-104**: HTTPS通信を使用し、API通信を暗号化

### 参照したEdgeケース
- **EDGE-001**: ネットワークタイムアウト時のエラーメッセージと再試行オプション
- **EDGE-002**: AI変換APIエラー時のフォールバック処理

### 参照した設計文書
- **アーキテクチャ**: `architecture.md` - フロントエンド⇔バックエンド通信
- **API仕様**: `api-endpoints.md` - POST /api/v1/ai/convert, POST /api/v1/ai/regenerate
- **型定義**: `interfaces.dart` - PolitenessLevel, AIConversionRequest, AIConversionResponse

---

## 品質判定

### ✅ 高品質

- **要件の曖昧さ**: なし（EARS要件・API仕様に明確に定義）
- **入出力定義**: 完全（型、制約、エラーコードすべて明確）
- **制約条件**: 明確（パフォーマンス、セキュリティ、レート制限）
- **実装可能性**: 確実（バックエンドAPI実装済み、dio導入済み）

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
