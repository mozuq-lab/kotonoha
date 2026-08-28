# TASK-0062: 履歴Hiveモデル・リポジトリ実装 - 要件定義書

## タスク概要

- **タスクID**: TASK-0062
- **タスク名**: 履歴Hiveモデル・リポジトリ実装
- **フェーズ**: Phase 4 - フロントエンド応用機能実装
- **推定工数**: 8時間
- **タスクタイプ**: TDD
- **関連要件**: REQ-601, REQ-602, REQ-605, NFR-101
- **依存タスク**: TASK-0054 (Hive初期化) - COMPLETED

## 背景・目的

履歴機能は、ユーザーが過去に読み上げた・表示した内容を再利用するための重要な機能です。本タスクでは、既に実装されているHistoryItemモデルに対応するHistoryRepositoryを実装し、以下を実現します：

1. 履歴のHiveへの永続化（ローカルストレージのみ、REQ-605）
2. 最大50件の自動管理（REQ-602）
3. 履歴種類の適切な管理（文字盤入力、定型文、AI変換結果、大ボタン）
4. アプリ再起動後のデータ保持（REQ-5003）

## 信頼性レベル

🔵 **青信号**: このタスクの要件は以下に明確に記載されています：
- `docs/spec/kotonoha-requirements.md`: REQ-601, REQ-602, REQ-605, NFR-101, REQ-5003
- `docs/design/kotonoha/interfaces.dart`: Historyエンティティ（108-145行目）
- `frontend/kotonoha_app/lib/shared/models/history_item.dart`: HistoryItemモデル（既実装）
- 既存のPresetPhraseRepositoryパターンを踏襲

## 機能要件（EARS記法）

### FR-062-001: 履歴のHive保存 🔵
**WHEN** ユーザーが文字盤入力・定型文・AI変換結果・大ボタンを読み上げた場合、**THEN** システムはその内容を履歴としてHiveボックス（'history'）に保存しなければならない。

- **関連要件**: REQ-601, REQ-605, NFR-101
- **実装対象**: `HistoryRepository.save(HistoryItem)` メソッド
- **永続化先**: Hive Box<HistoryItem> ('history')
- **データ項目**:
  - id: UUID形式の一意識別子
  - content: 読み上げ・表示したテキスト内容
  - createdAt: 作成日時
  - type: 履歴種類（'manualInput', 'preset', 'aiConverted', 'quickButton'）
  - isFavorite: お気に入りフラグ（デフォルトfalse）

### FR-062-002: 履歴の全件読み込み 🔵
**WHEN** アプリ起動時または履歴画面表示時、**THEN** システムはHiveから全ての履歴を読み込み、最新順（createdAtの降順）で返さなければならない。

- **関連要件**: REQ-601, NFR-004
- **実装対象**: `HistoryRepository.loadAll()` メソッド
- **戻り値**: `Future<List<HistoryItem>>`（最新順にソート）
- **パフォーマンス**: 50件の履歴を1秒以内に読み込む（NFR-004）

### FR-062-003: 履歴の50件上限自動削除 🔵
**WHERE** 履歴が50件に達した状態にある場合、**WHEN** 新しい履歴を追加する際、**THEN** システムは最も古い履歴（createdAtが最小）を自動削除しなければならない。

- **関連要件**: REQ-602, REQ-3002
- **実装対象**: `HistoryRepository.save(HistoryItem)` メソッド内のロジック
- **削除条件**: `box.length >= 50` の場合
- **削除対象**: createdAtが最も古い履歴1件
- **実装方針**: save()メソッド内で自動的に実行（ユーザーの操作不要）

### FR-062-004: 履歴の個別削除 🔵
**WHEN** ユーザーが特定の履歴を削除した場合、**THEN** システムはその履歴をHiveから削除しなければならない。

- **関連要件**: REQ-604
- **実装対象**: `HistoryRepository.delete(String id)` メソッド
- **エッジケース**: 存在しないIDでも例外を投げない（EDGE-006）

### FR-062-005: 履歴の全削除 🔵
**WHEN** ユーザーが全削除を実行した場合、**THEN** システムは全ての履歴をHiveから削除しなければならない。

