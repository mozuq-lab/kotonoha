# TASK-0062: 履歴Hiveモデル・リポジトリ実装 - テストケース定義書

## 文書情報

- **タスクID**: TASK-0062
- **タスク名**: 履歴Hiveモデル・リポジトリ実装
- **フェーズ**: Phase 4 - フロントエンド応用機能実装
- **作成日**: 2025-11-28
- **関連ドキュメント**:
  - 要件定義書: `docs/implements/kotonoha/TASK-0062/kotonoha-requirements.md`
  - 関連要件: REQ-601, REQ-602, REQ-605, NFR-101
- **テストフレームワーク**: flutter_test + Hive Testing

## テストケース概要

本テストケース定義書は、HistoryRepositoryクラスの実装に対するTDD（テスト駆動開発）のためのテストケースを網羅的に定義します。

### テスト対象

- **クラス**: `HistoryRepository`
- **ファイルパス**: `frontend/kotonoha_app/lib/features/history/data/history_repository.dart`
- **テストファイルパス**: `frontend/kotonoha_app/test/features/history/data/history_repository_test.dart`

### テストカバレッジ目標

- **目標カバレッジ**: 90%以上（NFR-062-004）
- **優先度**: 全テストケースP0（必須）およびP1（重要）を合格すること
- **テスト種類**: 正常系、異常系、境界値テスト、パフォーマンステスト

### 信頼性レベル凡例

- 🔵 **青信号**: 要件定義書・仕様書に基づく確実なテストケース
- 🟡 **黄信号**: 要件定義書から妥当な推測によるテストケース
- 🔴 **赤信号**: 要件定義書にない推測によるテストケース

---

## 1. 基本的なCRUD操作テスト（正常系）

### TC-062-001: 履歴の保存機能（save）🔵

**優先度**: P0（必須）
**関連要件**: REQ-601, REQ-605, NFR-101, FR-062-001
**関連AC**: AC-062-001

**テスト目的**:
履歴をHiveボックスに正常に保存できることを確認する。

**前提条件**:
- Hive初期化済み
- HistoryItemAdapter登録済み
- 空のhistoryボックスがオープン済み

**テストデータ**:
```dart
final testHistory = HistoryItem(
  id: 'test-001',
  content: 'こんにちは',
  createdAt: DateTime(2025, 1, 15, 10, 30),
  type: 'manualInput',
  isFavorite: false,
);
```

**テスト手順**:
1. HistoryRepositoryインスタンスを生成（モックBoxを注入）
2. `await repository.save(testHistory)` を実行
3. `await repository.getById('test-001')` で保存した履歴を取得

**期待結果**:
- `getById('test-001')` がnullでない
- 取得した履歴の `id` が `'test-001'`
- 取得した履歴の `content` が `'こんにちは'`
- 取得した履歴の `type` が `'manualInput'`
- 取得した履歴の `isFavorite` が `false`

**実装例**:
```dart
test('TC-062-001: 履歴をHiveに保存できる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);
  final history = HistoryItem(
    id: 'test-001',
    content: 'こんにちは',
    createdAt: DateTime(2025, 1, 15, 10, 30),
    type: 'manualInput',
    isFavorite: false,
  );

  // When
  await repository.save(history);

  // Then
  final loaded = await repository.getById('test-001');
  expect(loaded, isNotNull);
  expect(loaded!.id, 'test-001');
  expect(loaded.content, 'こんにちは');
  expect(loaded.type, 'manualInput');
  expect(loaded.isFavorite, false);

  await box.close();
});
```

---

### TC-062-002: 履歴の全件読み込み（loadAll）🔵

**優先度**: P0（必須）
**関連要件**: REQ-601, NFR-004, FR-062-002
**関連AC**: AC-062-002

**テスト目的**:
全ての履歴を最新順（createdAtの降順）で読み込めることを確認する。

**前提条件**:
- Hive初期化済み
- 3件の履歴が異なる時刻で保存済み

**テストデータ**:
```dart
// 保存順: 古い → 中間 → 最新
final histories = [
  HistoryItem(id: 'h1', content: '古い', createdAt: DateTime(2025, 1, 1, 10, 0), type: 'manualInput'),
  HistoryItem(id: 'h2', content: '中間', createdAt: DateTime(2025, 1, 1, 11, 0), type: 'preset'),
  HistoryItem(id: 'h3', content: '最新', createdAt: DateTime(2025, 1, 1, 12, 0), type: 'aiConverted'),
];
```

**テスト手順**:
1. 3件の履歴を異なる時刻で保存
2. `await repository.loadAll()` を実行

**期待結果**:
- 返されたリストの長さが3
- リスト[0]の `content` が `'最新'`（最新が先頭）
- リスト[1]の `content` が `'中間'`
- リスト[2]の `content` が `'古い'`
- createdAtが降順にソートされている

