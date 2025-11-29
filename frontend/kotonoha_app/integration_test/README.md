# E2E テスト

## 概要

このディレクトリにはFlutter integration_testパッケージを使用したE2Eテストが含まれています。

## テスト実行方法

### ローカル実行

```bash
# Web（Chrome）で実行
cd frontend/kotonoha_app
flutter test integration_test/ -d chrome

# iOS シミュレーターで実行
flutter test integration_test/ -d ios

# Android エミュレーターで実行
flutter test integration_test/ -d android

# 特定のテストファイルのみ実行
flutter test integration_test/app_startup_test.dart -d chrome
```

### CI環境での実行

GitHub Actionsで自動実行されます。`.github/workflows/flutter-test.yml` を参照してください。

## テストファイル構成

```
integration_test/
├── README.md                    # このファイル
├── test_driver.dart             # テストドライバー
├── app_startup_test.dart        # アプリ起動テスト
├── helpers/
│   ├── helpers.dart             # ヘルパーエクスポート
│   ├── test_helpers.dart        # テストユーティリティ
│   └── mock_api_server.dart     # モックAPIサーバー
└── (今後追加予定)
    ├── character_input_test.dart    # 文字入力テスト (TASK-0082)
    ├── preset_phrase_test.dart      # 定型文テスト (TASK-0083)
    ├── large_button_test.dart       # 大ボタンテスト (TASK-0084)
    └── history_favorite_test.dart   # 履歴・お気に入りテスト (TASK-0085)
```

## パフォーマンス要件

E2Eテストでは以下のパフォーマンス要件を検証します：

| 機能 | 目標時間 | 関連要件 |
|------|----------|----------|
| 文字盤タップ応答 | 100ms以内 | NFR-003 |
| TTS読み上げ開始 | 1秒以内 | NFR-001 |
| 定型文100件表示 | 1秒以内 | NFR-004 |
| AI変換応答 | 平均3秒以内 | NFR-002 |

## モックサーバー

`mock_api_server.dart` でAI変換APIのモックを提供しています。

### 設定方法

```dart
import 'package:dio/dio.dart';
import 'helpers/mock_api_server.dart';

void main() {
  final dio = Dio();
  MockApiServer.createMockAdapter(dio);
  // テスト実行
}
```

## テストデータ

`MockTestData` クラスでテスト用データを提供しています：

- `presetPhrases`: テスト用定型文リスト
- `createTestHistory(count)`: テスト用履歴データ生成
- `createTestFavorites(count)`: テスト用お気に入りデータ生成

## トラブルシューティング

### テストがタイムアウトする

`pumpAndSettle()` のタイムアウトを延長してください：

```dart
await tester.pumpAndSettle(timeout: const Duration(seconds: 10));
```

### Web特有の問題

- Web版ではTTSのテストが制限される場合があります
- ネイティブ機能はモックを使用してください

### CI環境での失敗

- GitHub Actionsではheadlessモードでの実行が必要です
- 環境変数の設定を確認してください
