# 定型文お気に入りとお気に入り画面の連動機能 - テストケース定義書

## 基本情報

- **タスクID**: TDD-FAVORITE-SYNC
- **機能名**: 定型文お気に入りとお気に入り画面の連動
- **作成日**: 2024-12-04
- **テストフレームワーク**: flutter_test + mocktail
- **対象ファイル**:
  - `lib/features/preset_phrase/providers/preset_phrase_notifier.dart`
  - `lib/features/favorite/providers/favorite_provider.dart`
  - `lib/features/favorite/domain/models/favorite.dart`

---

## 開発言語・フレームワーク

| 項目 | 選択 | 理由 |
|------|------|------|
| **プログラミング言語** | Dart | Flutterプロジェクトの標準言語 🔵 |
| **テストフレームワーク** | flutter_test + mocktail | 既存プロジェクトで使用中、Riverpod統合テストに対応 🔵 |
| **テスト実行環境** | `flutter test` | CI/CD統合済み 🔵 |

---

## 1. 正常系テストケース（基本的な動作）

### TC-SYNC-001: 定型文をお気に入りにするとFavoriteにも追加される

- **テスト名**: 定型文お気に入り追加時のFavorite連動
  - **何をテストするか**: `toggleFavorite()`で定型文をお気に入りにした際、`FavoriteNotifier`にも自動追加される
  - **期待される動作**: 定型文の`isFavorite`がtrueになり、同時にFavoriteリストにも追加される
- **入力値**:
  - `phraseId`: 既存の定型文ID
  - **入力データの意味**: お気に入りに登録したい定型文を特定
- **期待される結果**:
  - `PresetPhrase.isFavorite == true`
  - `FavoriteState.favorites`に該当定型文のcontentが追加される
  - **期待結果の理由**: REQ-701「定型文をお気に入りとして登録」の実現
- **テストの目的**: 連動追加機能の確認
  - **確認ポイント**: 両方のProviderの状態が同期すること
- 🔵 青信号（REQ-701に基づく）

```dart
// 【テスト目的】: 定型文お気に入り追加時にFavoriteにも自動追加されることを確認
// 【テスト内容】: toggleFavorite()でisFavorite=trueになった際、FavoriteNotifierにも追加
// 【期待される動作】: 両方のProviderに同じcontentが登録される
// 🔵 青信号 - REQ-701
test('TC-SYNC-001: 定型文をお気に入りにするとFavoriteにも追加される', () async {
  // Given: 定型文を1件追加
  // When: toggleFavorite()を実行
  // Then: PresetPhrase.isFavorite == true && FavoriteState.favoritesに追加
});
```

---

### TC-SYNC-002: 定型文のお気に入りを解除するとFavoriteからも削除される

- **テスト名**: 定型文お気に入り解除時のFavorite連動削除
  - **何をテストするか**: お気に入り済みの定型文を解除した際、`FavoriteNotifier`からも自動削除される
  - **期待される動作**: 定型文の`isFavorite`がfalseになり、同時にFavoriteリストからも削除される
- **入力値**:
  - `phraseId`: お気に入り済みの定型文ID
  - **入力データの意味**: お気に入り解除したい定型文を特定
- **期待される結果**:
  - `PresetPhrase.isFavorite == false`
  - `FavoriteState.favorites`から該当項目が削除される
  - **期待結果の理由**: UX一貫性のため、解除時も連動が必要
- **テストの目的**: 連動削除機能の確認
  - **確認ポイント**: 解除時に両方のProviderから削除されること
- 🔵 青信号（REQ-701に基づく）

```dart
// 【テスト目的】: 定型文お気に入り解除時にFavoriteからも自動削除されることを確認
// 【テスト内容】: toggleFavorite()でisFavorite=falseになった際、FavoriteNotifierからも削除
// 【期待される動作】: 両方のProviderから該当項目が削除される
// 🔵 青信号 - REQ-701
test('TC-SYNC-002: 定型文のお気に入りを解除するとFavoriteからも削除される', () async {
  // Given: お気に入り済みの定型文を準備
  // When: toggleFavorite()を再度実行（解除）
  // Then: PresetPhrase.isFavorite == false && FavoriteState.favoritesから削除
});
```

---

### TC-SYNC-003: Favoriteにsourceとして定型文情報が保存される

- **テスト名**: Favorite追加時のsource情報保存
  - **何をテストするか**: Favoriteエンティティに元データの情報（sourceType, sourceId）が保存される
  - **期待される動作**: `sourceType: 'preset_phrase'`と`sourceId: PresetPhrase.id`が設定される
