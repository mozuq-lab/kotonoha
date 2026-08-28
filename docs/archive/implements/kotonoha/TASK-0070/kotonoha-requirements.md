# TASK-0070: AI変換Provider・状態管理 要件定義書

## 機能概要

### 信頼性レベル: 🔵 青信号

EARS要件定義書（REQ-901, REQ-902, REQ-903, REQ-904）および設計文書（interfaces.dart）に明確に記載されている内容に基づいています。

### 1. 機能の概要

- 🔵 **何をする機能か**: AI変換機能の状態をRiverpodで一元管理するProvider実装。変換中状態、結果状態、エラー状態を管理し、UIコンポーネントとAPIクライアントを仲介する。
- 🔵 **どのような問題を解決するか**: AI変換処理の状態を一元管理し、複数のUIコンポーネント間で状態を共有可能にする。また、ネットワーク状態や設定との連携を容易にする。
- 🔵 **想定されるユーザー**: 発話困難な方がタブレットを使ってコミュニケーションする際にAI変換機能を利用
- 🔵 **システム内での位置づけ**: プレゼンテーション層の状態管理、TASK-0067（APIクライアント）、TASK-0068/0069（UIウィジェット）との連携

### 参照要件・設計文書

- **参照したEARS要件**: REQ-901, REQ-902, REQ-903, REQ-904, REQ-1001, REQ-3004
- **参照した設計文書**:
  - `docs/design/kotonoha/interfaces.dart` (AIConversionResultState, NetworkState)
  - `docs/design/kotonoha/dataflow.md` (AI変換フロー)
  - TASK-0067実装（AIConversionApiClient）
  - TASK-0068/0069実装（UIウィジェット）

---

## 2. 入力・出力の仕様

### 入力パラメータ 🔵

#### AIConversionNotifier.convert()

| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `inputText` | String | ✓ | 2文字以上500文字以下 | 変換対象テキスト |
| `politenessLevel` | PolitenessLevel? | - | casual/normal/polite | 丁寧さレベル（省略時は設定から取得） |

#### AIConversionNotifier.regenerate()

| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| なし | - | - | - | 前回の変換結果を使用して再生成 |

### 出力（状態） 🔵

#### AIConversionState

| プロパティ | 型 | 説明 |
|-----------|---|------|
| `status` | AIConversionStatus | 現在の状態（idle/converting/success/error） |
| `originalText` | String? | 変換元テキスト |
| `convertedText` | String? | 変換結果テキスト |
| `politenessLevel` | PolitenessLevel? | 使用した丁寧さレベル |
| `error` | AIConversionException? | エラー情報 |
| `isConverting` | bool | 変換中かどうか（status == converting） |
| `hasResult` | bool | 結果があるかどうか（status == success） |
| `hasError` | bool | エラーがあるかどうか（status == error） |

### データフロー 🔵

```
[UIコンポーネント] → [AIConversionNotifier.convert()]
                            ↓
                    [状態: converting]
                            ↓
              [AIConversionApiClient.convert()]
                            ↓
                ┌───────────┴───────────┐
                ↓                       ↓
        [成功レスポンス]           [例外発生]
                ↓                       ↓
        [状態: success]          [状態: error]
        [convertedText設定]      [error設定]
                ↓                       ↓
    [AIConversionResultDialog]  [エラーメッセージ表示]
                ↓
    ┌───────────┼───────────┐
    ↓           ↓           ↓
[採用]      [再生成]    [元の文を使う]
    ↓           ↓           ↓
[clear()]  [regenerate()] [clear()]
```

---

## 3. 制約条件

### パフォーマンス要件 🔵

- **応答性**: 状態更新は即座にUIに反映される
- **非同期処理**: API呼び出しは非同期で実行され、UIをブロックしない
- **REQ-2006**: 3秒超過時のローディング表示はUIウィジェット側で対応（TASK-0068で実装済み）

### ネットワーク連携要件 🔵

- **REQ-1001, REQ-3004**: オフライン時はAI変換を実行不可
- **ネットワーク状態監視**: NetworkNotifierと連携し、オフライン時はエラー状態を設定
- **変換前チェック**: convert()呼び出し時にネットワーク状態を確認

### 設定連携要件 🔵

