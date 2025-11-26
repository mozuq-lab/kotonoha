# TDD Red Phase メモ - TASK-0057

## 概要
- **タスク**: Riverpod Provider 構造設計
- **フェーズ**: Red（失敗するテスト作成）
- **実行日時**: 2025-11-26

## 作成したテストファイル

### 1. history_provider_test.dart
- **パス**: `test/features/history/providers/history_provider_test.dart`
- **テストケース数**: 12件（TC-057-001〜TC-057-012）
- **内容**: HistoryProviderのCRUD操作、検索、デフォルト値、異常系

### 2. favorite_provider_test.dart
- **パス**: `test/features/favorite/providers/favorite_provider_test.dart`
- **テストケース数**: 12件（TC-057-013〜TC-057-024）
- **内容**: FavoriteProviderのCRUD操作、並び替え、デフォルト値、異常系

### 3. network_provider_test.dart
- **パス**: `test/features/network/providers/network_provider_test.dart`
- **テストケース数**: 9件（TC-057-025〜TC-057-033）
- **内容**: NetworkProviderのオンライン/オフライン状態、AI変換可否判定

### 4. app_providers_test.dart
- **パス**: `test/shared/providers/app_providers_test.dart`
- **テストケース数**: 5件（TC-057-034〜TC-057-038）
- **内容**: app_providers.dartからの各Providerエクスポート確認

## テスト失敗状況

現時点では以下のファイルが存在しないため、テストはコンパイルエラーで失敗します：

### 未実装ファイル（Greenフェーズで作成予定）

1. **HistoryProvider関連**
   - `lib/features/history/providers/history_provider.dart`
   - `lib/features/history/domain/models/history.dart`
   - `lib/features/history/domain/models/history_type.dart`

2. **FavoriteProvider関連**
   - `lib/features/favorite/providers/favorite_provider.dart`
   - `lib/features/favorite/domain/models/favorite.dart`

3. **NetworkProvider関連**
   - `lib/features/network/providers/network_provider.dart`
   - `lib/features/network/domain/models/network_state.dart`

4. **app_providers.dart**
   - `lib/shared/providers/app_providers.dart`

## テストケース一覧（38件）

| カテゴリ | TC ID範囲 | 件数 |
|---------|----------|------|
| HistoryProvider | TC-057-001〜012 | 12 |
| FavoriteProvider | TC-057-013〜024 | 12 |
| NetworkProvider | TC-057-025〜033 | 9 |
| app_providers | TC-057-034〜038 | 5 |
| **合計** | | **38** |

## 次のステップ

Greenフェーズで以下の実装を行う：
1. domain/models の作成（History, HistoryType, Favorite, NetworkState）
2. Provider本体の作成（historyProvider, favoriteProvider, networkProvider）
3. app_providers.dart の作成