**実装例**:
```dart
test('TC-062-002: 全ての履歴を最新順で読み込める', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  await repository.save(HistoryItem(
    id: 'h1', content: '古い',
    createdAt: DateTime(2025, 1, 1, 10, 0), type: 'manualInput',
  ));
  await repository.save(HistoryItem(
    id: 'h2', content: '中間',
    createdAt: DateTime(2025, 1, 1, 11, 0), type: 'preset',
  ));
  await repository.save(HistoryItem(
    id: 'h3', content: '最新',
    createdAt: DateTime(2025, 1, 1, 12, 0), type: 'aiConverted',
  ));

  // When
  final histories = await repository.loadAll();

  // Then
  expect(histories.length, 3);
  expect(histories[0].content, '最新'); // 最新が先頭
  expect(histories[1].content, '中間');
  expect(histories[2].content, '古い');

  await box.close();
});
```

---

### TC-062-003: 履歴のIDによる取得（getById）🔵

**優先度**: P0（必須）
**関連要件**: REQ-603, FR-062-007
**関連AC**: AC-062-001

**テスト目的**:
特定のIDで履歴を取得できることを確認する。

**前提条件**:
- 履歴が1件以上保存済み

**テストデータ**:
```dart
final testHistory = HistoryItem(
  id: 'getbyid-test',
  content: 'ID検索テスト',
  createdAt: DateTime.now(),
  type: 'preset',
);
```

**テスト手順**:
1. 履歴を1件保存
2. `await repository.getById('getbyid-test')` を実行

**期待結果**:
- 返り値がnullでない
- `id` が `'getbyid-test'`
- `content` が `'ID検索テスト'`
- `type` が `'preset'`

**実装例**:
```dart
test('TC-062-003: IDで履歴を取得できる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);
  final history = HistoryItem(
    id: 'getbyid-test',
    content: 'ID検索テスト',
    createdAt: DateTime.now(),
    type: 'preset',
  );
  await repository.save(history);

  // When
  final loaded = await repository.getById('getbyid-test');

  // Then
  expect(loaded, isNotNull);
  expect(loaded!.id, 'getbyid-test');
  expect(loaded.content, 'ID検索テスト');
  expect(loaded.type, 'preset');

  await box.close();
});
```

---

### TC-062-004: 存在しないIDの取得（getById - null返却）🔵

**優先度**: P0（必須）
**関連要件**: FR-062-007
**関連AC**: AC-062-007

**テスト目的**:
存在しないIDで履歴を取得した場合にnullを返すことを確認する。

**前提条件**:
- 空のhistoryボックス、または特定のIDが存在しない状態

**テストデータ**:
- `'non-existent-id'`（存在しないID）

**テスト手順**:
1. `await repository.getById('non-existent-id')` を実行

**期待結果**:
- 返り値が `null`
- 例外が発生しない

**実装例**:
```dart
test('TC-062-004: 存在しないIDを取得するとnullを返す', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // When
  final loaded = await repository.getById('non-existent-id');

  // Then
  expect(loaded, isNull);

  await box.close();
});
```

---

### TC-062-005: 履歴の個別削除（delete）🔵

**優先度**: P0（必須）
**関連要件**: REQ-604, FR-062-004
**関連AC**: AC-062-004

**テスト目的**:
特定の履歴を削除できることを確認する。

**前提条件**:
- 履歴が1件保存済み

**テストデータ**:
```dart
final testHistory = HistoryItem(
  id: 'delete-test',
  content: '削除テスト',
  createdAt: DateTime.now(),
  type: 'manualInput',
);
```

**テスト手順**:
1. 履歴を1件保存
2. `await repository.getById('delete-test')` で存在確認
3. `await repository.delete('delete-test')` を実行
4. `await repository.getById('delete-test')` で削除確認

**期待結果**:
- 削除前は `getById` がnullでない
- 削除後は `getById` が `null`
- 例外が発生しない

**実装例**:
```dart
test('TC-062-005: 特定の履歴を削除できる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);
  final history = HistoryItem(
    id: 'delete-test',
    content: '削除テスト',
    createdAt: DateTime.now(),
    type: 'manualInput',
  );
  await repository.save(history);

  // When
  expect(await repository.getById('delete-test'), isNotNull);
  await repository.delete('delete-test');

  // Then
  expect(await repository.getById('delete-test'), isNull);

  await box.close();
});
```

---

### TC-062-006: 存在しないIDの削除（delete - エラーハンドリング）🔵

**優先度**: P0（必須）
**関連要件**: FR-062-004, EDGE-006
**関連AC**: AC-062-007

**テスト目的**:
存在しないIDを削除しても例外が発生しないことを確認する。

**前提条件**:
- 空のhistoryボックス、または特定のIDが存在しない状態

**テストデータ**:
- `'non-existent-id'`（存在しないID）

**テスト手順**:
1. `await repository.delete('non-existent-id')` を実行

**期待結果**:
- 例外が発生せず、正常に完了する
- `expectLater(..., completes)` でテスト

**実装例**:
```dart
test('TC-062-006: 存在しないIDを削除しても例外が発生しない', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // When & Then
  await expectLater(
    repository.delete('non-existent-id'),
    completes,
  );

  await box.close();
});
```

