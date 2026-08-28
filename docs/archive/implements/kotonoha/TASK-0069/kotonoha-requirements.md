# TASK-0069: AI変換結果表示・選択UI 要件定義書

## 機能概要

### 信頼性レベル: 🔵 青信号

EARS要件定義書（REQ-902, REQ-904）および設計文書（interfaces.dart）に明確に記載されている内容に基づいています。

### 1. 機能の概要

- 🔵 **何をする機能か**: AI変換の結果を表示し、ユーザーが「採用」「再生成」「元の文を使う」の選択ができるUI
- 🔵 **どのような問題を解決するか**: AI変換結果をユーザーが確認し、適切な文章を選択してコミュニケーションに使用できるようにする
- 🔵 **想定されるユーザー**: 発話困難な方がタブレットを使ってコミュニケーションする際にAI変換機能を利用
- 🔵 **システム内での位置づけ**: プレゼンテーション層のUIコンポーネント、TASK-0068（AI変換UIウィジェット）の後続機能

### 参照要件・設計文書

- **参照したEARS要件**: REQ-902, REQ-904, REQ-5001
- **参照した設計文書**:
  - `docs/design/kotonoha/interfaces.dart` (AIConversionResultState)
  - `docs/design/kotonoha/dataflow.md` (AI変換フロー)
  - TASK-0068実装（EmergencyConfirmationDialogパターン）

---

## 2. 入力・出力の仕様

### 入力パラメータ 🔵

#### AIConversionResultDialog

| パラメータ | 型 | 必須 | 制約 | 説明 |
|-----------|---|------|------|------|
| `originalText` | String | ✓ | 1文字以上 | 元の入力テキスト |
| `convertedText` | String | ✓ | 1文字以上 | AI変換後のテキスト |
| `politenessLevel` | PolitenessLevel | ✓ | casual/normal/polite | 使用した丁寧さレベル |
| `onAdopt` | void Function(String) | ✓ | - | 「採用」タップ時コールバック（変換結果を返す） |
| `onRegenerate` | VoidCallback | ✓ | - | 「再生成」タップ時コールバック |
| `onUseOriginal` | void Function(String) | ✓ | - | 「元の文を使う」タップ時コールバック（元の文を返す） |

### 出力（UI表示） 🔵

#### AIConversionResultDialog

| 表示領域 | 表示内容 |
|----------|----------|
| ヘッダー | 「AI変換結果」タイトル |
| 元の文セクション | ラベル「元の文」+ originalText表示 |
| 変換結果セクション | ラベル「変換結果」+ convertedText表示（強調表示） |
| 丁寧さレベル表示 | 使用した丁寧さレベル（例：「丁寧」） |
| 採用ボタン | 「採用」- プライマリカラー、大きめサイズ |
| 再生成ボタン | 「再生成」- セカンダリカラー |
| 元の文を使うボタン | 「元の文を使う」- テキストボタンまたはアウトラインボタン |

### データフロー 🔵

```
[AI変換ボタン] → [API呼び出し] → [変換結果受信]
                                      ↓
                            [AIConversionResultDialog表示]
                                      ↓
                      ┌───────────────┼───────────────┐
                      ↓               ↓               ↓
                  [採用]          [再生成]      [元の文を使う]
                      ↓               ↓               ↓
              [変換結果を反映]  [再度API呼び出し]  [元の文を反映]
                      ↓               ↓               ↓
                  [ダイアログ閉じる]  [ローディング表示]  [ダイアログ閉じる]
```

---

## 3. 制約条件

### パフォーマンス要件 🔵

- **応答性**: ボタンタップ後即座にフィードバック表示
- **ダイアログ表示**: アニメーション含めて300ms以内

### アクセシビリティ要件 🔵

