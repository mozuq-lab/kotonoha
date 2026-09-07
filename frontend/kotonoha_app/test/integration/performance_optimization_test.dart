/// TTS読み上げと定型文読み込みの統合パフォーマンステスト
/// テストフレームワーク: flutter_test + mocktail + Hive Testing
/// 対象: TTSService、PresetPhraseRepositoryの統合パフォーマンス
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
      // テスト前準備: Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() async {
      // テスト前準備: モックと実Hiveの両方を初期化
      // 環境初期化: 各テストが独立して実行できる環境を構築

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
      // テスト後処理: リソースをクリーンアップ
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_integration_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 統合テスト: 定型文選択から読み上げ開始までのE2Eパフォーマンス
    test('E2E: 定型文選択から読み上げ開始までのパフォーマンス', () async {
      // Given: テストデータ準備: 100件の定型文を保存、TTSを初期化
      // 初期条件設定: ユーザーが定型文画面を開く状況を想定
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'e2e-$i',
          content: '定型文$i',
          category: 'daily',
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);
      await ttsService.initialize();

      // When: 実際の処理実行: 定型文読み込み + 選択した定型文の読み上げ
      // 処理内容: E2Eシナリオを時間計測
      final stopwatch = Stopwatch()..start();

      // 1. 定型文一覧を読み込む
      final loadedPhrases = await repository.loadAll();

      // 2. 最初の定型文を選択して読み上げ
      final selectedPhrase = loadedPhrases.first;
      await ttsService.speak(selectedPhrase.content);

      stopwatch.stop();

      // Then: 結果検証: 1秒以内に読み上げが開始されることを確認
      // 期待値確認: ユーザー体験として許容される遅延
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(loadedPhrases.length, 100);
      expect(
        ttsService.state,
        TTSState.speaking,
      );
    });

    // 統合テスト: 連続操作時のパフォーマンス維持
    test('長文（500文字）でもTTS読み上げ開始が1秒以内', () async {
      // なぜ必要か: 利用者は1文字ずつ入力するため長文を作ることがある。
      // 文字数に比例して開始が遅くなると、待たされたぶんだけ会話が途切れる。
      // 移植元: integration_test/performance_profiling_e2e_test.dart
      // 。CI で一度も実行されていなかったため、動く層へ移した。

      // Given: 500文字のテキストと初期化済みTTS
      await ttsService.initialize();
      final longText = 'あ' * 500;

      // When: 読み上げ開始までの時間を計測
      final stopwatch = Stopwatch()..start();
      await ttsService.speak(longText);
      stopwatch.stop();

      // Then: 1秒以内に開始する
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
        reason: '長文（500文字）でTTS読み上げ開始が1秒を超えた'
            '（${stopwatch.elapsedMilliseconds}ms）',
      );
      expect(ttsService.state, isNot(TTSState.error));
    });

    test('空文字の読み上げ要求でもエラー状態にならず、後続の読み上げができる', () async {
      // なぜ必要か: 利用者は誤タップで空のまま読み上げを押しうる。
      // ここで TTS がエラー状態に落ちると、次の発話までできなくなる——
      // 発話で訂正できない利用者にとって復帰手段が無い。
      // 移植元: integration_test/performance_profiling_e2e_test.dart
      // 。

      // Given: 初期化済みTTS
      await ttsService.initialize();

      // When: 空文字で読み上げを要求する
      await ttsService.speak('');

      // Then: エラー状態にならない
      expect(
        ttsService.state,
        isNot(TTSState.error),
        reason: '空文字の読み上げ要求でTTSがエラー状態に落ちた',
      );

      // Then: 続けて通常の読み上げができる
      await ttsService.speak('みずをください');
      expect(
        ttsService.state,
        isNot(TTSState.error),
        reason: '空文字の要求の後、通常の読み上げができなくなった',
      );
    });

    test('連続操作: 複数の定型文を連続選択・読み上げ', () async {
      // Given: テストデータ準備: 定型文を保存し、TTSを初期化
      // 初期条件設定: キャッシュが構築される状態
      final phrases = List.generate(
        5,
        (i) => PresetPhrase(
          id: 'continuous-$i',
          content: '連続テスト$i',
          category: 'daily',
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);
      await ttsService.initialize();

      // 初回読み込みでキャッシュを構築
      final loadedPhrases = await repository.loadAll();

      // When/Then: 実際の処理実行: 5回連続で選択・読み上げ
      // 処理内容: 各回の時間を計測し、100ms以内であることを確認
      for (int i = 0; i < 5; i++) {
        final stopwatch = Stopwatch()..start();

        // 前の読み上げを停止
        if (ttsService.state == TTSState.speaking) {
          await ttsService.stop();
        }

        // 新しい定型文を読み上げ
        await ttsService.speak(loadedPhrases[i].content);

        stopwatch.stop();

        // 結果検証: 各回100ms以内に開始されることを確認
        expect(
          stopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(100),
        );
      }

      expect(
        ttsService.state,
        TTSState.speaking,
      );
    });

    // 統合テスト: 大量データでのE2Eパフォーマンス
    test('E2E: 500件の定型文からの選択・読み上げパフォーマンス', () async {
      // Given: テストデータ準備: 500件の定型文を保存
      // 初期条件設定: ヘビーユーザーのシナリオ
      final phrases = List.generate(
        500,
        (i) => PresetPhrase(
          id: 'large-e2e-$i',
          content: '大量データテスト$i',
          category: ['daily', 'health', 'other'][i % 3],
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);
      await ttsService.initialize();

      // When: 実際の処理実行: 500件読み込み + 読み上げ
      // 処理内容: 大量データでのE2E時間を計測
      final stopwatch = Stopwatch()..start();

      final loadedPhrases = await repository.loadAll();
      final randomPhrase = loadedPhrases[250]; // 中間のデータを選択
      await ttsService.speak(randomPhrase.content);

      stopwatch.stop();

      // Then: 結果検証: 1秒以内に完了することを確認
      // 期待値確認: 大量データでもパフォーマンス維持
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(loadedPhrases.length, 500);
      expect(
        ttsService.state,
        TTSState.speaking,
      );
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

    // キャッシュ効果: 初回 vs 2回目のパフォーマンス比較
    test('キャッシュ効果: 初回と2回目の読み込み時間比較', () async {
      // Given: テストデータ準備: 100件の定型文を保存
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'cache-compare-$i',
          content: '比較テスト$i',
          category: 'daily',
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await repository.saveAll(phrases);

      // When: 実際の処理実行: 初回と2回目の読み込み時間を計測
      // 初回読み込み
      final firstStopwatch = Stopwatch()..start();
      await repository.loadAll();
      firstStopwatch.stop();

      // 2回目読み込み（キャッシュヒット期待）
      final secondStopwatch = Stopwatch()..start();
      await repository.loadAll();
      secondStopwatch.stop();

      // Then: 結果検証: 2回目が大幅に高速であることを確認
      final firstTime = firstStopwatch.elapsedMilliseconds;
      final secondTime = secondStopwatch.elapsedMilliseconds;

      // 期待値確認: 2回目は初回より高速（最低でも50%以上の改善を期待）
      expect(
        secondTime,
        lessThanOrEqualTo(firstTime ~/ 2),
      );

      // キャッシュヒット時は10ms以内であることも確認
      expect(
        secondTime,
        lessThanOrEqualTo(10),
      );
    });
  });
}