---

### TC-062-007: 全履歴の削除（deleteAll）🔵

**優先度**: P0（必須）
**関連要件**: REQ-604, FR-062-005
**関連AC**: AC-062-005

**テスト目的**:
全ての履歴を一括削除できることを確認する。

**前提条件**:
- 複数件（5件）の履歴が保存済み

**テストデータ**:
```dart
// 5件の履歴
for (int i = 0; i < 5; i++) {
  HistoryItem(id: 'h$i', content: 'テスト$i', createdAt: DateTime.now(), type: 'manualInput');
}
```

**テスト手順**:
1. 5件の履歴を保存
2. `await repository.loadAll()` で5件であることを確認
3. `await repository.deleteAll()` を実行
4. `await repository.loadAll()` で空リストであることを確認

**期待結果**:
- 削除前は `loadAll()` が5件のリストを返す
- 削除後は `loadAll()` が空リスト `[]` を返す

**実装例**:
```dart
test('TC-062-007: 全ての履歴を削除できる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  for (int i = 0; i < 5; i++) {
    await repository.save(HistoryItem(
      id: 'h$i',
      content: 'テスト$i',
      createdAt: DateTime.now(),
      type: 'manualInput',
    ));
  }

  // When
  expect(await repository.loadAll(), hasLength(5));
  await repository.deleteAll();

  // Then
  expect(await repository.loadAll(), isEmpty);

  await box.close();
});
```

---

## 2. 50件上限管理テスト（境界値テスト）

### TC-062-008: 50件上限の自動削除（最古履歴削除）🔵

**優先度**: P0（必須）
**関連要件**: REQ-602, REQ-3002, FR-062-003
**関連AC**: AC-062-003

**テスト目的**:
履歴が50件を超えると最も古い履歴が自動削除されることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
// 50件の履歴 + 51件目
for (int i = 0; i < 51; i++) {
  HistoryItem(
    id: 'h$i',
    content: 'テスト$i',
    createdAt: DateTime(2025, 1, 1).add(Duration(minutes: i)),
    type: 'manualInput',
  );
}
```

**テスト手順**:
1. 50件の履歴を保存
2. `await repository.loadAll()` で50件であることを確認
3. 51件目の履歴を保存
4. `await repository.loadAll()` で50件であることを確認
5. `await repository.getById('h0')` で最古の'h0'が削除されていることを確認
6. `await repository.getById('h50')` で最新の'h50'が存在することを確認

**期待結果**:
- 50件保存後は `loadAll()` が50件のリストを返す
- 51件目保存後も `loadAll()` が50件のリストを返す（50件に維持）
- 最古の履歴'h0'が削除されている（`getById('h0')` が `null`）
- 最新の履歴'h50'が存在する（`getById('h50')` が `not null`）

**実装例**:
```dart
test('TC-062-008: 50件を超えると最も古い履歴が自動削除される', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // 50件の履歴を保存
  for (int i = 0; i < 50; i++) {
    await repository.save(HistoryItem(
      id: 'h$i',
      content: 'テスト$i',
      createdAt: DateTime(2025, 1, 1).add(Duration(minutes: i)),
      type: 'manualInput',
    ));
  }

  // When
  expect((await repository.loadAll()).length, 50);

  // 51件目を追加
  await repository.save(HistoryItem(
    id: 'h50',
    content: 'テスト50',
    createdAt: DateTime(2025, 1, 1).add(Duration(minutes: 50)),
    type: 'manualInput',
  ));

  // Then
  final histories = await repository.loadAll();
  expect(histories.length, 50); // 50件に維持される
  expect(await repository.getById('h0'), isNull); // 最古の'h0'が削除
  expect(await repository.getById('h50'), isNotNull); // 最新の'h50'は存在

  await box.close();
});
```

---

### TC-062-009: ちょうど50件の場合は削除されない 🔵

**優先度**: P1（重要）
**関連要件**: REQ-602, FR-062-003
**関連AC**: EDGE-062-002

**テスト目的**:
履歴がちょうど50件の場合は最古履歴が削除されないことを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
// ちょうど50件の履歴
for (int i = 0; i < 50; i++) {
  HistoryItem(
    id: 'edge-$i',
    content: 'エッジケース$i',
    createdAt: DateTime.now().add(Duration(seconds: i)),
    type: 'manualInput',
  );
}
```

**テスト手順**:
1. 50件の履歴を保存
2. `await repository.loadAll()` で50件であることを確認
3. `await repository.getById('edge-0')` で最古の履歴が残っていることを確認

**期待結果**:
- `loadAll()` が50件のリストを返す
- 最古の履歴'edge-0'が存在する（削除されていない）

**実装例**:
```dart
test('TC-062-009: ちょうど50件の場合は削除されない', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // 50件保存
  for (int i = 0; i < 50; i++) {
    await repository.save(HistoryItem(
      id: 'edge-$i',
      content: 'エッジケース$i',
      createdAt: DateTime.now().add(Duration(seconds: i)),
      type: 'manualInput',
    ));
  }

  // When & Then
  expect((await repository.loadAll()).length, 50);
  expect(await repository.getById('edge-0'), isNotNull); // 最古も残る

  await box.close();
});
```

