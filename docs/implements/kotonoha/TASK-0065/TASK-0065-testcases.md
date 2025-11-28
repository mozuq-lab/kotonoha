# TASK-0065: お気に入りHiveモデル・リポジトリ実装 - テストケース定義書

## テストケース概要

**タスクID**: TASK-0065
**タスク名**: お気に入りHiveモデル・リポジトリ実装
**作成日**: 2025-11-28
**テスト対象**: FavoriteItem Hiveモデル、FavoriteRepository
**テストフレームワーク**: flutter_test + Hive Testing

### テスト目的

お気に入り機能の永続化層（Hiveモデル・Repository）の正常動作を保証し、以下の要件を満たすことを検証する:
- お気に入りがHiveに正しく保存される（FR-065-001, FR-065-002）
- アプリ再起動後もデータが保持される（NFR-065-001）
- 並び順（displayOrder）が正しく管理される（FR-065-003）
- 履歴・定型文からお気に入り登録が可能（FR-065-005, FR-065-006）
- エッジケース・境界値での安定動作（EDGE-065-001〜010）

### テストカバレッジ目標

- **FavoriteRepository**: 90%以上
- **FavoriteItem モデル**: 80%以上
- **全体**: 80%以上

---

## 信頼性レベル凡例

- **🔵 青信号**: 要件定義書・設計文書・既存実装パターンに基づく確実なテスト
- **🟡 黄信号**: 要件定義書から妥当な推測によるテスト
- **🔴 赤信号**: 完全な推測によるテスト（本タスクでは使用しない）

---

## テストケース一覧

### カテゴリ1: FavoriteItem Hiveモデルのテスト

#### TC-065-001: FavoriteItem基本フィールドの保存・読み込み 🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteItem Hiveモデル
- **関連要件**: FR-065-001
- **テスト内容**:
  - FavoriteItemの全フィールド（id, content, createdAt, displayOrder）が正しく保存される
  - Hive TypeAdapter経由でシリアライズ・デシリアライズできる
- **期待される結果**:
  - 保存したフィールドが完全に復元される
  - データ型が保持される（String, DateTime, int）
- **テスト方法**:
  ```dart
  test('TC-065-001: FavoriteItemの全フィールドが保存される', () async {
    final favorite = FavoriteItem(
      id: 'test-001',
      content: 'こんにちは',
      createdAt: DateTime(2025, 1, 15, 10, 30),
      displayOrder: 5,
    );
    await box.put(favorite.id, favorite);
    final loaded = box.get('test-001');
    expect(loaded, isNotNull);
    expect(loaded!.id, 'test-001');
    expect(loaded.content, 'こんにちは');
    expect(loaded.displayOrder, 5);
  });
  ```

#### TC-065-002: FavoriteItem copyWith()メソッド 🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteItem.copyWith()
- **関連要件**: FR-065-001
- **テスト内容**:
  - copyWith()で一部フィールドのみ変更した新しいインスタンスが作成される
  - 変更していないフィールドは元の値が保持される
- **期待される結果**:
  - 不変オブジェクトパターンが正しく動作する
  - 元のオブジェクトは変更されない
- **テスト方法**:
  ```dart
  test('TC-065-002: copyWithで部分更新できる', () {
    final original = FavoriteItem(
      id: 'test-002',
      content: '元の内容',
      createdAt: DateTime.now(),
      displayOrder: 1,
    );
    final updated = original.copyWith(content: '更新後の内容');
    expect(updated.id, 'test-002'); // 変更なし
    expect(updated.content, '更新後の内容'); // 変更された
    expect(updated.displayOrder, 1); // 変更なし
  });
  ```

#### TC-065-003: FavoriteItem 等価性比較（==演算子）🔵
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteItem.operator==
- **関連要件**: FR-065-001
- **テスト内容**:
  - 同じidを持つFavoriteItemは等価と判定される
  - 異なるidを持つFavoriteItemは非等価と判定される
- **期待される結果**:
  - idベースの等価性比較が正しく動作する
- **テスト方法**:
  ```dart
  test('TC-065-003: 同じidなら等価と判定される', () {
    final fav1 = FavoriteItem(
      id: 'same-id',
      content: '内容A',
      createdAt: DateTime.now(),
      displayOrder: 1,
    );
    final fav2 = FavoriteItem(
      id: 'same-id',
      content: '内容B',
      createdAt: DateTime.now(),
      displayOrder: 2,
    );
    expect(fav1, equals(fav2)); // idが同じなら等価
  });
  ```