- **入力値**:
  - `phraseId`: 定型文ID
  - `content`: 定型文の内容
  - **入力データの意味**: 連動元の定型文を特定するための情報
- **期待される結果**:
  - `Favorite.sourceType == 'preset_phrase'`
  - `Favorite.sourceId == PresetPhrase.id`
  - **期待結果の理由**: 双方向連動のために元データを追跡する必要がある
- **テストの目的**: source情報保存の確認
  - **確認ポイント**: Favoriteから元の定型文を特定できること
- 🟡 黄信号（実装設計に基づく推測）

```dart
// 【テスト目的】: Favoriteに元データ情報が保存されることを確認
// 【テスト内容】: addFavoriteFromPresetPhrase()でsourceType, sourceIdが設定される
// 【期待される動作】: Favoriteエンティティに追跡情報が含まれる
// 🟡 黄信号 - 実装設計に基づく
test('TC-SYNC-003: Favoriteにsourceとして定型文情報が保存される', () async {
  // Given: 定型文を1件追加
  // When: toggleFavorite()を実行
  // Then: Favorite.sourceType == 'preset_phrase' && Favorite.sourceId == phraseId
});
```

---

### TC-SYNC-004: お気に入り画面に定型文由来のお気に入りが表示される

- **テスト名**: お気に入り画面での定型文由来項目表示
  - **何をテストするか**: 定型文からお気に入りにした項目がお気に入り画面に表示される
  - **期待される動作**: お気に入り画面（FavoritesScreen）に定型文のcontentが表示される
- **入力値**:
  - 定型文「おはようございます」をお気に入りに追加
  - **入力データの意味**: 典型的な定型文の例
- **期待される結果**:
  - お気に入り画面に「おはようございます」が表示される
  - **期待結果の理由**: REQ-701「定型文をお気に入りとして登録」のUI確認
- **テストの目的**: UI連動の確認
  - **確認ポイント**: お気に入り画面で定型文由来の項目が正しく表示されること
- 🔵 青信号（REQ-701に基づく）

```dart
// 【テスト目的】: お気に入り画面に定型文由来のお気に入りが表示されることを確認
// 【テスト内容】: 定型文をお気に入りにした後、FavoritesScreenで表示を確認
// 【期待される動作】: お気に入り画面に該当のcontentが表示される
// 🔵 青信号 - REQ-701
testWidgets('TC-SYNC-004: お気に入り画面に定型文由来のお気に入りが表示される', (tester) async {
  // Given: 定型文「おはようございます」をお気に入りに追加
  // When: お気に入り画面を表示
  // Then: 「おはようございます」が画面に表示される
});
```

---

### TC-SYNC-005: 複数の定型文を連続してお気に入りにできる

- **テスト名**: 複数定型文の連続お気に入り追加
  - **何をテストするか**: 複数の定型文を連続してお気に入りにした場合、すべてがFavoriteに追加される
  - **期待される動作**: 3件の定型文をお気に入りにすると、Favoriteリストにも3件追加される
- **入力値**:
  - 3件の定型文をそれぞれお気に入りに追加
  - **入力データの意味**: 複数操作の動作確認
- **期待される結果**:
  - `FavoriteState.favorites.length == 3`
  - **期待結果の理由**: 連続操作でも正しく動作することを保証
- **テストの目的**: 連続操作の動作確認
  - **確認ポイント**: 複数回の操作で状態が正しく同期されること
- 🔵 青信号（基本機能の確認）

```dart
// 【テスト目的】: 複数の定型文を連続してお気に入りにできることを確認
// 【テスト内容】: 3件の定型文をそれぞれtoggleFavorite()で追加
// 【期待される動作】: FavoriteState.favorites.length == 3
// 🔵 青信号
test('TC-SYNC-005: 複数の定型文を連続してお気に入りにできる', () async {
  // Given: 3件の定型文を準備
  // When: 各定型文をお気に入りに追加
  // Then: FavoriteState.favorites.length == 3
});
```

---

## 2. 異常系テストケース（エラーハンドリング）

### TC-SYNC-101: 存在しない定型文IDでtoggleFavoriteを呼び出しても例外が発生しない

- **テスト名**: 存在しないIDでのtoggleFavorite呼び出し
  - **エラーケースの概要**: 存在しない定型文IDで操作を試みた場合
  - **エラー処理の重要性**: アプリクラッシュを防止し、安定動作を保証
