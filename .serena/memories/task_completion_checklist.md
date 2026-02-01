# タスク完了時のチェックリスト

タスクが完了したら、以下を実行する:

## バックエンド変更がある場合
1. `cd backend && ruff check app tests` - リンターエラーがないこと
2. `cd backend && black --check app tests` - フォーマットが正しいこと
3. `cd backend && pytest` - 全テストがパスすること
4. DBスキーマ変更がある場合: `alembic revision --autogenerate` でマイグレーション作成

## フロントエンド変更がある場合
1. `cd frontend/kotonoha_app && flutter analyze --no-fatal-infos` - 解析エラーがないこと
2. `cd frontend/kotonoha_app && dart format --set-exit-if-changed .` - フォーマットが正しいこと
3. `cd frontend/kotonoha_app && flutter test` - 全テストがパスすること
4. Riverpod/JSON等のコード生成が必要な場合: `flutter pub run build_runner build --delete-conflicting-outputs`

## 共通
- カバレッジ目標: 全体80%以上、ビジネスロジック・API 90%以上
- コミットメッセージ形式: `タスク内容 (TASK-XXXX)`