#### TC-065-004: FavoriteItem hashCode 🔵
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteItem.hashCode
- **関連要件**: FR-065-001
- **テスト内容**:
  - 同じidを持つFavoriteItemは同じhashCodeを返す
  - Set、Mapで正しく使える
- **期待される結果**:
  - hashCode契約が守られる（== trueならhashCodeも同じ）
- **テスト方法**:
  ```dart
  test('TC-065-004: 同じidなら同じhashCodeを返す', () {
    final fav1 = FavoriteItem(id: 'hash-test', content: 'A', createdAt: DateTime.now(), displayOrder: 1);
    final fav2 = FavoriteItem(id: 'hash-test', content: 'B', createdAt: DateTime.now(), displayOrder: 2);
    expect(fav1.hashCode, equals(fav2.hashCode));
  });
  ```

#### TC-065-005: FavoriteItem toString()メソッド 🔵
- **優先度**: P2（推奨）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteItem.toString()
- **関連要件**: FR-065-001
- **テスト内容**:
  - toString()が全フィールドを含む文字列を返す
  - デバッグ用に使える
- **期待される結果**:
  - id, content, createdAt, displayOrderが文字列に含まれる
- **テスト方法**:
  ```dart
  test('TC-065-005: toStringでデバッグ文字列が返る', () {
    final fav = FavoriteItem(id: 'str-test', content: 'テスト', createdAt: DateTime(2025, 1, 1), displayOrder: 3);
    final str = fav.toString();
    expect(str, contains('str-test'));
    expect(str, contains('テスト'));
    expect(str, contains('3'));
  });
  ```

---

### カテゴリ2: FavoriteRepository 基本CRUD操作のテスト

#### TC-065-006: お気に入りの保存（save）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: FR-065-002, AC-065-001
- **テスト内容**:
  - save()メソッドでお気に入りをHiveに保存できる
  - getById()で保存したお気に入りを取得できる
- **期待される結果**:
  - お気に入りがHive Boxに正しく保存される
  - 全フィールドが保持される
- **テスト方法**:
  ```dart
  test('TC-065-006: お気に入りをHiveに保存できる', () async {
    final favorite = FavoriteItem(
      id: 'save-test',
      content: 'こんにちは',
      createdAt: DateTime(2025, 1, 15, 10, 30),
      displayOrder: 0,
    );
    await repository.save(favorite);
    final loaded = await repository.getById('save-test');
    expect(loaded, isNotNull);
    expect(loaded!.id, 'save-test');
    expect(loaded.content, 'こんにちは');
  });
  ```

#### TC-065-007: 全お気に入りの読み込み（loadAll）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.loadAll()
- **関連要件**: FR-065-002, AC-065-004
- **テスト内容**:
  - loadAll()で全お気に入りを取得できる
  - displayOrder昇順でソートされる
- **期待される結果**:
  - displayOrder: 0, 1, 2, ... の順で返る
- **テスト方法**:
  ```dart
  test('TC-065-007: 全お気に入りをdisplayOrder昇順で取得できる', () async {
    await repository.save(FavoriteItem(id: 'f3', content: '3番目', createdAt: DateTime.now(), displayOrder: 3));
    await repository.save(FavoriteItem(id: 'f1', content: '1番目', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'f2', content: '2番目', createdAt: DateTime.now(), displayOrder: 2));

    final favorites = await repository.loadAll();
    expect(favorites.length, 3);
    expect(favorites[0].displayOrder, 1); // 昇順
    expect(favorites[1].displayOrder, 2);
    expect(favorites[2].displayOrder, 3);
  });
  ```

#### TC-065-008: IDによるお気に入り取得（getById）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.getById()
- **関連要件**: FR-065-002
- **テスト内容**:
  - getById()で特定のお気に入りを取得できる
- **期待される結果**:
  - 指定IDのお気に入りが返る
