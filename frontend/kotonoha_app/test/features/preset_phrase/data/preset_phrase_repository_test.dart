library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('PresetPhraseRepository - 正常系テスト', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      // テスト前準備: Hive環境を初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      // path_provider対策: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_repo_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（重複登録回避）
      // 重複登録回避: 既に登録されている場合はスキップ
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      // テスト後処理: Hiveボックスをクローズし、ディスクから削除
      // 状態復元: 次のテストに影響しないよう、テストデータを削除
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_presetPhrases');
      await Hive.close();

      // 一時ディレクトリ削除: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // Repository経由で定型文を1件保存できる
    test('TC-055-001: Repository経由で定型文を1件保存できる', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 基本的な定型文データ（日常カテゴリ、お気に入りなし）
      // 初期条件設定: Repositoryが空の状態
      final phrase = PresetPhrase(
        id: 'test-uuid-001',
        content: 'こんにちは',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 26, 10, 0),
        updatedAt: DateTime(2025, 11, 26, 10, 0),
      );

      // When（実行フェーズ）
      // 実際の処理実行: repository.saveで定型文を保存
      // 処理内容: Hive Boxにデータを書き込む
      await repository.save(phrase);

      // Then（検証フェーズ）
      // 結果検証: 保存したデータがloadAllで取得できることを確認
      // の要件を満たす
      final loaded = await repository.loadAll();

      // 検証項目: 件数が1件であること
      expect(loaded.length, 1);

      // 検証項目: 内容が一致すること
      expect(loaded.first.id, 'test-uuid-001');
      expect(loaded.first.content, 'こんにちは');
      expect(loaded.first.category, 'daily');
    });

    // Repository経由で複数の定型文を保存できる
    test('TC-055-002: Repository経由で複数の定型文を保存できる（saveAll）', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 複数カテゴリにまたがる3件の定型文
      final phrases = [
        PresetPhrase(
          id: 'uuid-001',
          content: 'おはようございます',
          category: 'daily',
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'uuid-002',
          content: 'お水をください',
          category: 'health',
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'uuid-003',
          content: 'ありがとう',
          category: 'daily',
          displayOrder: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // When（実行フェーズ）
      // 実際の処理実行: repository.saveAllで一括保存
      await repository.saveAll(phrases);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 3件すべて保存されていること
      expect(loaded.length, 3);

      // 検証項目: カテゴリ別に正しく分類されていること
      expect(loaded.where((p) => p.category == 'daily').length, 2);
      expect(loaded.where((p) => p.category == 'health').length, 1);
    });

    // Repository経由で定型文を更新できる
    test('TC-055-003: Repository経由で定型文を更新できる', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 初期データを保存
      final original = PresetPhrase(
        id: 'uuid-update',
        content: '元の内容',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 26, 10, 0),
        updatedAt: DateTime(2025, 11, 26, 10, 0),
      );
      await repository.save(original);

      // When（実行フェーズ）
      // 実際の処理実行: 同じIDで新しい内容を保存（更新）
      final updated = original.copyWith(
        content: '更新後の内容',
        updatedAt: DateTime(2025, 11, 26, 12, 0),
      );
      await repository.save(updated);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 件数が増えていないこと
      expect(loaded.length, 1);

      // 検証項目: 内容が更新されていること
      expect(loaded.first.content, '更新後の内容');
    });

    // Repository経由で定型文を削除できる
    test('TC-055-004: Repository経由で定型文を削除できる', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 削除対象の定型文を保存
      final phrase = PresetPhrase(
        id: 'uuid-delete',
        content: '削除予定',
        category: 'other',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(phrase);

      // 削除前の確認
      var loaded = await repository.loadAll();
      expect(loaded.length, 1);

      // When（実行フェーズ）
      // 実際の処理実行: repository.deleteで削除
      await repository.delete('uuid-delete');

      // Then（検証フェーズ）
      loaded = await repository.loadAll();

      // 検証項目: 件数が0になること
      expect(loaded.length, 0);
    });

    // カテゴリ情報がHiveに正しく保存される
    test('TC-055-006: カテゴリ情報がHiveに正しく保存される', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 3種類のカテゴリ
      final dailyPhrase = PresetPhrase(
        id: 'cat-daily',
        content: '日常',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final healthPhrase = PresetPhrase(
        id: 'cat-health',
        content: '体調',
        category: 'health',
        displayOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final otherPhrase = PresetPhrase(
        id: 'cat-other',
        content: 'その他',
        category: 'other',
        displayOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.saveAll([dailyPhrase, healthPhrase, otherPhrase]);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 各カテゴリが正しく保存されること
      expect(loaded.firstWhere((p) => p.id == 'cat-daily').category, 'daily');
      expect(loaded.firstWhere((p) => p.id == 'cat-health').category, 'health');
      expect(loaded.firstWhere((p) => p.id == 'cat-other').category, 'other');
    });
  });

  group('PresetPhraseRepository - 境界値テスト', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_repo_boundary_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 空文字の定型文を保存できる
    test('TC-055-015: 空文字の定型文を保存できる', () async {
      // Given（準備フェーズ）
      final emptyContentPhrase = PresetPhrase(
        id: 'empty-content',
        content: '',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.save(emptyContentPhrase);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 空文字が保存されること
      expect(loaded.length, 1);
      expect(loaded.first.content, '');
    });

    // 500文字の定型文を保存できる
    test('TC-055-016: 500文字の定型文を保存できる', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 500文字の定型文
      final longContent = 'あ' * 500;
      final longPhrase = PresetPhrase(
        id: 'long-content',
        content: longContent,
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.save(longPhrase);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 500文字すべてが保存されること
      expect(loaded.first.content.length, 500);
      expect(loaded.first.content, longContent);
    });

    // 0件の状態でloadAllを呼び出す
    test('TC-055-018: 0件の状態でloadAll()を呼び出す', () async {
      // When（実行フェーズ）
      // 実際の処理実行: 空の状態でloadAll
      final loaded = await repository.loadAll();

      // Then（検証フェーズ）
      // 検証項目: 空リストが返ること
      expect(loaded, isA<List<PresetPhrase>>());
      expect(loaded.isEmpty, true);
    });

    // 100件の定型文を一括保存・読み込み
    test('TC-055-019: 100件の定型文を一括保存・読み込み', () async {
      // Given（準備フェーズ）
      // テストデータ準備: 100件の定型文を生成
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'bulk-$i',
          content: '定型文$i',
          category: ['daily', 'health', 'other'][i % 3],
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // When（実行フェーズ）
      await repository.saveAll(phrases);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 100件すべて保存されること
      expect(loaded.length, 100);
    });
  });

  group('PresetPhraseRepository - 異常系テスト', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_repo_error_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 存在しないIDで削除しても例外が発生しない
    test('TC-055-011: 存在しないIDで削除しても例外が発生しない', () async {
      // When（実行フェーズ）
      // 実際の処理実行: 存在しないIDで削除を試みる

      // Then（検証フェーズ）
      // 検証項目: 例外が発生しないこと
      await expectLater(
        repository.delete('non-existent-id'),
        completes,
      );
    });

    // getByIdで存在しないIDを指定するとnullが返る
    test('TC-055-012: getById()で存在しないIDを指定するとnullが返る', () async {
      // When（実行フェーズ）
      final result = await repository.getById('non-existent-id');

      // Then（検証フェーズ）
      // 検証項目: nullが返ること
      expect(result, isNull);
    });
  });

  group('PresetPhraseRepository - 永続化テスト', () {
    // アプリ再起動後も定型文が保持される
    test('TC-055-007: アプリ再起動後も定型文が保持される', () async {
      late Directory tempDir;

      // Given（準備フェーズ）
      // テストデータ準備: 定型文を保存してBoxを閉じる（再起動をシミュレート）
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_persistence_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      var presetBox = await Hive.openBox<PresetPhrase>('persistence_test');
      var repository = PresetPhraseRepository(box: presetBox);

      final phrase = PresetPhrase(
        id: 'persist-001',
        content: '永続化テスト',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 26, 10, 0),
        updatedAt: DateTime(2025, 11, 26, 10, 0),
      );

      await repository.save(phrase);

      // Boxを閉じる（アプリ終了をシミュレート）
      await presetBox.close();

      // When（実行フェーズ）
      // 実際の処理実行: Boxを再度開く（再起動をシミュレート）
      presetBox = await Hive.openBox<PresetPhrase>('persistence_test');
      repository = PresetPhraseRepository(box: presetBox);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 検証項目: 再起動後もデータが保持されること
      expect(loaded.length, 1);
      expect(loaded.first.id, 'persist-001');
      expect(loaded.first.content, '永続化テスト');
      expect(loaded.first.displayOrder, 0);

      // クリーンアップ
      await presetBox.close();
      await Hive.deleteBoxFromDisk('persistence_test');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
