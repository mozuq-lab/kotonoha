# Redフェーズ設計書 - 定型文お気に入りとお気に入り画面の連動機能

## 基本情報

- **タスクID**: TDD-FAVORITE-SYNC
- **フェーズ**: Red（失敗するテスト作成）
- **作成日**: 2024-12-04
- **テストファイル**: `test/features/favorite_sync/favorite_sync_test.dart`

---

## 1. テスト設計概要

### 1.1 テスト対象

| ファイル | 変更内容 |
|----------|----------|
| `lib/features/favorite/domain/models/favorite.dart` | sourceType, sourceIdフィールド追加 |
| `lib/features/favorite/providers/favorite_provider.dart` | addFavoriteFromPresetPhrase, deleteFavoriteBySourceIdメソッド追加 |
| `lib/features/preset_phrase/providers/preset_phrase_notifier.dart` | toggleFavorite, deletePhraseに連動ロジック追加 |

### 1.2 テストケース一覧

| テストケースID | テスト名 | 信頼性 | 状態 |
|---------------|---------|--------|------|
| TC-SYNC-001 | 定型文をお気に入りにするとFavoriteにも追加される | 🔵 | 失敗 |
| TC-SYNC-002 | 定型文のお気に入りを解除するとFavoriteからも削除される | 🔵 | 失敗 |
| TC-SYNC-003 | Favoriteにsourceとして定型文情報が保存される | 🟡 | 失敗 |
| TC-SYNC-005 | 複数の定型文を連続してお気に入りにできる | 🔵 | 失敗 |
| TC-SYNC-101 | 存在しない定型文IDでtoggleFavoriteを呼び出しても例外が発生しない | 🟡 | 失敗 |
| TC-SYNC-102 | 同じ定型文を重複してお気に入りに追加しようとしても1件のみ登録される | 🔵 | 失敗 |
| TC-SYNC-103 | 同じcontentの履歴由来と定型文由来が共存できる | 🟡 | 失敗 |
| TC-SYNC-201 | お気に入りが0件の状態から定型文を追加 | 🔵 | 失敗 |
| TC-SYNC-202 | お気に入り済み定型文を削除した場合、Favoriteからも削除される | 🔵 | 失敗 |
| TC-SYNC-203 | 全削除後に定型文をお気に入りにできる | 🟡 | 失敗 |
| TC-SYNC-301 | addFavoriteFromPresetPhrase()で定型文由来のFavoriteが追加される | 🟡 | 失敗 |
| TC-SYNC-302 | deleteFavoriteBySourceId()でsourceIdに一致するFavoriteが削除される | 🟡 | 失敗 |
| TC-SYNC-303 | deleteFavoriteBySourceId()で該当なしの場合は何も削除されない | 🟡 | 失敗 |

---

## 2. 期待される失敗メッセージ

テスト実行時にコンパイルエラーで失敗:

```
test/features/favorite_sync/favorite_sync_test.dart:156:23: Error: The getter 'sourceType' isn't defined for the type 'Favorite'.
test/features/favorite_sync/favorite_sync_test.dart:158:23: Error: The getter 'sourceId' isn't defined for the type 'Favorite'.
test/features/favorite_sync/favorite_sync_test.dart:429:30: Error: The method 'addFavoriteFromPresetPhrase' isn't defined for the type 'FavoriteNotifier'.
test/features/favorite_sync/favorite_sync_test.dart:466:30: Error: The method 'deleteFavoriteBySourceId' isn't defined for the type 'FavoriteNotifier'.
```

---

## 3. Greenフェーズで必要な実装

### 3.1 Favoriteモデルの拡張

```dart
// lib/features/favorite/domain/models/favorite.dart
class Favorite {
  final String id;
  final String content;
  final DateTime createdAt;
  final int displayOrder;
  final String? sourceType;  // 【新規追加】: 'preset_phrase' | 'history' | null
  final String? sourceId;    // 【新規追加】: 元データのID

  const Favorite({
    required this.id,
    required this.content,
    required this.createdAt,
    this.displayOrder = 0,
    this.sourceType,        // 【新規追加】
    this.sourceId,          // 【新規追加】
  });

  // copyWith, fromJson, toJsonも更新必要
}
```

### 3.2 FavoriteNotifierの拡張

```dart
// lib/features/favorite/providers/favorite_provider.dart
class FavoriteNotifier extends StateNotifier<FavoriteState> {
  // 既存メソッド...

  /// 【新規メソッド】: 定型文由来のお気に入りを追加
  Future<void> addFavoriteFromPresetPhrase(String content, String sourceId) async {
    // sourceType: 'preset_phrase', sourceId: sourceId を設定してFavorite追加
  }

  /// 【新規メソッド】: sourceIdに一致するFavoriteを削除
  Future<void> deleteFavoriteBySourceId(String sourceId) async {
    // sourceIdが一致するFavoriteを検索して削除
  }
}
```

### 3.3 PresetPhraseNotifierの修正

```dart
// lib/features/preset_phrase/providers/preset_phrase_notifier.dart
class PresetPhraseNotifier extends StateNotifier<PresetPhraseState> {
  // FavoriteNotifierへの参照が必要

  Future<void> toggleFavorite(String id) async {
    // 既存の処理...

    // 【追加】: FavoriteNotifierとの連動
    if (updatedPhrase.isFavorite) {
      // お気に入り追加 → Favoriteにも追加
      await favoriteNotifier.addFavoriteFromPresetPhrase(
        updatedPhrase.content,
        updatedPhrase.id,
      );
    } else {
      // お気に入り解除 → Favoriteからも削除
      await favoriteNotifier.deleteFavoriteBySourceId(updatedPhrase.id);
    }
  }

  Future<void> deletePhrase(String id) async {
    // 【追加】: 削除前にお気に入り済みなら連動削除
    final phrase = state.phrases.firstWhere((p) => p.id == id, orElse: () => null);
    if (phrase?.isFavorite == true) {
      await favoriteNotifier.deleteFavoriteBySourceId(id);
    }

    // 既存の削除処理...
  }
}
```

---

## 4. テスト実行コマンド

```bash
# 全テスト実行
flutter test test/features/favorite_sync/favorite_sync_test.dart

# 特定のテストグループ実行
flutter test test/features/favorite_sync/favorite_sync_test.dart --name "正常系テスト"

# 詳細出力
flutter test test/features/favorite_sync/favorite_sync_test.dart --reporter expanded
```

---

## 5. 品質判定

### ✅ Redフェーズ完了

| 項目 | 状態 | 備考 |
|------|------|------|
| テスト実行 | ✅ 失敗（コンパイルエラー） | 未実装のフィールド・メソッドを参照 |
| 期待値 | ✅ 明確 | 各テストケースで具体的な期待値を定義 |
| アサーション | ✅ 適切 | 状態変化を明確に検証 |
| 実装方針 | ✅ 明確 | 必要な変更を具体的に特定 |

---

## 6. 次のステップ

次のお勧めステップ: `/tsumiki:tdd-green` でGreenフェーズ（最小実装）を開始します。