- **REQ-903**: 丁寧さレベルのデフォルト値は設定から取得（将来実装予定）
- **現在の実装**: convert()呼び出し時にpolitenessLevelを明示的に指定

### エラーハンドリング要件 🔵

- **EDGE-002**: API変換エラー時は元のテキストを使用可能にする
- **エラー状態の管理**: AIConversionExceptionをキャプチャし、状態に設定
- **状態復元**: clear()で初期状態に戻す

---

## 4. 想定される使用例

### 基本的な使用パターン 🔵

```dart
// AI変換の実行
final aiConversionNotifier = ref.read(aiConversionProvider.notifier);
await aiConversionNotifier.convert(
  inputText: '水 ぬるく',
  politenessLevel: PolitenessLevel.polite,
);

// 状態の監視
final state = ref.watch(aiConversionProvider);
if (state.isConverting) {
  // ローディング表示
} else if (state.hasResult) {
  // 結果表示
  showDialog(
    context: context,
    builder: (_) => AIConversionResultDialog(
      originalText: state.originalText!,
      convertedText: state.convertedText!,
      politenessLevel: state.politenessLevel!,
      onAdopt: (result) {
        inputController.text = result;
        aiConversionNotifier.clear();
      },
      onRegenerate: () {
        aiConversionNotifier.regenerate();
      },
      onUseOriginal: (original) {
        inputController.text = original;
        aiConversionNotifier.clear();
      },
    ),
  );
} else if (state.hasError) {
  // エラー表示
  showSnackBar(state.error!.message);
}
```

### 再生成の使用パターン 🔵

```dart
// 前回の変換結果に満足しない場合
aiConversionNotifier.regenerate();
// 内部で前回のoriginalText、politenessLevel、convertedTextを使用して再生成
```

### エッジケース 🔵

#### オフライン時の動作

```dart
// NetworkNotifierがoffline状態の場合
await aiConversionNotifier.convert(inputText: 'テスト');
// → 状態がerrorになり、NETWORK_ERRORのAIConversionExceptionが設定される
```

#### 変換中に再度変換を呼び出した場合

```dart
// 既にconverting状態の場合、新しい変換リクエストは無視される
// または前回のリクエストをキャンセルして新しいリクエストを実行
// （実装方針: 前回のリクエストを無視し、新しいリクエストを優先）
```

---

## 5. 実装仕様

### ディレクトリ構造 🔵

```
lib/features/ai_conversion/
└── providers/
    ├── ai_conversion_provider.dart    # AI変換Provider・Notifier
    └── ai_conversion_state.dart       # AI変換状態クラス
```

### 主要クラス設計 🔵

#### AIConversionStatus

```dart
/// AI変換の状態
enum AIConversionStatus {
  /// 初期状態・アイドル
  idle,

  /// 変換中
  converting,

  /// 変換成功
  success,

  /// エラー
  error,
}
```

#### AIConversionState

```dart
/// AI変換の状態を表す不変クラス
class AIConversionState {
  /// 現在の状態
  final AIConversionStatus status;

  /// 変換元テキスト
  final String? originalText;

  /// 変換結果テキスト
  final String? convertedText;

  /// 使用した丁寧さレベル
  final PolitenessLevel? politenessLevel;

  /// エラー情報
  final AIConversionException? error;

  const AIConversionState({
    this.status = AIConversionStatus.idle,
    this.originalText,
    this.convertedText,
    this.politenessLevel,
    this.error,
  });

  /// 変換中かどうか
  bool get isConverting => status == AIConversionStatus.converting;

  /// 結果があるかどうか
  bool get hasResult => status == AIConversionStatus.success;

  /// エラーがあるかどうか
  bool get hasError => status == AIConversionStatus.error;

  /// 初期状態
  static const AIConversionState initial = AIConversionState();

  AIConversionState copyWith({...});
}
```

#### AIConversionNotifier

```dart
/// AI変換の状態管理Notifier
class AIConversionNotifier extends StateNotifier<AIConversionState> {
  final AIConversionApiClient _apiClient;
  final NetworkNotifier _networkNotifier;

  AIConversionNotifier({
    required AIConversionApiClient apiClient,
    required NetworkNotifier networkNotifier,
  }) : _apiClient = apiClient,
       _networkNotifier = networkNotifier,
       super(AIConversionState.initial);

  /// AI変換を実行
  Future<void> convert({
    required String inputText,
    required PolitenessLevel politenessLevel,
  });

  /// 再生成を実行
  Future<void> regenerate();

  /// 状態をクリア
  void clear();
}
```

