# TASK-0076: ネットワーク状態管理Provider実装

## 実装サマリー

- **タスクID**: TASK-0076
- **完了日**: 2025-11-29
- **実装タイプ**: TDDプロセス
- **テストケース**: 19件（全通過）
  - 既存テスト: 9件
  - 新規テスト: 10件

## 関連要件

- **REQ-1001**: オフライン時AI変換無効化 🔵
- **REQ-1002**: オフライン状態表示 🔵
- **REQ-1003**: オフライン時基本機能動作 🔵
- **REQ-3004**: ネットワーク状態の正確な検知 🔵

## 実装内容

### 1. connectivity_plusパッケージ統合

- **pubspec.yaml**: `connectivity_plus: ^6.1.3` を追加

### 2. ConnectivityService

- **ファイル**: `lib/features/network/domain/services/connectivity_service.dart`
- connectivity_plusをラップしたテスト可能なサービス
- `checkConnectivity()`: 現在の接続状態を取得
- `onConnectivityChanged`: 接続状態変更ストリーム
- Providerとして提供（テスト時にモック可能）

### 3. NetworkNotifier拡張

- **ファイル**: `lib/features/network/providers/network_provider.dart`
- ConnectivityServiceを依存性注入で受け取る
- 新規メソッド:
  - `initializeWithConnectivity()`: connectivity_plusで接続状態を初期化
  - `startListening()`: 接続状態変更リスナーを開始
  - `stopListening()`: リスナーを停止
- 接続タイプに基づく状態判定:
  - WiFi/Mobile/Ethernet → online
  - None/Empty → offline
- エラー時は安全側にオフライン扱い

### 4. テスト追加

- **ファイル**: `test/features/network/providers/network_connectivity_test.dart`
- TC-076-001〜TC-076-010 (10件)

## テスト結果

```
19 tests passed
```

## テストケース一覧

### 既存テスト（TASK-0057）
- TC-057-025: オンライン状態を検知できる
- TC-057-026: オフライン状態を検知できる
- TC-057-027: オンラインでAI変換が有効
- TC-057-028: オフラインでAI変換が無効
- TC-057-029: ネットワーク状態変更時に通知される
- TC-057-030: 初期状態はchecking
- TC-057-031: 接続チェック失敗時はoffline扱い
- TC-057-032: オフラインでも基本機能は動作
- TC-057-033: オフラインでも定型文は動作

### 新規テスト（TASK-0076）
- TC-076-001: WiFi接続時にオンライン状態
- TC-076-002: モバイルデータ接続時にオンライン状態
- TC-076-003: イーサネット接続時にオンライン状態
- TC-076-004: 接続なし時にオフライン状態
- TC-076-005: WiFi→オフライン変更を検知
- TC-076-006: オフライン→WiFi変更を検知
- TC-076-007: 複数の接続タイプがある場合はオンライン
- TC-076-008: 定期接続確認が動作する
- TC-076-009: 接続確認でエラーが発生してもオフライン扱い
- TC-076-010: stopListeningでリスナーが停止する

## 完了条件の達成状況

- ✅ ネットワーク状態がProviderで管理される
- ✅ オンライン/オフラインが正しく検知される
- ✅ 状態変更時にUIが更新される（リスナー実装）
- ✅ 定期的な接続確認が動作する（checkConnectivity()）

## 信頼性レベル

- 🔵 **青信号**: REQ-1001〜1003, REQ-3004 - EARS要件定義書に明記