- **テスト方法**:
  ```dart
  test('TC-065-008: IDでお気に入りを取得できる', () async {
    final favorite = FavoriteItem(id: 'getbyid-test', content: 'ID検索', createdAt: DateTime.now(), displayOrder: 0);
    await repository.save(favorite);
    final loaded = await repository.getById('getbyid-test');
    expect(loaded, isNotNull);
    expect(loaded!.id, 'getbyid-test');
  });
  ```

#### TC-065-009: 存在しないIDの取得（getById - null返却）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.getById()
- **関連要件**: EDGE-065-003, AC-065-012
- **テスト内容**:
  - 存在しないIDでgetById()を呼び出すとnullを返す
- **期待される結果**:
  - nullが返る（例外は投げない）
- **テスト方法**:
  ```dart
  test('TC-065-009: 存在しないIDを取得するとnullを返す', () async {
    final loaded = await repository.getById('non-existent-id');
    expect(loaded, isNull);
  });
  ```

#### TC-065-010: お気に入りの削除（delete）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.delete()
- **関連要件**: FR-065-002, AC-065-002
- **テスト内容**:
  - delete()で特定のお気に入りを削除できる
  - 他のお気に入りは影響を受けない
- **期待される結果**:
  - 指定IDのお気に入りが削除される
  - getById()でnullが返る
- **テスト方法**:
  ```dart
  test('TC-065-010: 特定のお気に入りを削除できる', () async {
    await repository.save(FavoriteItem(id: 'del-1', content: 'A', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'del-2', content: 'B', createdAt: DateTime.now(), displayOrder: 2));

    await repository.delete('del-1');
    expect(await repository.getById('del-1'), isNull);
    expect(await repository.getById('del-2'), isNotNull); // 他は残る
  });
  ```

#### TC-065-011: 存在しないIDの削除（delete - エラーハンドリング）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.delete()
- **関連要件**: EDGE-065-002, AC-065-011
- **テスト内容**:
  - 存在しないIDでdelete()を呼び出しても例外なく終了する
- **期待される結果**:
  - 例外なく正常終了（silent fail）
- **テスト方法**:
  ```dart
  test('TC-065-011: 存在しないIDを削除しても例外が発生しない', () async {
    await expectLater(
      repository.delete('non-existent-id'),
      completes,
    );
  });
  ```

#### TC-065-012: 全お気に入りの削除（deleteAll）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.deleteAll()
- **関連要件**: FR-065-002, AC-065-003
- **テスト内容**:
  - deleteAll()で全お気に入りを一括削除できる
- **期待される結果**:
  - loadAll()が空リストを返す
- **テスト方法**:
  ```dart
  test('TC-065-012: 全お気に入りを削除できる', () async {
    for (int i = 0; i < 5; i++) {
      await repository.save(FavoriteItem(id: 'all-$i', content: 'テスト$i', createdAt: DateTime.now(), displayOrder: i));
    }
    expect((await repository.loadAll()).length, 5);

    await repository.deleteAll();
    expect(await repository.loadAll(), isEmpty);
  });
  ```

#### TC-065-013: 同一IDで複数回保存（上書き更新）🔵
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: EDGE-065-004
- **テスト内容**:
  - 同じIDで保存すると上書き更新される
  - 重複エラーにならない
- **期待される結果**:
  - 最後の保存内容で上書きされる
  - お気に入り数は1件のまま
- **テスト方法**:
  ```dart
  test('TC-065-013: 同じIDで保存すると上書きされる', () async {
    await repository.save(FavoriteItem(id: 'overwrite', content: '元の内容', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'overwrite', content: '更新後の内容', createdAt: DateTime.now(), displayOrder: 2));

    final loaded = await repository.getById('overwrite');
    expect(loaded!.content, '更新後の内容');
    expect(loaded.displayOrder, 2);
    expect((await repository.loadAll()).length, 1); // 1件のみ
  });
  ```

---

### カテゴリ3: displayOrder管理のテスト

#### TC-065-014: 並び順でソート 🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.loadAll()
- **関連要件**: FR-065-003, AC-065-004
- **テスト内容**:
  - loadAll()がdisplayOrder昇順でソートされたリストを返す
- **期待される結果**:
  - displayOrder: 0, 1, 2, 3, ... の順
