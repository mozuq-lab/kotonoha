# E2E テスト

## 概要

このディレクトリにはFlutter integration_testパッケージを使用したE2Eテストが含まれています。

## テスト実行方法

### ローカル実行

**Web（ヘッドレスChrome）**

web では `flutter test integration_test/ -d chrome` は使えません。
`flutter drive` とchromedriverを経由し、1ターゲットずつ実行します。

```bash
cd frontend/kotonoha_app

# 別ターミナルでchromedriverを起動（ポートは flutter drive の既定値 4444）
chromedriver --port=4444

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_startup_test.dart \
  -d web-server \
  --browser-name=chrome \
  --headless
```

**実機・シミュレーター**

`-d` にはデバイスIDを渡します（`flutter devices` で確認）。

```bash
# 接続中のデバイス一覧を確認
flutter devices

# 指定デバイスで実行
flutter test integration_test/ -d <device_id>
```

### CI環境での実行

`.github/workflows/flutter.yml` の `integration-test` ジョブで自動実行されます。
上記のヘッドレスWeb手順を各ターゲットに対して順に実行し、
**失敗はジョブ失敗として扱われます**（握り潰しはしません）。

以下はCIの実行対象から除外しています（除外理由はワークフロー内のコメント参照）。

| 除外対象 | 理由 |
|---|---|
| `ai_conversion_e2e_test.dart` | AI変換APIとAPIキーが必要 |
| `performance_profiling_e2e_test.dart` | 実性能測定でCIでは不安定 |
| `device_test/` 配下 | 実機前提（サブディレクトリのためglob対象外） |

## テストファイル構成

`flutter drive` のドライバー本体は `integration_test/` ではなく
**`test_driver/integration_test.dart`**（パッケージルート直下）にあります。

```
frontend/kotonoha_app/
├── test_driver/
│   └── integration_test.dart        # flutter drive のホスト側エントリ（integrationDriver）
└── integration_test/
    ├── README.md                        # このファイル
    ├── test_driver.dart                 # 旧エントリ（未使用・*_test.dart に一致せず実行されない）
    ├── app_startup_test.dart            # アプリ起動テスト
    ├── character_input_tts_test.dart    # 文字入力・読み上げテスト (TASK-0082)
    ├── preset_phrase_test.dart          # 定型文テスト (TASK-0083)
    ├── large_emergency_buttons_test.dart # 大ボタン・緊急ボタンテスト (TASK-0084)
    ├── ai_conversion_e2e_test.dart      # AI変換（CI除外: API必須）
    ├── performance_profiling_e2e_test.dart # 性能計測（CI除外: 不安定）
    ├── device_test/                     # 実機前提（CI除外）
    └── helpers/
        ├── helpers.dart                 # ヘルパーエクスポート
        ├── test_helpers.dart            # テストユーティリティ
        └── mock_api_server.dart         # モックAPIサーバー
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