- **関連要件**: REQ-604
- **実装対象**: `HistoryRepository.deleteAll()` メソッド
- **実装方針**: `box.clear()` を使用

### FR-062-006: 履歴種類の適切な管理 🔵
**WHEN** 履歴を保存する際、**THEN** システムは履歴の種類（文字盤入力、定型文、AI変換結果、大ボタン）を正しく記録しなければならない。

- **関連要件**: dataflow.mdの履歴管理フロー
- **履歴種類**:
  - `'manualInput'`: 文字盤入力
  - `'preset'`: 定型文
  - `'aiConverted'`: AI変換結果
  - `'quickButton'`: 大ボタン
- **実装対象**: HistoryItemモデルのtypeフィールド（既実装）
- **検証**: 各種類の履歴が正しく保存・表示される

### FR-062-007: IDによる履歴取得 🔵
**WHEN** 特定のIDで履歴を取得する場合、**THEN** システムはそのIDに対応する履歴を返さなければならない（存在しない場合はnull）。

- **関連要件**: REQ-603（再読み上げ機能の基盤）
- **実装対象**: `HistoryRepository.getById(String id)` メソッド
- **戻り値**: `Future<HistoryItem?>`（存在しない場合はnull）

## 非機能要件

### NFR-062-001: データ永続化 🔵
システムはアプリクラッシュ・強制終了後も履歴を失わない永続化を実装しなければならない。

- **関連要件**: REQ-5003, NFR-302
- **実装方針**: Hiveの標準永続化機能を使用
- **検証**: アプリ再起動後も履歴が保持される

### NFR-062-002: ローカルストレージのみ 🔵
システムは履歴をローカル端末内（Hive）のみに保存し、クラウド同期は行わなければならない。

- **関連要件**: REQ-605, NFR-101
- **実装方針**: HistoryRepositoryはHive Boxのみに依存
- **禁止事項**: API通信、クラウドストレージへのアップロード

### NFR-062-003: パフォーマンス 🔵
システムは50件の履歴を1秒以内に読み込み・表示しなければならない。

- **関連要件**: NFR-004
- **計測対象**: `loadAll()` メソッドの実行時間
- **目標値**: 50件で1000ms以内

### NFR-062-004: テストカバレッジ 🔵
HistoryRepositoryのテストカバレッジは90%以上としなければならない。

- **関連要件**: NFR-502（ビジネスロジック90%以上）
- **テスト対象**: すべてのpublicメソッド
- **テスト種類**: 正常系、異常系、境界値テスト

### NFR-062-005: コード品質 🔵
実装コードはflutter_lints準拠でなければならない。

- **関連要件**: NFR-503
- **検証**: `flutter analyze` でエラー・警告が0件
- **ドキュメント**: 全publicメソッドにDartDocコメント必須

## 受け入れ基準（Acceptance Criteria）

### AC-062-001: 履歴保存の正常動作 🔵
```dart
test('履歴をHiveに保存できる', () async {
  final repository = HistoryRepository(box: mockBox);
  final history = HistoryItem(
    id: 'test-001',
    content: 'こんにちは',
    createdAt: DateTime.now(),
    type: 'manualInput',
  );

  await repository.save(history);

  final loaded = await repository.getById('test-001');
  expect(loaded, isNotNull);
  expect(loaded!.content, 'こんにちは');
});
```

### AC-062-002: 履歴の全件読み込み 🔵
```dart
test('全ての履歴を最新順で読み込める', () async {
  final repository = HistoryRepository(box: mockBox);

  // 3件の履歴を保存（異なる時刻）
  await repository.save(HistoryItem(
    id: 'h1',
    content: '古い',
    createdAt: DateTime(2025, 1, 1, 10, 0),
    type: 'manualInput',
  ));
  await repository.save(HistoryItem(
    id: 'h2',
    content: '中間',
    createdAt: DateTime(2025, 1, 1, 11, 0),
    type: 'preset',
  ));
  await repository.save(HistoryItem(
    id: 'h3',
    content: '最新',
    createdAt: DateTime(2025, 1, 1, 12, 0),
    type: 'aiConverted',
  ));

  final histories = await repository.loadAll();

  expect(histories.length, 3);
  expect(histories[0].content, '最新'); // 最新が先頭
  expect(histories[1].content, '中間');
  expect(histories[2].content, '古い');
});
```

