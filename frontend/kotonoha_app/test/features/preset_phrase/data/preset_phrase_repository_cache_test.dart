/// PresetPhraseRepositoryキャッシュ最適化テスト（Redフェーズ）
///
/// TASK-0090: TTS・ローカルストレージ最適化
/// テストケース: TC-090-005〜TC-090-008, TC-090-010, TC-090-012, TC-090-013
///
/// テストフレームワーク: flutter_test + Hive Testing
/// 対象: PresetPhraseRepositoryのキャッシュ機能
///
/// 【TDD Redフェーズ】: キャッシュ機能が未実装のため、テストが失敗するはず
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
  group('PresetPhraseRepositoryキャッシュテスト - 正常系', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      // 【テスト前準備】: Hive環境を初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
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
      // 【テスト後処理】: Hiveボックスをクローズし、ディスクから削除
      // 【状態復元】: 次のテストに影響しないよう、テストデータを削除
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_cache_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // TC-090-005: 定型文100件の読み込みが1秒以内に完了する
    // =========================================================================
    test('TC-090-005: 定型文100件読み込みパフォーマンス計測', () async {
      // 【テスト目的】: loadAll()の実行時間を計測し、NFR-004を満たすか確認
      // 【テスト内容】: 100件の定型文を1秒以内に読み込む
      // 【期待される動作】: loadAll()が1000ms以内に完了
      // 🔵 青信号: NFR-004パフォーマンス要件

      // Given: 【テストデータ準備】: 100件の定型文を事前に保存
      // 【初期条件設定】: Hive Boxに100件のデータが存在
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

      // When: 【実際の処理実行】: loadAll()を呼び出して時間を計測
      // 【処理内容】: Stopwatchで読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に読み込みが完了することを確認
      // 【期待値確認】: NFR-004（100件を1秒以内に表示）
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 100件の読み込みが1秒以内 🔵

      expect(loaded.length, 100); // 【確認内容】: 全100件が読み込まれている 🔵
    });

    // =========================================================================
    // TC-090-006: キャッシュ有効時は2回目の読み込みが高速化される
    // =========================================================================
    test('TC-090-006: キャッシュによる読み込み高速化確認', () async {
      // 【テスト目的】: 2回目のloadAll()呼び出し時の速度向上を確認
      // 【テスト内容】: メモリキャッシュから即座に返す
      // 【期待される動作】: 2回目は10ms以内に完了
      // 🟡 黄信号: 最適化実装の期待値

      // Given: 【テストデータ準備】: 100件の定型文を保存し、1回目のloadAll()を実行
      // 【初期条件設定】: キャッシュに読み込み済み
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

      // 1回目のloadAll()でキャッシュを構築
      await repository.loadAll();

      // When: 【実際の処理実行】: 2回目のloadAll()を呼び出して時間を計測
      // 【処理内容】: キャッシュからの読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 【結果検証】: キャッシュヒット時に10ms以内で完了することを確認
      // 【期待値確認】: ディスクI/Oなしでメモリから読み出し
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(10),
      ); // 【確認内容】: キャッシュヒット時は10ms以内 🟡

      expect(loaded.length, 100); // 【確認内容】: 全100件が返される 🟡
    });

    // =========================================================================
    // TC-090-007: キャッシュ無効化後は最新データが読み込まれる
    // =========================================================================
    test('TC-090-007: キャッシュ無効化と最新データ取得', () async {
      // 【テスト目的】: invalidateCache()後のloadAll()で最新データが取得されることを確認
      // 【テスト内容】: キャッシュをクリアし、Hiveから再読み込み
      // 【期待される動作】: 更新後のデータが取得される
      // 🔵 青信号: キャッシュ実装の基本動作

      // Given: 【テストデータ準備】: 初期データを保存してキャッシュを構築
      // 【初期条件設定】: キャッシュに旧データが存在
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

      // When: 【実際の処理実行】: キャッシュを無効化して再読み込み
      // 【処理内容】: invalidateCache()後にloadAll()
      repository.invalidateCache();
      final loaded = await repository.loadAll();

      // Then: 【結果検証】: 最新データが取得されることを確認
      // 【期待値確認】: キャッシュ無効化後は再読み込みされる
      expect(loaded.length, 1); // 【確認内容】: 1件存在 🔵
      expect(
        loaded.first.content,
        '更新後のデータ',
      ); // 【確認内容】: 最新のデータが取得される 🔵
    });

    // =========================================================================
    // TC-090-008: 保存操作時にキャッシュが自動無効化される
    // =========================================================================
    test('TC-090-008: 保存時のキャッシュ自動無効化確認', () async {
      // 【テスト目的】: save()呼び出し後にキャッシュが無効化されることを確認
      // 【テスト内容】: save()後のloadAll()で最新データが取得される
      // 【期待される動作】: 2回目のloadAll()で新データが取得される
      // 🔵 青信号: データ整合性要件

      // Given: 【テストデータ準備】: 初期データを保存してキャッシュを構築
      // 【初期条件設定】: キャッシュが存在する状態
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

      // When: 【実際の処理実行】: save()で新しいデータを保存
      // 【処理内容】: save()呼び出し（キャッシュ自動無効化が期待される）
      final newPhrase = PresetPhrase(
        id: 'auto-invalidate-new',
        content: '新しいデータ',
        category: 'health',
        displayOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.save(newPhrase);

      // 2回目のloadAll()
      final secondLoad = await repository.loadAll();

      // Then: 【結果検証】: 新しいデータが含まれることを確認
      // 【期待値確認】: save()後はキャッシュが更新される
      expect(secondLoad.length, 2); // 【確認内容】: 2件になっている 🔵
      expect(
        secondLoad.any((p) => p.content == '新しいデータ'),
        isTrue,
      ); // 【確認内容】: 新しいデータが含まれる 🔵
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

    // =========================================================================
    // TC-090-010: Hive読み込みエラー時の安全な処理
    // =========================================================================
    test('TC-090-010: Hive読み込みエラー時のフォールバック', () async {
      // 【テスト目的】: Hiveからのデータ読み込みが失敗した場合のフォールバック確認
      // 【テスト内容】: エラー発生時に空リストが返される
      // 【期待される動作】: データ損失を防ぎ、空リストで継続
      // 🟡 黄信号: NFR-304から推測

      // Given: 【テストデータ準備】: 正常なデータを保存
      // 【初期条件設定】: 正常なRepositoryの状態
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

      // When/Then: 【実際の処理実行】: loadAll()を呼び出してエラーハンドリングを確認
      // 【処理内容】: クローズ済みBoxへのアクセス
      // 注意: このテストはエラーハンドリング実装後にのみ成功する
      // 現状ではHiveError例外がスローされるはず

      // Then: 【結果検証】: エラー時の動作を確認
      // 【期待値確認】: 例外がスローされるか、安全に空リストが返される
      // 🟡 黄信号: エラーハンドリングの実装次第

      // 実装前: 例外がスローされることを確認
      await expectLater(
        () async => await repository.loadAll(),
        throwsA(isA<HiveError>()),
      ); // 【確認内容】: 未実装時はHiveErrorがスローされる 🟡

      // 注意: 実装後は以下のように変更が必要
      // final result = await repository.loadAllSafe();
      // expect(result, isEmpty);
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

    // =========================================================================
    // TC-090-012: 定型文0件でのloadAll()パフォーマンス
    // =========================================================================
    test('TC-090-012: 空データでの読み込みパフォーマンス', () async {
      // 【テスト目的】: データ最小値（0件）でのパフォーマンス確認
      // 【テスト内容】: 空でもエラーなく高速に返す
      // 【期待される動作】: 空リストが10ms以内に返される
      // 🔵 青信号: EDGE-104（空の一覧表示）

      // Given: 【テストデータ準備】: 空のRepository
      // 【初期条件設定】: データが0件の状態

      // When: 【実際の処理実行】: loadAll()を呼び出して時間を計測
      // 【処理内容】: 空データでの読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 【結果検証】: 10ms以内に空リストが返されることを確認
      // 【期待値確認】: 空でもエラーなく高速に返す
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(10),
      ); // 【確認内容】: 0件でも10ms以内 🔵

      expect(loaded, isEmpty); // 【確認内容】: 空リストが返される 🔵
      expect(loaded, isA<List<PresetPhrase>>()); // 【確認内容】: 型が正しい 🔵
    });

    // =========================================================================
    // TC-090-013: 定型文500件でのloadAll()パフォーマンス
    // =========================================================================
    test('TC-090-013: 大量データでの読み込みパフォーマンス', () async {
      // 【テスト目的】: データ上限値（想定最大500件）でのパフォーマンス確認
      // 【テスト内容】: 大量データでも1秒以内
      // 【期待される動作】: 500件が1秒以内に読み込まれる
      // 🟡 黄信号: 要件定義書から推測、NFR-004の拡張

      // Given: 【テストデータ準備】: 500件の定型文を保存
      // 【初期条件設定】: Hive Boxに500件のデータが存在
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

      // When: 【実際の処理実行】: loadAll()を呼び出して時間を計測
      // 【処理内容】: 500件の読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に読み込みが完了することを確認
      // 【期待値確認】: 大量データでもパフォーマンス維持
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 500件でも1秒以内 🟡

      expect(loaded.length, 500); // 【確認内容】: 全500件が読み込まれている 🟡
    });

    // =========================================================================
    // TC-090-013a: キャッシュ構築後の500件読み込みが高速
    // =========================================================================
    test('TC-090-013a: キャッシュ構築後の大量データ読み込み高速化', () async {
      // 【テスト目的】: 500件でもキャッシュ効果があることを確認
      // 【テスト内容】: キャッシュ構築後は大幅に高速化
      // 【期待される動作】: 2回目は50ms以内に完了
      // 🟡 黄信号: キャッシュ最適化の期待値

      // Given: 【テストデータ準備】: 500件の定型文を保存して1回目のloadAll()を実行
      // 【初期条件設定】: キャッシュに読み込み済み
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

      // 1回目のloadAll()でキャッシュを構築
      await repository.loadAll();

      // When: 【実際の処理実行】: 2回目のloadAll()を呼び出して時間を計測
      // 【処理内容】: キャッシュからの大量データ読み込み時間を計測
      final stopwatch = Stopwatch()..start();
      final loaded = await repository.loadAll();
      stopwatch.stop();

      // Then: 【結果検証】: キャッシュヒット時に大幅に高速化することを確認
      // 【期待値確認】: 大量データでもキャッシュ効果あり
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(50),
      ); // 【確認内容】: 500件でもキャッシュヒット時は50ms以内 🟡

      expect(loaded.length, 500); // 【確認内容】: 全500件が返される 🟡
    });
  });
}