- **テスト方法**:
  ```dart
  test('TC-065-014: displayOrder昇順でソートされる', () async {
    await repository.save(FavoriteItem(id: 'f5', content: '5', createdAt: DateTime.now(), displayOrder: 5));
    await repository.save(FavoriteItem(id: 'f1', content: '1', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'f3', content: '3', createdAt: DateTime.now(), displayOrder: 3));

    final favorites = await repository.loadAll();
    expect(favorites[0].displayOrder, 1);
    expect(favorites[1].displayOrder, 3);
    expect(favorites[2].displayOrder, 5);
  });
  ```

#### TC-065-015: 並び順の単一更新（updateDisplayOrder）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.updateDisplayOrder()
- **関連要件**: FR-065-003, AC-065-005
- **テスト内容**:
  - updateDisplayOrder()で特定のお気に入りの並び順を更新できる
- **期待される結果**:
  - 指定したdisplayOrderに更新される
- **テスト方法**:
  ```dart
  test('TC-065-015: 並び順を単一更新できる', () async {
    await repository.save(FavoriteItem(id: 'order-test', content: 'テスト', createdAt: DateTime.now(), displayOrder: 5));

    await repository.updateDisplayOrder('order-test', 10);

    final loaded = await repository.getById('order-test');
    expect(loaded!.displayOrder, 10);
  });
  ```

#### TC-065-016: 並び順の一括更新（reorderFavorites）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.reorderFavorites()
- **関連要件**: FR-065-003, AC-065-006
- **テスト内容**:
  - reorderFavorites()で複数のお気に入りの並び順を一括更新できる
- **期待される結果**:
  - 指定した順序通りにdisplayOrderが設定される
- **テスト方法**:
  ```dart
  test('TC-065-016: 並び順を一括更新できる', () async {
    await repository.save(FavoriteItem(id: 'a', content: 'A', createdAt: DateTime.now(), displayOrder: 0));
    await repository.save(FavoriteItem(id: 'b', content: 'B', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'c', content: 'C', createdAt: DateTime.now(), displayOrder: 2));

    // 順序を逆にする: c, a, b
    await repository.reorderFavorites(['c', 'a', 'b']);

    final favorites = await repository.loadAll();
    expect(favorites[0].id, 'c'); // displayOrder: 0
    expect(favorites[1].id, 'a'); // displayOrder: 1
    expect(favorites[2].id, 'b'); // displayOrder: 2
  });
  ```

#### TC-065-017: displayOrderの重複（二次ソート）🟡
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.loadAll()
- **関連要件**: EDGE-065-005
- **テスト内容**:
  - displayOrderが重複している場合、createdAtの降順（新しい順）で二次ソートされる
- **期待される結果**:
  - displayOrderが同じ場合、createdAtの新しい方が先
- **テスト方法**:
  ```dart
  test('TC-065-017: displayOrder重複時はcreatedAtで二次ソート', () async {
    await repository.save(FavoriteItem(id: 'f1', content: '古い', createdAt: DateTime(2025, 1, 1, 10, 0), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'f2', content: '新しい', createdAt: DateTime(2025, 1, 1, 12, 0), displayOrder: 1));

    final favorites = await repository.loadAll();
    expect(favorites[0].id, 'f2'); // 新しい方が先
    expect(favorites[1].id, 'f1');
  });
  ```

#### TC-065-018: 新規追加時のdisplayOrder自動採番 🔵
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: FR-065-003
- **テスト内容**:
  - displayOrderを指定せずに保存した場合、自動で最大値+1が設定される
- **期待される結果**:
  - 既存の最大displayOrder + 1が設定される
- **テスト方法**:
  ```dart
  test('TC-065-018: 新規追加時は最大displayOrder+1が設定される', () async {
    await repository.save(FavoriteItem(id: 'f1', content: 'A', createdAt: DateTime.now(), displayOrder: 0));
    await repository.save(FavoriteItem(id: 'f2', content: 'B', createdAt: DateTime.now(), displayOrder: 5));

    // displayOrderを指定せずに追加（デフォルト値0）
    final newFav = await repository.saveWithAutoOrder(FavoriteItem(id: 'f3', content: 'C', createdAt: DateTime.now(), displayOrder: 0));

    expect(newFav.displayOrder, 6); // 最大値5 + 1
  });
  ```

---

### カテゴリ4: 履歴・定型文からの登録テスト