- **入力値**:
  - `phraseId`: 存在しないID（'non-existent-id'）
  - **不正な理由**: データベースに該当IDが存在しない
  - **実際の発生シナリオ**: バグや競合状態で古いIDが参照された場合
- **期待される結果**:
  - 例外が発生せず、状態変化なし
  - **エラーメッセージの内容**: エラーは発生しないが、操作は無視される
  - **システムの安全性**: アプリが安定動作を継続
- **テストの目的**: エラーハンドリングの確認
  - **品質保証の観点**: 堅牢性の確保
- 🟡 黄信号（エラーハンドリングの推測）

```dart
// 【テスト目的】: 存在しないIDでの操作が安全に処理されることを確認
// 【テスト内容】: 存在しないIDでtoggleFavorite()を呼び出し
// 【期待される動作】: 例外なし、状態変化なし
// 🟡 黄信号
test('TC-SYNC-101: 存在しない定型文IDでtoggleFavoriteを呼び出しても例外が発生しない', () async {
  // Given: 空の状態
  // When: 存在しないIDでtoggleFavorite()を実行
  // Then: 例外なし、状態変化なし
});
```

---

### TC-SYNC-102: 同じ定型文を重複してお気に入りに追加しようとしても1件のみ登録される

- **テスト名**: 重複登録の防止
  - **エラーケースの概要**: 同じ定型文を複数回お気に入りにした場合
  - **エラー処理の重要性**: データの重複を防止し、整合性を保持
- **入力値**:
  - 同じ定型文に対して`toggleFavorite()`を2回連続で呼び出し（追加→解除→追加）
  - **不正な理由**: 同じデータの重複登録は不整合を引き起こす
  - **実際の発生シナリオ**: ユーザーが素早く連打した場合
- **期待される結果**:
  - Favoriteリストに該当contentが1件のみ存在
  - **エラーメッセージの内容**: なし（正常処理として扱う）
  - **システムの安全性**: データ整合性が保持される
- **テストの目的**: 重複防止機能の確認
  - **品質保証の観点**: データ整合性の保証
- 🔵 青信号（要件定義3.2に基づく）

```dart
// 【テスト目的】: 重複登録が防止されることを確認
// 【テスト内容】: 同じ定型文に対して複数回お気に入り操作
// 【期待される動作】: Favoriteリストに1件のみ存在
// 🔵 青信号 - 要件定義3.2
test('TC-SYNC-102: 同じ定型文を重複してお気に入りに追加しようとしても1件のみ登録される', () async {
  // Given: 定型文を1件追加
  // When: toggleFavorite()を3回実行（追加→解除→追加）
  // Then: FavoriteState.favoritesに1件のみ
});
```

---

### TC-SYNC-103: 同じcontentの履歴由来お気に入りと定型文由来お気に入りが共存できる

- **テスト名**: 履歴由来と定型文由来の共存
  - **エラーケースの概要**: 同じcontentで異なるsourceの項目が存在する場合
  - **エラー処理の重要性**: sourceIdで区別するため、contentの重複は許容
- **入力値**:
  - 履歴から「おはようございます」をお気に入りに追加
  - 定型文の「おはようございます」もお気に入りに追加
  - **不正な理由**: 実際は不正ではなく、正常ケース
  - **実際の発生シナリオ**: ユーザーが履歴と定型文の両方からお気に入り登録
- **期待される結果**:
  - 2件の独立したFavoriteが存在（sourceIdが異なる）
  - **エラーメッセージの内容**: なし
  - **システムの安全性**: sourceIdで管理するため整合性は保持
- **テストの目的**: sourceId管理の確認
  - **品質保証の観点**: 異なるソースからの追加が正しく処理される
- 🟡 黄信号（設計判断に基づく推測）

```dart
// 【テスト目的】: 異なるsourceからの同じcontentが共存できることを確認
// 【テスト内容】: 履歴と定型文の両方から同じcontentをお気に入りに追加
// 【期待される動作】: 2件の独立したFavoriteが存在
// 🟡 黄信号
test('TC-SYNC-103: 同じcontentの履歴由来と定型文由来が共存できる', () async {
  // Given: 履歴から「おはようございます」をお気に入りに追加済み
  // When: 定型文の「おはようございます」をお気に入りに追加
  // Then: FavoriteState.favorites.length == 2
});
```

---

## 3. 境界値テストケース

### TC-SYNC-201: お気に入りが0件の状態から定型文を追加

