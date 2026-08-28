# TASK-0078: エラーUI・エラーメッセージ実装

## 実装サマリー

- **タスクID**: TASK-0078
- **完了日**: 2025-11-29
- **実装タイプ**: TDDプロセス
- **テストケース**: 11件（全通過）

## 関連要件

- **NFR-204**: 分かりやすい日本語エラーメッセージ 🔵
- **EDGE-001**: ネットワークエラー時の再試行オプション 🔵
- **EDGE-002**: AI変換エラー時のフォールバック 🔵
- **EDGE-004**: TTS再生エラー時のメッセージ 🔵

## 実装内容

### 1. 汎用エラーダイアログ (showErrorDialog)

- **ファイル**: `lib/core/widgets/error_dialog.dart`
- タイトル、メッセージ、アイコン表示
- 再試行ボタンオプション
- OKボタンで閉じる機能

### 2. エラースナックバー (showErrorSnackBar)

- 画面下部に一時的にエラー表示
- 再試行ボタンオプション
- カスタム表示時間設定可能

### 3. ネットワークエラーダイアログ (showNetworkErrorDialog)

- EDGE-001対応
- wifi_offアイコン表示
- 「インターネットに接続できませんでした」メッセージ
- 再試行ボタン + キャンセルボタン

### 4. AI変換エラーダイアログ (showAIConversionErrorDialog)

- EDGE-002対応
- 元のテキストをプレビュー表示
- 「元のテキストを使用」ボタンでフォールバック
- 再試行ボタン（オプション）

### 5. TTS再生エラーダイアログ (showTTSErrorDialog)

- EDGE-004対応
- volume_offアイコン表示
- 「テキストは画面に表示されています」メッセージ
- 端末設定確認の案内

### 6. エラーメッセージ定数クラス (ErrorMessages)

- NFR-204対応
- 日本語エラーメッセージを一元管理
- ネットワーク/タイムアウト/サーバー/AI変換/TTS/保存/読み込みエラー

## テスト結果

```
11 tests passed
```

## テストケース一覧

### ErrorDialog 基本テスト
- TC-078-001: エラーダイアログにタイトルとメッセージが表示される
- TC-078-002: OKボタンでダイアログが閉じる

### 再試行オプションテスト
- TC-078-003: 再試行ボタンが表示される
- TC-078-004: 再試行ボタンタップでコールバックが呼ばれる

### ErrorSnackBar テスト
- TC-078-005: エラースナックバーが表示される
- TC-078-006: スナックバーに再試行ボタンが表示される

### NetworkErrorDialog テスト
- TC-078-007: ネットワークエラーダイアログが表示される

### AIConversionErrorDialog テスト
- TC-078-008: AI変換エラーダイアログが表示される
- TC-078-009: 元のテキストを使用ボタンでコールバックが呼ばれる

### TTSErrorDialog テスト
- TC-078-010: TTS再生エラーダイアログが表示される

### 日本語メッセージテスト
- TC-078-011: エラーメッセージが日本語で表示される

## 完了条件の達成状況

- ✅ エラーメッセージが分かりやすい日本語で表示される
- ✅ ネットワークエラー時に再試行オプションが提供される
- ✅ AI変換エラー時にフォールバック処理が実行される
- ✅ TTS再生エラー時にテキスト表示のみで継続される

## ファイル構成

```
lib/core/widgets/
└── error_dialog.dart (NEW)

test/core/widgets/
└── error_dialog_test.dart (NEW)
```

## 使用例

```dart
// 汎用エラーダイアログ
showErrorDialog(
  context: context,
  title: 'エラー',
  message: 'エラーが発生しました',
  showRetry: true,
  onRetry: () => _retry(),
);

// ネットワークエラー
showNetworkErrorDialog(
  context: context,
  onRetry: () => _fetchData(),
);

// AI変換エラー
showAIConversionErrorDialog(
  context: context,
  originalText: inputText,
  onUseOriginal: () => _useOriginalText(inputText),
);

// TTS再生エラー
showTTSErrorDialog(
  context: context,
  onRetry: () => _retryTTS(),
);
```

## 信頼性レベル

- 🔵 **青信号**: NFR-204, EDGE-001, EDGE-002, EDGE-004 - EARS要件定義書に明記
