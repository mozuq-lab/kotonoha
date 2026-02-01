# コードスタイルと規約

## Flutter/Dart
- **Null Safety有効**
- `const`コンストラクタを可能な限り使用（`prefer_const_constructors`ルール有効）
- ウィジェットは`key`パラメータを持つ（`use_key_in_widget_constructors`ルール有効）
- `flutter_lints`パッケージ使用
- 生成ファイル（`*.g.dart`, `*.freezed.dart`）はanalyzerから除外
- `avoid_print` ルール有効（loggerパッケージを使用）
- Feature-basedディレクトリ構成（`lib/features/`）
- 状態管理: Riverpod 2.x + Notifierパターン（riverpod_generator使用）

## Python
- **型ヒント必須**（ruff ANN ルール有効）
- 行長: **100文字以内**
- docstring: **Google Style**
- リンター: **Ruff** (select: E, F, I, N, W, B, ANN, S, C90)
- フォーマッター: **Black** (line-length=100, target-version=py310)
- テストファイルでは assert使用、型注釈省略、日本語関数名を許容
- FastAPI Depends()パターンはB008の例外

## テスト
- Flutter: `mocktail`使用
- Python: `pytest` + `pytest-asyncio` (asyncio_mode=auto, function scope)
- カバレッジ目標: 全体80%以上、ビジネスロジック・API 90%以上

## コミット規約
- 1タスク完了ごとにコミット
- メッセージ形式: `タスク内容 (TASK-XXXX)`
- 例: `Add Docker environment setup (TASK-0002)`

## Pre-commit hooks
- trailing-whitespace, end-of-file-fixer（frontend除外）
- ruff (lint + format) - backend/
- flutter analyze + dart format - frontend/
