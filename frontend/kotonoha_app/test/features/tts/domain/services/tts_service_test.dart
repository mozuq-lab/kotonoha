/// TTSService テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import '../../../../mocks/mock_flutter_tts.dart';

void main() {
  group('TTSService', () {
    late MockFlutterTts mockFlutterTts;
    late TTSService service;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(() {}); // VoidCallback用
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

    group('正常系テストケース', () {
      /// TTSServiceが正常に初期化される
      test('TC-048-001: TTSServiceが正常に初期化される', () async {
        // When: 実際の処理実行: initializeを呼び出す
        // 処理内容: flutter_ttsの初期化処理を実行
        final result = await service.initialize();

        // Then: 結果検証: 初期化が成功することを確認
        // trueが返され、setLanguage("ja-JP")とsetSpeechRate(1.0)が呼ばれる
        expect(result, isTrue);
        verify(() => mockFlutterTts.setLanguage('ja-JP')).called(1);
        verify(() => mockFlutterTts.setSpeechRate(1.0)).called(1);
      });

      /// 初期化時にCompletionHandlerが登録される
      test('TC-048-001a: 初期化時にCompletionHandlerが登録される', () async {
        // When: 実際の処理実行: initializeを呼び出す
        await service.initialize();

        // Then: 結果検証: setCompletionHandlerが呼ばれることを確認
        verify(() => mockFlutterTts.setCompletionHandler(any())).called(1);
      });

      /// TTS-SPEED-RESTORE-FIX: 初期化前に設定された速度を上書きしない
      test('TTS-SPEED-RESTORE-FIX: 初期化前に設定された速度をinitialize()が上書きしない', () async {
        // Given: テストデータ準備: 初期化前に速度を「速い」に設定した状態を用意
        await service.setSpeed(TTSSpeed.fast);
        clearInteractions(mockFlutterTts);

        // When: 実際の処理実行: initializeを呼び出す（アプリ起動時の初期化を模擬）
        await service.initialize();

        // Then: 結果検証: setSpeechRate(1.3)が維持され、1.0への上書きが発生しないことを確認
        verify(() => mockFlutterTts.setSpeechRate(1.3)).called(1);
        verifyNever(() => mockFlutterTts.setSpeechRate(1.0));
        expect(service.currentSpeed, TTSSpeed.fast);
      });

      /// テキストを渡すと読み上げが開始される
      test('TC-048-002: テキストを渡すと読み上げが開始される', () async {
        // Given: テストデータ準備: 読み上げるテキストを準備
        // 初期条件設定: サービスが初期化済みの状態
        await service.initialize();
        const testText = 'こんにちは';

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 指定したテキストの読み上げを開始
        await service.speak(testText);

        // Then: 結果検証: flutter_ttsのspeakが呼ばれることを確認
        // speak('こんにちは')が1回呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText)).called(1);
        expect(service.state, TTSState.speaking);
      });

      /// 空文字列の読み上げ試行時は何もしない
      test('TC-048-003: 空文字列の読み上げ試行時は何もしない', () async {
        // Given: テストデータ準備: 空文字列を準備
        // 初期条件設定: サービスが初期化済み、idle状態
        await service.initialize();

        // When: 実際の処理実行: 空文字列でspeakを呼び出す
        // 処理内容: 空文字列の読み上げを試行
        await service.speak('');

        // Then: 結果検証: flutter_ttsのspeakが呼ばれないことを確認
        // speakが呼ばれず、状態がidleのまま
        verifyNever(() => mockFlutterTts.speak(any()));
        expect(service.state, TTSState.idle);
      });

      /// 読み上げ中にstopを呼ぶと停止する
      test('TC-048-004: 読み上げ中にstop()を呼ぶと停止する', () async {
        // Given: テストデータ準備: 読み上げ中の状態を作る
        // 初期条件設定: サービスが読み上げ中の状態
        await service.initialize();
        await service.speak('長いテキストです');

        // When: 実際の処理実行: stopを呼び出す
        // 処理内容: 読み上げを停止
        await service.stop();

        // Then: 結果検証: flutter_ttsのstopが呼ばれることを確認
        // stopが1回呼ばれ、状態がstoppedになる
        verify(() => mockFlutterTts.stop()).called(1);
        expect(service.state, TTSState.stopped);
      });

      /// 読み上げ速度を「遅い」に設定できる
      test('TC-048-005: 読み上げ速度を「遅い」に設定できる', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスが初期化済みの状態
        await service.initialize();

        // When: 実際の処理実行: setSpeed(TTSSpeed.slow)を呼び出す
        // 処理内容: 読み上げ速度を「遅い」に設定
        await service.setSpeed(TTSSpeed.slow);

        // Then: 結果検証: flutter_ttsのsetSpeechRate(0.7)が呼ばれることを確認
        // setSpeechRate(0.7)が呼ばれ、currentSpeedがslowになる
        verify(() => mockFlutterTts.setSpeechRate(0.7)).called(1);
        expect(service.currentSpeed, TTSSpeed.slow);
      });

      /// 読み上げ速度を「普通」に設定できる
      test('TC-048-006: 読み上げ速度を「普通」に設定できる', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスが初期化済みの状態
        await service.initialize();

        // モックの呼び出し履歴をクリア（initializeの呼び出しをリセット）
        clearInteractions(mockFlutterTts);

        // When: 実際の処理実行: setSpeed(TTSSpeed.normal)を呼び出す
        // 処理内容: 読み上げ速度を「普通」に設定
        await service.setSpeed(TTSSpeed.normal);

        // Then: 結果検証: flutter_ttsのsetSpeechRate(1.0)が呼ばれることを確認
        // setSpeechRate(1.0)が呼ばれ、currentSpeedがnormalになる
        verify(() => mockFlutterTts.setSpeechRate(1.0)).called(1);
        expect(service.currentSpeed, TTSSpeed.normal);
      });

      /// 読み上げ速度を「速い」に設定できる
      test('TC-048-007: 読み上げ速度を「速い」に設定できる', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスが初期化済みの状態
        await service.initialize();

        // When: 実際の処理実行: setSpeed(TTSSpeed.fast)を呼び出す
        // 処理内容: 読み上げ速度を「速い」に設定
        await service.setSpeed(TTSSpeed.fast);

        // Then: 結果検証: flutter_ttsのsetSpeechRate(1.3)が呼ばれることを確認
        // setSpeechRate(1.3)が呼ばれ、currentSpeedがfastになる
        verify(() => mockFlutterTts.setSpeechRate(1.3)).called(1);
        expect(service.currentSpeed, TTSSpeed.fast);
      });

      /// 読み上げ速度を「とても遅い」に設定できる
      test('TTC-VS-002: 読み上げ速度を「とても遅い」に設定できる', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスが初期化済みの状態
        await service.initialize();

        // When: 実際の処理実行: setSpeed(TTSSpeed.verySlow)を呼び出す
        // 処理内容: 読み上げ速度を「とても遅い」に設定
        await service.setSpeed(TTSSpeed.verySlow);

        // Then: 結果検証: flutter_ttsのsetSpeechRate(0.5)が呼ばれることを確認
        // setSpeechRate(0.5)が呼ばれ、currentSpeedがverySlowになる
        verify(() => mockFlutterTts.setSpeechRate(0.5)).called(1);
        expect(service.currentSpeed, TTSSpeed.verySlow);
      });

      /// 状態が正しく遷移する（idle→speaking→completed）
      test('TC-048-008: 状態が正しく遷移する（idle→speaking→completed）', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスがidle状態
        await service.initialize();

        // Then: 結果検証: 初期状態がidleであることを確認
        expect(service.state, TTSState.idle);

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 読み上げを開始
        await service.speak('テスト');

        // Then: 結果検証: 読み上げ開始直後の状態を確認
        expect(service.state, TTSState.speaking);

        // When: 実際の処理実行: 読み上げ完了をシミュレート
        // 処理内容: 完了コールバックを発火
        await service.onComplete();

        // Then: 結果検証: 完了後の状態を確認
        expect(service.state, TTSState.completed);
      });

      /// 読み上げ完了後にidleに戻る
      test('TC-048-009: 読み上げ完了後にidleに戻る', () async {
        // Given: テストデータ準備: サービスを初期化し、読み上げを開始
        // 初期条件設定: サービスが読み上げ中の状態
        await service.initialize();
        await service.speak('短いテキスト');

        // When: 実際の処理実行: 読み上げ完了をシミュレート
        // 処理内容: 完了コールバックを発火
        await service.onComplete();

        // Then: 結果検証: 完了時にcompletedになることを確認
        expect(service.state, TTSState.completed);

        // When: 実際の処理実行: 時間経過をシミュレート
        // 処理内容: 自動的にidleに戻るのを待つ
        await Future.delayed(const Duration(milliseconds: 100));

        // Then: 結果検証: idleに戻ることを確認
        expect(service.state, TTSState.idle);
      });

      /// 複数回のspeak呼び出しで連続読み上げができる
      test('TC-048-010: 複数回のspeak()呼び出しで連続読み上げができる', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスがidle状態
        await service.initialize();

        // When: 実際の処理実行: 1回目のspeakを呼び出す
        // 処理内容: 最初のテキストの読み上げを開始
        await service.speak('最初のテキスト');
        await service.onComplete();
        await Future.delayed(const Duration(milliseconds: 100));

        // When: 実際の処理実行: 2回目のspeakを呼び出す
        // 処理内容: 次のテキストの読み上げを開始
        await service.speak('次のテキスト');

        // Then: 結果検証: flutter_ttsのspeakが合計2回呼ばれることを確認
        // speakが2回呼ばれ、それぞれ異なるテキストで呼ばれる
        verify(() => mockFlutterTts.speak('最初のテキスト')).called(1);
        verify(() => mockFlutterTts.speak('次のテキスト')).called(1);
      });
    });

    group('異常系テストケース', () {
      /// TTS初期化失敗時もアプリはクラッシュしない
      test('TC-048-011: TTS初期化失敗時もアプリはクラッシュしない', () async {
        // Given: テストデータ準備: setLanguageが例外をスローするように設定
        // 初期条件設定: モックで例外をスローする設定
        when(() => mockFlutterTts.setLanguage(any()))
            .thenThrow(Exception('TTS初期化失敗'));

        // When: 実際の処理実行: initializeを呼び出す
        // 処理内容: 初期化を試行
        final result = await service.initialize();

        // Then: 結果検証: 初期化が失敗することを確認
        // falseが返され、エラーメッセージが設定される
        expect(result, isFalse);
        expect(service.errorMessage, isNotNull);
        expect(service.errorMessage, contains('初期化'));
      });

      /// 読み上げエラー時もアプリはクラッシュしない
      test('TC-048-012: 読み上げエラー時もアプリはクラッシュしない', () async {
        // Given: テストデータ準備: speakが例外をスローするように設定
        // 初期条件設定: モックで例外をスローする設定
        await service.initialize();
        when(() => mockFlutterTts.speak(any())).thenThrow(Exception('読み上げエラー'));

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 読み上げを試行
        await service.speak('テスト');

        // Then: 結果検証: 状態がerrorになることを確認
        // 状態がerrorになり、エラーメッセージが設定される
        expect(service.state, TTSState.error);
        expect(service.errorMessage, isNotNull);
        expect(service.errorMessage, contains('読み上げ'));
      });

      /// 読み上げ中でない状態でstopを呼んでもエラーにならない
      test('TC-048-013: 読み上げ中でない状態でstop()を呼んでもエラーにならない', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスがidle状態
        await service.initialize();

        // When: 実際の処理実行: stopを呼び出す
        // 処理内容: idle状態でstopを呼び出す
        // Then: 結果検証: エラーが発生しないことを確認
        // 例外がスローされず、状態がidleのまま
        expect(() => service.stop(), returnsNormally);
        expect(service.state, TTSState.idle);
      });

      /// 初期化前にspeakを呼ぶと自動初期化される
      test('TC-048-014: 初期化前にspeak()を呼ぶと自動初期化される', () async {
        // When: 実際の処理実行: 初期化せずにspeakを呼び出す
        // 処理内容: 初期化前に読み上げを試行（自動初期化が実行される）
        await service.speak('テスト');

        // Then: 結果検証: 自動初期化が実行され、読み上げが開始されることを確認
        // 状態がspeakingになり、setLanguageとspeakが呼ばれる
        expect(service.state, TTSState.speaking);
        verify(() => mockFlutterTts.setLanguage('ja-JP')).called(1);
        verify(() => mockFlutterTts.speak('テスト')).called(1);
      });
    });

    group('境界値テストケース', () {
      /// 1文字のテキストが正常に読み上げられる
      test('TC-048-015: 1文字のテキストが正常に読み上げられる', () async {
        // Given: テストデータ準備: 1文字のテキストを準備
        // 初期条件設定: サービスが初期化済みの状態
        await service.initialize();
        const testText = 'あ';

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 1文字のテキストの読み上げを開始
        await service.speak(testText);

        // Then: 結果検証: flutter_ttsのspeakが呼ばれることを確認
        // speak('あ')が呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText)).called(1);
        expect(service.state, TTSState.speaking);
      });
    });
  });
}
