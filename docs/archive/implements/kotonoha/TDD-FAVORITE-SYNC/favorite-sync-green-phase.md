# Greenフェーズ設計書 - 定型文お気に入りとお気に入り画面の連動機能

## 基本情報

- **タスクID**: TDD-FAVORITE-SYNC
- **フェーズ**: Green（最小実装）
- **実装日**: 2024-12-04
- **テストファイル**: `test/features/favorite_sync/favorite_sync_test.dart`

---

## 1. 実装概要

### 1.1 実装したファイル

| ファイル | 変更内容 |
|----------|----------|
| `lib/features/favorite/domain/models/favorite.dart` | sourceType, sourceIdフィールド追加 |
| `lib/features/favorite/providers/favorite_provider.dart` | addFavoriteFromPresetPhrase, deleteFavoriteBySourceIdメソッド追加 |
| `lib/features/preset_phrase/providers/preset_phrase_notifier.dart` | FavoriteNotifier連動ロジック追加 |

### 1.2 テスト結果

```
00:01 +13: All tests passed!
```

全13テストケースが成功。

---

## 2. 実装詳細

### 2.1 Favoriteモデルの拡張

**ファイル**: `lib/features/favorite/domain/models/favorite.dart`

```dart
/// 【フィールド定義】: 元データの種類（'preset_phrase' | 'history' | null）
/// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件定義に基づく
final String? sourceType;

/// 【フィールド定義】: 元データのID（定型文IDまたは履歴ID）
/// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件定義に基づく
final String? sourceId;
```

**更新したメソッド**:
- `fromJson()`: sourceType, sourceIdの復元対応
- `toJson()`: sourceType, sourceIdの保存対応
- `copyWith()`: sourceType, sourceIdの更新対応
- `==` / `hashCode`: sourceType, sourceIdを含めた比較

### 2.2 FavoriteNotifierの拡張

**ファイル**: `lib/features/favorite/providers/favorite_provider.dart`

#### addFavoriteFromPresetPhrase()

```dart
/// 【メソッド定義】: 定型文由来のお気に入りを追加する
/// 【テスト対応】: TC-SYNC-001, TC-SYNC-003, TC-SYNC-301
/// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件定義に基づく
Future<void> addFavoriteFromPresetPhrase(String content, String sourceId) async {
  // 空文字チェック
  if (content.isEmpty) return;

  // sourceIdで重複チェック（contentではなく）
  final existsBySourceId = state.favorites.any((f) => f.sourceId == sourceId);
  if (existsBySourceId) return;

  // Favorite作成（sourceType='preset_phrase', sourceId=定型文ID）
  final newFavorite = Favorite(
    id: _uuid.v4(),
    content: content,
    createdAt: DateTime.now(),
    displayOrder: state.favorites.length,
    sourceType: 'preset_phrase',
    sourceId: sourceId,
  );

  state = state.copyWith(favorites: [...state.favorites, newFavorite]);
}
```

#### deleteFavoriteBySourceId()

```dart
/// 【メソッド定義】: sourceIdに一致するお気に入りを削除する
/// 【テスト対応】: TC-SYNC-002, TC-SYNC-202, TC-SYNC-302, TC-SYNC-303
/// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件定義に基づく
Future<void> deleteFavoriteBySourceId(String sourceId) async {
  final index = state.favorites.indexWhere((f) => f.sourceId == sourceId);
  if (index == -1) return; // 該当なしは何もしない

  final updatedFavorites = List<Favorite>.from(state.favorites);
  updatedFavorites.removeAt(index);
  state = state.copyWith(favorites: updatedFavorites);
}
```

### 2.3 PresetPhraseNotifierの修正

**ファイル**: `lib/features/preset_phrase/providers/preset_phrase_notifier.dart`

#### コンストラクタ変更

```dart
/// FavoriteNotifierへの参照を受け取る
PresetPhraseNotifier(this._favoriteNotifier) : super(const PresetPhraseState());

final FavoriteNotifier? _favoriteNotifier;
```

