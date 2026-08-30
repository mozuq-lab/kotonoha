/// HistoryRepository TDDテスト（Redフェーズ）
/// TASK-0062: 履歴Hiveモデル・リポジトリ実装
///
/// テストフレームワーク: flutter_test + Hive Testing
/// 対象: HistoryRepository（履歴のHive永続化を担当）
///
/// 【TDD Redフェーズ】: Repositoryが未実装のため、このテストは失敗する
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
/// - 🔴 赤信号: 要件定義書にない推測によるテスト
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';

void main() {
  group('HistoryRepository - 基本的なCRUD操作', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      // 【テスト前準備】: Hive環境を初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【path_provider対策】: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（重複登録回避）
      // 【重複登録回避】: 既に登録されている場合はスキップ
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      // 【テスト後処理】: Hiveボックスをクローズし、ディスクから削除
      // 【状態復元】: 次のテストに影響しないよう、テストデータを削除
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      // 【一時ディレクトリ削除】: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-001: 履歴の保存機能（save）🔵
    // =========================================================================
    test('TC-062-001: 履歴をHiveに保存できる', () async {
      // 【テスト目的】: HistoryRepository.save()メソッドの基本動作確認
      // 【テスト内容】: 履歴をsave()で保存し、getById()で取得できることを検証
      // 【期待される動作】: 履歴がHive Boxに正しく保存される
      // 🔵 青信号: REQ-601（履歴保存機能）の基本動作

      // Given（準備フェーズ）
      // 【テストデータ準備】: 基本的な履歴データ（文字盤入力、お気に入りなし）
      // 【初期条件設定】: Repositoryが空の状態
      final history = HistoryItem(
        id: 'test-001',
        content: 'こんにちは',
        createdAt: DateTime(2025, 1, 15, 10, 30),
        type: 'manualInput',
      );

      // When（実行フェーズ）
      // 【実際の処理実行】: repository.save()で履歴を保存
      // 【処理内容】: Hive Boxにデータを書き込む
      await repository.save(history);

      // Then（検証フェーズ）
      // 【結果検証】: 保存したデータがgetById()で取得できることを確認
      // 【期待値確認】: REQ-601の要件を満たす
      final loaded = await repository.getById('test-001');

      // 【検証項目】: 取得できること
      // 🔵 青信号: 基本的なデータ存在確認
      expect(loaded, isNotNull); // 【確認内容】: 履歴が保存されている
      expect(loaded!.id, 'test-001'); // 【確認内容】: idが保持されている
      expect(loaded.content, 'こんにちは'); // 【確認内容】: contentが保持されている
      expect(loaded.type, 'manualInput'); // 【確認内容】: typeが保持されている
    });

    // =========================================================================
    // TC-062-002: 履歴の全件読み込み（loadAll）🔵
    // =========================================================================
    test('TC-062-002: 全ての履歴を最新順で読み込める', () async {
      // 【テスト目的】: loadAll()メソッドによる最新順ソートの確認
      // 【テスト内容】: 3件の履歴を異なる時刻で保存し、最新順で取得できることを検証
      // 【期待される動作】: createdAtの降順でソートされたリストが返る
      // 🔵 青信号: REQ-601, FR-062-002

      // Given（準備フェーズ）
      // 【テストデータ準備】: 異なる時刻の3件の履歴
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

      // When（実行フェーズ）
      // 【実際の処理実行】: repository.loadAll()を実行
      final histories = await repository.loadAll();

      // Then（検証フェーズ）
      // 【検証項目】: 3件すべて取得でき、最新順であること
      // 🔵 青信号: 最新順ソートの確認
      expect(histories.length, 3); // 【確認内容】: 3件取得されている
      expect(histories[0].content, '最新'); // 【確認内容】: 最新が先頭
      expect(histories[1].content, '中間'); // 【確認内容】: 中間が2番目
      expect(histories[2].content, '古い'); // 【確認内容】: 最古が末尾
    });

    // =========================================================================
    // TC-062-003: 履歴のIDによる取得（getById）🔵
    // =========================================================================
    test('TC-062-003: IDで履歴を取得できる', () async {
      // 【テスト目的】: getById()メソッドの正常動作確認
      // 【テスト内容】: 特定のIDで履歴を取得できることを検証
      // 【期待される動作】: 指定IDの履歴が返る
      // 🔵 青信号: REQ-603, FR-062-007

      // Given（準備フェーズ）
      final history = HistoryItem(
        id: 'getbyid-test',
        content: 'ID検索テスト',
        createdAt: DateTime.now(),
        type: 'preset',
      );
      await repository.save(history);

      // When（実行フェーズ）
      final loaded = await repository.getById('getbyid-test');

      // Then（検証フェーズ）
      expect(loaded, isNotNull); // 【確認内容】: 履歴が取得できる
      expect(loaded!.id, 'getbyid-test'); // 【確認内容】: IDが一致
      expect(loaded.content, 'ID検索テスト'); // 【確認内容】: contentが一致
      expect(loaded.type, 'preset'); // 【確認内容】: typeが一致
    });

    // =========================================================================
    // TC-062-004: 存在しないIDの取得（getById - null返却）🔵
    // =========================================================================
    test('TC-062-004: 存在しないIDを取得するとnullを返す', () async {
      // 【テスト目的】: 存在しないIDでnullを返すことの確認
      // 【テスト内容】: 存在しないIDでgetById()を呼び出すとnullが返ることを検証
      // 【期待される動作】: nullが返る（例外ではない）
      // 🔵 青信号: FR-062-007

      // When（実行フェーズ）
      final loaded = await repository.getById('non-existent-id');

      // Then（検証フェーズ）
      expect(loaded, isNull); // 【確認内容】: nullが返る
    });

    // =========================================================================
    // TC-062-005: 履歴の個別削除（delete）🔵
    // =========================================================================
    test('TC-062-005: 特定の履歴を削除できる', () async {
      // 【テスト目的】: delete()メソッドの正常動作確認
      // 【テスト内容】: 保存したデータを削除し、取得できなくなることを検証
      // 【期待される動作】: 指定IDの履歴が削除される
      // 🔵 青信号: REQ-604, FR-062-004

      // Given（準備フェーズ）
      final history = HistoryItem(
        id: 'delete-test',
        content: '削除テスト',
        createdAt: DateTime.now(),
        type: 'manualInput',
      );
      await repository.save(history);

      // 削除前の確認
      expect(await repository.getById('delete-test'), isNotNull);

      // When（実行フェーズ）
      await repository.delete('delete-test');

      // Then（検証フェーズ）
      expect(
          await repository.getById('delete-test'), isNull); // 【確認内容】: 削除されている
    });

    // =========================================================================
    // TC-062-006: 存在しないIDの削除（delete - エラーハンドリング）🔵
    // =========================================================================
    test('TC-062-006: 存在しないIDを削除しても例外が発生しない', () async {
      // 【テスト目的】: 無効なIDでの削除操作への耐性確認
      // 【テスト内容】: 存在しないIDでdelete()を呼び出しても例外なく終了することを検証
      // 【期待される動作】: 例外なく正常終了
      // 🔵 青信号: FR-062-004, EDGE-006

      // When & Then（実行・検証フェーズ）
      await expectLater(
        repository.delete('non-existent-id'),
        completes,
      ); // 【確認内容】: 例外なく完了
    });

    // =========================================================================
    // TC-062-007: 全履歴の削除（deleteAll）🔵
    // =========================================================================
    test('TC-062-007: 全ての履歴を削除できる', () async {
      // 【テスト目的】: deleteAll()メソッドの正常動作確認
      // 【テスト内容】: 全ての履歴を一括削除できることを検証
      // 【期待される動作】: 全履歴が削除される
      // 🔵 青信号: REQ-604, FR-062-005

      // Given（準備フェーズ）
      for (int i = 0; i < 5; i++) {
        await repository.save(HistoryItem(
          id: 'h$i',
          content: 'テスト$i',
          createdAt: DateTime.now(),
          type: 'manualInput',
        ));
      }

      // 削除前の確認
      expect((await repository.loadAll()).length, 5);

      // When（実行フェーズ）
      await repository.deleteAll();

      // Then（検証フェーズ）
      expect(await repository.loadAll(), isEmpty); // 【確認内容】: 全削除されている
    });
  });

  group('HistoryRepository - 50件上限管理', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_limit_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-008: 50件上限の自動削除（最古履歴削除）🔵
    // =========================================================================
    test('TC-062-008: 50件を超えると最も古い履歴が自動削除される', () async {
      // 【テスト目的】: 50件上限管理の確認
      // 【テスト内容】: 51件目を保存すると最古の履歴が自動削除されることを検証
      // 【期待される動作】: 50件に維持され、最古が削除される
      // 🔵 青信号: REQ-602, FR-062-003

      // Given（準備フェーズ）
      // 50件の履歴を保存
      for (int i = 0; i < 50; i++) {
        await repository.save(HistoryItem(
          id: 'h$i',
          content: 'テスト$i',
          createdAt: DateTime(2025, 1, 1).add(Duration(minutes: i)),
          type: 'manualInput',
        ));
      }

      expect((await repository.loadAll()).length, 50);

      // When（実行フェーズ）
      // 51件目を追加
      await repository.save(HistoryItem(
        id: 'h50',
        content: 'テスト50',
        createdAt: DateTime(2025, 1, 1).add(const Duration(minutes: 50)),
        type: 'manualInput',
      ));

      // Then（検証フェーズ）
      final histories = await repository.loadAll();
      expect(histories.length, 50); // 【確認内容】: 50件に維持される
      expect(await repository.getById('h0'), isNull); // 【確認内容】: 最古の'h0'が削除
      expect(await repository.getById('h50'), isNotNull); // 【確認内容】: 最新の'h50'は存在
    });

    // =========================================================================
    // TC-062-009: ちょうど50件の場合は削除されない 🔵
    // =========================================================================
    test('TC-062-009: ちょうど50件の場合は削除されない', () async {
      // 【テスト目的】: 境界値テスト（ちょうど50件）
      // 【テスト内容】: 50件保存時に最古履歴が残ることを検証
      // 【期待される動作】: 最古履歴が残る
      // 🔵 青信号: REQ-602, EDGE-062-002

      // Given（準備フェーズ）
      // 50件保存
      for (int i = 0; i < 50; i++) {
        await repository.save(HistoryItem(
          id: 'edge-$i',
          content: 'エッジケース$i',
          createdAt: DateTime.now().add(Duration(seconds: i)),
          type: 'manualInput',
        ));
      }

      // When & Then（実行・検証フェーズ）
      expect((await repository.loadAll()).length, 50);
      expect(await repository.getById('edge-0'), isNotNull); // 【確認内容】: 最古も残る
    });
  });

  group('HistoryRepository - 履歴種類管理', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_type_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-010: 履歴種類の保存・取得 🔵
    // =========================================================================
    test('TC-062-010: 履歴種類が正しく保存される', () async {
      // 【テスト目的】: 4種類の履歴タイプの保存確認
      // 【テスト内容】: 各typeが正確に保存されることを検証
      // 【期待される動作】: 'manualInput', 'preset', 'aiConverted', 'quickButton'が正確に保存される
      // 🔵 青信号: FR-062-006

      // Given（準備フェーズ）
      final types = ['manualInput', 'preset', 'aiConverted', 'quickButton'];

      // When（実行フェーズ）
      for (int i = 0; i < types.length; i++) {
        await repository.save(HistoryItem(
          id: 'type-$i',
          content: 'テスト${types[i]}',
          createdAt: DateTime.now().add(Duration(seconds: i)),
          type: types[i],
        ));
      }

      // Then（検証フェーズ）
      for (int i = 0; i < types.length; i++) {
        final history = await repository.getById('type-$i');
        expect(history, isNotNull);
        expect(history!.type, types[i]); // 【確認内容】: typeが正しく保存されている
      }
    });
  });

  group('HistoryRepository - エッジケース', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_edge_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-011: 空の履歴リスト 🔵
    // =========================================================================
    test('TC-062-011: 履歴が0件の場合に空リストを返す', () async {
      // 【テスト目的】: データなし状態での動作確認
      // 【テスト内容】: 空のBoxからloadAll()で空リストが返ることを検証
      // 【期待される動作】: 空リストが返る（nullではない）
      // 🔵 青信号: EDGE-062-001

      // When（実行フェーズ）
      final histories = await repository.loadAll();

      // Then（検証フェーズ）
      expect(histories, isEmpty); // 【確認内容】: 空リスト
    });

    // =========================================================================
    // TC-062-012: 同一IDの上書き保存 🔵
    // =========================================================================
    test('TC-062-012: 同じIDで保存すると上書きされる', () async {
      // 【テスト目的】: 上書き保存の確認
      // 【テスト内容】: 同じIDで保存すると内容が更新されることを検証
      // 【期待される動作】: 上書き更新される
      // 🔵 青信号: EDGE-062-003

      // Given（準備フェーズ）
      await repository.save(HistoryItem(
        id: 'overwrite-test',
        content: '元の内容',
        createdAt: DateTime.now(),
        type: 'manualInput',
      ));

      // When（実行フェーズ）
      await repository.save(HistoryItem(
        id: 'overwrite-test',
        content: '更新後の内容',
        createdAt: DateTime.now(),
        type: 'preset',
      ));

      // Then（検証フェーズ）
      final history = await repository.getById('overwrite-test');
      expect(history!.content, '更新後の内容'); // 【確認内容】: 内容が更新されている
      expect(history.type, 'preset'); // 【確認内容】: typeが更新されている
      expect((await repository.loadAll()).length, 1); // 【確認内容】: 1件のみ
    });

    // =========================================================================
    // TC-062-013: 極端に長いcontent（1000文字）🟡
    // =========================================================================
    test('TC-062-013: 1000文字のcontentも正しく保存できる', () async {
      // 【テスト目的】: 長文contentの保存確認
      // 【テスト内容】: 1000文字の長文が保存できることを検証
      // 【期待される動作】: 全文が保存される
      // 🟡 黄信号: EDGE-062-004

      // Given（準備フェーズ）
      final longContent = 'あ' * 1000;

      // When（実行フェーズ）
      await repository.save(HistoryItem(
        id: 'long-test',
        content: longContent,
        createdAt: DateTime.now(),
        type: 'manualInput',
      ));

      // Then（検証フェーズ）
      final history = await repository.getById('long-test');
      expect(history, isNotNull);
      expect(history!.content.length, 1000); // 【確認内容】: 1000文字保存されている
    });

    // =========================================================================
    // TC-062-014: 特殊文字を含むcontent 🟡
    // =========================================================================
    test('TC-062-014: 特殊文字を含むcontentも正しく保存できる', () async {
      // 【テスト目的】: 特殊文字の保存確認
      // 【テスト内容】: 絵文字、改行、タブなどが保存できることを検証
      // 【期待される動作】: 特殊文字が失われない
      // 🟡 黄信号

      // Given（準備フェーズ）
      final specialContent = 'こんにちは😊\n改行テスト\t"タブと引用符"';

      // When（実行フェーズ）
      await repository.save(HistoryItem(
        id: 'special-test',
        content: specialContent,
        createdAt: DateTime.now(),
        type: 'manualInput',
      ));

      // Then（検証フェーズ）
      final history = await repository.getById('special-test');
      expect(history, isNotNull);
      expect(history!.content, specialContent); // 【確認内容】: 特殊文字が保持されている
    });
  });

  group('HistoryRepository - データ永続化', () {
    // =========================================================================
    // TC-062-016: アプリ再起動後のデータ保持 🔵
    // =========================================================================
    test('TC-062-016: アプリ再起動後も履歴が保持される', () async {
      // 【テスト目的】: Hiveのディスク永続化機能確認
      // 【テスト内容】: Box close/re-open後もデータが保持されることを検証
      // 【期待される動作】: re-open後に同じデータが取得できる
      // 🔵 青信号: REQ-5003, NFR-062-001

      late Directory tempDir;

      // Given（準備フェーズ）
      // 1回目: 履歴を保存
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_persistence_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      var historyBox = await Hive.openBox<HistoryItem>('persistence_test');
      var repository = HistoryRepository(box: historyBox);

      await repository.save(HistoryItem(
        id: 'persist-test',
        content: '永続化テスト',
        createdAt: DateTime.now(),
        type: 'manualInput',
      ));

      // Boxを閉じる（アプリ終了をシミュレート）
      await historyBox.close();

      // When（実行フェーズ）
      // 2回目: Boxを再度開く（再起動をシミュレート）
      historyBox = await Hive.openBox<HistoryItem>('persistence_test');
      repository = HistoryRepository(box: historyBox);

      // Then（検証フェーズ）
      final history = await repository.getById('persist-test');
      expect(history, isNotNull);
      expect(history!.content, '永続化テスト'); // 【確認内容】: データが保持されている

      // クリーンアップ
      await historyBox.close();
      await Hive.deleteBoxFromDisk('persistence_test');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('HistoryRepository - パフォーマンス', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_perf_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-017: 50件の履歴を1秒以内に読み込み 🔵
    // =========================================================================
    test('TC-062-017: 50件の履歴を1秒以内に読み込める', () async {
      // 【テスト目的】: パフォーマンス要件の確認
      // 【テスト内容】: 50件の履歴を1秒以内に読み込めることを検証
      // 【期待される動作】: 1000ms未満で読み込み完了
      // 🔵 青信号: NFR-004, NFR-062-003

      // Given（準備フェーズ）
      // 50件の履歴を保存
      for (int i = 0; i < 50; i++) {
        await repository.save(HistoryItem(
          id: 'perf-$i',
          content: 'パフォーマンステスト$i' * 10, // ある程度の長さ
          createdAt: DateTime.now().add(Duration(seconds: i)),
          type: 'manualInput',
        ));
      }

      // When（実行フェーズ）
      final stopwatch = Stopwatch()..start();
      final histories = await repository.loadAll();
      stopwatch.stop();

      // Then（検証フェーズ）
      expect(histories.length, 50);
      expect(
          stopwatch.elapsedMilliseconds, lessThan(1000)); // 【確認内容】: 1秒以内に読み込み
    });
  });

  group('HistoryRepository - ソート・順序', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_sort_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-018: 最新順ソートの正確性 🔵
    // =========================================================================
    test('TC-062-018: 最新順ソートの正確性', () async {
      // 【テスト目的】: loadAll()が厳密にcreatedAtの降順でソートすることの確認
      // 【テスト内容】: ランダムな順序で保存し、取得時に正しくソートされるか確認
      // 【期待される動作】: createdAtの降順でソートされる
      // 🔵 青信号: FR-062-002

      // Given（準備フェーズ）
      // ランダムな順序で保存
      await repository.save(HistoryItem(
        id: 'h3',
        content: '3番目',
        createdAt: DateTime(2025, 1, 1, 12, 30),
        type: 'manualInput',
      ));
      await repository.save(HistoryItem(
        id: 'h1',
        content: '1番目',
        createdAt: DateTime(2025, 1, 1, 12, 10),
        type: 'preset',
      ));
      await repository.save(HistoryItem(
        id: 'h5',
        content: '5番目',
        createdAt: DateTime(2025, 1, 1, 12, 50),
        type: 'aiConverted',
      ));
      await repository.save(HistoryItem(
        id: 'h2',
        content: '2番目',
        createdAt: DateTime(2025, 1, 1, 12, 20),
        type: 'quickButton',
      ));
      await repository.save(HistoryItem(
        id: 'h4',
        content: '4番目',
        createdAt: DateTime(2025, 1, 1, 12, 40),
        type: 'manualInput',
      ));

      // When（実行フェーズ）
      final histories = await repository.loadAll();

      // Then（検証フェーズ）
      expect(histories[0].id, 'h5'); // 【確認内容】: 最新が先頭
      expect(histories[1].id, 'h4');
      expect(histories[2].id, 'h3');
      expect(histories[3].id, 'h2');
      expect(histories[4].id, 'h1'); // 【確認内容】: 最古が末尾
    });
  });

  group('HistoryRepository - 複数操作の組み合わせ', () {
    late Directory tempDir;
    late Box<HistoryItem> historyBox;
    late HistoryRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_history_combo_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
      repository = HistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-062-019: 保存・削除・再保存の組み合わせ 🔵
    // =========================================================================
    test('TC-062-019: 保存・削除・再保存の組み合わせ', () async {
      // 【テスト目的】: 複数操作の組み合わせが正しく動作することの確認
      // 【テスト内容】: 保存・削除・再保存を組み合わせた操作を検証
      // 【期待される動作】: すべての操作が正しく実行される
      // 🔵 青信号: FR-062-001, FR-062-004

      // Given（準備フェーズ）
      // 3件保存
      await repository.save(HistoryItem(
        id: 'combo-1',
        content: '1つ目',
        createdAt: DateTime.now(),
        type: 'manualInput',
      ));
      await repository.save(HistoryItem(
        id: 'combo-2',
        content: '2つ目',
        createdAt: DateTime.now(),
        type: 'preset',
      ));
      await repository.save(HistoryItem(
        id: 'combo-3',
        content: '3つ目',
        createdAt: DateTime.now(),
        type: 'aiConverted',
      ));

      // When（実行フェーズ）
      await repository.delete('combo-2'); // 2件目を削除
      await repository.save(HistoryItem(
        id: 'combo-4',
        content: '4つ目',
        createdAt: DateTime.now(),
        type: 'quickButton',
      ));

      // Then（検証フェーズ）
      final histories = await repository.loadAll();
      expect(histories.length, 3); // 【確認内容】: 1, 3, 4が残る
      expect(await repository.getById('combo-2'), isNull); // 【確認内容】: 2件目は削除済み
    });
  });
}
