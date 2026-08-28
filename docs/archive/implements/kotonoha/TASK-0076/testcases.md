# TASK-0076: ネットワーク状態管理Provider - テストケース

## テスト概要

- **タスクID**: TASK-0076
- **総テストケース数**: 19件
  - 既存テスト（TASK-0057）: 9件
  - 新規テスト: 10件
- **テストファイル**:
  - `test/features/network/providers/network_provider_test.dart`
  - `test/features/network/providers/network_connectivity_test.dart`

---

## 1. 既存テスト（TASK-0057からの継承）

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-057-025 | オンライン状態を検知できる | - | setOnline()を呼ぶ | NetworkState.online | REQ-3004 |
| TC-057-026 | オフライン状態を検知できる | - | setOffline()を呼ぶ | NetworkState.offline | REQ-3004 |
| TC-057-027 | オンラインでAI変換が有効 | オンライン状態 | isAIConversionAvailableを確認 | true | REQ-1001 |
| TC-057-028 | オフラインでAI変換が無効 | オフライン状態 | isAIConversionAvailableを確認 | false | REQ-1001 |
| TC-057-029 | ネットワーク状態変更時に通知される | - | 状態変更を監視 | 通知が発行される | REQ-1002 |
| TC-057-030 | 初期状態はchecking | 新規コンテナ | networkProviderを読む | NetworkState.checking | - |
| TC-057-031 | 接続チェック失敗時はoffline扱い | - | エラー発生をシミュレート | NetworkState.offline | NET-010 |
| TC-057-032 | オフラインでも基本機能は動作 | オフライン状態 | 基本機能の状態確認 | 影響なし | REQ-1003 |
| TC-057-033 | オフラインでも定型文は動作 | オフライン状態 | 定型文機能の状態確認 | 影響なし | REQ-1003 |

---

## 2. 新規テスト - 接続検知テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-076-001 | WiFi接続時にオンライン状態 | モック: wifi | initializeWithConnectivity() | NetworkState.online | NET-005, REQ-3004 |
| TC-076-002 | モバイルデータ接続時にオンライン状態 | モック: mobile | initializeWithConnectivity() | NetworkState.online | NET-006, REQ-3004 |
| TC-076-003 | イーサネット接続時にオンライン状態 | モック: ethernet | initializeWithConnectivity() | NetworkState.online | NET-007, REQ-3004 |
| TC-076-004 | 接続なし時にオフライン状態 | モック: none | initializeWithConnectivity() | NetworkState.offline | NET-008, REQ-3004 |

---

## 3. 新規テスト - 接続状態変更リスナーテスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-076-005 | WiFi→オフライン変更を検知 | WiFi接続中 | 接続がnoneに変更 | NetworkState.offline | CHG-001, REQ-3004 |
| TC-076-006 | オフライン→WiFi変更を検知 | オフライン状態 | 接続がwifiに変更 | NetworkState.online | CHG-002, REQ-3004 |
| TC-076-007 | 複数の接続タイプがある場合はオンライン | モック: [wifi, mobile] | initializeWithConnectivity() | NetworkState.online | NET-009 |

---

## 4. 新規テスト - 定期接続確認テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-076-008 | 定期接続確認が動作する | - | checkConnectivity呼び出し回数確認 | 初期化時に1回呼ばれる | NET-002 |
| TC-076-009 | 接続確認でエラーが発生してもオフライン扱い | モック: throw Exception | initializeWithConnectivity() | NetworkState.offline | NET-010 |

---

## 5. 新規テスト - リソース解放テスト

| TC-ID | テストケース名 | 前提条件 | テスト内容 | 期待結果 | 関連要件 |
|-------|---------------|----------|-----------|----------|----------|
| TC-076-010 | stopListeningでリスナーが停止する | リスナー動作中 | stopListening()後に状態変更 | 状態変更が検知されない | NET-004 |

---

## テスト実行コマンド

```bash
# 全テスト実行
flutter test test/features/network/providers/

# 個別テスト実行
flutter test test/features/network/providers/network_provider_test.dart
flutter test test/features/network/providers/network_connectivity_test.dart
```

## モック設定

```dart
class MockConnectivityService extends Mock implements ConnectivityService {}

// モック設定例
when(() => mockService.checkConnectivity())
    .thenAnswer((_) async => [ConnectivityResult.wifi]);

when(() => mockService.onConnectivityChanged)
    .thenAnswer((_) => connectivityController.stream);
```

## テスト結果

```
19 tests passed
```