- **テスト名**: 空状態からの最初のお気に入り追加
  - **境界値の意味**: お気に入り0件は下限境界値
  - **境界値での動作保証**: 空リストへの追加が正しく動作すること
- **入力値**:
  - お気に入り0件の状態で定型文をお気に入りに追加
  - **境界値選択の根拠**: リストが空の場合の初期追加処理
  - **実際の使用場面**: アプリ初回起動時
- **期待される結果**:
  - `FavoriteState.favorites.length == 1`
  - **境界での正確性**: 空リストへの追加が正常に動作
  - **一貫した動作**: 1件以上ある場合と同じ動作
- **テストの目的**: 空状態からの追加確認
  - **堅牢性の確認**: 境界条件での安定動作
- 🔵 青信号（EDGE-104関連）

```dart
// 【テスト目的】: 空状態からの最初のお気に入り追加が正常に動作することを確認
// 【テスト内容】: お気に入り0件の状態で定型文をお気に入りに追加
// 【期待される動作】: FavoriteState.favorites.length == 1
// 🔵 青信号 - EDGE-104関連
test('TC-SYNC-201: お気に入りが0件の状態から定型文を追加', () async {
  // Given: お気に入り0件の状態
  // When: 定型文をお気に入りに追加
  // Then: FavoriteState.favorites.length == 1
});
```

---

### TC-SYNC-202: お気に入り済み定型文を削除した場合、Favoriteからも削除される

- **テスト名**: 定型文削除時の連動Favorite削除
  - **境界値の意味**: 定型文削除という特殊な状態変化
  - **境界値での動作保証**: 孤立データを防止
- **入力値**:
  - お気に入り済みの定型文を`deletePhrase()`で削除
  - **境界値選択の根拠**: 定型文削除は関連データに影響を与える操作
  - **実際の使用場面**: ユーザーが不要な定型文を削除した場合
- **期待される結果**:
  - 該当定型文が削除される
  - 対応するFavoriteも削除される
  - **境界での正確性**: 連動削除が正しく動作
  - **一貫した動作**: 孤立データが残らない
- **テストの目的**: 連動削除の確認
  - **堅牢性の確認**: データ整合性の維持
- 🔵 青信号（要件定義3.2「孤立データ防止」）

```dart
// 【テスト目的】: 定型文削除時にFavoriteも連動削除されることを確認
// 【テスト内容】: お気に入り済みの定型文を削除
// 【期待される動作】: 対応するFavoriteも削除される
// 🔵 青信号 - 要件定義3.2
test('TC-SYNC-202: お気に入り済み定型文を削除した場合、Favoriteからも削除される', () async {
  // Given: お気に入り済みの定型文を準備
  // When: deletePhrase()を実行
  // Then: FavoriteState.favoritesから該当項目が削除される
});
```

---

### TC-SYNC-203: 全削除後に定型文をお気に入りにできる

- **テスト名**: 全削除後のお気に入り追加
  - **境界値の意味**: 全削除後の空状態からの復帰
  - **境界値での動作保証**: 全削除後も正常に機能すること
- **入力値**:
  - `clearAllFavorites()`で全削除後、新たに定型文をお気に入りに追加
  - **境界値選択の根拠**: 全削除は状態をリセットする特殊操作
  - **実際の使用場面**: ユーザーが全削除後に再度お気に入りを登録
- **期待される結果**:
  - 全削除後も正常にお気に入り追加可能
  - `FavoriteState.favorites.length == 1`
  - **境界での正確性**: リセット後の追加が正常動作
  - **一貫した動作**: 通常の追加と同じ動作
- **テストの目的**: リセット後の動作確認
  - **堅牢性の確認**: 状態リセット後の安定動作
- 🟡 黄信号（エッジケースの推測）

```dart
// 【テスト目的】: 全削除後もお気に入り追加が正常に動作することを確認
// 【テスト内容】: clearAllFavorites()後に定型文をお気に入りに追加
// 【期待される動作】: FavoriteState.favorites.length == 1
// 🟡 黄信号
test('TC-SYNC-203: 全削除後に定型文をお気に入りにできる', () async {
  // Given: お気に入りを追加後、全削除
  // When: 新たに定型文をお気に入りに追加
  // Then: FavoriteState.favorites.length == 1
});
```

---

## 4. FavoriteNotifier拡張テストケース

### TC-SYNC-301: addFavoriteFromPresetPhrase()で定型文由来のFavoriteが追加される

- **テスト名**: 定型文由来Favorite追加メソッド
  - **何をテストするか**: 新規メソッド`addFavoriteFromPresetPhrase()`の動作
  - **期待される動作**: sourceType, sourceIdが正しく設定されたFavoriteが追加される