---

## 3. 履歴種類管理テスト

### TC-062-010: 履歴種類の保存・取得 🔵

**優先度**: P0（必須）
**関連要件**: FR-062-006, dataflow.mdの履歴管理フロー
**関連AC**: AC-062-006

**テスト目的**:
4種類の履歴タイプ（manualInput, preset, aiConverted, quickButton）が正しく保存・取得できることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
final types = ['manualInput', 'preset', 'aiConverted', 'quickButton'];
```

**テスト手順**:
1. 4種類の履歴タイプをそれぞれ保存
2. 各履歴を `getById` で取得
3. 各履歴の `type` が正しいことを確認

**期待結果**:
- 各typeが正しく保存される
- `getById` で取得した履歴の `type` が元のtypeと一致

**実装例**:
```dart
test('TC-062-010: 履歴種類が正しく保存される', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);
  final types = ['manualInput', 'preset', 'aiConverted', 'quickButton'];

  // When
  for (int i = 0; i < types.length; i++) {
    await repository.save(HistoryItem(
      id: 'type-$i',
      content: 'テスト${types[i]}',
      createdAt: DateTime.now().add(Duration(seconds: i)),
      type: types[i],
    ));
  }

  // Then
  for (int i = 0; i < types.length; i++) {
    final history = await repository.getById('type-$i');
    expect(history, isNotNull);
    expect(history!.type, types[i]);
  }

  await box.close();
});
```

---

## 4. エッジケーステスト

### TC-062-011: 空の履歴リスト 🔵

**優先度**: P1（重要）
**関連要件**: FR-062-002
**関連AC**: EDGE-062-001

**テスト目的**:
履歴が0件の場合に空リストを返すことを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
- なし

**テスト手順**:
1. `await repository.loadAll()` を実行

**期待結果**:
- 返り値が空リスト `[]`
- 例外が発生しない

**実装例**:
```dart
test('TC-062-011: 履歴が0件の場合に空リストを返す', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // When
  final histories = await repository.loadAll();

  // Then
  expect(histories, isEmpty);

  await box.close();
});
```

---

### TC-062-012: 同一IDの上書き保存 🔵

**優先度**: P1（重要）
**関連要件**: FR-062-001
**関連AC**: EDGE-062-003

**テスト目的**:
同じIDで保存すると上書きされることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
final original = HistoryItem(
  id: 'overwrite-test',
  content: '元の内容',
  createdAt: DateTime.now(),
  type: 'manualInput',
);

final updated = HistoryItem(
  id: 'overwrite-test',
  content: '更新後の内容',
  createdAt: DateTime.now(),
  type: 'preset',
);
```

**テスト手順**:
1. 最初の履歴を保存
2. 同じIDで異なる内容の履歴を保存
3. `await repository.getById('overwrite-test')` で取得
4. `await repository.loadAll()` で件数確認

**期待結果**:
- 取得した履歴の `content` が `'更新後の内容'`
- 取得した履歴の `type` が `'preset'`
- `loadAll()` が1件のみのリストを返す（重複していない）

**実装例**:
```dart
test('TC-062-012: 同じIDで保存すると上書きされる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  await repository.save(HistoryItem(
    id: 'overwrite-test',
    content: '元の内容',
    createdAt: DateTime.now(),
    type: 'manualInput',
  ));

  // When
  await repository.save(HistoryItem(
    id: 'overwrite-test',
    content: '更新後の内容',
    createdAt: DateTime.now(),
    type: 'preset',
  ));

  // Then
  final history = await repository.getById('overwrite-test');
  expect(history!.content, '更新後の内容');
  expect(history.type, 'preset');
  expect((await repository.loadAll()).length, 1); // 1件のみ

  await box.close();
});
```

---

### TC-062-013: 極端に長いcontent（1000文字）🟡

**優先度**: P2（低）
**関連要件**: NFR-062-001（データ永続化）
**関連AC**: EDGE-062-004

**テスト目的**:
1000文字の長文contentも正しく保存できることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
final longContent = 'あ' * 1000; // 1000文字の文字列
```

**テスト手順**:
1. 1000文字のcontentを持つ履歴を保存
2. `await repository.getById('long-test')` で取得
3. contentの長さを確認

**期待結果**:
- 取得した履歴のcontentの長さが1000
- 内容が正しく保存・取得される

**実装例**:
```dart
test('TC-062-013: 1000文字のcontentも正しく保存できる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);
  final longContent = 'あ' * 1000;

  // When
  await repository.save(HistoryItem(
    id: 'long-test',
    content: longContent,
    createdAt: DateTime.now(),
    type: 'manualInput',
  ));

  // Then
  final history = await repository.getById('long-test');
  expect(history, isNotNull);
  expect(history!.content.length, 1000);

  await box.close();
});
```

---

### TC-062-014: 特殊文字を含むcontent 🟡

**優先度**: P2（低）
**関連要件**: NFR-062-001（データ永続化）
**関連AC**: なし（エッジケース）

**テスト目的**:
特殊文字（絵文字、記号、改行など）を含むcontentも正しく保存できることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
final specialContent = 'こんにちは😊\n改行テスト\t"タブと引用符"';
```

