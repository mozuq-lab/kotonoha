/// 統合パフォーマンス最適化テスト（Redフェーズ）
///
/// TASK-0090: TTS・ローカルストレージ最適化
/// TTS読み上げと定型文読み込みの統合パフォーマンステスト
///
/// テストフレームワーク: flutter_test + mocktail + Hive Testing
/// 対象: TTSService、PresetPhraseRepositoryの統合パフォーマンス
///
/// 【TDD Redフェーズ】: 最適化機能が未実装のため、一部テストが失敗するはず
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
/// - 🔴 赤信号: 要件定義書にない推測によるテスト
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import '../mocks/mock_flutter_tts.dart';

void main() {
  group('統合パフォーマンステスト - TTS + 定型文読み込み', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService ttsService;
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUpAll(() {
      // 【テスト前準備】: Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() async {
      // 【テスト前準備】: モックと実Hiveの両方を初期化
      // 【環境初期化】: 各テストが独立して実行できる環境を構築

      // TTS モック設定
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
      ttsService = TTSService(tts: mockFlutterTts);

      // Hive 初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_integration_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox =
          await Hive.openBox<PresetPhrase>('test_integration_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      // 【テスト後処理】: リソースをクリーンアップ
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_integration_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // 統合テスト: 定型文選択から読み上げ開始までのE2Eパフォーマンス
    // =========================================================================
    test('E2E: 定型文選択から読み上げ開始までのパフォーマンス', () async {
      // 【テスト目的】: 定型文選択から読み上げ開始までの総時間を計測
      // 【テスト内容】: 定型文読み込み + TTS読み上げ開始の合計時間
      // 【期待される動作】: 合計1秒以内に読み上げが開始される
      // 🔵 青信号: NFR-001 + NFR-004の組み合わせ

      // Given: 【テストデータ準備】: 100件の定型文を保存、TTSを初期化
      // 【初期条件設定】: ユーザーが定型文画面を開く状況を想定
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'e2e-$i',
          content: '定型文$i',
          category: 'daily',
          isFavorite: i == 0, // 最初のをお気に入りに
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);
      await ttsService.initialize();

      // When: 【実際の処理実行】: 定型文読み込み + 選択した定型文の読み上げ
      // 【処理内容】: E2Eシナリオを時間計測
      final stopwatch = Stopwatch()..start();

      // 1. 定型文一覧を読み込む
      final loadedPhrases = await repository.loadAll();

      // 2. 最初の定型文を選択して読み上げ
      final selectedPhrase = loadedPhrases.first;
      await ttsService.speak(selectedPhrase.content);

      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に読み上げが開始されることを確認
      // 【期待値確認】: ユーザー体験として許容される遅延
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: E2E時間が1秒以内 🔵

      expect(loadedPhrases.length, 100); // 【確認内容】: 100件読み込まれている 🔵
      expect(
        ttsService.state,
        TTSState.speaking,
      ); // 【確認内容】: 読み上げが開始されている 🔵
    });

    // =========================================================================
    // 統合テスト: 連続操作時のパフォーマンス維持
    // =========================================================================
    test('連続操作: 複数の定型文を連続選択・読み上げ', () async {
      // 【テスト目的】: 複数の定型文を連続して選択・読み上げする際のパフォーマンス
      // 【テスト内容】: 5回連続の選択・読み上げで各回100ms以内
      // 【期待される動作】: 初回以降はキャッシュ効果で高速
      // 🟡 黄信号: 実際のユーザー操作パターンから推測

      // Given: 【テストデータ準備】: 定型文を保存し、TTSを初期化
      // 【初期条件設定】: キャッシュが構築される状態
      final phrases = List.generate(
        5,
        (i) => PresetPhrase(
          id: 'continuous-$i',
          content: '連続テスト$i',
          category: 'daily',
          isFavorite: false,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);
      await ttsService.initialize();

      // 初回読み込みでキャッシュを構築
      final loadedPhrases = await repository.loadAll();

      // When/Then: 【実際の処理実行】: 5回連続で選択・読み上げ
      // 【処理内容】: 各回の時間を計測し、100ms以内であることを確認
      for (int i = 0; i < 5; i++) {
        final stopwatch = Stopwatch()..start();

        // 前の読み上げを停止
        if (ttsService.state == TTSState.speaking) {
          await ttsService.stop();
        }

        // 新しい定型文を読み上げ
        await ttsService.speak(loadedPhrases[i].content);

        stopwatch.stop();

        // 【結果検証】: 各回100ms以内に開始されることを確認
        expect(
          stopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(100),
        ); // 【確認内容】: 連続操作$i回目は100ms以内 🟡
      }

      expect(
        ttsService.state,
        TTSState.speaking,
      ); // 【確認内容】: 最後の読み上げが開始されている 🟡
    });

    // =========================================================================
    // 統合テスト: 大量データでのE2Eパフォーマンス
    // =========================================================================
    test('E2E: 500件の定型文からの選択・読み上げパフォーマンス', () async {
      // 【テスト目的】: 最大想定データ量でのE2Eパフォーマンス確認
      // 【テスト内容】: 500件の読み込み + 読み上げでも1秒以内
      // 【期待される動作】: スケーラビリティ維持
      // 🟡 黄信号: 要件の上限値でのテスト

      // Given: 【テストデータ準備】: 500件の定型文を保存
      // 【初期条件設定】: ヘビーユーザーのシナリオ
      final phrases = List.generate(
        500,
        (i) => PresetPhrase(
          id: 'large-e2e-$i',
          content: '大量データテスト$i',
          category: ['daily', 'health', 'other'][i % 3],
          isFavorite: i % 50 == 0,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);
      await ttsService.initialize();

      // When: 【実際の処理実行】: 500件読み込み + 読み上げ
      // 【処理内容】: 大量データでのE2E時間を計測
      final stopwatch = Stopwatch()..start();

      final loadedPhrases = await repository.loadAll();
      final randomPhrase = loadedPhrases[250]; // 中間のデータを選択
      await ttsService.speak(randomPhrase.content);

      stopwatch.stop();

      // Then: 【結果検証】: 1秒以内に完了することを確認
      // 【期待値確認】: 大量データでもパフォーマンス維持
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      ); // 【確認内容】: 500件でもE2E時間が1秒以内 🟡

      expect(loadedPhrases.length, 500); // 【確認内容】: 500件読み込まれている 🟡
      expect(
        ttsService.state,
        TTSState.speaking,
      ); // 【確認内容】: 読み上げが開始されている 🟡
    });
  });

  group('統合パフォーマンステスト - キャッシュ効果', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_cache_int_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox =
          await Hive.openBox<PresetPhrase>('test_cache_int_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_cache_int_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // =========================================================================
    // キャッシュ効果: 初回 vs 2回目のパフォーマンス比較
    // =========================================================================
    test('キャッシュ効果: 初回と2回目の読み込み時間比較', () async {
      // 【テスト目的】: キャッシュによるパフォーマンス向上を数値で確認
      // 【テスト内容】: 初回と2回目の時間を比較し、2回目が大幅に高速
      // 【期待される動作】: 2回目は初回の10%以下の時間
      // 🟡 黄信号: キャッシュ最適化の効果測定

      // Given: 【テストデータ準備】: 100件の定型文を保存
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'cache-compare-$i',
          content: '比較テスト$i',
          category: 'daily',
          isFavorite: false,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);

      // When: 【実際の処理実行】: 初回と2回目の読み込み時間を計測
      // 初回読み込み
      final firstStopwatch = Stopwatch()..start();
      await repository.loadAll();
      firstStopwatch.stop();

      // 2回目読み込み（キャッシュヒット期待）
      final secondStopwatch = Stopwatch()..start();
      await repository.loadAll();
      secondStopwatch.stop();

      // Then: 【結果検証】: 2回目が大幅に高速であることを確認
      final firstTime = firstStopwatch.elapsedMilliseconds;
      final secondTime = secondStopwatch.elapsedMilliseconds;

      // 【期待値確認】: 2回目は初回より高速（最低でも50%以上の改善を期待）
      // 注意: このテストはキャッシュ実装後のみ成功する
      expect(
        secondTime,
        lessThanOrEqualTo(firstTime ~/ 2),
      ); // 【確認内容】: 2回目は初回の50%以下 🟡

      // キャッシュヒット時は10ms以内であることも確認
      expect(
        secondTime,
        lessThanOrEqualTo(10),
      ); // 【確認内容】: キャッシュヒット時は10ms以内 🟡
    });
  });
}
