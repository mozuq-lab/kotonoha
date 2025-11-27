/// PresetPhraseRepository TDDテスト（Redフェーズ）
/// TASK-0055: 定型文ローカル保存（Hive）
///
/// テストフレームワーク: flutter_test + Hive Testing
/// 対象: PresetPhraseRepository（定型文のHive永続化を担当）
///
/// 【TDD Redフェーズ】: Repositoryが未実装のため、このテストはコンパイルエラーになる
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
/// - 🔴 赤信号: 要件定義書にない推測によるテスト
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
      // 【テスト前準備】: Hive環境を初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【path_provider対策】: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_repo_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（重複登録回避）
      // 【重複登録回避】: 既に登録されている場合はスキップ
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      // 【テスト後処理】: Hiveボックスをクローズし、ディスクから削除
      // 【状態復元】: 次のテストに影響しないよう、テストデータを削除
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_presetPhrases');
      await Hive.close();

      // 【一時ディレクトリ削除】: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-055-001: Repository経由で定型文を1件保存できる
    // =========================================================================
    test('TC-055-001: Repository経由で定型文を1件保存できる', () async {
      // 【テスト目的】: PresetPhraseRepository.save()メソッドの基本動作確認
      // 【テスト内容】: 定型文をsave()で保存し、loadAll()で取得できることを検証
      // 【期待される動作】: 定型文がHive Boxに正しく保存される
      // 🔵 青信号: REQ-104（定型文追加機能）の基本動作

      // Given（準備フェーズ）
      // 【テストデータ準備】: 基本的な定型文データ（日常カテゴリ、お気に入りなし）
      // 【初期条件設定】: Repositoryが空の状態
      final phrase = PresetPhrase(
        id: 'test-uuid-001',
        content: 'こんにちは',
        category: 'daily',
        isFavorite: false,
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 26, 10, 0),
        updatedAt: DateTime(2025, 11, 26, 10, 0),
      );

      // When（実行フェーズ）
      // 【実際の処理実行】: repository.save()で定型文を保存
      // 【処理内容】: Hive Boxにデータを書き込む
      await repository.save(phrase);

      // Then（検証フェーズ）
      // 【結果検証】: 保存したデータがloadAll()で取得できることを確認
      // 【期待値確認】: REQ-104の要件を満たす
      final loaded = await repository.loadAll();

      // 【検証項目】: 件数が1件であること
      // 🔵 青信号: 基本的なデータ存在確認
      expect(loaded.length, 1); // 【確認内容】: 1件保存されている

      // 【検証項目】: 内容が一致すること
      // 🔵 青信号: データの完全性確認
      expect(loaded.first.id, 'test-uuid-001'); // 【確認内容】: idが保持されている
      expect(loaded.first.content, 'こんにちは'); // 【確認内容】: contentが保持されている
      expect(loaded.first.category, 'daily'); // 【確認内容】: categoryが保持されている
    });

    // =========================================================================
    // TC-055-002: Repository経由で複数の定型文を保存できる
    // =========================================================================
    test('TC-055-002: Repository経由で複数の定型文を保存できる（saveAll）', () async {
      // 【テスト目的】: saveAll()メソッドによる一括保存の確認
      // 【テスト内容】: 3件の定型文を一括保存し、全件取得できることを検証
      // 【期待される動作】: 複数件の定型文がすべて保存される
      // 🔵 青信号: REQ-106のカテゴリ分類と合わせた動作確認

      // Given（準備フェーズ）
      // 【テストデータ準備】: 複数カテゴリにまたがる3件の定型文
      final phrases = [
        PresetPhrase(
          id: 'uuid-001',
          content: 'おはようございます',
          category: 'daily',
          isFavorite: false,
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'uuid-002',
          content: 'お水をください',
          category: 'health',
          isFavorite: true,
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'uuid-003',
          content: 'ありがとう',
          category: 'daily',
          isFavorite: false,
          displayOrder: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // When（実行フェーズ）
      // 【実際の処理実行】: repository.saveAll()で一括保存
      await repository.saveAll(phrases);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 3件すべて保存されていること
      // 🔵 青信号: 一括保存の完全性確認
      expect(loaded.length, 3); // 【確認内容】: 3件保存されている

      // 【検証項目】: カテゴリ別に正しく分類されていること
      // 🔵 青信号: REQ-106のカテゴリ分類確認
      expect(loaded.where((p) => p.category == 'daily').length,
          2); // 【確認内容】: dailyが2件
      expect(loaded.where((p) => p.category == 'health').length,
          1); // 【確認内容】: healthが1件
    });

    // =========================================================================
    // TC-055-003: Repository経由で定型文を更新できる
    // =========================================================================
    test('TC-055-003: Repository経由で定型文を更新できる', () async {
      // 【テスト目的】: save()メソッドによる既存データの上書き更新確認
      // 【テスト内容】: 同じIDで保存し直すと内容が更新されることを検証
      // 【期待される動作】: 同じIDのデータが新しい内容で上書きされる
      // 🔵 青信号: REQ-104（定型文編集機能）

      // Given（準備フェーズ）
      // 【テストデータ準備】: 初期データを保存
      final original = PresetPhrase(
        id: 'uuid-update',
        content: '元の内容',
        category: 'daily',
        isFavorite: false,
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 26, 10, 0),
        updatedAt: DateTime(2025, 11, 26, 10, 0),
      );
      await repository.save(original);

      // When（実行フェーズ）
      // 【実際の処理実行】: 同じIDで新しい内容を保存（更新）
      final updated = original.copyWith(
        content: '更新後の内容',
        updatedAt: DateTime(2025, 11, 26, 12, 0),
      );
      await repository.save(updated);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 件数が増えていないこと
      // 🔵 青信号: 上書き更新の確認
      expect(loaded.length, 1); // 【確認内容】: 件数は1件のまま

      // 【検証項目】: 内容が更新されていること
      // 🔵 青信号: データ更新の確認
      expect(loaded.first.content, '更新後の内容'); // 【確認内容】: contentが更新されている
    });

    // =========================================================================
    // TC-055-004: Repository経由で定型文を削除できる
    // =========================================================================
    test('TC-055-004: Repository経由で定型文を削除できる', () async {
      // 【テスト目的】: delete()メソッドの正常動作確認
      // 【テスト内容】: 保存したデータを削除し、取得できなくなることを検証
      // 【期待される動作】: 指定IDの定型文が削除される
      // 🔵 青信号: REQ-104（定型文削除機能）

      // Given（準備フェーズ）
      // 【テストデータ準備】: 削除対象の定型文を保存
      final phrase = PresetPhrase(
        id: 'uuid-delete',
        content: '削除予定',
        category: 'other',
        isFavorite: false,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(phrase);

      // 削除前の確認
      var loaded = await repository.loadAll();
      expect(loaded.length, 1); // 【確認内容】: 削除前に1件存在

      // When（実行フェーズ）
      // 【実際の処理実行】: repository.delete()で削除
      await repository.delete('uuid-delete');

      // Then（検証フェーズ）
      loaded = await repository.loadAll();

      // 【検証項目】: 件数が0になること
      // 🔵 青信号: 削除の確認
      expect(loaded.length, 0); // 【確認内容】: データが削除されている
    });

    // =========================================================================
    // TC-055-005: お気に入りフラグがHiveに正しく保存される
    // =========================================================================
    test('TC-055-005: お気に入りフラグがHiveに正しく保存される', () async {
      // 【テスト目的】: isFavoriteフィールドの永続化確認
      // 【テスト内容】: true/falseの両方が正確に保存・読み込みされることを検証
      // 【期待される動作】: true/falseが正確に保存・読み込みされる
      // 🔵 青信号: REQ-105（お気に入り機能）の基盤

      // Given（準備フェーズ）
      // 【テストデータ準備】: お気に入りtrue/falseの2件
      final favoritePhrase = PresetPhrase(
        id: 'fav-001',
        content: 'お気に入り',
        category: 'daily',
        isFavorite: true,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final normalPhrase = PresetPhrase(
        id: 'normal-001',
        content: '通常',
        category: 'daily',
        isFavorite: false,
        displayOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.save(favoritePhrase);
      await repository.save(normalPhrase);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: お気に入りフラグが正しく保持されること
      // 🔵 青信号: bool型の正確な保存
      final fav = loaded.firstWhere((p) => p.id == 'fav-001');
      final normal = loaded.firstWhere((p) => p.id == 'normal-001');

      expect(fav.isFavorite, true); // 【確認内容】: お気に入りフラグがtrue
      expect(normal.isFavorite, false); // 【確認内容】: お気に入りフラグがfalse
    });

    // =========================================================================
    // TC-055-006: カテゴリ情報がHiveに正しく保存される
    // =========================================================================
    test('TC-055-006: カテゴリ情報がHiveに正しく保存される', () async {
      // 【テスト目的】: categoryフィールドの永続化確認
      // 【テスト内容】: 3種類のカテゴリが正確に保存されることを検証
      // 【期待される動作】: 'daily', 'health', 'other'が正確に保存される
      // 🔵 青信号: REQ-106（カテゴリ分類）

      // Given（準備フェーズ）
      // 【テストデータ準備】: 3種類のカテゴリ
      final dailyPhrase = PresetPhrase(
        id: 'cat-daily',
        content: '日常',
        category: 'daily',
        isFavorite: false,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final healthPhrase = PresetPhrase(
        id: 'cat-health',
        content: '体調',
        category: 'health',
        isFavorite: false,
        displayOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final otherPhrase = PresetPhrase(
        id: 'cat-other',
        content: 'その他',
        category: 'other',
        isFavorite: false,
        displayOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.saveAll([dailyPhrase, healthPhrase, otherPhrase]);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 各カテゴリが正しく保存されること
      // 🔵 青信号: REQ-106のカテゴリ分類確認
      expect(loaded.firstWhere((p) => p.id == 'cat-daily').category,
          'daily'); // 【確認内容】: dailyカテゴリ
      expect(loaded.firstWhere((p) => p.id == 'cat-health').category,
          'health'); // 【確認内容】: healthカテゴリ
      expect(loaded.firstWhere((p) => p.id == 'cat-other').category,
          'other'); // 【確認内容】: otherカテゴリ
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

    // =========================================================================
    // TC-055-015: 空文字の定型文を保存できる
    // =========================================================================
    test('TC-055-015: 空文字の定型文を保存できる', () async {
      // 【テスト目的】: content最小長（0文字）での動作確認
      // 【テスト内容】: 空文字でも保存可能であることを検証
      // 【期待される動作】: 空文字でも保存成功
      // 🟡 黄信号: EDGE-102の文字数制限下限から推測

      // Given（準備フェーズ）
      final emptyContentPhrase = PresetPhrase(
        id: 'empty-content',
        content: '',
        category: 'daily',
        isFavorite: false,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.save(emptyContentPhrase);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 空文字が保存されること
      // 🟡 黄信号: Hive層ではバリデーションなし
      expect(loaded.length, 1); // 【確認内容】: 1件保存されている
      expect(loaded.first.content, ''); // 【確認内容】: 空文字が保持されている
    });

    // =========================================================================
    // TC-055-016: 500文字の定型文を保存できる
    // =========================================================================
    test('TC-055-016: 500文字の定型文を保存できる', () async {
      // 【テスト目的】: content最大長（EDGE-102）での動作確認
      // 【テスト内容】: 500文字すべてが保存・読み込みできることを検証
      // 【期待される動作】: 最大長でも完全に保存
      // 🔵 青信号: EDGE-102の文字数制限

      // Given（準備フェーズ）
      // 【テストデータ準備】: 500文字の定型文
      final longContent = 'あ' * 500;
      final longPhrase = PresetPhrase(
        id: 'long-content',
        content: longContent,
        category: 'daily',
        isFavorite: false,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      await repository.save(longPhrase);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 500文字すべてが保存されること
      // 🔵 青信号: 文字欠落なしの確認
      expect(loaded.first.content.length, 500); // 【確認内容】: 長さが500文字
      expect(loaded.first.content, longContent); // 【確認内容】: 内容が完全一致
    });

    // =========================================================================
    // TC-055-018: 0件の状態でloadAll()を呼び出す
    // =========================================================================
    test('TC-055-018: 0件の状態でloadAll()を呼び出す', () async {
      // 【テスト目的】: データなし状態での動作確認
      // 【テスト内容】: 空のBoxからloadAll()で空リストが返ることを検証
      // 【期待される動作】: 空リストが返る（nullではない）
      // 🔵 青信号: EDGE-104対応

      // When（実行フェーズ）
      // 【実際の処理実行】: 空の状態でloadAll()
      final loaded = await repository.loadAll();

      // Then（検証フェーズ）
      // 【検証項目】: 空リストが返ること
      // 🔵 青信号: null参照エラーなし
      expect(loaded, isA<List<PresetPhrase>>()); // 【確認内容】: List型
      expect(loaded.isEmpty, true); // 【確認内容】: 空リスト
    });

    // =========================================================================
    // TC-055-019: 100件の定型文を一括保存・読み込み
    // =========================================================================
    test('TC-055-019: 100件の定型文を一括保存・読み込み', () async {
      // 【テスト目的】: REQ-107の上限値での動作確認
      // 【テスト内容】: 100件の定型文が保存・読み込みできることを検証
      // 【期待される動作】: 全件が正確に保存
      // 🟡 黄信号: REQ-107の「50-100個程度」から

      // Given（準備フェーズ）
      // 【テストデータ準備】: 100件の定型文を生成
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'bulk-$i',
          content: '定型文$i',
          category: ['daily', 'health', 'other'][i % 3],
          isFavorite: i % 5 == 0,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // When（実行フェーズ）
      await repository.saveAll(phrases);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 100件すべて保存されること
      // 🟡 黄信号: NFR-004のパフォーマンス要件
      expect(loaded.length, 100); // 【確認内容】: 100件保存されている
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

    // =========================================================================
    // TC-055-011: 存在しないIDで削除しても例外が発生しない
    // =========================================================================
    test('TC-055-011: 存在しないIDで削除しても例外が発生しない', () async {
      // 【テスト目的】: 無効なIDでの削除操作への耐性確認
      // 【テスト内容】: 存在しないIDでdelete()を呼び出しても例外なく終了することを検証
      // 【期待される動作】: 例外なく正常終了
      // 🟡 黄信号: EDGE-010対応

      // When（実行フェーズ）
      // 【実際の処理実行】: 存在しないIDで削除を試みる

      // Then（検証フェーズ）
      // 【検証項目】: 例外が発生しないこと
      // 🟡 黄信号: 堅牢性の確認
      await expectLater(
        repository.delete('non-existent-id'),
        completes,
      ); // 【確認内容】: 例外なく完了
    });

    // =========================================================================
    // TC-055-012: getById()で存在しないIDを指定するとnullが返る
    // =========================================================================
    test('TC-055-012: getById()で存在しないIDを指定するとnullが返る', () async {
      // 【テスト目的】: 存在しないIDでの取得操作確認
      // 【テスト内容】: 存在しないIDでgetById()を呼び出すとnullが返ることを検証
      // 【期待される動作】: nullが返る（例外ではない）
      // 🟡 黄信号: EDGE-009対応

      // When（実行フェーズ）
      final result = await repository.getById('non-existent-id');

      // Then（検証フェーズ）
      // 【検証項目】: nullが返ること
      // 🟡 黄信号: エッジケース動作の確認
      expect(result, isNull); // 【確認内容】: nullが返る
    });
  });

  group('PresetPhraseRepository - 永続化テスト', () {
    // =========================================================================
    // TC-055-007: アプリ再起動後も定型文が保持される
    // =========================================================================
    test('TC-055-007: アプリ再起動後も定型文が保持される', () async {
      // 【テスト目的】: Hiveのディスク永続化機能確認
      // 【テスト内容】: Box close/re-open後もデータが保持されることを検証
      // 【期待される動作】: re-open後に同じデータが取得できる
      // 🔵 青信号: REQ-5003の永続化要件

      late Directory tempDir;

      // Given（準備フェーズ）
      // 【テストデータ準備】: 定型文を保存してBoxを閉じる（再起動をシミュレート）
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
        isFavorite: true,
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 26, 10, 0),
        updatedAt: DateTime(2025, 11, 26, 10, 0),
      );

      await repository.save(phrase);

      // Boxを閉じる（アプリ終了をシミュレート）
      await presetBox.close();

      // When（実行フェーズ）
      // 【実際の処理実行】: Boxを再度開く（再起動をシミュレート）
      presetBox = await Hive.openBox<PresetPhrase>('persistence_test');
      repository = PresetPhraseRepository(box: presetBox);

      // Then（検証フェーズ）
      final loaded = await repository.loadAll();

      // 【検証項目】: 再起動後もデータが保持されること
      // 🔵 青信号: REQ-5003の永続化確認
      expect(loaded.length, 1); // 【確認内容】: 1件保持されている
      expect(loaded.first.id, 'persist-001'); // 【確認内容】: IDが保持されている
      expect(loaded.first.content, '永続化テスト'); // 【確認内容】: contentが保持されている
      expect(loaded.first.isFavorite, true); // 【確認内容】: isFavoriteが保持されている

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