**テスト手順**:
1. 特殊文字を含むcontentの履歴を保存
2. `await repository.getById('special-test')` で取得
3. contentが元の文字列と一致するか確認

**期待結果**:
- 特殊文字が失われず正しく保存される
- 取得したcontentが元の文字列と完全一致

**実装例**:
```dart
test('TC-062-014: 特殊文字を含むcontentも正しく保存できる', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);
  final specialContent = 'こんにちは😊\n改行テスト\t"タブと引用符"';

  // When
  await repository.save(HistoryItem(
    id: 'special-test',
    content: specialContent,
    createdAt: DateTime.now(),
    type: 'manualInput',
  ));

  // Then
  final history = await repository.getById('special-test');
  expect(history, isNotNull);
  expect(history!.content, specialContent);

  await box.close();
});
```

---

### TC-062-015: isFavoriteフラグの保存・取得 🔵

**優先度**: P1（重要）
**関連要件**: REQ-603（お気に入り機能の基盤）
**関連AC**: なし（将来の機能準備）

**テスト目的**:
isFavoriteフラグが正しく保存・取得できることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
final favoriteHistory = HistoryItem(
  id: 'favorite-test',
  content: 'お気に入りテスト',
  createdAt: DateTime.now(),
  type: 'preset',
  isFavorite: true,
);
```

**テスト手順**:
1. `isFavorite: true` の履歴を保存
2. `await repository.getById('favorite-test')` で取得
3. isFavoriteが `true` であることを確認

**期待結果**:
- 取得した履歴の `isFavorite` が `true`

**実装例**:
```dart
test('TC-062-015: isFavoriteフラグが正しく保存される', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // When
  await repository.save(HistoryItem(
    id: 'favorite-test',
    content: 'お気に入りテスト',
    createdAt: DateTime.now(),
    type: 'preset',
    isFavorite: true,
  ));

  // Then
  final history = await repository.getById('favorite-test');
  expect(history, isNotNull);
  expect(history!.isFavorite, true);

  await box.close();
});
```

---

## 5. データ永続化テスト（クラッシュリカバリ）

### TC-062-016: アプリ再起動後のデータ保持 🔵

**優先度**: P0（必須）
**関連要件**: REQ-5003, NFR-062-001, NFR-302
**関連AC**: AC-062-008

**テスト目的**:
アプリ再起動後も履歴が保持されることを確認する。

**前提条件**:
- Hive初期化済み

**テストデータ**:
```dart
final persistHistory = HistoryItem(
  id: 'persist-test',
  content: '永続化テスト',
  createdAt: DateTime.now(),
  type: 'manualInput',
);
```

**テスト手順**:
1. 履歴を1件保存
2. ボックスをクローズ（再起動をシミュレート）
3. 同じボックスを再オープン
4. `await repository.getById('persist-test')` で取得

**期待結果**:
- 再オープン後も履歴が存在する
- `getById('persist-test')` が `not null`
- `content` が `'永続化テスト'` で一致

**実装例**:
```dart
test('TC-062-016: アプリ再起動後も履歴が保持される', () async {
  // 1回目: 履歴を保存
  {
    final box = await Hive.openBox<HistoryItem>('history_persist_test');
    final repository = HistoryRepository(box: box);

    await repository.save(HistoryItem(
      id: 'persist-test',
      content: '永続化テスト',
      createdAt: DateTime.now(),
      type: 'manualInput',
    ));

    await box.close();
  }

  // 2回目: 同じボックスを再オープン（再起動をシミュレート）
  {
    final box = await Hive.openBox<HistoryItem>('history_persist_test');
    final repository = HistoryRepository(box: box);

    final history = await repository.getById('persist-test');
    expect(history, isNotNull);
    expect(history!.content, '永続化テスト');

    await box.close();
  }
});
```

**注意事項**:
- このテストは `test/features/history/data/history_repository_crash_test.dart` として別ファイルに分離することを推奨
- 実際のHiveファイルを使用するため、一時ディレクトリでの実行が必要

---

## 6. パフォーマンステスト

### TC-062-017: 50件の履歴を1秒以内に読み込み 🔵

**優先度**: P0（必須）
**関連要件**: NFR-004, NFR-062-003
**関連AC**: AC-062-009

**テスト目的**:
50件の履歴を1秒以内に読み込めることを確認する（パフォーマンス要件）。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
// 50件の履歴（ある程度の長さのcontentを含む）
for (int i = 0; i < 50; i++) {
  HistoryItem(
    id: 'perf-$i',
    content: 'パフォーマンステスト$i' * 10, // 約200文字
    createdAt: DateTime.now().add(Duration(seconds: i)),
    type: 'manualInput',
  );
}
```