#### Provider定義

```dart
/// AI変換APIクライアントのProvider
final aiConversionApiClientProvider = Provider<AIConversionApiClient>((ref) {
  // 環境変数からベースURLを取得（デフォルト: localhost:8000）
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  return AIConversionApiClient(baseUrl: baseUrl);
});

/// AI変換Providerの定義
final aiConversionProvider = StateNotifierProvider<AIConversionNotifier, AIConversionState>((ref) {
  final apiClient = ref.watch(aiConversionApiClientProvider);
  final networkNotifier = ref.watch(networkProvider.notifier);
  return AIConversionNotifier(
    apiClient: apiClient,
    networkNotifier: networkNotifier,
  );
});
```

---

## 6. EARS要件・設計文書との対応関係

### 参照したユーザストーリー

- 発話困難なユーザーが短いキーワードを入力し、丁寧な文章に変換して読み上げる
- ユーザーがAI変換結果を確認し、採用するかどうかを選択する
- ユーザーが変換結果に満足しない場合、再生成または元の文を使用する

### 参照した機能要件

- **REQ-901**: 短い入力をより丁寧で自然な文章に変換する候補を生成 🔵
- **REQ-902**: AI変換結果を自動的に表示し、採用・却下を選択可能 🔵
- **REQ-903**: 丁寧さレベルを3段階から選択可能（カジュアル/普通/丁寧）🔵
- **REQ-904**: AI変換結果が気に入らない場合、再生成または元の文のまま使用可能 🔵

### 参照した非機能要件

- **REQ-1001**: ネットワーク状態を監視し、オフライン時はAI変換を無効化 🔵
- **REQ-3004**: オフライン時はAI変換ボタンを無効化し、他の機能は継続 🔵

### 参照したEdgeケース

- **EDGE-002**: AI変換APIエラー時、元の入力文をそのまま使用可能にするフォールバック処理 🔵

### 参照した設計文書

- **インターフェース定義**: `interfaces.dart` - AIConversionResultState（Line 543-572）
- **データフロー**: `dataflow.md` - AI変換処理フロー
- **既存実装パターン**: `NetworkNotifier`, `SettingsNotifier` - Provider設計パターン

---

## 7. 依存関係

### 前提タスク

- **TASK-0067**: AI変換APIクライアント実装（Flutter）- AIConversionApiClientの利用 ✅
- **TASK-0068**: AI変換UIウィジェット実装 - UIコンポーネントとの連携 ✅
- **TASK-0069**: AI変換結果表示・選択UI - 結果ダイアログとの連携 ✅

### 後続タスク

- **TASK-0077**: オフライン時UI表示・AI変換無効化 - ネットワーク連携の活用

### 依存パッケージ

- `flutter_riverpod` - 状態管理・Provider連携
- `dio` - HTTPクライアント（APIクライアント経由）

---

## 8. テスト観点

### 単体テスト（Provider Test）

1. 初期状態がidleである
2. convert()呼び出しで状態がconvertingになる
3. convert()成功で状態がsuccessになり、結果が設定される
4. convert()失敗で状態がerrorになり、例外が設定される
5. regenerate()で前回の情報を使用して再変換が実行される
6. clear()で状態がidleに戻る
7. オフライン時のconvert()でエラー状態になる
8. 変換中に再度convert()を呼び出した場合の動作

### 状態遷移テスト

1. idle → converting → success → idle (clear)
2. idle → converting → error → idle (clear)
3. success → converting → success (regenerate)

### 連携テスト

1. NetworkNotifierとの連携が正しく動作する
2. AIConversionApiClientとの連携が正しく動作する

---

## 品質判定

### ✅ 高品質

- **要件の曖昧さ**: なし（EARS要件REQ-901〜904、REQ-1001、REQ-3004に明確に定義）
- **入出力定義**: 完全（状態クラス、メソッドパラメータすべて明確）
- **制約条件**: 明確（ネットワーク連携、エラーハンドリング）
- **実装可能性**: 確実（既存のNetworkNotifier、SettingsNotifierパターンを参考に実装可能）

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