### AC-062-003: 50件上限の自動削除 🔵
```dart
test('50件を超えると最も古い履歴が自動削除される', () async {
  final repository = HistoryRepository(box: mockBox);

  // 50件の履歴を保存
  for (int i = 0; i < 50; i++) {
    await repository.save(HistoryItem(
      id: 'h$i',
      content: 'テスト$i',
      createdAt: DateTime(2025, 1, 1).add(Duration(minutes: i)),
      type: 'manualInput',
    ));
  }

  expect(await repository.loadAll(), hasLength(50));

  // 51件目を追加
  await repository.save(HistoryItem(
    id: 'h50',
    content: 'テスト50',
    createdAt: DateTime(2025, 1, 1).add(Duration(minutes: 50)),
    type: 'manualInput',
  ));

  final histories = await repository.loadAll();
  expect(histories.length, 50); // 50件に維持される
  expect(await repository.getById('h0'), isNull); // 最古の'h0'が削除
  expect(await repository.getById('h50'), isNotNull); // 最新の'h50'は存在
});
```

### AC-062-004: 個別削除の動作 🔵
```dart
test('特定の履歴を削除できる', () async {
  final repository = HistoryRepository(box: mockBox);

  await repository.save(HistoryItem(
    id: 'delete-test',
    content: '削除テスト',
    createdAt: DateTime.now(),
    type: 'manualInput',
  ));

  expect(await repository.getById('delete-test'), isNotNull);

  await repository.delete('delete-test');

  expect(await repository.getById('delete-test'), isNull);
});
```

### AC-062-005: 全削除の動作 🔵
```dart
test('全ての履歴を削除できる', () async {
  final repository = HistoryRepository(box: mockBox);

  // 複数の履歴を保存
  for (int i = 0; i < 5; i++) {
    await repository.save(HistoryItem(
      id: 'h$i',
      content: 'テスト$i',
      createdAt: DateTime.now(),
      type: 'manualInput',
    ));
  }

  expect(await repository.loadAll(), hasLength(5));

  await repository.deleteAll();

  expect(await repository.loadAll(), isEmpty);
});
```

### AC-062-006: 履歴種類の保存 🔵
```dart
test('履歴種類が正しく保存される', () async {
  final repository = HistoryRepository(box: mockBox);

  final types = ['manualInput', 'preset', 'aiConverted', 'quickButton'];

  for (int i = 0; i < types.length; i++) {
    await repository.save(HistoryItem(
      id: 'type-$i',
      content: 'テスト${types[i]}',
      createdAt: DateTime.now().add(Duration(seconds: i)),
      type: types[i],
    ));
  }

  for (int i = 0; i < types.length; i++) {
    final history = await repository.getById('type-$i');
    expect(history, isNotNull);
    expect(history!.type, types[i]);
  }
});
```

### AC-062-007: 存在しないID削除時のエラーハンドリング 🔵
```dart
test('存在しないIDを削除しても例外が発生しない', () async {
  final repository = HistoryRepository(box: mockBox);

  // 例外が発生しないことを確認
  await expectLater(
    repository.delete('non-existent-id'),
    completes,
  );
});
```

### AC-062-008: アプリ再起動後のデータ保持 🔵
```dart
test('アプリ再起動後も履歴が保持される', () async {
  // 1回目: 履歴を保存
  {
    final box = await Hive.openBox<HistoryItem>('history_test');
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
    final box = await Hive.openBox<HistoryItem>('history_test');
    final repository = HistoryRepository(box: box);

    final history = await repository.getById('persist-test');
    expect(history, isNotNull);
    expect(history!.content, '永続化テスト');

    await box.close();
  }
});
```