**テスト手順**:
1. 50件の履歴を保存（ある程度の長さのcontentを含む）
2. Stopwatchで計測開始
3. `await repository.loadAll()` を実行
4. Stopwatchで計測終了
5. 経過時間を確認

**期待結果**:
- `loadAll()` が50件のリストを返す
- 経過時間が1000ms未満

**実装例**:
```dart
test('TC-062-017: 50件の履歴を1秒以内に読み込める', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // 50件の履歴を保存
  for (int i = 0; i < 50; i++) {
    await repository.save(HistoryItem(
      id: 'perf-$i',
      content: 'パフォーマンステスト$i' * 10, // ある程度の長さ
      createdAt: DateTime.now().add(Duration(seconds: i)),
      type: 'manualInput',
    ));
  }

  // When
  final stopwatch = Stopwatch()..start();
  final histories = await repository.loadAll();
  stopwatch.stop();

  // Then
  expect(histories.length, 50);
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));

  await box.close();
});
```

---

## 7. ソート・順序テスト

### TC-062-018: 最新順ソートの正確性 🔵

**優先度**: P0（必須）
**関連要件**: FR-062-002
**関連AC**: AC-062-002

**テスト目的**:
loadAll()が厳密にcreatedAtの降順でソートすることを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
// ランダムな順序で保存し、取得時に正しくソートされるか確認
final histories = [
  HistoryItem(id: 'h3', content: '3番目', createdAt: DateTime(2025, 1, 1, 12, 30), type: 'manualInput'),
  HistoryItem(id: 'h1', content: '1番目', createdAt: DateTime(2025, 1, 1, 12, 10), type: 'preset'),
  HistoryItem(id: 'h5', content: '5番目', createdAt: DateTime(2025, 1, 1, 12, 50), type: 'aiConverted'),
  HistoryItem(id: 'h2', content: '2番目', createdAt: DateTime(2025, 1, 1, 12, 20), type: 'quickButton'),
  HistoryItem(id: 'h4', content: '4番目', createdAt: DateTime(2025, 1, 1, 12, 40), type: 'manualInput'),
];
```

**テスト手順**:
1. ランダムな順序で5件の履歴を保存
2. `await repository.loadAll()` を実行
3. 返されたリストが厳密にcreatedAtの降順であることを確認

**期待結果**:
- リスト[0]が'h5'（最新 12:50）
- リスト[1]が'h4'（12:40）
- リスト[2]が'h3'（12:30）
- リスト[3]が'h2'（12:20）
- リスト[4]が'h1'（最古 12:10）

**実装例**:
```dart
test('TC-062-018: 最新順ソートの正確性', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // ランダムな順序で保存
  await repository.save(HistoryItem(
    id: 'h3', content: '3番目',
    createdAt: DateTime(2025, 1, 1, 12, 30), type: 'manualInput',
  ));
  await repository.save(HistoryItem(
    id: 'h1', content: '1番目',
    createdAt: DateTime(2025, 1, 1, 12, 10), type: 'preset',
  ));
  await repository.save(HistoryItem(
    id: 'h5', content: '5番目',
    createdAt: DateTime(2025, 1, 1, 12, 50), type: 'aiConverted',
  ));
  await repository.save(HistoryItem(
    id: 'h2', content: '2番目',
    createdAt: DateTime(2025, 1, 1, 12, 20), type: 'quickButton',
  ));
  await repository.save(HistoryItem(
    id: 'h4', content: '4番目',
    createdAt: DateTime(2025, 1, 1, 12, 40), type: 'manualInput',
  ));

  // When
  final histories = await repository.loadAll();

  // Then
  expect(histories[0].id, 'h5'); // 最新
  expect(histories[1].id, 'h4');
  expect(histories[2].id, 'h3');
  expect(histories[3].id, 'h2');
  expect(histories[4].id, 'h1'); // 最古

  await box.close();
});
```

---

## 8. 複数操作の組み合わせテスト

### TC-062-019: 保存・削除・再保存の組み合わせ 🔵

**優先度**: P1（重要）
**関連要件**: FR-062-001, FR-062-004
**関連AC**: なし（統合テスト的な確認）

**テスト目的**:
保存・削除・再保存を組み合わせた操作が正しく動作することを確認する。

**前提条件**:
- 空のhistoryボックス

**テストデータ**:
```dart
final history1 = HistoryItem(id: 'combo-1', content: '1つ目', createdAt: DateTime.now(), type: 'manualInput');
final history2 = HistoryItem(id: 'combo-2', content: '2つ目', createdAt: DateTime.now(), type: 'preset');
final history3 = HistoryItem(id: 'combo-3', content: '3つ目', createdAt: DateTime.now(), type: 'aiConverted');
```

**テスト手順**:
1. 3件の履歴を保存
2. 2件目を削除
3. 4件目を保存
4. `await repository.loadAll()` で確認

**期待結果**:
- `loadAll()` が3件のリストを返す（1件目、3件目、4件目）
- 削除した2件目は存在しない

**実装例**:
```dart
test('TC-062-019: 保存・削除・再保存の組み合わせ', () async {
  // Given
  final box = await Hive.openBox<HistoryItem>('history_test');
  final repository = HistoryRepository(box: box);

  // 3件保存
  await repository.save(HistoryItem(
    id: 'combo-1', content: '1つ目',
    createdAt: DateTime.now(), type: 'manualInput',
  ));
  await repository.save(HistoryItem(
    id: 'combo-2', content: '2つ目',
    createdAt: DateTime.now(), type: 'preset',
  ));
  await repository.save(HistoryItem(
    id: 'combo-3', content: '3つ目',
    createdAt: DateTime.now(), type: 'aiConverted',
  ));

  // When
  await repository.delete('combo-2'); // 2件目を削除
  await repository.save(HistoryItem(
    id: 'combo-4', content: '4つ目',
    createdAt: DateTime.now(), type: 'quickButton',
  ));

  // Then
  final histories = await repository.loadAll();
  expect(histories.length, 3); // 1, 3, 4が残る
  expect(await repository.getById('combo-2'), isNull); // 2件目は削除済み

  await box.close();
});
```

---

## テストカバレッジマトリックス

| テストケースID | テスト名 | 優先度 | 関連要件 | 関連AC | 信頼性 |
|--------------|---------|-------|---------|--------|-------|
| TC-062-001 | 履歴の保存機能 | P0 | REQ-601, FR-062-001 | AC-062-001 | 🔵 |
| TC-062-002 | 履歴の全件読み込み | P0 | REQ-601, FR-062-002 | AC-062-002 | 🔵 |
| TC-062-003 | IDによる履歴取得 | P0 | REQ-603, FR-062-007 | AC-062-001 | 🔵 |
| TC-062-004 | 存在しないIDの取得 | P0 | FR-062-007 | AC-062-007 | 🔵 |
| TC-062-005 | 履歴の個別削除 | P0 | REQ-604, FR-062-004 | AC-062-004 | 🔵 |
| TC-062-006 | 存在しないIDの削除 | P0 | FR-062-004 | AC-062-007 | 🔵 |
| TC-062-007 | 全履歴の削除 | P0 | REQ-604, FR-062-005 | AC-062-005 | 🔵 |
| TC-062-008 | 50件上限の自動削除 | P0 | REQ-602, FR-062-003 | AC-062-003 | 🔵 |
| TC-062-009 | ちょうど50件の場合 | P1 | REQ-602, FR-062-003 | EDGE-062-002 | 🔵 |
| TC-062-010 | 履歴種類の保存・取得 | P0 | FR-062-006 | AC-062-006 | 🔵 |
| TC-062-011 | 空の履歴リスト | P1 | FR-062-002 | EDGE-062-001 | 🔵 |
| TC-062-012 | 同一IDの上書き保存 | P1 | FR-062-001 | EDGE-062-003 | 🔵 |
| TC-062-013 | 極端に長いcontent | P2 | NFR-062-001 | EDGE-062-004 | 🟡 |
| TC-062-014 | 特殊文字を含むcontent | P2 | NFR-062-001 | - | 🟡 |
| TC-062-015 | isFavoriteフラグの保存 | P1 | REQ-603 | - | 🔵 |
| TC-062-016 | アプリ再起動後のデータ保持 | P0 | REQ-5003, NFR-062-001 | AC-062-008 | 🔵 |
| TC-062-017 | 50件の読み込みパフォーマンス | P0 | NFR-004, NFR-062-003 | AC-062-009 | 🔵 |
| TC-062-018 | 最新順ソートの正確性 | P0 | FR-062-002 | AC-062-002 | 🔵 |
| TC-062-019 | 保存・削除・再保存の組み合わせ | P1 | FR-062-001, FR-062-004 | - | 🔵 |

**合計**: 19テストケース
**P0（必須）**: 13ケース
**P1（重要）**: 5ケース
**P2（低）**: 2ケース

---

## テスト実装ガイドライン

### テストファイル構成

```dart
// test/features/history/data/history_repository_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';

