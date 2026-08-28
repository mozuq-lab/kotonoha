# TDD Red Phase メモ - TASK-0056

## 概要
- **タスク**: アプリ設定保存（shared_preferences）
- **フェーズ**: Red（失敗するテストを作成）
- **実行日時**: 2025-11-26

## 作成したテストファイル
- `test/features/settings/data/app_settings_repository_test.dart`

## テストケース数
- 正常系: 6件
- デフォルト値: 3件
- 境界値: 4件
- 異常系: 4件
- 上書き: 2件
- **合計**: 19件

## テスト実行結果（Red Phase）

```
Error: Error when reading 'lib/shared/models/app_settings.dart': No such file or directory
Error: Error when reading 'lib/features/settings/data/app_settings_repository.dart': No such file or directory
Error: 'AppSettingsRepository' isn't a type.
Error: Undefined name 'FontSize'.
Error: Undefined name 'AppTheme'.
Error: Undefined name 'TtsSpeed'.
Error: Undefined name 'PolitenessLevel'.
Error: Method not found: 'AppSettings'.
```

## 失敗原因（期待通り）
1. `AppSettings` モデルが存在しない
2. `AppSettingsRepository` クラスが存在しない
3. 列挙型（`FontSize`, `AppTheme`, `TtsSpeed`, `PolitenessLevel`）が未定義

## 次のステップ
Green フェーズで以下を実装する：
1. `lib/shared/models/app_settings.dart` - モデル + 列挙型
2. `lib/features/settings/data/app_settings_repository.dart` - Repository
