library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import '../../../../mocks/mock_flutter_tts.dart';

void main() {
  group('TTSService最適化テスト - 正常系', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      // テスト前準備: Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      // テスト前準備: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 環境初期化: モックを作成し、デフォルト動作を設定
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

      service = TTSService(tts: mockFlutterTts);
    });

    // TTS事前初期化がバックグラウンドで実行される
    test('TC-090-001: TTS事前初期化のバックグラウンド実行確認', () async {
      // Given: テストデータ準備: モックでの初期化追跡用
      // 初期条件設定: TTSNotifierを作成してバックグラウンド初期化を開始

      // When: 実際の処理実行: TTSNotifierをProviderContainer経由で作成
      // 処理内容: buildでバックグラウンド初期化が開始されるはず
      final container = ProviderContainer(
        overrides: [
          ttsProvider.overrideWith(() => TTSNotifier(
                serviceOverride: TTSService(
                  tts: mockFlutterTts,
                  onStateChanged: () {},
                ),
              )),
        ],
      );
      // Notifierのbuildを呼び出すためにreadする
      container.read(ttsProvider);

      // 待機: バックグラウンド初期化が完了するのを待つ
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: 結果検証: 初期化が自動的に実行されていることを確認
      // setLanguageが呼ばれている = 初期化が実行された
      verify(() => mockFlutterTts.setLanguage('ja-JP')).called(1);

      container.dispose();
    });

    // 事前初期化後の読み上げ開始時間が1秒以内
    test('TC-090-002: TTS読み上げ開始時間の計測（事前初期化済み）', () async {
      // Given: テストデータ準備: サービスを事前に初期化
      // 初期条件設定: TTSServiceが初期化済みの状態
      await service.initialize();
      const testText = 'こんにちは';

      // When: 実際の処理実行: speakを呼び出して時間を計測
      // 処理内容: Stopwatchで読み上げ開始時間を計測
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 結果検証: 1秒以内に読み上げが開始されることを確認
      // 経過時間が1000ms以内
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(
        service.state,
        TTSState.speaking,
      );
    });

    // 初期化前でも読み上げが1秒以内に開始される
    test('TC-090-003: TTS自動初期化込みの読み上げ開始時間計測', () async {
      // Given: テストデータ準備: 未初期化のTTSService
      // 初期条件設定: initializeを呼ばない状態
      const testText = 'テスト';

      // When: 実際の処理実行: 未初期化状態からspeakを呼び出して時間を計測
      // 処理内容: 自動初期化を含むトータル時間を計測
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 結果検証: 自動初期化込みで1秒以内に開始されることを確認
      // 自動初期化のオーバーヘッドを含めても1秒以内
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(
        service.state,
        TTSState.speaking,
      );
    });

    // 連続読み上げで2回目以降は即座に開始される
    test('TC-090-004: 連続読み上げのパフォーマンス確認', () async {
      // Given: テストデータ準備: サービスを初期化して1回目の読み上げを実行
      // 初期条件設定: 1回目の読み上げが完了した状態
      await service.initialize();
      await service.speak('最初');
      await service.onComplete();
      await Future.delayed(const Duration(milliseconds: 150));

      // When: 実際の処理実行: 2回目のspeakを呼び出して時間を計測
      // 処理内容: 初期化済み状態での2回目の読み上げ
      final stopwatch = Stopwatch()..start();
      await service.speak('次');
      stopwatch.stop();

      // Then: 結果検証: 2回目は100ms以内に開始されることを確認
      // 初期化済みのためオーバーヘッドなし
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(100),
      );

      expect(
        service.state,
        TTSState.speaking,
      );
    });
  });

  group('TTSService最適化テスト - 異常系', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
      service = TTSService(tts: mockFlutterTts);
    });

    // TTS初期化失敗時も読み上げが安全に失敗する
    test('TC-090-009: TTS初期化失敗時のエラーハンドリング', () async {
      // Given: テストデータ準備: setLanguageがExceptionをスロー
      // 初期条件設定: モックで例外をスロー
      when(() => mockFlutterTts.setLanguage(any()))
          .thenThrow(Exception('TTS初期化失敗'));

      // When: 実際の処理実行: initializeを呼び出す
      // 処理内容: 初期化を試行
      final result = await service.initialize();

      // Then: 結果検証: 初期化が失敗し、エラー状態になることを確認
      // falseが返され、エラーメッセージが設定される
      expect(result, isFalse);
      expect(
        service.errorMessage,
        isNotNull,
      );
      expect(
        service.errorMessage,
        contains('初期化'),
      );
    });

    // 初期化未完了時のspeak呼び出しは待機後に実行
    test('TC-090-011: 初期化中のspeak()呼び出し処理', () async {
      // Given: テストデータ準備: 初期化に時間がかかる状況を模擬
      // 初期条件設定: setLanguageを遅延させる
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 1;
      });

      // When: 実際の処理実行: 初期化開始直後にspeakを呼び出す
      // 処理内容: 並行して初期化とspeakを実行

      // 初期化を開始（完了を待たない）
      final initFuture = service.initialize();

      // 少し待ってからspeakを呼び出す
      await Future.delayed(const Duration(milliseconds: 10));
      await service.speak('テスト');

      // 初期化の完了を待つ
      await initFuture;

      // Then: 結果検証: 競合状態なく正常に処理されることを確認
      // 状態がspeakingになり、読み上げが実行される
      expect(
        service.state,
        TTSState.speaking,
      );

      verify(
        () => mockFlutterTts.speak('テスト'),
      ).called(1);
    });
  });

  group('TTSService最適化テスト - 境界値', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
      service = TTSService(tts: mockFlutterTts);
    });

    // 1文字テキストの読み上げ開始時間
    test('TC-090-014: 最小テキストでの読み上げ開始時間', () async {
      // Given: テストデータ準備: 1文字のテキスト
      // 初期条件設定: サービスが初期化済みの状態
      await service.initialize();
      const testText = 'あ';

      // When: 実際の処理実行: 1文字テキストで読み上げ時間を計測
      // 処理内容: 短いテキストでのパフォーマンスを検証
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 結果検証: 1秒以内に読み上げが開始されることを確認
      // 短いテキストでも遅延なし
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(
        service.state,
        TTSState.speaking,
      );
    });

    // 1000文字テキストの読み上げ開始時間
    test('TC-090-015: 最大テキストでの読み上げ開始時間', () async {
      // Given: テストデータ準備: 1000文字のテキスト
      // 初期条件設定: サービスが初期化済みの状態
      await service.initialize();
      final testText = 'あ' * 1000;

      // When: 実際の処理実行: 1000文字テキストで読み上げ時間を計測
      // 処理内容: 長文でのパフォーマンスを検証
      final stopwatch = Stopwatch()..start();
      await service.speak(testText);
      stopwatch.stop();

      // Then: 結果検証: 1秒以内に読み上げが開始されることを確認
      // 長文でも短いテキストと同等の開始時間
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(1000),
      );

      expect(
        service.state,
        TTSState.speaking,
      );
    });
  });

  group('TTSNotifier最適化テスト - 事前初期化', () {
    late MockFlutterTts mockFlutterTts;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {});
    });

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    // TTSNotifier生成時にinitializeが自動実行される
    test('TC-090-001a: TTSNotifier生成時にバックグラウンド初期化が開始される', () async {
      // Given: テストデータ準備: 初期化追跡用のモック設定
      // 初期条件設定: モックが設定済み

      // When: 実際の処理実行: TTSNotifierをProviderContainer経由で生成
      // 処理内容: buildでバックグラウンド初期化が開始されるはず
      final service = TTSService(
        tts: mockFlutterTts,
        onStateChanged: () {},
      );
      final container = ProviderContainer(
        overrides: [
          ttsProvider.overrideWith(() => TTSNotifier(serviceOverride: service)),
        ],
      );
      container.read(ttsProvider);

      // バックグラウンド初期化が完了するのを待つ
      await Future.delayed(const Duration(milliseconds: 200));

      // Then: 結果検証: 初期化が自動実行されることを確認
      // setLanguageとsetSpeechRateが呼ばれる
      verify(
        () => mockFlutterTts.setLanguage('ja-JP'),
      ).called(1);

      verify(
        () => mockFlutterTts.setSpeechRate(1.0),
      ).called(1);

      container.dispose();
    });
  });
}
