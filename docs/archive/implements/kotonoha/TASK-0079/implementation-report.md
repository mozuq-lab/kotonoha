# TASK-0079: アプリ状態復元・クラッシュリカバリ実装

## 実装サマリー

- **タスクID**: TASK-0079
- **完了日**: 2025-11-29
- **実装タイプ**: TDDプロセス
- **テストケース**: 10件（全通過）

## 関連要件

- **NFR-302**: データ整合性の保持 🔵
- **EDGE-201**: バックグラウンド復帰時の状態復元 🔵
- **REQ-5003**: クラッシュ時のデータ保持 🔵

## 実装内容

### 1. AppSessionState

- **ファイル**: `lib/features/app_state/providers/app_session_provider.dart`
- セッション状態を表すイミュータブルなデータクラス
- プロパティ:
  - `draftText`: 入力中のテキスト
  - `lastRoute`: 最後に表示したルート
  - `isInitialized`: 初期化完了フラグ
  - `sessionTimestamp`: セッションタイムスタンプ

### 2. AppSessionNotifier

- セッション状態を管理するStateNotifier
- メソッド:
  - `initialize()`: SharedPreferencesから状態を復元
  - `saveDraftText()`: 入力中テキストを保存
  - `saveLastRoute()`: 最後のルートを保存
  - `onAppPaused()`: バックグラウンド移行時の保存
  - `onAppResumed()`: フォアグラウンド復帰時の復元
  - `clearSession()`: セッションクリア

### 3. AppLifecycleObserver

- **ファイル**: `lib/features/app_state/providers/app_lifecycle_observer.dart`
- アプリライフサイクルを監視するウィジェット
- `WidgetsBindingObserver`を使用
- バックグラウンド移行/復帰時に自動でセッション保存/復元

### 4. SharedPreferencesキー

- `draft_text`: 入力中のテキスト
- `last_route`: 最後に表示したルート
- `session_timestamp`: セッションタイムスタンプ

## テスト結果

```
10 tests passed
```

## テストケース一覧

### 入力中テキスト保存・復元テスト
- TC-079-001: 入力中テキストが保存される
- TC-079-002: アプリ再起動後に入力中テキストが復元される
- TC-079-003: 空のテキストはクリアされる

### 最後の画面状態復元テスト
- TC-079-004: 最後に表示した画面パスが保存される
- TC-079-005: アプリ再起動後に最後の画面パスが復元される

### バックグラウンド復帰テスト (EDGE-201)
- TC-079-006: バックグラウンド移行時に状態が保存される
- TC-079-007: フォアグラウンド復帰時に状態が復元される

### クラッシュリカバリテスト (REQ-5003)
- TC-079-008: 保存された状態が永続化されている
- TC-079-009: 状態をクリアできる

### データ整合性テスト (NFR-302)
- TC-079-010: 複数の状態を同時に保存・復元できる

## 完了条件の達成状況

- ✅ バックグラウンド復帰時に前回の状態が復元される
- ✅ アプリクラッシュ後も定型文・設定・履歴が保持される（SharedPreferences使用）
- ✅ 入力中のテキストが復元される
- ✅ データの整合性が保たれる

## ファイル構成

```
lib/features/app_state/
└── providers/
    ├── app_session_provider.dart (NEW)
    └── app_lifecycle_observer.dart (NEW)

test/features/app_state/
└── app_state_test.dart (NEW)
```

## 使用例

```dart
// main.dartでAppLifecycleObserverをラップ
void main() {
  runApp(
    ProviderScope(
      child: AppLifecycleObserver(
        child: MyApp(),
      ),
    ),
  );
}

// 入力テキストの自動保存
final notifier = ref.read(appSessionProvider.notifier);
await notifier.saveDraftText(inputText);

// ルートの保存
await notifier.saveLastRoute(context.location);

// 復元されたテキストの取得
final draftText = ref.read(appSessionProvider).draftText;
```

## 信頼性レベル

- 🔵 **青信号**: NFR-302, EDGE-201, REQ-5003 - EARS要件定義書に明記

## 注記

既存のHive実装（定型文、履歴、お気に入り）はTASK-0054で既に永続化されており、
クラッシュ時のデータ保持は達成されている。
本タスクでは、追加でセッション状態（入力中テキスト、最後のルート）の
保存・復元機能を実装した。