void main() {
  group('HistoryRepository - 基本的なCRUD操作', () {
    late Directory tempDir;

    setUp(() async {
      // Hive環境をクリーンな状態にリセット
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('history_test_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // TC-062-001 ~ TC-062-007
    // ...
  });

  group('HistoryRepository - 50件上限管理', () {
    // TC-062-008 ~ TC-062-009
    // ...
  });

  group('HistoryRepository - エッジケース', () {
    // TC-062-011 ~ TC-062-015
    // ...
  });

  group('HistoryRepository - パフォーマンス', () {
    // TC-062-017
    // ...
  });
}
```

### モック戦略

- **実際のHiveボックスを使用**: PresetPhraseRepositoryテストと同様に、モックライブラリを使わず実際のHiveボックスを一時ディレクトリで使用
- **setUp/tearDownでクリーンアップ**: 各テスト前後でHiveをクローズし、一時ディレクトリを削除
- **isAdapterRegisteredで重複登録回避**: TypeAdapterの重複登録を防ぐ

### テスト実行コマンド

```bash
# 個別テストファイル実行
flutter test test/features/history/data/history_repository_test.dart

# カバレッジ付きで実行
flutter test --coverage test/features/history/data/history_repository_test.dart

# カバレッジレポート生成
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 受け入れ基準（Acceptance Criteria）カバレッジ

| AC番号 | AC内容 | 対応テストケース |
|--------|-------|----------------|
| AC-062-001 | 履歴保存の正常動作 | TC-062-001, TC-062-003 |
| AC-062-002 | 履歴の全件読み込み | TC-062-002, TC-062-018 |
| AC-062-003 | 50件上限の自動削除 | TC-062-008 |
| AC-062-004 | 個別削除の動作 | TC-062-005 |
| AC-062-005 | 全削除の動作 | TC-062-007 |
| AC-062-006 | 履歴種類の保存 | TC-062-010 |
| AC-062-007 | 存在しないID削除時のエラーハンドリング | TC-062-006, TC-062-004 |
| AC-062-008 | アプリ再起動後のデータ保持 | TC-062-016 |
| AC-062-009 | パフォーマンス要件 | TC-062-017 |

**全9件のACをカバー**: ✅ 完全カバレッジ達成

---

## エッジケース（EDGE）カバレッジ

| EDGE番号 | EDGE内容 | 対応テストケース |
|----------|---------|----------------|
| EDGE-062-001 | 空の履歴リスト | TC-062-011 |
| EDGE-062-002 | ちょうど50件の履歴 | TC-062-009 |
| EDGE-062-003 | 同一IDの上書き保存 | TC-062-012 |
| EDGE-062-004 | 極端に長いcontent | TC-062-013 |

**全4件のEDGEをカバー**: ✅ 完全カバレッジ達成

---

## 非機能要件（NFR）カバレッジ

| NFR番号 | NFR内容 | 対応テストケース |
|---------|--------|----------------|
| NFR-062-001 | データ永続化 | TC-062-016 |
| NFR-062-002 | ローカルストレージのみ | 全テスト（Hive Boxのみ使用） |
| NFR-062-003 | パフォーマンス | TC-062-017 |
| NFR-062-004 | テストカバレッジ90%以上 | 全19テストケース |
| NFR-062-005 | コード品質 | `flutter analyze` で検証 |

**全5件のNFRをカバー**: ✅ 完全カバレッジ達成

---

## テスト実施チェックリスト

### Redフェーズ（失敗するテスト作成）

- [ ] TC-062-001 ~ TC-062-019の全テストケースを実装
- [ ] 全テストが失敗することを確認（HistoryRepository未実装）
- [ ] テストコードが `flutter analyze` でエラー・警告なし

### Greenフェーズ（テストを通す最小実装）

- [ ] HistoryRepositoryクラスを実装
- [ ] 全publicメソッドにDartDocコメント追加
- [ ] 50件上限管理ロジックを実装
- [ ] 全テストケースが合格
- [ ] `flutter analyze` でエラー・警告なし

### Refactorフェーズ（リファクタリング）

- [ ] コードの重複を削除
- [ ] 変数名・メソッド名を最適化
- [ ] コメント・ドキュメントを充実化
- [ ] 全テストが依然として合格

### 最終検証

- [ ] テストカバレッジが90%以上
- [ ] パフォーマンステスト（TC-062-017）が合格
- [ ] 永続化テスト（TC-062-016）が合格
- [ ] 既存のHive初期化コードとの統合確認

---

## 次フェーズへの準備

### TASK-0063（履歴再読み上げ・削除機能）への引き継ぎ

- HistoryRepositoryの `getById`, `delete`, `deleteAll` メソッドが実装済み
- UIレイヤーから呼び出す準備が整っている

### TASK-0061（履歴一覧UI）への引き継ぎ

- HistoryRepositoryの `loadAll` メソッドが実装済み
- 最新順ソート済みのリストを取得可能

### TASK-0065（お気に入り機能）への引き継ぎ

- `isFavorite` フィールドが正しく保存・取得できる
- お気に入り登録時に履歴から参照可能

---

## 参考資料

- **要件定義書**: `docs/implements/kotonoha/TASK-0062/kotonoha-requirements.md`
- **既存テスト**: `test/core/utils/hive_init_test.dart`（Hive初期化テストのパターン）
- **PresetPhraseRepository**: `lib/features/preset_phrase/data/preset_phrase_repository.dart`（参考実装）
- **HistoryItemモデル**: `lib/shared/models/history_item.dart`
- **Hive公式ドキュメント**: https://docs.hivedb.dev/
- **Flutter Test公式ドキュメント**: https://flutter.dev/docs/testing

---

## 更新履歴

- **2025-11-28**: TASK-0062 テストケース定義書作成（tsumiki:tdd-testcases により生成）