- **REQ-5001**: タップターゲットサイズは最小44px × 44px（推奨60px × 60px）
- **Semantics**: スクリーンリーダー対応のラベル付与
- **視覚的フィードバック**: ボタン状態（通常/タップ中/無効）が視覚的に区別可能
- **テーマ対応**: ライト/ダーク/高コントラストモードでの適切な表示

### UI/UX制約 🔵

- **比較表示**: 元の文と変換結果を並べて表示し、ユーザーが比較しやすくする
- **ボタン優先度**: 「採用」ボタンを最も目立たせる（プライマリアクション）
- **連続タップ防止**: ボタン処理中は再タップを無効化
- **ダイアログ外タップ**: 誤操作防止のため、ダイアログ外タップでは閉じない（barrierDismissible: false）

### テーマ対応仕様 🟡

| モード | 背景色 | テキスト色 | 採用ボタン色 |
|--------|--------|-----------|-------------|
| ライト | 白 | 黒 | プライマリ（青系） |
| ダーク | 暗いグレー | 白 | プライマリ（明るめ） |
| 高コントラスト | 黒 | 白 | 高コントラスト用カラー |

---

## 4. 想定される使用例

### 基本的な使用パターン 🔵

#### ダイアログ表示

```dart
// AI変換完了後にダイアログ表示
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => AIConversionResultDialog(
    originalText: '水 ぬるく',
    convertedText: 'お水をぬるめでお願いします',
    politenessLevel: PolitenessLevel.polite,
    onAdopt: (result) {
      Navigator.of(context).pop();
      // 変換結果を入力欄に反映
      inputController.text = result;
    },
    onRegenerate: () {
      Navigator.of(context).pop();
      // 再度AI変換を実行
      startAIConversion();
    },
    onUseOriginal: (original) {
      Navigator.of(context).pop();
      // 元の文を入力欄に反映
      inputController.text = original;
    },
  ),
);
```

### エッジケース 🔵

#### 長いテキストの表示

- 変換結果が長い場合はスクロール可能なエリアで表示
- 最大表示行数を設定し、超える場合はスクロールバーを表示

#### 再生成時の動作

- ダイアログを閉じてローディング表示
- 再度API呼び出し後、新しい結果でダイアログ再表示

#### 元の文と変換結果が同じ場合

- 「変換結果が元の文と同じです」という補足メッセージを表示（オプション）
- ユーザーはそのまま採用可能

---

## 5. 実装仕様

### ディレクトリ構造 🔵

```
lib/features/ai_conversion/
└── presentation/
    └── widgets/
        └── ai_conversion_result_dialog.dart  # AI変換結果ダイアログ
```

### 主要クラス設計 🔵

#### AIConversionResultDialog

```dart
/// AI変換結果表示・選択ダイアログ
///
/// REQ-902: AI変換結果を表示し、採用・却下を選択可能
/// REQ-904: 再生成または元の文を使用できる機能を提供
class AIConversionResultDialog extends StatefulWidget {
  /// 元の入力テキスト
  final String originalText;

  /// 変換後のテキスト
  final String convertedText;

  /// 使用した丁寧さレベル
  final PolitenessLevel politenessLevel;

  /// 「採用」タップ時コールバック
  final void Function(String result) onAdopt;

  /// 「再生成」タップ時コールバック
  final VoidCallback onRegenerate;

  /// 「元の文を使う」タップ時コールバック
  final void Function(String original) onUseOriginal;

  const AIConversionResultDialog({
    super.key,
    required this.originalText,
    required this.convertedText,
    required this.politenessLevel,
    required this.onAdopt,
    required this.onRegenerate,
    required this.onUseOriginal,
  });

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show({
    required BuildContext context,
    required String originalText,
    required String convertedText,
    required PolitenessLevel politenessLevel,
    required void Function(String result) onAdopt,
    required VoidCallback onRegenerate,
    required void Function(String original) onUseOriginal,
  });
}
```

### UI構成 🔵