#### TC-065-019: 履歴からお気に入り登録（saveFromHistory）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.saveFromHistory()
- **関連要件**: FR-065-005, AC-065-007
- **テスト内容**:
  - saveFromHistory()で履歴からお気に入りを作成できる
  - 新しいUUIDが生成される（履歴のIDとは別）
- **期待される結果**:
  - お気に入りのcontent == 履歴のcontent
  - お気に入りのid ≠ 履歴のid
  - displayOrderは自動採番される
- **テスト方法**:
  ```dart
  test('TC-065-019: 履歴からお気に入り登録できる', () async {
    final history = HistoryItem(
      id: 'history-001',
      content: '履歴テスト',
      createdAt: DateTime.now(),
      type: 'manualInput',
    );

    final favorite = await repository.saveFromHistory(history);

    expect(favorite.content, '履歴テスト');
    expect(favorite.id, isNot('history-001')); // 新しいID
    expect(favorite.displayOrder, greaterThanOrEqualTo(0));
  });
  ```

#### TC-065-020: 定型文からお気に入り登録（saveFromPreset）🔵
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.saveFromPreset()
- **関連要件**: FR-065-006, AC-065-008
- **テスト内容**:
  - saveFromPreset()で定型文からお気に入りを作成できる
  - 新しいUUIDが生成される（定型文のIDとは別）
- **期待される結果**:
  - お気に入りのcontent == 定型文のcontent
  - お気に入りのid ≠ 定型文のid
  - displayOrderは自動採番される
- **テスト方法**:
  ```dart
  test('TC-065-020: 定型文からお気に入り登録できる', () async {
    final preset = PresetPhrase(
      id: 'preset-001',
      content: '定型文テスト',
      category: 'daily',
      displayOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final favorite = await repository.saveFromPreset(preset);

    expect(favorite.content, '定型文テスト');
    expect(favorite.id, isNot('preset-001')); // 新しいID
    expect(favorite.displayOrder, greaterThanOrEqualTo(0));
  });
  ```

#### TC-065-021: 履歴削除後もお気に入りは保持 🔵
- **優先度**: P1（重要）
- **テストの種類**: Integration Test
- **テスト対象**: FavoriteRepository, HistoryRepository
- **関連要件**: EDGE-065-009
- **テスト内容**:
  - 履歴からお気に入り登録後、元の履歴を削除してもお気に入りは残る
- **期待される結果**:
  - お気に入りは削除されず保持される
- **テスト方法**:
  ```dart
  test('TC-065-021: 履歴削除後もお気に入りは保持される', () async {
    final history = HistoryItem(id: 'h1', content: '履歴', createdAt: DateTime.now(), type: 'manualInput');
    await historyRepository.save(history);

    final favorite = await favoriteRepository.saveFromHistory(history);
    await historyRepository.delete('h1'); // 履歴を削除

    final loadedFav = await favoriteRepository.getById(favorite.id);
    expect(loadedFav, isNotNull); // お気に入りは残る
  });
  ```

---

### カテゴリ5: エッジケース・境界値テスト

#### TC-065-022: お気に入り0件の状態 🟡
- **優先度**: P0（必須）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.loadAll()
- **関連要件**: EDGE-065-001, AC-065-010
- **テスト内容**:
  - お気に入りが1件も登録されていない状態でloadAll()を実行
- **期待される結果**:
  - 空のリスト[]を返す（nullではない）
- **テスト方法**:
  ```dart
  test('TC-065-022: お気に入り0件の場合に空リストを返す', () async {
    final favorites = await repository.loadAll();
    expect(favorites, isEmpty);
  });
  ```

#### TC-065-023: 極端に長いcontent（1000文字超）🟡
- **優先度**: P2（推奨）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: EDGE-065-006
- **テスト内容**:
  - 1000文字を超えるテキストをお気に入り登録
- **期待される結果**:
  - そのまま保存される（上限制限なし）
- **テスト方法**:
  ```dart
  test('TC-065-023: 1000文字のcontentも正しく保存できる', () async {
    final longContent = 'あ' * 1000;
    await repository.save(FavoriteItem(id: 'long', content: longContent, createdAt: DateTime.now(), displayOrder: 0));

    final loaded = await repository.getById('long');
    expect(loaded!.content.length, 1000);
  });
  ```