#### toggleFavorite()の連動処理

```dart
// 【連動処理】: FavoriteNotifierへの連動（TC-SYNC-001, TC-SYNC-002）
if (_favoriteNotifier != null) {
  if (updatedPhrase.isFavorite) {
    await _favoriteNotifier.addFavoriteFromPresetPhrase(
      updatedPhrase.content,
      updatedPhrase.id,
    );
  } else {
    await _favoriteNotifier.deleteFavoriteBySourceId(updatedPhrase.id);
  }
}
```

#### deletePhrase()の連動処理

```dart
// 【連動処理】: お気に入り済みの定型文を削除する場合、Favoriteからも削除（TC-SYNC-202）
final phrase = state.phrases[index];
if (phrase.isFavorite && _favoriteNotifier != null) {
  await _favoriteNotifier.deleteFavoriteBySourceId(id);
}
```

#### Provider定義の更新

```dart
final presetPhraseNotifierProvider =
    StateNotifierProvider<PresetPhraseNotifier, PresetPhraseState>((ref) {
  final favoriteNotifier = ref.read(favoriteProvider.notifier);
  return PresetPhraseNotifier(favoriteNotifier);
});
```

---

## 3. テストケース成功確認

| テストケースID | テスト名 | 状態 |
|---------------|---------|------|
| TC-SYNC-001 | 定型文をお気に入りにするとFavoriteにも追加される | ✅ 成功 |
| TC-SYNC-002 | 定型文のお気に入りを解除するとFavoriteからも削除される | ✅ 成功 |
| TC-SYNC-003 | Favoriteにsourceとして定型文情報が保存される | ✅ 成功 |
| TC-SYNC-005 | 複数の定型文を連続してお気に入りにできる | ✅ 成功 |
| TC-SYNC-101 | 存在しない定型文IDでtoggleFavoriteを呼び出しても例外が発生しない | ✅ 成功 |
| TC-SYNC-102 | 同じ定型文を重複してお気に入りに追加しようとしても1件のみ登録される | ✅ 成功 |
| TC-SYNC-103 | 同じcontentの履歴由来と定型文由来が共存できる | ✅ 成功 |
| TC-SYNC-201 | お気に入りが0件の状態から定型文を追加 | ✅ 成功 |
| TC-SYNC-202 | お気に入り済み定型文を削除した場合、Favoriteからも削除される | ✅ 成功 |
| TC-SYNC-203 | 全削除後に定型文をお気に入りにできる | ✅ 成功 |
| TC-SYNC-301 | addFavoriteFromPresetPhrase()で定型文由来のFavoriteが追加される | ✅ 成功 |
| TC-SYNC-302 | deleteFavoriteBySourceId()でsourceIdに一致するFavoriteが削除される | ✅ 成功 |
| TC-SYNC-303 | deleteFavoriteBySourceId()で該当なしの場合は何も削除されない | ✅ 成功 |

---

## 4. 既存テストへの影響

| テスト領域 | テスト件数 | 結果 |
|-----------|-----------|------|
| preset_phrase関連 | 102件 | ✅ 全成功 |
| favorite関連 | 36件 | ✅ 全成功 |

---

## 5. 品質判定

### ✅ Greenフェーズ完了

| 項目 | 状態 | 備考 |
|------|------|------|
| 全テスト成功 | ✅ | 13/13テストケース成功 |
| 既存テスト影響なし | ✅ | preset_phrase, favorite両方で成功 |
| 最小実装 | ✅ | 必要な機能のみ実装 |
| コード品質 | ✅ | コメント・ドキュメント付き |

---

## 6. 次のステップ

次のお勧めステップ: `/tsumiki:tdd-refactor` でRefactorフェーズ（品質改善）を開始します。

### Refactorフェーズで検討する項目

1. **ドキュメント整理**: 実装ファイルのヘッダーコメント更新
2. **Provider依存関係**: `ref.read`から`ref.watch`への変更検討
3. **エラーハンドリング**: 連動処理失敗時のフォールバック
