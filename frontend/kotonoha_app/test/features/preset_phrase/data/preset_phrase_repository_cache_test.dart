library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('PresetPhraseRepositoryキャッシュテスト - 正常系', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      // テスト前準備: Hive環境を初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_cache_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（重複登録回避）
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_cache_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      // テスト後処理: Hiveボックスをクローズし、ディスクから削除
      // 状態復元: 次のテストに影響しないよう、テストデータを削除
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_cache_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 定型文100件の読み込みが1秒以内に完了する
    test('TC-090-005: 定型文100件読み込みパフォーマンス計測', () async {
      // Given: テストデータ準備: 100件の定型文を事前に保存
      // 初期条件設定: Hive Boxに100件のデータが存在
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'perf-$i',
          content: '定型文$i - これはパフォーマンステスト用のテキストです。',
          category: ['daily', 'health', 'other'][i % 3],
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);

      // When: 実際の処理実行: loadAllを呼び出して時間を計測
      // 処理内容: Stopwatchで読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 結果検証: 1秒以内に読み込みが完了することを確認
      // （100件を1秒以内に表示）
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(loaded.length, 100);
    });

    // キャッシュ有効時は2回目の読み込みが高速化される
    test('TC-090-006: キャッシュによる読み込み高速化確認', () async {
      // Given: テストデータ準備: 100件の定型文を保存し、1回目のloadAllを実行
      // 初期条件設定: キャッシュに読み込み済み
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'cache-$i',
          content: '定型文$i',
          category: 'daily',
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);

      // 1回目のloadAllでキャッシュを構築
      await repository.loadAll();

      // When: 実際の処理実行: 2回目のloadAllを呼び出して時間を計測
      // 処理内容: キャッシュからの読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 結果検証: キャッシュヒット時に10ms以内で完了することを確認
      // ディスクI/Oなしでメモリから読み出し
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(10),
      );

      expect(loaded.length, 100);
    });

    // キャッシュ無効化後は最新データが読み込まれる
    test('TC-090-007: キャッシュ無効化と最新データ取得', () async {
      // Given: テストデータ準備: 初期データを保存してキャッシュを構築
      // 初期条件設定: キャッシュに旧データが存在
      final originalPhrase = PresetPhrase(
        id: 'invalidate-test',
        content: '元のデータ',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(originalPhrase);
      await repository.loadAll(); // キャッシュ構築

      // Hive Boxを直接更新（repositoryのsaveを経由しない）
      final updatedPhrase = originalPhrase.copyWith(content: '更新後のデータ');
      await presetBox.put(updatedPhrase.id, updatedPhrase);

      // When: 実際の処理実行: キャッシュを無効化して再読み込み
      // 処理内容: invalidateCache後にloadAll
      repository.invalidateCache();
      final loaded = await repository.loadAll();

      // Then: 結果検証: 最新データが取得されることを確認
      // キャッシュ無効化後は再読み込みされる
      expect(loaded.length, 1);
      expect(
        loaded.first.content,
        '更新後のデータ',
      );
    });

    // 保存操作時にキャッシュが自動無効化される
    test('TC-090-008: 保存時のキャッシュ自動無効化確認', () async {
      // Given: テストデータ準備: 初期データを保存してキャッシュを構築
      // 初期条件設定: キャッシュが存在する状態
      final originalPhrase = PresetPhrase(
        id: 'auto-invalidate',
        content: '元のデータ',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(originalPhrase);
      final firstLoad = await repository.loadAll();
      expect(firstLoad.first.content, '元のデータ'); // 初回確認

      // When: 実際の処理実行: saveで新しいデータを保存
      // 処理内容: save呼び出し（キャッシュ自動無効化が期待される）
      final newPhrase = PresetPhrase(
        id: 'auto-invalidate-new',
        content: '新しいデータ',
        category: 'health',
        displayOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(newPhrase);

      // 2回目のloadAll
      final secondLoad = await repository.loadAll();

      // Then: 結果検証: 新しいデータが含まれることを確認
      // save後はキャッシュが更新される
      expect(secondLoad.length, 2);
      expect(
        secondLoad.any((p) => p.content == '新しいデータ'),
        isTrue,
      );
    });
  });

  group('PresetPhraseRepositoryキャッシュテスト - 異常系', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_cache_error_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox =
          await Hive.openBox<PresetPhrase>('test_cache_error_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_cache_error_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // Hive読み込みエラー時の安全な処理
    test('TC-090-010: Hive読み込みエラー時のフォールバック', () async {
      // Given: テストデータ準備: 正常なデータを保存
      // 初期条件設定: 正常なRepositoryの状態
      final phrase = PresetPhrase(
        id: 'error-test',
        content: 'テストデータ',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(phrase);

      // Boxを閉じてエラー状態を作る
      await presetBox.close();

      // 閉じたBoxへの読み込みは、空リストに置き換えずHiveErrorを伝える。

      await expectLater(
        () async => await repository.loadAll(),
        throwsA(isA<HiveError>()),
      );
    });
  });

  group('PresetPhraseRepositoryキャッシュテスト - 境界値', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_cache_boundary_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox =
          await Hive.openBox<PresetPhrase>('test_cache_boundary_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_cache_boundary_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 定型文0件でのloadAllパフォーマンス
    test('TC-090-012: 空データでの読み込みパフォーマンス', () async {
      // Given: テストデータ準備: 空のRepository
      // 初期条件設定: データが0件の状態

      // When: 実際の処理実行: loadAllを呼び出して時間を計測
      // 処理内容: 空データでの読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 結果検証: 10ms以内に空リストが返されることを確認
      // 空でもエラーなく高速に返す
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(10),
      );

      expect(loaded, isEmpty);
      expect(loaded, isA<List<PresetPhrase>>());
    });

    // 定型文500件でのloadAllパフォーマンス
    test('TC-090-013: 大量データでの読み込みパフォーマンス', () async {
      // Given: テストデータ準備: 500件の定型文を保存
      // 初期条件設定: Hive Boxに500件のデータが存在
      final phrases = List.generate(
        500,
        (i) => PresetPhrase(
          id: 'large-$i',
          content: '定型文$i - これは大量データテスト用のテキストです。',
          category: ['daily', 'health', 'other'][i % 3],
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);

      // When: 実際の処理実行: loadAllを呼び出して時間を計測
      // 処理内容: 500件の読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 結果検証: 1秒以内に読み込みが完了することを確認
      // 大量データでもパフォーマンス維持
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(loaded.length, 500);
    });

    // キャッシュ構築後の500件読み込みが高速
    test('TC-090-013a: キャッシュ構築後の大量データ読み込み高速化', () async {
      // Given: テストデータ準備: 500件の定型文を保存して1回目のloadAllを実行
      // 初期条件設定: キャッシュに読み込み済み
      final phrases = List.generate(
        500,
        (i) => PresetPhrase(
          id: 'cache-large-$i',
          content: '定型文$i',
          category: 'daily',
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);

      // 1回目のloadAllでキャッシュを構築
      await repository.loadAll();

      // When: 実際の処理実行: 2回目のloadAllを呼び出して時間を計測
      // 処理内容: キャッシュからの大量データ読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 結果検証: キャッシュヒット時に大幅に高速化することを確認
      // 大量データでもキャッシュ効果あり
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(50),
      );

      expect(loaded.length, 500);
    });
  });
}