#### TC-065-024: 特殊文字を含むcontent 🟡
- **優先度**: P2（推奨）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: EDGE-065-006
- **テスト内容**:
  - 絵文字、改行、タブなどの特殊文字が保存できる
- **期待される結果**:
  - 特殊文字が失われない
- **テスト方法**:
  ```dart
  test('TC-065-024: 特殊文字を含むcontentも正しく保存できる', () async {
    final specialContent = 'こんにちは😊\n改行テスト\t"タブと引用符"';
    await repository.save(FavoriteItem(id: 'special', content: specialContent, createdAt: DateTime.now(), displayOrder: 0));

    final loaded = await repository.getById('special');
    expect(loaded!.content, specialContent);
  });
  ```

#### TC-065-025: 空文字列のcontent 🟡
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: EDGE-065-007
- **テスト内容**:
  - contentが空文字列（""）のお気に入りを保存
- **期待される結果**:
  - 保存自体は成功する（Repository層ではバリデーションしない）
- **テスト方法**:
  ```dart
  test('TC-065-025: 空文字列のcontentも保存できる', () async {
    await repository.save(FavoriteItem(id: 'empty', content: '', createdAt: DateTime.now(), displayOrder: 0));

    final loaded = await repository.getById('empty');
    expect(loaded, isNotNull);
    expect(loaded!.content, '');
  });
  ```

#### TC-065-026: displayOrderの負の値 🟡
- **優先度**: P2（推奨）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.save(), loadAll()
- **関連要件**: EDGE-065-008
- **テスト内容**:
  - displayOrderに負の値（-1など）を設定
- **期待される結果**:
  - 保存自体は成功する
  - ソート時は負の値も含めて昇順ソート（-1, 0, 1, 2, ...）
- **テスト方法**:
  ```dart
  test('TC-065-026: displayOrderの負の値も保存できる', () async {
    await repository.save(FavoriteItem(id: 'f1', content: 'A', createdAt: DateTime.now(), displayOrder: -1));
    await repository.save(FavoriteItem(id: 'f2', content: 'B', createdAt: DateTime.now(), displayOrder: 0));
    await repository.save(FavoriteItem(id: 'f3', content: 'C', createdAt: DateTime.now(), displayOrder: 1));

    final favorites = await repository.loadAll();
    expect(favorites[0].displayOrder, -1);
    expect(favorites[1].displayOrder, 0);
    expect(favorites[2].displayOrder, 1);
  });
  ```

#### TC-065-027: 重複登録チェック（isDuplicate）🟡
- **優先度**: P1（重要）
- **テストの種類**: Unit Test
- **テスト対象**: FavoriteRepository.isDuplicate()
- **関連要件**: FR-065-004, AC-065-013
- **テスト内容**:
  - 同じcontentのお気に入りが既に存在するかチェックできる
- **期待される結果**:
  - 既存の場合: true
  - 存在しない場合: false
- **テスト方法**:
  ```dart
  test('TC-065-027: 重複登録をチェックできる', () async {
    await repository.save(FavoriteItem(id: 'f1', content: 'こんにちは', createdAt: DateTime.now(), displayOrder: 0));

    expect(await repository.isDuplicate('こんにちは'), true);
    expect(await repository.isDuplicate('さようなら'), false);
  });
  ```

---

### カテゴリ6: データ永続化・パフォーマンステスト

#### TC-065-028: アプリ再起動後のデータ保持 🔵
- **優先度**: P0（必須）
- **テストの種類**: Integration Test
- **テスト対象**: FavoriteRepository, Hive
- **関連要件**: NFR-065-001, AC-065-009
- **テスト内容**:
  - お気に入りを保存後、Boxを閉じて再度開いてもデータが保持される
- **期待される結果**:
  - 再起動後も同じお気に入りが取得できる
- **テスト方法**:
  ```dart
  test('TC-065-028: アプリ再起動後も履歴が保持される', () async {
    // 1回目: 保存
    await repository.save(FavoriteItem(id: 'persist', content: '永続化テスト', createdAt: DateTime.now(), displayOrder: 0));
    await box.close();

    // 2回目: 再度開く
    box = await Hive.openBox<FavoriteItem>('favorites');
    repository = FavoriteRepository(box: box);

    final loaded = await repository.getById('persist');
    expect(loaded, isNotNull);
    expect(loaded!.content, '永続化テスト');
  });
  ```

