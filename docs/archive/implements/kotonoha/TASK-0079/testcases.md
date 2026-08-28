# TASK-0079: アプリ状態復元・クラッシュリカバリ実装 - テストケース

## テスト概要

- **タスクID**: TASK-0079
- **総テストケース数**: 10件
- **テストファイル**: `test/features/app_state/app_state_test.dart`

---

## 1. 入力中テキスト保存・復元テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-079-001 | 入力中テキストが保存される | - | saveDraftText('入力中のテキスト')を呼ぶ | draftTextが'入力中のテキスト'になる | NOT-002 |
| TC-079-002 | アプリ再起動後に入力中テキストが復元される | draft_text='保存されたテキスト'がSPに保存済み | 新コンテナでinitialize()を呼ぶ | draftTextが'保存されたテキスト'になる | NOT-001, REQ-5003 |
| TC-079-003 | 空のテキストはクリアされる | draftTextに値がある | saveDraftText('')を呼ぶ | draftTextが空になる | NOT-007 |

---

## 2. 最後の画面状態復元テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-079-004 | 最後に表示した画面パスが保存される | - | saveLastRoute('/history')を呼ぶ | lastRouteが'/history'になる | NOT-003 |
| TC-079-005 | アプリ再起動後に最後の画面パスが復元される | last_route='/settings'がSPに保存済み | 新コンテナでinitialize()を呼ぶ | lastRouteが'/settings'になる | NOT-001, REQ-5003 |

---

## 3. バックグラウンド復帰テスト (EDGE-201)

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-079-006 | バックグラウンド移行時に状態が保存される | draftText, lastRouteが設定済み | onAppPaused()を呼ぶ | SharedPreferencesに状態が保存される | NOT-004, EDGE-201 |
| TC-079-007 | フォアグラウンド復帰時に状態が復元される | SPに状態が保存済み | onAppResumed()を呼ぶ | draftText, lastRouteが復元される | NOT-005, EDGE-201 |

---

## 4. クラッシュリカバリテスト (REQ-5003)

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-079-008 | 保存された状態が永続化されている | - | saveDraftText, saveLastRouteを呼ぶ | SharedPreferencesに値が保存される | REQ-5003 |
| TC-079-009 | 状態をクリアできる | 状態が保存済み | clearSession()を呼ぶ | draftTextが空、lastRouteがnullになる | NOT-006 |

---

## 5. データ整合性テスト (NFR-302)

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-079-010 | 複数の状態を同時に保存・復元できる | SPに複数の値が保存済み | 新コンテナでinitialize()を呼ぶ | すべての状態が正しく復元される | NFR-302 |

---

## テスト実行コマンド

```bash
# 全テスト実行
flutter test test/features/app_state/app_state_test.dart

# カバレッジ付きテスト実行
flutter test --coverage test/features/app_state/app_state_test.dart
```

## テスト対象クラス

| クラス名 | 説明 | 関連要件 |
|----------|------|----------|
| AppSessionState | セッション状態データクラス | STATE-001〜006 |
| AppSessionNotifier | セッション状態管理Notifier | NOT-001〜007 |
| AppLifecycleObserver | ライフサイクル監視ウィジェット | OBS-001〜005 |

## SharedPreferencesキー

| キー | 説明 |
|------|------|
| draft_text | 入力中のテキスト |
| last_route | 最後に表示したルート |
| session_timestamp | セッションタイムスタンプ |

## テスト結果

```
10 tests passed
```
