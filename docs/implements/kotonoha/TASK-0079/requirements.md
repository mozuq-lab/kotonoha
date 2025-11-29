# TASK-0079: アプリ状態復元・クラッシュリカバリ実装 - 要件定義

## タスク概要

- **タスクID**: TASK-0079
- **タスク名**: アプリ状態復元・クラッシュリカバリ実装
- **関連要件**: NFR-302, EDGE-201, REQ-5003
- **依存タスク**: TASK-0054 (Hive初期化)

## 関連要件（EARS記法）

### NFR-302: データ整合性の保持 🔵

**EARS記法**: Ubiquitous
> システムはデータの整合性を保持しなければならない

**受け入れ基準**:
- 複数の状態を同時に保存・復元できる
- 保存された状態が正しく復元される
- データの破損がない

### EDGE-201: バックグラウンド復帰時の状態復元 🔵

**EARS記法**: Event-driven
> ユーザーがアプリをバックグラウンドから復帰した場合、システムは前回の状態を復元しなければならない

**受け入れ基準**:
- バックグラウンド移行時に状態が自動保存される
- フォアグラウンド復帰時に状態が自動復元される
- 入力中のテキストが復元される
- 最後に表示した画面パスが復元される

### REQ-5003: クラッシュ時のデータ保持 🔵

**EARS記法**: State-driven
> システムがクラッシュした場合、保存済みのデータは保持されなければならない

**受け入れ基準**:
- 定型文・設定・履歴がHiveで永続化される（既存実装）
- セッション状態がSharedPreferencesで永続化される
- アプリ再起動後にデータが復元される

## 機能要件

### 1. AppSessionState

| 要件ID | 説明 | 優先度 |
|--------|------|--------|
| STATE-001 | 入力中のテキスト（draftText）を保持する | 高 |
| STATE-002 | 最後に表示したルート（lastRoute）を保持する | 高 |
| STATE-003 | 初期化完了フラグ（isInitialized）を保持する | 中 |
| STATE-004 | セッションタイムスタンプを保持する | 低 |
| STATE-005 | copyWithでイミュータブルな更新ができる | 高 |
| STATE-006 | clearedで状態をクリアできる | 高 |

### 2. AppSessionNotifier

| 要件ID | 説明 | 優先度 |
|--------|------|--------|
| NOT-001 | initialize()でSharedPreferencesから状態を復元する | 高 |
| NOT-002 | saveDraftText()で入力中テキストを保存する | 高 |
| NOT-003 | saveLastRoute()で最後のルートを保存する | 高 |
| NOT-004 | onAppPaused()でバックグラウンド移行時に状態を保存する | 高 |
| NOT-005 | onAppResumed()でフォアグラウンド復帰時に状態を復元する | 高 |
| NOT-006 | clearSession()でセッション状態をクリアする | 中 |
| NOT-007 | 空のテキストはSharedPreferencesから削除する | 中 |

### 3. AppLifecycleObserver

| 要件ID | 説明 | 優先度 |
|--------|------|--------|
| OBS-001 | WidgetsBindingObserverでライフサイクルを監視する | 高 |
| OBS-002 | AppLifecycleState.pausedでonAppPaused()を呼ぶ | 高 |
| OBS-003 | AppLifecycleState.resumedでonAppResumed()を呼ぶ | 高 |
| OBS-004 | initStateでProviderを初期化する | 高 |
| OBS-005 | disposeでObserverを解除する | 高 |

### 4. SharedPreferencesキー

| キー名 | 説明 | 型 |
|--------|------|-----|
| draft_text | 入力中のテキスト | String |
| last_route | 最後に表示したルート | String |
| session_timestamp | セッションタイムスタンプ | String (milliseconds) |

## 非機能要件

| 要件ID | 説明 | 基準値 |
|--------|------|--------|
| NFR-APP-001 | 状態保存 | 非同期、UIをブロックしない |
| NFR-APP-002 | 状態復元 | 100ms以内 |
| NFR-APP-003 | SharedPreferences書き込み | バックグラウンド移行前に完了 |

## 信頼性レベル

- 🔵 **青信号**: NFR-302, EDGE-201, REQ-5003 - EARS要件定義書に明記