### AC-062-009: パフォーマンス要件 🔵
```dart
test('50件の履歴を1秒以内に読み込める', () async {
  final repository = HistoryRepository(box: mockBox);

  // 50件の履歴を保存
  for (int i = 0; i < 50; i++) {
    await repository.save(HistoryItem(
      id: 'perf-$i',
      content: 'パフォーマンステスト$i' * 10, // ある程度の長さ
      createdAt: DateTime.now().add(Duration(seconds: i)),
      type: 'manualInput',
    ));
  }

  final stopwatch = Stopwatch()..start();
  final histories = await repository.loadAll();
  stopwatch.stop();

  expect(histories.length, 50);
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

## エッジケース・境界値テスト

### EDGE-062-001: 空の履歴リスト 🔵
```dart
test('履歴が0件の場合に空リストを返す', () async {
  final repository = HistoryRepository(box: mockBox);

  final histories = await repository.loadAll();

  expect(histories, isEmpty);
});
```

### EDGE-062-002: ちょうど50件の履歴 🔵
```dart
test('ちょうど50件の場合は削除されない', () async {
  final repository = HistoryRepository(box: mockBox);

  // 50件保存
  for (int i = 0; i < 50; i++) {
    await repository.save(HistoryItem(
      id: 'edge-$i',
      content: 'エッジケース$i',
      createdAt: DateTime.now().add(Duration(seconds: i)),
      type: 'manualInput',
    ));
  }

  expect(await repository.loadAll(), hasLength(50));
  expect(await repository.getById('edge-0'), isNotNull); // 最古も残る
});
```

### EDGE-062-003: 同一IDの上書き保存 🔵
```dart
test('同じIDで保存すると上書きされる', () async {
  final repository = HistoryRepository(box: mockBox);

  await repository.save(HistoryItem(
    id: 'overwrite-test',
    content: '元の内容',
    createdAt: DateTime.now(),
    type: 'manualInput',
  ));

  await repository.save(HistoryItem(
    id: 'overwrite-test',
    content: '更新後の内容',
    createdAt: DateTime.now(),
    type: 'preset',
  ));

  final history = await repository.getById('overwrite-test');
  expect(history!.content, '更新後の内容');
  expect(history.type, 'preset');

  expect(await repository.loadAll(), hasLength(1)); // 1件のみ
});
```

### EDGE-062-004: 極端に長いcontent 🟡
```dart
test('1000文字のcontentも正しく保存できる', () async {
  final repository = HistoryRepository(box: mockBox);

  final longContent = 'あ' * 1000;
  await repository.save(HistoryItem(
    id: 'long-test',
    content: longContent,
    createdAt: DateTime.now(),
    type: 'manualInput',
  ));

  final history = await repository.getById('long-test');
  expect(history!.content.length, 1000);
});
```

## 実装仕様

### ファイル構成

```
frontend/kotonoha_app/
├── lib/
│   └── features/
│       └── history/
│           ├── data/
│           │   └── history_repository.dart  # 【新規作成】Repositoryクラス
│           └── domain/
│               └── history_service.dart      # 【将来実装】ビジネスロジック層
├── test/
│   └── features/
│       └── history/
│           ├── data/
│           │   ├── history_repository_test.dart        # 【新規作成】単体テスト
│           │   └── history_repository_crash_test.dart  # 【新規作成】クラッシュリカバリテスト
```

### HistoryRepository クラス設計

```dart
/// 【Repository定義】: 履歴のHive永続化を担当するRepository
/// 【実装内容】: HistoryItem のCRUD操作をHive Boxに委譲
/// 【設計根拠】: Repositoryパターンによりデータアクセス層を抽象化
/// 🔵 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
class HistoryRepository {
  final Box<HistoryItem> _box;

  HistoryRepository({required Box<HistoryItem> box}) : _box = box;

  /// 【メソッド定義】: 全履歴を読み込み（最新順）
  /// 【戻り値】: `Future<List<HistoryItem>>`（最新順にソート）
  Future<List<HistoryItem>> loadAll() async;

  /// 【メソッド定義】: 履歴を保存（50件超過時は自動削除）
  /// 【引数】: history - 保存する履歴
  Future<void> save(HistoryItem history) async;

  /// 【メソッド定義】: 履歴を削除
  /// 【引数】: id - 削除する履歴のID
  Future<void> delete(String id) async;