#### TC-065-029: お気に入り100件の読み込みパフォーマンス 🟡
- **優先度**: P1（重要）
- **テストの種類**: Performance Test
- **テスト対象**: FavoriteRepository.loadAll()
- **関連要件**: NFR-065-002
- **テスト内容**:
  - 100件のお気に入りを500ms以内に読み込めることを検証
- **期待される結果**:
  - 500ms未満で読み込み完了
- **テスト方法**:
  ```dart
  test('TC-065-029: 100件のお気に入りを500ms以内に読み込める', () async {
    for (int i = 0; i < 100; i++) {
      await repository.save(FavoriteItem(
        id: 'perf-$i',
        content: 'パフォーマンステスト$i' * 5,
        createdAt: DateTime.now(),
        displayOrder: i,
      ));
    }

    final stopwatch = Stopwatch()..start();
    final favorites = await repository.loadAll();
    stopwatch.stop();

    expect(favorites.length, 100);
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
  ```

#### TC-065-030: ストレージ容量不足のシミュレーション 🟡
- **優先度**: P2（推奨）
- **テストの種類**: Error Handling Test
- **テスト対象**: FavoriteRepository.save()
- **関連要件**: EDGE-065-010
- **テスト内容**:
  - ストレージ容量不足時にHiveErrorが発生することを確認
- **期待される結果**:
  - 例外が上位層に伝播する（Repository層ではキャッチしない）
- **テスト方法**:
  ```dart
  test('TC-065-030: ストレージ容量不足時に例外が発生する', () async {
    // 注: 実際のストレージ不足はシミュレート困難なため、
    // Hiveのmockを使用して例外をスローさせる
    // この実装は実装フェーズで詳細化する
  });
  ```

---

### カテゴリ7: 複数操作の組み合わせテスト

#### TC-065-031: 保存・削除・再保存の組み合わせ 🔵
- **優先度**: P1（重要）
- **テストの種類**: Integration Test
- **テスト対象**: FavoriteRepository
- **関連要件**: FR-065-002
- **テスト内容**:
  - 保存・削除・再保存を組み合わせた操作が正しく動作する
- **期待される結果**:
  - すべての操作が正しく実行される
- **テスト方法**:
  ```dart
  test('TC-065-031: 保存・削除・再保存の組み合わせ', () async {
    await repository.save(FavoriteItem(id: 'c1', content: '1', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'c2', content: '2', createdAt: DateTime.now(), displayOrder: 2));
    await repository.save(FavoriteItem(id: 'c3', content: '3', createdAt: DateTime.now(), displayOrder: 3));

    await repository.delete('c2');
    await repository.save(FavoriteItem(id: 'c4', content: '4', createdAt: DateTime.now(), displayOrder: 4));

    final favorites = await repository.loadAll();
    expect(favorites.length, 3); // c1, c3, c4
    expect(await repository.getById('c2'), isNull);
  });
  ```

#### TC-065-032: 並び替え中の削除操作 🔵
- **優先度**: P1（重要）
- **テストの種類**: Integration Test
- **テスト対象**: FavoriteRepository
- **関連要件**: FR-065-003, NFR-065-003
- **テスト内容**:
  - 並び替え操作中に削除しても整合性が保たれる
- **期待される結果**:
  - データ不整合が発生しない
- **テスト方法**:
  ```dart
  test('TC-065-032: 並び替え中の削除操作で整合性を保つ', () async {
    await repository.save(FavoriteItem(id: 'f1', content: 'A', createdAt: DateTime.now(), displayOrder: 1));
    await repository.save(FavoriteItem(id: 'f2', content: 'B', createdAt: DateTime.now(), displayOrder: 2));
    await repository.save(FavoriteItem(id: 'f3', content: 'C', createdAt: DateTime.now(), displayOrder: 3));

    await repository.reorderFavorites(['f3', 'f2', 'f1']);
    await repository.delete('f2');

    final favorites = await repository.loadAll();
    expect(favorites.length, 2);
    expect(favorites[0].id, 'f3');
    expect(favorites[1].id, 'f1');
  });
  ```

---

## テスト実行順序