- **入力値**:
  - `content`: 'おはようございます'
  - `sourceId`: '123e4567-e89b-12d3-a456-426614174000'
- **期待される結果**:
  - Favoriteが追加される
  - `Favorite.sourceType == 'preset_phrase'`
  - `Favorite.sourceId == sourceId`
- **テストの目的**: 新規メソッドの動作確認
- 🟡 黄信号（新規実装）

```dart
// 【テスト目的】: addFavoriteFromPresetPhrase()の動作確認
// 【テスト内容】: 定型文由来のFavoriteを追加
// 【期待される動作】: sourceType, sourceIdが正しく設定される
// 🟡 黄信号
test('TC-SYNC-301: addFavoriteFromPresetPhrase()で定型文由来のFavoriteが追加される', () async {
  // Given: FavoriteNotifierを準備
  // When: addFavoriteFromPresetPhrase()を実行
  // Then: Favorite.sourceType == 'preset_phrase'
});
```

---

### TC-SYNC-302: deleteFavoriteBySourceId()でsourceIdに一致するFavoriteが削除される

- **テスト名**: sourceIdによるFavorite削除メソッド
  - **何をテストするか**: 新規メソッド`deleteFavoriteBySourceId()`の動作
  - **期待される動作**: 指定したsourceIdに一致するFavoriteが削除される
- **入力値**:
  - `sourceId`: 削除対象の定型文ID
- **期待される結果**:
  - 該当Favoriteが削除される
  - 他のFavoriteは影響を受けない
- **テストの目的**: 新規メソッドの動作確認
- 🟡 黄信号（新規実装）

```dart
// 【テスト目的】: deleteFavoriteBySourceId()の動作確認
// 【テスト内容】: sourceIdに一致するFavoriteを削除
// 【期待される動作】: 該当Favoriteのみ削除される
// 🟡 黄信号
test('TC-SYNC-302: deleteFavoriteBySourceId()でsourceIdに一致するFavoriteが削除される', () async {
  // Given: 複数のFavoriteを準備（異なるsourceId）
  // When: deleteFavoriteBySourceId()を実行
  // Then: 該当Favoriteのみ削除される
});
```

---

### TC-SYNC-303: deleteFavoriteBySourceId()で該当なしの場合は何も削除されない

- **テスト名**: sourceIdに該当なしの場合の安全性
  - **何をテストするか**: 存在しないsourceIdで削除を試みた場合の動作
  - **期待される動作**: 例外なし、状態変化なし
- **入力値**:
  - `sourceId`: 存在しないID
- **期待される結果**:
  - 例外が発生しない
  - Favoriteリストは変化なし
- **テストの目的**: 安全性の確認
- 🟡 黄信号（エラーハンドリング）

```dart
// 【テスト目的】: 存在しないsourceIdでの削除が安全に処理されることを確認
// 【テスト内容】: 存在しないsourceIdでdeleteFavoriteBySourceId()を実行
// 【期待される動作】: 例外なし、状態変化なし
// 🟡 黄信号
test('TC-SYNC-303: deleteFavoriteBySourceId()で該当なしの場合は何も削除されない', () async {
  // Given: Favoriteを準備
  // When: 存在しないsourceIdでdeleteFavoriteBySourceId()を実行
  // Then: 例外なし、Favoriteリスト変化なし
});
```

---

## 5. テストケースサマリー

| カテゴリ | テストケース数 | 信頼性レベル |
|---------|---------------|-------------|
| 正常系 | 5件 | 🔵4件、🟡1件 |
| 異常系 | 3件 | 🔵1件、🟡2件 |
| 境界値 | 3件 | 🔵2件、🟡1件 |
| FavoriteNotifier拡張 | 3件 | 🟡3件 |
| **合計** | **14件** | 🔵7件、🟡7件 |

---

## 6. 品質判定

### ✅ 高品質

| 項目 | 状態 | 備考 |
|------|------|------|
| テストケース分類 | 網羅 | 正常系・異常系・境界値をカバー |
| 期待値定義 | 明確 | 各テストケースで具体的な期待値を定義 |
| 技術選択 | 確定 | flutter_test + mocktail（既存プロジェクトと統一） |
| 実装可能性 | 確実 | 既存のテストパターンを踏襲 |

---

## 7. 次のステップ

次のお勧めステップ: `/tsumiki:tdd-red` でRedフェーズ（失敗テスト作成）を開始します。