```
┌─────────────────────────────────────────┐
│           AI変換結果                     │
├─────────────────────────────────────────┤
│ 元の文:                                  │
│ ┌─────────────────────────────────────┐ │
│ │ 水 ぬるく                            │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ 変換結果 (丁寧):                         │
│ ┌─────────────────────────────────────┐ │
│ │ お水をぬるめでお願いします             │ │  ← 強調表示（背景色付き）
│ └─────────────────────────────────────┘ │
│                                          │
│ ┌─────────────────────────────────────┐ │
│ │           採 用                      │ │  ← プライマリ、大きめ
│ └─────────────────────────────────────┘ │
│                                          │
│ ┌───────────────┐  ┌─────────────────┐ │
│ │    再生成     │  │ 元の文を使う    │ │  ← セカンダリ、横並び
│ └───────────────┘  └─────────────────┘ │
└─────────────────────────────────────────┘
```

### 公開定数 🔵

```dart
/// ダイアログの最大幅
const double kDialogMaxWidth = 400.0;

/// ダイアログの最小幅
const double kDialogMinWidth = 300.0;

/// 変換結果表示エリアの最大高さ
const double kResultAreaMaxHeight = 200.0;
```

---

## 6. EARS要件・設計文書との対応関係

### 参照したユーザストーリー

- 発話困難なユーザーがAI変換結果を確認し、採用するかどうかを選択する
- ユーザーが変換結果に満足しない場合、再生成または元の文を使用する

### 参照した機能要件

- **REQ-902**: AI変換結果を自動的に表示し、ユーザーが採用・却下を選択できなければならない 🔵
- **REQ-904**: AI変換結果が気に入らない場合、再生成または元の文のまま使用できる機能を提供 🔵

### 参照した非機能要件

- **REQ-5001**: タップターゲットサイズ44px以上 🔵
- **NFR-202**: ボタンを視認性が高く押しやすいサイズで設計（推奨60px以上）🔵

### 参照したEdgeケース

- **EDGE-002**: AI変換APIエラー時、元の入力文をそのまま使用可能にするフォールバック処理 🔵

### 参照した設計文書

- **インターフェース定義**: `interfaces.dart` - AIConversionResultState（Line 543-572）
- **データフロー**: `dataflow.md` - AI変換処理フロー
- **既存実装パターン**: `EmergencyConfirmationDialog` - ダイアログ設計パターン

---

## 7. 依存関係

### 前提タスク

- **TASK-0067**: AI変換APIクライアント実装（Flutter）- APIレスポンスの型定義
- **TASK-0068**: AI変換UIウィジェット実装 - AIConversionButton、ローディング表示

### 後続タスク

- **TASK-0070**: AI変換Provider・状態管理 - このダイアログとの連携

### 依存パッケージ

- `flutter_riverpod` - 状態管理・Provider連携（オプション、ダイアログ自体はStatefulWidget）

---

## 8. テスト観点

### 単体テスト（Widget Test）

1. ダイアログが正しく表示される
2. 元の文と変換結果が両方表示される
3. 丁寧さレベルが表示される
4. 「採用」ボタンタップで正しいコールバックが呼ばれる
5. 「再生成」ボタンタップで正しいコールバックが呼ばれる
6. 「元の文を使う」ボタンタップで正しいコールバックが呼ばれる
7. 連続タップが防止される
8. アクセシビリティ（Semantics）が正しく設定される

### テーマ別テスト

1. ライトモードで正しく表示される
2. ダークモードで正しく表示される
3. 高コントラストモードで正しく表示される

---

## 品質判定

### ✅ 高品質

- **要件の曖昧さ**: なし（EARS要件REQ-902, REQ-904に明確に定義）
- **入出力定義**: 完全（パラメータ、表示状態すべて明確）
- **制約条件**: 明確（アクセシビリティ、テーマ対応、連続タップ防止）
- **実装可能性**: 確実（既存のEmergencyConfirmationDialogパターンを参考に実装可能）

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
