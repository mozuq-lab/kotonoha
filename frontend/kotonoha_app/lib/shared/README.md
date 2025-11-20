# Shared

複数の機能で共有される再利用可能なコンポーネントを格納するディレクトリです。

## ディレクトリ構成

### widgets/
共通UIウィジェット（複数機能で使用される再利用可能なウィジェット）

**実装予定（TASK-0017）**:
- `large_button.dart`: 大きなタップ可能ボタン
- `text_input_field.dart`: テキスト入力欄
- `emergency_button.dart`: 緊急ボタン
- その他共通ウィジェット

### models/
共通データモデル（複数機能で使用されるモデル）

**実装予定（TASK-0014）**:
- `history_item.dart`: 履歴アイテムモデル（Hive対応）
- `preset_phrase.dart`: 定型文モデル（Hive対応）
- その他共通モデル

### services/
共通サービス（APIクライアント、ストレージ管理など）

**実装予定**:
- `api_service.dart`: バックエンドAPI通信サービス
- `storage_service.dart`: ローカルストレージサービス
- `tts_service.dart`: TTS（音声読み上げ）サービス

## 使用方法

### 共通ウィジェットの使用例
```dart
import 'package:kotonoha_app/shared/widgets/large_button.dart';

LargeButton(
  label: 'はい',
  onPressed: () {
    // 処理
  },
)
```

### 共通モデルの使用例
```dart
import 'package:kotonoha_app/shared/models/history_item.dart';

final item = HistoryItem(
  id: '1',
  text: 'ありがとう',
  createdAt: DateTime.now(),
);
```

## 実装方針

- **widgets/**: TASK-0017で大ボタン、入力欄などを実装
- **models/**: TASK-0014でHiveモデルを実装
- **services/**: 各機能の実装時に必要に応じて追加
