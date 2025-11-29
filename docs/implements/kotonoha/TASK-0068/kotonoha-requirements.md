# TASK-0068: AI変換UIウィジェット実装 要件定義書

## 機能概要

### 信頼性レベル: 🔵 青信号

EARS要件定義書および設計文書に明確に記載されている内容に基づいています。

### 1. 機能の概要

- 🔵 **何をする機能か**: AI変換機能を利用するためのUIウィジェット群（変換ボタン、丁寧さレベル選択、ローディング表示、オフラインインジケーター）
- 🔵 **どのような問題を解決するか**: ユーザーがAI変換機能を直感的に操作でき、処理状態やネットワーク状態を視覚的に把握できるようにする
- 🔵 **想定されるユーザー**: 発話困難な方がタブレットを使ってコミュニケーションする際にAI変換機能を利用
- 🔵 **システム内での位置づけ**: プレゼンテーション層のUIコンポーネント、Riverpod経由でAPIクライアント・ネットワーク状態と連携

### 参照要件・設計文書

- **参照したEARS要件**: REQ-901, REQ-902, REQ-903, REQ-2006, REQ-3004, REQ-5001
- **参照した設計文書**:
  - `docs/design/kotonoha/interfaces.dart` (PolitenessLevel)
  - `docs/design/kotonoha/dataflow.md` (AI変換フロー)

---

## 2. 入力・出力の仕様

### 入力パラメータ 🔵

#### AIConversionButton

| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `inputText` | String | ✓ | 2文字以上 | 変換対象テキスト |
| `politenessLevel` | PolitenessLevel | ✓ | casual/normal/polite | 丁寧さレベル |
| `onConvert` | Future<String> Function() | ✓ | - | 変換処理コールバック |
| `onConversionStart` | VoidCallback? | - | - | 変換開始時コールバック |
| `onConversionComplete` | void Function(String)? | - | - | 変換完了時コールバック |

#### PolitenessLevelSelector

| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `selectedLevel` | PolitenessLevel | ✓ | casual/normal/polite | 現在の選択レベル |
| `onLevelChanged` | void Function(PolitenessLevel) | ✓ | - | レベル変更コールバック |

#### AIConversionLoading

| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `showExtendedMessage` | bool | - | デフォルト: false | 拡張メッセージ強制表示 |
| `extendedMessageDelaySeconds` | int | - | デフォルト: 3 | メッセージ表示遅延秒数 |

### 出力（UI表示） 🔵

#### AIConversionButton

| 状態 | 表示内容 |
|------|----------|
| 有効（オンライン・入力2文字以上） | 「AI変換」ボタン（タップ可能） |
| 無効（オフライン） | グレーアウトボタン（タップ不可） |
| 無効（入力不足） | グレーアウトボタン（タップ不可） |
| ローディング中 | CircularProgressIndicator |

#### PolitenessLevelSelector

| 状態 | 表示内容 |
|------|----------|
| 選択中 | プライマリカラー背景のボタン |
| 非選択 | サーフェスカラー背景のボタン |

#### AIConversionLoading

| 状態 | 表示内容 |
|------|----------|
| 3秒未満 | CircularProgressIndicator のみ |
| 3秒以上 | CircularProgressIndicator + 「AI変換中...」メッセージ |

---

## 3. 制約条件

### パフォーマンス要件 🔵

- **REQ-2006**: 3秒超過時にローディングメッセージを表示
- **応答性**: ボタン状態の更新は即時（ネットワーク状態変化を監視）

### アクセシビリティ要件 🔵

- **REQ-5001**: タップターゲットサイズは最小44px × 44px
- **Semantics**: スクリーンリーダー対応のラベル付与
- **視覚的フィードバック**: 選択状態・無効状態が視覚的に区別可能

### ネットワーク制約 🔵

- **REQ-3004**: オフライン時はAI変換ボタンを無効化
- **リアクティブ更新**: ネットワーク状態変化時に自動でUI更新

### 入力バリデーション 🟡

- **最小文字数**: 2文字以上で有効化（API仕様に基づく）
- **重複タップ防止**: ローディング中は再タップを無効化

---

## 4. 想定される使用例

### 基本的な使用パターン 🔵