### Phase 1: 基本機能（必須・P0）
1. TC-065-001〜005: FavoriteItemモデル
2. TC-065-006〜013: 基本CRUD操作
3. TC-065-014〜016: displayOrder管理
4. TC-065-019〜020: 履歴・定型文からの登録
5. TC-065-022: 0件状態のテスト
6. TC-065-028: データ永続化

### Phase 2: エッジケース・境界値（P1）
7. TC-065-017〜018: displayOrder追加機能
8. TC-065-021: 履歴削除後の保持
9. TC-065-025: 空文字列
10. TC-065-027: 重複チェック
11. TC-065-029: パフォーマンステスト
12. TC-065-031〜032: 複数操作の組み合わせ

### Phase 3: 推奨テスト（P2）
13. TC-065-023〜024: 長文・特殊文字
14. TC-065-026: 負の値
15. TC-065-030: ストレージ容量不足

---

## テストカバレッジ計測方法

```bash
# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### カバレッジ目標の達成確認
- **FavoriteRepository**: 90%以上（すべてのCRUDメソッド + displayOrder管理）
- **FavoriteItem モデル**: 80%以上（コンストラクタ、copyWith、==、hashCode、toString）
- **全体**: 80%以上

---

## テスト環境セットアップ

### setUp() 処理
```dart
setUp(() async {
  await Hive.close();
  tempDir = await Directory.systemTemp.createTemp('hive_favorite_test_');
  Hive.init(tempDir.path);

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(FavoriteItemAdapter());
  }

  favoriteBox = await Hive.openBox<FavoriteItem>('test_favorites');
  repository = FavoriteRepository(box: favoriteBox);
});
```

### tearDown() 処理
```dart
tearDown(() async {
  await favoriteBox.close();
  await Hive.deleteBoxFromDisk('test_favorites');
  await Hive.close();

  if (tempDir.existsSync()) {
    await tempDir.delete(recursive: true);
  }
});
```

---

## 完了条件（Definition of Done）

### テスト成功基準
- [ ] すべてのP0テスト（必須）が成功する
- [ ] P1テスト（重要）の90%以上が成功する
- [ ] カバレッジ目標を達成する（FavoriteRepository: 90%以上、全体: 80%以上）
- [ ] エッジケーステストがすべて成功する
- [ ] パフォーマンステスト（TC-065-029）が基準を満たす

### 品質基準
- [ ] テストコードがflutter_lintsに準拠している
- [ ] 各テストケースに適切なコメントがある
- [ ] テストが独立して実行できる（順序依存なし）
- [ ] tearDown()でリソースがクリーンアップされる

---

## 参考資料

- **要件定義書**: `docs/implements/kotonoha/TASK-0065/TASK-0065-requirements.md`
- **既存テスト**: `test/features/history/data/history_repository_test.dart`
- **既存モデル**: `lib/shared/models/history_item.dart`, `lib/shared/models/preset_phrase.dart`
- **Hive公式ドキュメント**: https://docs.hivedb.dev/
- **Flutter Test公式ドキュメント**: https://docs.flutter.dev/cookbook/testing/unit/introduction

---

## 次のステップ

1. `/tsumiki:tdd-red` - 失敗するテスト作成（本テストケース定義書に基づく）
2. `/tsumiki:tdd-green` - テストを通す実装
3. `/tsumiki:tdd-refactor` - リファクタリング
4. `/tsumiki:tdd-verify-complete` - 完了検証

---

## テストケース統計

- **総テストケース数**: 32件
- **P0（必須）**: 18件
- **P1（重要）**: 10件
- **P2（推奨）**: 4件
- **🔵 青信号**: 24件（75.0%）
- **🟡 黄信号**: 8件（25.0%）
- **🔴 赤信号**: 0件（0.0%）

### カテゴリ別統計
1. FavoriteItemモデル: 5件（TC-065-001〜005）
2. 基本CRUD操作: 8件（TC-065-006〜013）
3. displayOrder管理: 5件（TC-065-014〜018）
4. 履歴・定型文からの登録: 3件（TC-065-019〜021）
5. エッジケース・境界値: 6件（TC-065-022〜027）
6. データ永続化・パフォーマンス: 3件（TC-065-028〜030）
7. 複数操作の組み合わせ: 2件（TC-065-031〜032）

---

**作成者**: Claude Code (Tsumiki TDD フロー)
**最終更新日**: 2025-11-28
**ドキュメントバージョン**: 1.0
