/// FavoriteRepository TDDテスト（Redフェーズ）
/// TASK-0065: お気に入りHiveモデル・リポジトリ実装
///
/// テストフレームワーク: flutter_test + Hive Testing
/// 対象: FavoriteRepository（お気に入りのHive永続化を担当）
///
/// TDD Redフェーズ: Repositoryが未実装のため、このテストは失敗する
///
/// 信頼性レベル凡例:
/// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 黄信号: 要件定義書から妥当な推測によるテスト
/// - 赤信号: 要件定義書にない推測によるテスト
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/favorite/data/favorite_repository.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';

void main() {
  group('FavoriteRepository - 基本的なCRUD操作', () {
    late Directory tempDir;
    late Box<FavoriteItem> favoriteBox;
    late FavoriteRepository repository;

    setUp(() async {
      // テスト前準備: Hive環境を初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      // path_provider対策: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_favorite_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（重複登録回避）
      // 重複登録回避: 既に登録されている場合はスキップ
      // typeId 2: FavoriteItem (typeId 0: HistoryItem, 1: PresetPhrase)
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      favoriteBox = await Hive.openBox<FavoriteItem>('test_favorites');
      repository = FavoriteRepository(box: favoriteBox);
    });

    tearDown(() async {
      // テスト後処理: Hiveボックスをクローズし、ディスクから削除
      // 状態復元: 次のテストに影響しないよう、テストデータを削除
      await favoriteBox.close();
      await Hive.deleteBoxFromDisk('test_favorites');
      await Hive.close();

      // 一時ディレクトリ削除: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-065-006: お気に入りの保存（save）
    // =========================================================================
    test('TC-065-006: お気に入りをHiveに保存できる', () async {
      // テスト目的: FavoriteRepository.save()メソッドの基本動作確認
      // テスト内容: お気に入りをsave()で保存し、getById()で取得できることを検証
      // 期待される動作: お気に入りがHive Boxに正しく保存される
      // 青信号: FR-065-002, AC-065-001

      // Given（準備フェーズ）
      final favorite = FavoriteItem(
        id: 'save-test',
        content: 'こんにちは',
        createdAt: DateTime(2025, 1, 15, 10, 30),
        displayOrder: 0,
      );

      // When（実行フェーズ）
      await repository.save(favorite);

      // Then（検証フェーズ）
      final loaded = await repository.getById('save-test');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'save-test');
      expect(loaded.content, 'こんにちは');
      expect(loaded.displayOrder, 0);
    });

    // =========================================================================
    // TC-065-007: 全お気に入りの読み込み（loadAll）
    // =========================================================================
    test('TC-065-007: 全お気に入りをdisplayOrder昇順で取得できる', () async {
      // テスト目的: loadAll()メソッドによるdisplayOrder昇順ソートの確認
      // テスト内容: 3件のお気に入りを異なるdisplayOrderで保存し、昇順で取得できることを検証
      // 期待される動作: displayOrderの昇順でソートされたリストが返る
      // 青信号: FR-065-002, AC-065-004

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'f3',
        content: '3番目',
        createdAt: DateTime.now(),
        displayOrder: 3,
      ));
      await repository.save(FavoriteItem(
        id: 'f1',
        content: '1番目',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'f2',
        content: '2番目',
        createdAt: DateTime.now(),
        displayOrder: 2,
      ));

      // When（実行フェーズ）
      final favorites = await repository.loadAll();

      // Then（検証フェーズ）
      expect(favorites.length, 3);
      expect(favorites[0].displayOrder, 1); // 昇順
      expect(favorites[1].displayOrder, 2);
      expect(favorites[2].displayOrder, 3);
    });

    // =========================================================================
    // TC-065-008: IDによるお気に入り取得（getById）
    // =========================================================================
    test('TC-065-008: IDでお気に入りを取得できる', () async {
      // テスト目的: getById()メソッドの正常動作確認
      // テスト内容: 特定のIDでお気に入りを取得できることを検証
      // 期待される動作: 指定IDのお気に入りが返る
      // 青信号: FR-065-002

      // Given（準備フェーズ）
      final favorite = FavoriteItem(
        id: 'getbyid-test',
        content: 'ID検索',
        createdAt: DateTime.now(),
        displayOrder: 0,
      );
      await repository.save(favorite);

      // When（実行フェーズ）
      final loaded = await repository.getById('getbyid-test');

      // Then（検証フェーズ）
      expect(loaded, isNotNull);
      expect(loaded!.id, 'getbyid-test');
    });

    // =========================================================================
    // TC-065-009: 存在しないIDの取得（getById - null返却）
    // =========================================================================
    test('TC-065-009: 存在しないIDを取得するとnullを返す', () async {
      // テスト目的: 存在しないIDでnullを返すことの確認
      // テスト内容: 存在しないIDでgetById()を呼び出すとnullが返ることを検証
      // 期待される動作: nullが返る（例外ではない）
      // 青信号: EDGE-065-003, AC-065-012

      // When（実行フェーズ）
      final loaded = await repository.getById('non-existent-id');

      // Then（検証フェーズ）
      expect(loaded, isNull);
    });

    // =========================================================================
    // TC-065-010: お気に入りの削除（delete）
    // =========================================================================
    test('TC-065-010: 特定のお気に入りを削除できる', () async {
      // テスト目的: delete()メソッドの正常動作確認
      // テスト内容: 複数のお気に入りを保存し、1つだけ削除して他が残ることを検証
      // 期待される動作: 指定IDのお気に入りのみ削除される
      // 青信号: FR-065-002, AC-065-002

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'del-1',
        content: 'A',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'del-2',
        content: 'B',
        createdAt: DateTime.now(),
        displayOrder: 2,
      ));

      // When（実行フェーズ）
      await repository.delete('del-1');

      // Then（検証フェーズ）
      expect(await repository.getById('del-1'), isNull);
      expect(await repository.getById('del-2'), isNotNull); // 他は残る
    });

    // =========================================================================
    // TC-065-011: 存在しないIDの削除（delete - エラーハンドリング）
    // =========================================================================
    test('TC-065-011: 存在しないIDを削除しても例外が発生しない', () async {
      // テスト目的: 無効なIDでの削除操作への耐性確認
      // テスト内容: 存在しないIDでdelete()を呼び出しても例外なく終了することを検証
      // 期待される動作: 例外なく正常終了（silent fail）
      // 青信号: EDGE-065-002, AC-065-011

      // When & Then（実行・検証フェーズ）
      await expectLater(
        repository.delete('non-existent-id'),
        completes,
      );
    });

    // =========================================================================
    // TC-065-012: 全お気に入りの削除（deleteAll）
    // =========================================================================
    test('TC-065-012: 全お気に入りを削除できる', () async {
      // テスト目的: deleteAll()メソッドの正常動作確認
      // テスト内容: 全てのお気に入りを一括削除できることを検証
      // 期待される動作: 全お気に入りが削除される
      // 青信号: FR-065-002, AC-065-003

      // Given（準備フェーズ）
      for (int i = 0; i < 5; i++) {
        await repository.save(FavoriteItem(
          id: 'all-$i',
          content: 'テスト$i',
          createdAt: DateTime.now(),
          displayOrder: i,
        ));
      }
      expect((await repository.loadAll()).length, 5);

      // When（実行フェーズ）
      await repository.deleteAll();

      // Then（検証フェーズ）
      expect(await repository.loadAll(), isEmpty);
    });

    // =========================================================================
    // TC-065-013: 同一IDで複数回保存（上書き更新）
    // =========================================================================
    test('TC-065-013: 同じIDで保存すると上書きされる', () async {
      // テスト目的: 上書き更新の確認
      // テスト内容: 同じIDで保存すると内容が更新されることを検証
      // 期待される動作: 最後の保存内容で上書きされる
      // 青信号: EDGE-065-004

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'overwrite',
        content: '元の内容',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'overwrite',
        content: '更新後の内容',
        createdAt: DateTime.now(),
        displayOrder: 2,
      ));

      // When & Then（実行・検証フェーズ）
      final loaded = await repository.getById('overwrite');
      expect(loaded!.content, '更新後の内容');
      expect(loaded.displayOrder, 2);
      expect((await repository.loadAll()).length, 1); // 1件のみ
    });
  });

  group('FavoriteRepository - displayOrder管理', () {
    late Directory tempDir;
    late Box<FavoriteItem> favoriteBox;
    late FavoriteRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_favorite_order_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      favoriteBox = await Hive.openBox<FavoriteItem>('test_favorites');
      repository = FavoriteRepository(box: favoriteBox);
    });

    tearDown(() async {
      await favoriteBox.close();
      await Hive.deleteBoxFromDisk('test_favorites');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-065-014: 並び順でソート
    // =========================================================================
    test('TC-065-014: displayOrder昇順でソートされる', () async {
      // テスト目的: loadAll()が厳密にdisplayOrderの昇順でソートすることの確認
      // テスト内容: ランダムな順序で保存し、取得時に正しくソートされるか確認
      // 期待される動作: displayOrderの昇順でソートされる
      // 青信号: FR-065-003, AC-065-004

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'f5',
        content: '5',
        createdAt: DateTime.now(),
        displayOrder: 5,
      ));
      await repository.save(FavoriteItem(
        id: 'f1',
        content: '1',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'f3',
        content: '3',
        createdAt: DateTime.now(),
        displayOrder: 3,
      ));

      // When（実行フェーズ）
      final favorites = await repository.loadAll();

      // Then（検証フェーズ）
      expect(favorites[0].displayOrder, 1);
      expect(favorites[1].displayOrder, 3);
      expect(favorites[2].displayOrder, 5);
    });

    // =========================================================================
    // TC-065-015: 並び順の単一更新（updateDisplayOrder）
    // =========================================================================
    test('TC-065-015: 並び順を単一更新できる', () async {
      // テスト目的: updateDisplayOrder()メソッドの正常動作確認
      // テスト内容: 特定のお気に入りの並び順を変更できることを検証
      // 期待される動作: 指定したdisplayOrderに更新される
      // 青信号: FR-065-003, AC-065-005

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'order-test',
        content: 'テスト',
        createdAt: DateTime.now(),
        displayOrder: 5,
      ));

      // When（実行フェーズ）
      await repository.updateDisplayOrder('order-test', 10);

      // Then（検証フェーズ）
      final loaded = await repository.getById('order-test');
      expect(loaded!.displayOrder, 10);
    });

    // =========================================================================
    // TC-065-016: 並び順の一括更新（reorderFavorites）
    // =========================================================================
    test('TC-065-016: 並び順を一括更新できる', () async {
      // テスト目的: reorderFavorites()メソッドの正常動作確認
      // テスト内容: 複数のお気に入りの並び順を一括で更新できることを検証
      // 期待される動作: 指定した順序通りにdisplayOrderが設定される
      // 青信号: FR-065-003, AC-065-006

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'a',
        content: 'A',
        createdAt: DateTime.now(),
        displayOrder: 0,
      ));
      await repository.save(FavoriteItem(
        id: 'b',
        content: 'B',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'c',
        content: 'C',
        createdAt: DateTime.now(),
        displayOrder: 2,
      ));

      // When（実行フェーズ）
      // 順序を逆にする: c, a, b
      await repository.reorderFavorites(['c', 'a', 'b']);

      // Then（検証フェーズ）
      final favorites = await repository.loadAll();
      expect(favorites[0].id, 'c'); // displayOrder: 0
      expect(favorites[1].id, 'a'); // displayOrder: 1
      expect(favorites[2].id, 'b'); // displayOrder: 2
    });

    // =========================================================================
    // TC-065-017: displayOrderの重複（二次ソート）
    // =========================================================================
    test('TC-065-017: displayOrder重複時はcreatedAtで二次ソート', () async {
      // テスト目的: displayOrder重複時の二次ソート確認
      // テスト内容: displayOrderが重複している場合、createdAtの降順（新しい順）で二次ソートされることを検証
      // 期待される動作: displayOrderが同じ場合、createdAtの新しい方が先
      // 黄信号: EDGE-065-005

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'f1',
        content: '古い',
        createdAt: DateTime(2025, 1, 1, 10, 0),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'f2',
        content: '新しい',
        createdAt: DateTime(2025, 1, 1, 12, 0),
        displayOrder: 1,
      ));

      // When（実行フェーズ）
      final favorites = await repository.loadAll();

      // Then（検証フェーズ）
      expect(favorites[0].id, 'f2'); // 新しい方が先
      expect(favorites[1].id, 'f1');
    });
  });

  group('FavoriteRepository - エッジケース', () {
    late Directory tempDir;
    late Box<FavoriteItem> favoriteBox;
    late FavoriteRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_favorite_edge_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      favoriteBox = await Hive.openBox<FavoriteItem>('test_favorites');
      repository = FavoriteRepository(box: favoriteBox);
    });

    tearDown(() async {
      await favoriteBox.close();
      await Hive.deleteBoxFromDisk('test_favorites');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-065-022: お気に入り0件の状態
    // =========================================================================
    test('TC-065-022: お気に入り0件の場合に空リストを返す', () async {
      // テスト目的: データなし状態での動作確認
      // テスト内容: 空のBoxからloadAll()で空リストが返ることを検証
      // 期待される動作: 空リストが返る（nullではない）
      // 黄信号: EDGE-065-001, AC-065-010

      // When（実行フェーズ）
      final favorites = await repository.loadAll();

      // Then（検証フェーズ）
      expect(favorites, isEmpty);
    });

    // =========================================================================
    // TC-065-023: 極端に長いcontent（1000文字超）
    // =========================================================================
    test('TC-065-023: 1000文字のcontentも正しく保存できる', () async {
      // テスト目的: 長文contentの保存確認
      // テスト内容: 1000文字の長文が保存できることを検証
      // 期待される動作: 全文が保存される
      // 黄信号: EDGE-065-006

      // Given（準備フェーズ）
      final longContent = 'あ' * 1000;

      // When（実行フェーズ）
      await repository.save(FavoriteItem(
        id: 'long',
        content: longContent,
        createdAt: DateTime.now(),
        displayOrder: 0,
      ));

      // Then（検証フェーズ）
      final loaded = await repository.getById('long');
      expect(loaded!.content.length, 1000);
    });

    // =========================================================================
    // TC-065-024: 特殊文字を含むcontent
    // =========================================================================
    test('TC-065-024: 特殊文字を含むcontentも正しく保存できる', () async {
      // テスト目的: 特殊文字の保存確認
      // テスト内容: 絵文字、改行、タブなどが保存できることを検証
      // 期待される動作: 特殊文字が失われない
      // 黄信号: EDGE-065-006

      // Given（準備フェーズ）
      final specialContent = 'こんにちは😊\n改行テスト\t"タブと引用符"';

      // When（実行フェーズ）
      await repository.save(FavoriteItem(
        id: 'special',
        content: specialContent,
        createdAt: DateTime.now(),
        displayOrder: 0,
      ));

      // Then（検証フェーズ）
      final loaded = await repository.getById('special');
      expect(loaded!.content, specialContent);
    });

    // =========================================================================
    // TC-065-025: 空文字列のcontent
    // =========================================================================
    test('TC-065-025: 空文字列のcontentも保存できる', () async {
      // テスト目的: 空文字列の保存確認
      // テスト内容: contentが空文字列（""）のお気に入りを保存できることを検証
      // 期待される動作: 保存自体は成功する（Repository層ではバリデーションしない）
      // 黄信号: EDGE-065-007

      // When（実行フェーズ）
      await repository.save(FavoriteItem(
        id: 'empty',
        content: '',
        createdAt: DateTime.now(),
        displayOrder: 0,
      ));

      // Then（検証フェーズ）
      final loaded = await repository.getById('empty');
      expect(loaded, isNotNull);
      expect(loaded!.content, '');
    });

    // =========================================================================
    // TC-065-026: displayOrderの負の値
    // =========================================================================
    test('TC-065-026: displayOrderの負の値も保存できる', () async {
      // テスト目的: 負の値の保存とソート確認
      // テスト内容: displayOrderに負の値を設定できることを検証
      // 期待される動作: 保存成功、ソート時は負の値も含めて昇順ソート
      // 黄信号: EDGE-065-008

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'f1',
        content: 'A',
        createdAt: DateTime.now(),
        displayOrder: -1,
      ));
      await repository.save(FavoriteItem(
        id: 'f2',
        content: 'B',
        createdAt: DateTime.now(),
        displayOrder: 0,
      ));
      await repository.save(FavoriteItem(
        id: 'f3',
        content: 'C',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));

      // When（実行フェーズ）
      final favorites = await repository.loadAll();

      // Then（検証フェーズ）
      expect(favorites[0].displayOrder, -1);
      expect(favorites[1].displayOrder, 0);
      expect(favorites[2].displayOrder, 1);
    });
  });

  group('FavoriteRepository - データ永続化', () {
    // =========================================================================
    // TC-065-028: アプリ再起動後のデータ保持
    // =========================================================================
    test('TC-065-028: アプリ再起動後もお気に入りが保持される', () async {
      // テスト目的: Hiveのディスク永続化機能確認
      // テスト内容: Box close/re-open後もデータが保持されることを検証
      // 期待される動作: re-open後に同じデータが取得できる
      // 青信号: NFR-065-001, AC-065-009

      late Directory tempDir;

      // Given（準備フェーズ）
      // 1回目: お気に入りを保存
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_persistence_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      var favoriteBox = await Hive.openBox<FavoriteItem>('persistence_test');
      var repository = FavoriteRepository(box: favoriteBox);

      await repository.save(FavoriteItem(
        id: 'persist',
        content: '永続化テスト',
        createdAt: DateTime.now(),
        displayOrder: 0,
      ));

      // Boxを閉じる（アプリ終了をシミュレート）
      await favoriteBox.close();

      // When（実行フェーズ）
      // 2回目: Boxを再度開く（再起動をシミュレート）
      favoriteBox = await Hive.openBox<FavoriteItem>('persistence_test');
      repository = FavoriteRepository(box: favoriteBox);

      // Then（検証フェーズ）
      final favorite = await repository.getById('persist');
      expect(favorite, isNotNull);
      expect(favorite!.content, '永続化テスト');

      // クリーンアップ
      await favoriteBox.close();
      await Hive.deleteBoxFromDisk('persistence_test');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('FavoriteRepository - パフォーマンス', () {
    late Directory tempDir;
    late Box<FavoriteItem> favoriteBox;
    late FavoriteRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_favorite_perf_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      favoriteBox = await Hive.openBox<FavoriteItem>('test_favorites');
      repository = FavoriteRepository(box: favoriteBox);
    });

    tearDown(() async {
      await favoriteBox.close();
      await Hive.deleteBoxFromDisk('test_favorites');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-065-029: お気に入り100件の読み込みパフォーマンス
    // =========================================================================
    test('TC-065-029: 100件のお気に入りを500ms以内に読み込める', () async {
      // テスト目的: パフォーマンス要件の確認
      // テスト内容: 100件のお気に入りを500ms以内に読み込めることを検証
      // 期待される動作: 500ms未満で読み込み完了
      // 黄信号: NFR-065-002

      // Given（準備フェーズ）
      for (int i = 0; i < 100; i++) {
        await repository.save(FavoriteItem(
          id: 'perf-$i',
          content: 'パフォーマンステスト$i' * 5,
          createdAt: DateTime.now(),
          displayOrder: i,
        ));
      }

      // When（実行フェーズ）
      final stopwatch = Stopwatch()..start();
      final favorites = await repository.loadAll();
      stopwatch.stop();

      // Then（検証フェーズ）
      expect(favorites.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });

  group('FavoriteRepository - 複数操作の組み合わせ', () {
    late Directory tempDir;
    late Box<FavoriteItem> favoriteBox;
    late FavoriteRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_favorite_combo_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      favoriteBox = await Hive.openBox<FavoriteItem>('test_favorites');
      repository = FavoriteRepository(box: favoriteBox);
    });

    tearDown(() async {
      await favoriteBox.close();
      await Hive.deleteBoxFromDisk('test_favorites');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-065-031: 保存・削除・再保存の組み合わせ
    // =========================================================================
    test('TC-065-031: 保存・削除・再保存の組み合わせ', () async {
      // テスト目的: 複数操作の組み合わせが正しく動作することの確認
      // テスト内容: 保存・削除・再保存を組み合わせた操作を検証
      // 期待される動作: すべての操作が正しく実行される
      // 青信号: FR-065-002

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'c1',
        content: '1',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'c2',
        content: '2',
        createdAt: DateTime.now(),
        displayOrder: 2,
      ));
      await repository.save(FavoriteItem(
        id: 'c3',
        content: '3',
        createdAt: DateTime.now(),
        displayOrder: 3,
      ));

      // When（実行フェーズ）
      await repository.delete('c2');
      await repository.save(FavoriteItem(
        id: 'c4',
        content: '4',
        createdAt: DateTime.now(),
        displayOrder: 4,
      ));

      // Then（検証フェーズ）
      final favorites = await repository.loadAll();
      expect(favorites.length, 3); // c1, c3, c4
      expect(await repository.getById('c2'), isNull);
    });

    // =========================================================================
    // TC-065-032: 並び替え中の削除操作
    // =========================================================================
    test('TC-065-032: 並び替え中の削除操作で整合性を保つ', () async {
      // テスト目的: 並び替え操作と削除操作の組み合わせ確認
      // テスト内容: 並び替え操作中に削除しても整合性が保たれることを検証
      // 期待される動作: データ不整合が発生しない
      // 青信号: FR-065-003, NFR-065-003

      // Given（準備フェーズ）
      await repository.save(FavoriteItem(
        id: 'f1',
        content: 'A',
        createdAt: DateTime.now(),
        displayOrder: 1,
      ));
      await repository.save(FavoriteItem(
        id: 'f2',
        content: 'B',
        createdAt: DateTime.now(),
        displayOrder: 2,
      ));
      await repository.save(FavoriteItem(
        id: 'f3',
        content: 'C',
        createdAt: DateTime.now(),
        displayOrder: 3,
      ));

      // When（実行フェーズ）
      await repository.reorderFavorites(['f3', 'f2', 'f1']);
      await repository.delete('f2');

      // Then（検証フェーズ）
      final favorites = await repository.loadAll();
      expect(favorites.length, 2);
      expect(favorites[0].id, 'f3');
      expect(favorites[1].id, 'f1');
    });
  });
}