  /// 【メソッド定義】: 全履歴を削除
  Future<void> deleteAll() async;

  /// 【メソッド定義】: IDで履歴を取得
  /// 【引数】: id - 取得する履歴のID
  /// 【戻り値】: HistoryItem?（存在しない場合はnull）
  Future<HistoryItem?> getById(String id) async;
}
```

### 既存コードとの関係

- **HistoryItemモデル**: `lib/shared/models/history_item.dart`（既実装、変更不要）
- **HistoryItemAdapter**: `lib/shared/models/history_item_adapter.dart`（既実装、typeId: 0）
- **Hive初期化**: `lib/core/utils/hive_init.dart`（既実装、履歴ボックスオープン済み）
- **参考実装**: `lib/features/preset_phrase/data/preset_phrase_repository.dart`

### 実装上の注意点

1. **PresetPhraseRepositoryパターンの踏襲**: 既存の実装パターンを一貫して使用
2. **50件上限ロジック**: `save()`メソッド内で自動実行（透過的な制限）
3. **ソート処理**: `loadAll()`でcreatedAtの降順ソート
4. **エラーハンドリング**: Hive例外は上位層で処理（Repository層では例外を投げる）
5. **テスト容易性**: コンストラクタでBoxを注入（モック可能）

## テスト戦略

### テストケース分類

1. **正常系テスト** (AC-062-001 〜 AC-062-009)
   - 基本的なCRUD操作
   - 50件上限管理
   - データ永続化

2. **エッジケーステスト** (EDGE-062-001 〜 EDGE-062-004)
   - 境界値（0件、50件、51件）
   - 同一ID上書き
   - 極端な入力値

3. **パフォーマンステスト** (AC-062-009)
   - 50件読み込み時間計測

4. **クラッシュリカバリテスト** (AC-062-008)
   - アプリ再起動後のデータ保持

### テストデータ

- **履歴種類のバリエーション**: 'manualInput', 'preset', 'aiConverted', 'quickButton'
- **日時のバリエーション**: 過去、現在、異なる時刻
- **contentのバリエーション**: 短文、長文（1000文字）、特殊文字

### モック戦略

- Hive Boxのモック: `mockito`または実際のHiveテストボックス使用
- 既存のPresetPhraseRepositoryテストを参考に実装

## 完了条件チェックリスト

- [ ] HistoryRepositoryクラスが実装されている
- [ ] すべてのpublicメソッドにDartDocコメントがある
- [ ] 全受け入れ基準（AC-062-001〜009）のテストが実装され、合格している
- [ ] 全エッジケース（EDGE-062-001〜004）のテストが実装され、合格している
- [ ] `flutter analyze`でエラー・警告が0件
- [ ] テストカバレッジが90%以上
- [ ] 50件の履歴を1秒以内に読み込める（パフォーマンステスト合格）
- [ ] アプリ再起動後もデータが保持される（永続化テスト合格）
- [ ] 50件上限の自動削除が動作する
- [ ] 既存のHive初期化コードとの統合が完了している

## 次タスクへの引き継ぎ事項

- **TASK-0063**: 履歴再読み上げ・削除機能で、このRepositoryを使用
- **TASK-0061**: 履歴一覧UIで、このRepositoryから履歴を表示
- **TASK-0065**: お気に入り機能で、履歴からお気に入り登録時に参照

## 参考資料

- **要件定義書**: `docs/spec/kotonoha-requirements.md`（REQ-601, REQ-602, REQ-605）
- **インターフェース定義**: `docs/design/kotonoha/interfaces.dart`（Historyエンティティ）
- **既存モデル**: `frontend/kotonoha_app/lib/shared/models/history_item.dart`
- **参考実装**: `frontend/kotonoha_app/lib/features/preset_phrase/data/preset_phrase_repository.dart`
- **Hive初期化**: `frontend/kotonoha_app/lib/core/utils/hive_init.dart`
- **アーキテクチャ設計**: `docs/design/kotonoha/architecture.md`

## 更新履歴

- **2025-11-28**: TASK-0062 TDD要件定義書作成（tsumiki:tdd-requirements により生成）
