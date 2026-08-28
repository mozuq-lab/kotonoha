# TASK-0066: お気に入り追加・削除・並び替え機能 - テストケース定義

## テストケース一覧

### 1. Unit Tests

#### TC-066-001: FavoriteNotifier 履歴からお気に入り追加
- **テストファイル**: `test/features/favorite/providers/favorite_provider_test.dart`
- **テスト内容**: 履歴からお気に入りを追加できる
- **前提条件**: FavoriteNotifierが初期状態
- **入力**: 履歴テキスト "こんにちは"
- **期待結果**: お気に入り一覧に追加される、displayOrderが正しい
- **信頼性**: 🔵 青信号 - REQ-701

#### TC-066-002: FavoriteNotifier 重複追加防止
- **テストファイル**: `test/features/favorite/providers/favorite_provider_test.dart`
- **テスト内容**: 同一内容の重複追加を防止する
- **前提条件**: "こんにちは"がお気に入りに存在
- **入力**: 同じテキスト "こんにちは"
- **期待結果**: 追加されない、お気に入り数は変わらない
- **信頼性**: 🔵 青信号 - REQ-701

#### TC-066-003: FavoriteNotifier 並び替え実行
- **テストファイル**: `test/features/favorite/providers/favorite_provider_test.dart`
- **テスト内容**: 並び替えが正しく実行される
- **前提条件**: お気に入りが3件存在 (A, B, C)
- **入力**: Aを位置2に移動
- **期待結果**: 順序が (B, C, A) になる
- **信頼性**: 🔵 青信号 - REQ-703

#### TC-066-004: FavoriteNotifier 並び替え後のdisplayOrder
- **テストファイル**: `test/features/favorite/providers/favorite_provider_test.dart`
- **テスト内容**: 並び替え後のdisplayOrderが正しく更新される
- **前提条件**: お気に入りが3件存在
- **入力**: 並び替え実行
- **期待結果**: 各項目のdisplayOrderが0, 1, 2となる
- **信頼性**: 🔵 青信号 - REQ-703

### 2. Widget Tests

#### TC-066-010: 履歴画面 長押しメニュー表示
- **テストファイル**: `test/features/history/presentation/history_screen_favorite_test.dart`
- **テスト内容**: 履歴項目を長押しするとコンテキストメニューが表示される
- **前提条件**: 履歴に1件以上のデータが存在
- **操作**: 履歴項目を長押し
- **期待結果**: 「お気に入りに追加」メニューが表示される
- **信頼性**: 🔵 青信号 - REQ-701

#### TC-066-011: 履歴画面 お気に入り追加成功
- **テストファイル**: `test/features/history/presentation/history_screen_favorite_test.dart`
- **テスト内容**: 「お気に入りに追加」タップでお気に入りに追加される
- **前提条件**: 履歴項目が長押しされ、メニューが表示されている
- **操作**: 「お気に入りに追加」をタップ
- **期待結果**: スナックバーに成功メッセージ、FavoriteNotifierに追加される
- **信頼性**: 🔵 青信号 - REQ-701

#### TC-066-012: 履歴画面 重複追加エラーメッセージ
- **テストファイル**: `test/features/history/presentation/history_screen_favorite_test.dart`
- **テスト内容**: 既に登録済みの場合エラーメッセージが表示される
- **前提条件**: 同一内容がお気に入りに存在
- **操作**: 「お気に入りに追加」をタップ
- **期待結果**: スナックバーに「既にお気に入りに登録されています」
- **信頼性**: 🔵 青信号 - REQ-701

#### TC-066-020: お気に入り画面 編集モードトグル
- **テストファイル**: `test/features/favorites/presentation/favorites_reorder_test.dart`
- **テスト内容**: 編集ボタンタップで編集モードに入る
- **前提条件**: お気に入りに1件以上のデータが存在
- **操作**: 編集ボタンをタップ
- **期待結果**: ドラッグハンドルが表示される
- **信頼性**: 🔵 青信号 - REQ-703

#### TC-066-021: お気に入り画面 ドラッグ&ドロップ並び替え
- **テストファイル**: `test/features/favorites/presentation/favorites_reorder_test.dart`
- **テスト内容**: ドラッグ&ドロップで順序が変更される
- **前提条件**: お気に入りに3件以上のデータが存在、編集モード
- **操作**: 1番目の項目を3番目にドラッグ
- **期待結果**: 順序が変更され、UIに反映される
- **信頼性**: 🔵 青信号 - REQ-703

#### TC-066-022: お気に入り画面 編集モード終了
- **テストファイル**: `test/features/favorites/presentation/favorites_reorder_test.dart`
- **テスト内容**: 編集モード終了でドラッグハンドルが非表示になる
- **前提条件**: 編集モード中
- **操作**: 完了ボタンをタップ
- **期待結果**: ドラッグハンドルが非表示になる
- **信頼性**: 🔵 青信号 - REQ-703

### 3. Integration Tests

#### TC-066-030: 履歴→お気に入り追加→表示確認フロー
- **テストファイル**: `test/integration/favorite_flow_test.dart`
- **テスト内容**: 履歴からお気に入り追加し、お気に入り画面で表示される
- **シナリオ**:
  1. 履歴画面を表示
  2. 履歴項目を長押し
  3. 「お気に入りに追加」をタップ
  4. お気に入り画面に遷移
  5. 追加した項目が表示される
- **期待結果**: お気に入り画面に項目が表示される
- **信頼性**: 🔵 青信号 - REQ-701

#### TC-066-031: 並び替え後の順序維持確認
- **テストファイル**: `test/integration/favorite_flow_test.dart`
- **テスト内容**: 並び替え後にProvider状態が維持される
- **シナリオ**:
  1. お気に入り画面で編集モードに入る
  2. 項目を並び替える
  3. 編集モードを終了
  4. 順序が維持されている
- **期待結果**: 並び替えた順序が維持される
- **信頼性**: 🔵 青信号 - REQ-703

### 4. 削除確認ダイアログ（既存テスト確認）

#### TC-066-040: 個別削除確認ダイアログ
- **テストファイル**: `test/features/favorites/presentation/favorites_screen_test.dart`
- **テスト内容**: 削除ボタンタップで確認ダイアログが表示される
- **状態**: ✅ 既存テストで対応済み
- **信頼性**: 🔵 青信号 - REQ-704, REQ-2002

#### TC-066-041: 全削除確認ダイアログ
- **テストファイル**: `test/features/favorites/presentation/favorites_screen_test.dart`
- **テスト内容**: 全削除ボタンタップで確認ダイアログが表示される
- **状態**: ✅ 既存テストで対応済み
- **信頼性**: 🔵 青信号 - REQ-704, REQ-2002

## テストファイル構成

```
test/
├── features/
│   ├── favorite/
│   │   └── providers/
│   │       └── favorite_provider_test.dart  # TC-066-001〜004
│   ├── favorites/
│   │   └── presentation/
│   │       └── favorites_reorder_test.dart  # TC-066-020〜022 (新規)
│   └── history/
│       └── presentation/
│           └── history_screen_favorite_test.dart  # TC-066-010〜012 (新規)
└── integration/
    └── favorite_flow_test.dart  # TC-066-030〜031 (新規)
```

## 実装優先順位

1. **TC-066-001〜004**: FavoriteNotifier Unit Tests（基盤）
2. **TC-066-010〜012**: 履歴画面Widget Tests（新機能）
3. **TC-066-020〜022**: 並び替えWidget Tests（新機能）
4. **TC-066-030〜031**: Integration Tests（統合確認）

## 更新履歴

- 2025-11-29: 初版作成（TDD Testcasesフェーズ）