```dart
// AI変換ボタンの使用
AIConversionButton(
  inputText: '水 ぬるく',
  politenessLevel: PolitenessLevel.polite,
  onConvert: () async {
    return await aiConversionClient.convert(
      inputText: '水 ぬるく',
      politenessLevel: PolitenessLevel.polite,
    ).then((r) => r.convertedText);
  },
  onConversionComplete: (result) {
    // 変換結果を処理
  },
);

// 丁寧さレベル選択の使用
PolitenessLevelSelector(
  selectedLevel: PolitenessLevel.normal,
  onLevelChanged: (level) {
    // 選択されたレベルを保存
  },
);
```

### エッジケース 🔵

#### オフライン時の動作

- AI変換ボタンが自動的にグレーアウト
- OfflineIndicatorが「オフライン」と表示
- オンライン復帰時に自動で有効化

#### 長時間処理時の動作

- 3秒経過後に「AI変換中...」メッセージを追加表示
- ユーザーに処理継続を通知

#### 重複タップ時の動作

- ローディング中はボタンが無効化
- 重複リクエストを防止

---

## 5. 実装仕様

### ディレクトリ構造 🔵

```
lib/features/ai_conversion/
└── presentation/
    └── widgets/
        ├── ai_conversion_button.dart       # AI変換ボタン + OfflineIndicator
        ├── ai_conversion_loading.dart      # ローディング表示
        └── politeness_level_selector.dart  # 丁寧さレベル選択
```

### 主要クラス設計 🔵

#### AIConversionButton

```dart
class AIConversionButton extends ConsumerStatefulWidget {
  final String inputText;
  final PolitenessLevel politenessLevel;
  final Future<String> Function() onConvert;
  final VoidCallback? onConversionStart;
  final void Function(String result)? onConversionComplete;
}
```

#### PolitenessLevelSelector

```dart
class PolitenessLevelSelector extends StatelessWidget {
  final PolitenessLevel selectedLevel;
  final void Function(PolitenessLevel) onLevelChanged;
}
```

#### AIConversionLoading

```dart
class AIConversionLoading extends StatefulWidget {
  final bool showExtendedMessage;
  final int extendedMessageDelaySeconds;
}
```

#### OfflineIndicator

```dart
class OfflineIndicator extends ConsumerWidget {
  // ネットワーク状態を監視し、オフライン時に表示
}
```

### 公開定数 🔵

```dart
/// 入力テキストの最小文字数
const int kMinInputLength = 2;

/// 最小タップターゲットサイズ（ピクセル）
const double kMinTapTargetSize = 44.0;
```

---

## 6. EARS要件・設計文書との対応関係

### 参照したユーザストーリー

- 発話困難なユーザーが短いキーワードを入力し、丁寧な文章に変換して読み上げる
- ユーザーが丁寧さレベルを選択してAI変換を実行する

### 参照した機能要件

- **REQ-901**: 短い入力をより丁寧で自然な文章に変換する候補を生成
- **REQ-902**: AI変換結果を自動的に表示し、採用・却下を選択可能
- **REQ-903**: 丁寧さレベルを3段階から選択可能（カジュアル/普通/丁寧）

### 参照した非機能要件

- **REQ-2006**: 3秒超過時にローディング表示
- **REQ-3004**: オフライン時はAI変換を無効化し、文字盤入力・定型文・TTS読み上げは継続
- **REQ-5001**: タップターゲットサイズ44px以上

### 参照した設計文書

- **インターフェース定義**: `interfaces.dart` - PolitenessLevel enum
- **データフロー**: `dataflow.md` - AI変換処理フロー

---

## 7. 依存関係

### 前提タスク

- **TASK-0067**: AI変換APIクライアント実装（Flutter）- APIクライアントの利用

### 後続タスク

- **TASK-0069**: AI変換結果表示・選択UI - 変換結果の表示・選択機能
- **TASK-0070**: AI変換Provider・状態管理 - 状態管理との統合

### 依存パッケージ

- `flutter_riverpod` - 状態管理・Provider連携
- `connectivity_plus`（間接依存） - ネットワーク状態監視

---

## 品質判定

### ✅ 高品質

- **要件の曖昧さ**: なし（EARS要件に明確に定義）
- **入出力定義**: 完全（パラメータ、表示状態すべて明確）
- **制約条件**: 明確（アクセシビリティ、ネットワーク、パフォーマンス）
- **実装可能性**: 確実（Flutter標準ウィジェット、Riverpod導入済み）

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
