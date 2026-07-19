/// TTSService テスト
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// テストケース: TC-048-001〜TC-048-015（正常系・異常系・境界値）
///
/// テスト対象: lib/features/tts/domain/services/tts_service.dart
///
/// 【TDD Redフェーズ】: サービスクラスが未実装、テストが失敗するはず
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
      // 【テスト前準備】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【環境初期化】: モックを作成し、デフォルト動作を設定
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

      service = TTSService(tts: mockFlutterTts);
    });

    // =========================================================================
    // 1. 正常系テストケース（基本的な動作）
    // =========================================================================
    group('正常系テストケース', () {
      /// TC-048-001: TTSServiceが正常に初期化される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-401, AC-001
      /// 検証内容: initialize()が成功し、flutter_ttsが正しく初期化されることを確認
      test('TC-048-001: TTSServiceが正常に初期化される', () async {
        // 【テスト目的】: TTSService.initialize()が成功し、flutter_ttsが正しく初期化されることを確認 🔵
        // 【テスト内容】: initialize()を呼び出し、日本語（ja-JP）と標準速度（1.0）が設定されることを確認
        // 【期待される動作】: 初期化が成功し、trueが返される。日本語（ja-JP）と標準速度（1.0）が設定される
        // 🔵 青信号: requirements.md「TTSService.initialize()」セクション（119-126行目）に基づく

        // When: 【実際の処理実行】: initialize()を呼び出す
        // 【処理内容】: flutter_ttsの初期化処理を実行
        final result = await service.initialize();

        // Then: 【結果検証】: 初期化が成功することを確認
        // 【期待値確認】: trueが返され、setLanguage("ja-JP")とsetSpeechRate(1.0)が呼ばれる
        expect(result, isTrue); // 【確認内容】: 初期化が成功したことを確認 🔵
        verify(() => mockFlutterTts.setLanguage('ja-JP'))
            .called(1); // 【確認内容】: 日本語が設定されたことを確認 🔵
        verify(() => mockFlutterTts.setSpeechRate(1.0))
            .called(1); // 【確認内容】: 標準速度が設定されたことを確認 🔵
      });

      /// TC-048-001a: 初期化時にCompletionHandlerが登録される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-401, AC-001
      /// 検証内容: initialize()呼び出し時にsetCompletionHandlerが登録されることを確認
      test('TC-048-001a: 初期化時にCompletionHandlerが登録される', () async {
        // 【テスト目的】: initialize()時にsetCompletionHandlerが呼ばれることを確認 🔵
        // 【テスト内容】: initialize()後、CompletionHandlerが設定されていることを確認
        // 【期待される動作】: setCompletionHandler()が1回呼ばれる
        // 🔵 青信号: 読み上げ完了時にボタン状態を戻す機能の要件に基づく

        // When: 【実際の処理実行】: initialize()を呼び出す
        await service.initialize();

        // Then: 【結果検証】: setCompletionHandlerが呼ばれることを確認
        verify(() => mockFlutterTts.setCompletionHandler(any()))
            .called(1); // 【確認内容】: CompletionHandlerが登録されたことを確認 🔵
      });

      /// TTS-SPEED-RESTORE-FIX: 初期化前に設定された速度を上書きしない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, REQ-5003
      /// 検証内容: initialize()呼び出し前にsetSpeed()で速度が変更されていた場合、
      /// initialize()がその速度を尊重し、標準速度(1.0)で上書きしないことを確認する回帰テスト
      test('TTS-SPEED-RESTORE-FIX: 初期化前に設定された速度をinitialize()が上書きしない', () async {
        // 【テスト目的】: initialize()が現在のcurrentSpeedを尊重し、
        // 無条件に標準速度(1.0)を設定しないことを確認 🔵
        // 【背景】: 従来はinitialize()内でsetSpeechRate(1.0)を無条件に実行していたため、
        // アプリ起動直後に保存済みの速度を先に適用しても、後から初期化が完了すると
        // 標準速度で上書きされてしまう不具合があった。

        // Given: 【テストデータ準備】: 初期化前に速度を「速い」に設定した状態を用意
        await service.setSpeed(TTSSpeed.fast);
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: initialize()を呼び出す（アプリ起動時の初期化を模擬）
        await service.initialize();

        // Then: 【結果検証】: setSpeechRate(1.3)が維持され、1.0への上書きが発生しないことを確認
        verify(() => mockFlutterTts.setSpeechRate(1.3))
            .called(1); // 【確認内容】: 速度が上書きされず維持されたことを確認 🔵
        verifyNever(() => mockFlutterTts
            .setSpeechRate(1.0)); // 【確認内容】: 標準速度への上書きが発生していないことを確認 🔵
        expect(service.currentSpeed,
            TTSSpeed.fast); // 【確認内容】: 内部状態も維持されていることを確認 🔵
      });

      /// TC-048-002: テキストを渡すと読み上げが開始される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-401, AC-002
      /// 検証内容: speak(text)を呼び出すと、指定したテキストの読み上げが開始されることを確認
      test('TC-048-002: テキストを渡すと読み上げが開始される', () async {
        // 【テスト目的】: TTSService.speak(text)を呼び出すと、指定したテキストの読み上げが開始されることを確認 🔵
        // 【テスト内容】: speak('こんにちは')を呼び出し、flutter_ttsのspeak()メソッドが呼ばれることを確認
        // 【期待される動作】: flutter_ttsの`speak(text)`メソッドが呼ばれ、状態が`TTSState.speaking`になる
        // 🔵 青信号: requirements.md「TTSService.speak(String text)」セクション（128-139行目）に基づく

        // Given: 【テストデータ準備】: 読み上げるテキストを準備
        // 【初期条件設定】: サービスが初期化済みの状態
        await service.initialize();
        const testText = 'こんにちは';

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 指定したテキストの読み上げを開始
        await service.speak(testText);

        // Then: 【結果検証】: flutter_ttsのspeak()が呼ばれることを確認
        // 【期待値確認】: speak('こんにちは')が1回呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText))
            .called(1); // 【確認内容】: 指定したテキストで読み上げが開始されたことを確認 🔵
        expect(service.state,
            TTSState.speaking); // 【確認内容】: 状態がspeakingになったことを確認 🔵
      });

      /// TC-048-003: 空文字列の読み上げ試行時は何もしない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-3, AC-005
      /// 検証内容: 空文字列を渡してspeak()を呼んだ場合、読み上げが開始されず、エラーも発生しないことを確認
      test('TC-048-003: 空文字列の読み上げ試行時は何もしない', () async {
        // 【テスト目的】: 空文字列を渡してspeak()を呼んだ場合、読み上げが開始されず、エラーも発生しないことを確認 🔵
        // 【テスト内容】: speak('')を呼び出し、flutter_ttsのspeak()が呼ばれないことを確認
        // 【期待される動作】: flutter_ttsのspeak()が呼ばれず、状態が`TTSState.idle`のまま維持される
        // 🔵 青信号: requirements.md「TTSService.speak()の制約」（133行目）、「EDGE-3: 空文字列の読み上げ試行」（483-489行目）に基づく

        // Given: 【テストデータ準備】: 空文字列を準備
        // 【初期条件設定】: サービスが初期化済み、idle状態
        await service.initialize();

        // When: 【実際の処理実行】: 空文字列でspeak()を呼び出す
        // 【処理内容】: 空文字列の読み上げを試行
        await service.speak('');

        // Then: 【結果検証】: flutter_ttsのspeak()が呼ばれないことを確認
        // 【期待値確認】: speak()が呼ばれず、状態がidleのまま
        verifyNever(() =>
            mockFlutterTts.speak(any())); // 【確認内容】: speak()が呼ばれていないことを確認 🔵
        expect(service.state, TTSState.idle); // 【確認内容】: 状態がidleのままであることを確認 🔵
      });

      /// TC-048-004: 読み上げ中にstop()を呼ぶと停止する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-403, AC-003
      /// 検証内容: 読み上げ中にstop()を呼ぶと、読み上げが即座に停止することを確認
      test('TC-048-004: 読み上げ中にstop()を呼ぶと停止する', () async {
        // 【テスト目的】: 読み上げ中にTTSService.stop()を呼ぶと、読み上げが即座に停止することを確認 🔵
        // 【テスト内容】: 読み上げ開始後にstop()を呼び出し、flutter_ttsのstop()が呼ばれることを確認
        // 【期待される動作】: flutter_ttsの`stop()`メソッドが呼ばれ、状態が`TTSState.stopped`になる
        // 🔵 青信号: requirements.md「TTSService.stop()」セクション（141-145行目）に基づく

        // Given: 【テストデータ準備】: 読み上げ中の状態を作る
        // 【初期条件設定】: サービスが読み上げ中の状態
        await service.initialize();
        await service.speak('長いテキストです');

        // When: 【実際の処理実行】: stop()を呼び出す
        // 【処理内容】: 読み上げを停止
        await service.stop();

        // Then: 【結果検証】: flutter_ttsのstop()が呼ばれることを確認
        // 【期待値確認】: stop()が1回呼ばれ、状態がstoppedになる
        verify(() => mockFlutterTts.stop())
            .called(1); // 【確認内容】: stop()が呼ばれたことを確認 🔵
        expect(
            service.state, TTSState.stopped); // 【確認内容】: 状態がstoppedになったことを確認 🔵
      });

      /// TC-048-005: 読み上げ速度を「遅い」に設定できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, AC-004
      /// 検証内容: setSpeed(TTSSpeed.slow)を呼ぶと、読み上げ速度が0.7に設定されることを確認
      test('TC-048-005: 読み上げ速度を「遅い」に設定できる', () async {
        // 【テスト目的】: TTSService.setSpeed(TTSSpeed.slow)を呼ぶと、読み上げ速度が0.7に設定されることを確認 🔵
        // 【テスト内容】: setSpeed(TTSSpeed.slow)を呼び出し、flutter_ttsのsetSpeechRate(0.7)が呼ばれることを確認
        // 【期待される動作】: flutter_ttsの`setSpeechRate(0.7)`が呼ばれる
        // 🔵 青信号: requirements.md「TTSService.setSpeed()」セクション（148-158行目）、interfaces.dart「TTSSpeed enum」に基づく

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスが初期化済みの状態
        await service.initialize();

        // When: 【実際の処理実行】: setSpeed(TTSSpeed.slow)を呼び出す
        // 【処理内容】: 読み上げ速度を「遅い」に設定
        await service.setSpeed(TTSSpeed.slow);

        // Then: 【結果検証】: flutter_ttsのsetSpeechRate(0.7)が呼ばれることを確認
        // 【期待値確認】: setSpeechRate(0.7)が呼ばれ、currentSpeedがslowになる
        verify(() => mockFlutterTts.setSpeechRate(0.7))
            .called(1); // 【確認内容】: 速度0.7が設定されたことを確認 🔵
        expect(service.currentSpeed,
            TTSSpeed.slow); // 【確認内容】: 内部状態がslowになったことを確認 🔵
      });

      /// TC-048-006: 読み上げ速度を「普通」に設定できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, AC-004
      /// 検証内容: setSpeed(TTSSpeed.normal)を呼ぶと、読み上げ速度が1.0に設定されることを確認
      test('TC-048-006: 読み上げ速度を「普通」に設定できる', () async {
        // 【テスト目的】: TTSService.setSpeed(TTSSpeed.normal)を呼ぶと、読み上げ速度が1.0に設定されることを確認 🔵
        // 【テスト内容】: setSpeed(TTSSpeed.normal)を呼び出し、flutter_ttsのsetSpeechRate(1.0)が呼ばれることを確認
        // 【期待される動作】: flutter_ttsの`setSpeechRate(1.0)`が呼ばれる
        // 🔵 青信号: requirements.md「TTSService.setSpeed()」セクション、interfaces.dartに基づく

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスが初期化済みの状態
        await service.initialize();

        // モックの呼び出し履歴をクリア（initialize()の呼び出しをリセット）
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: setSpeed(TTSSpeed.normal)を呼び出す
        // 【処理内容】: 読み上げ速度を「普通」に設定
        await service.setSpeed(TTSSpeed.normal);

        // Then: 【結果検証】: flutter_ttsのsetSpeechRate(1.0)が呼ばれることを確認
        // 【期待値確認】: setSpeechRate(1.0)が呼ばれ、currentSpeedがnormalになる
        verify(() => mockFlutterTts.setSpeechRate(1.0))
            .called(1); // 【確認内容】: 速度1.0が設定されたことを確認 🔵
        expect(service.currentSpeed,
            TTSSpeed.normal); // 【確認内容】: 内部状態がnormalになったことを確認 🔵
      });

      /// TC-048-007: 読み上げ速度を「速い」に設定できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404, AC-004
      /// 検証内容: setSpeed(TTSSpeed.fast)を呼ぶと、読み上げ速度が1.3に設定されることを確認
      test('TC-048-007: 読み上げ速度を「速い」に設定できる', () async {
        // 【テスト目的】: TTSService.setSpeed(TTSSpeed.fast)を呼ぶと、読み上げ速度が1.3に設定されることを確認 🔵
        // 【テスト内容】: setSpeed(TTSSpeed.fast)を呼び出し、flutter_ttsのsetSpeechRate(1.3)が呼ばれることを確認
        // 【期待される動作】: flutter_ttsの`setSpeechRate(1.3)`が呼ばれる
        // 🔵 青信号: requirements.md「TTSService.setSpeed()」セクション、interfaces.dartに基づく

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスが初期化済みの状態
        await service.initialize();

        // When: 【実際の処理実行】: setSpeed(TTSSpeed.fast)を呼び出す
        // 【処理内容】: 読み上げ速度を「速い」に設定
        await service.setSpeed(TTSSpeed.fast);

        // Then: 【結果検証】: flutter_ttsのsetSpeechRate(1.3)が呼ばれることを確認
        // 【期待値確認】: setSpeechRate(1.3)が呼ばれ、currentSpeedがfastになる
        verify(() => mockFlutterTts.setSpeechRate(1.3))
            .called(1); // 【確認内容】: 速度1.3が設定されたことを確認 🔵
        expect(service.currentSpeed,
            TTSSpeed.fast); // 【確認内容】: 内部状態がfastになったことを確認 🔵
      });

      /// TTC-VS-002: 読み上げ速度を「とても遅い」に設定できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: setSpeed(TTSSpeed.verySlow)を呼ぶと、読み上げ速度が0.5に設定されることを確認
      test('TTC-VS-002: 読み上げ速度を「とても遅い」に設定できる', () async {
        // 【テスト目的】: TTSService.setSpeed(TTSSpeed.verySlow)を呼ぶと、読み上げ速度が0.5に設定されることを確認 🔵
        // 【テスト内容】: setSpeed(TTSSpeed.verySlow)を呼び出し、flutter_ttsのsetSpeechRate(0.5)が呼ばれることを確認
        // 【期待される動作】: flutter_ttsの`setSpeechRate(0.5)`が呼ばれる
        // 🔵 青信号: 既存のsetSpeed()テスト（TC-048-005〜007）と同じパターン

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスが初期化済みの状態
        await service.initialize();

        // When: 【実際の処理実行】: setSpeed(TTSSpeed.verySlow)を呼び出す
        // 【処理内容】: 読み上げ速度を「とても遅い」に設定
        await service.setSpeed(TTSSpeed.verySlow);

        // Then: 【結果検証】: flutter_ttsのsetSpeechRate(0.5)が呼ばれることを確認
        // 【期待値確認】: setSpeechRate(0.5)が呼ばれ、currentSpeedがverySlowになる
        verify(() => mockFlutterTts.setSpeechRate(0.5))
            .called(1); // 【確認内容】: 速度0.5が設定されたことを確認 🔵
        expect(service.currentSpeed,
            TTSSpeed.verySlow); // 【確認内容】: 内部状態がverySlowになったことを確認 🔵
      });

      /// TC-048-008: 状態が正しく遷移する（idle→speaking→completed）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-006
      /// 検証内容: 読み上げ開始から完了までの状態遷移が正しく行われることを確認
      test('TC-048-008: 状態が正しく遷移する（idle→speaking→completed）', () async {
        // 【テスト目的】: 読み上げ開始から完了までの状態遷移が正しく行われることを確認 🔵
        // 【テスト内容】: speak()を呼び出し、状態がidle→speaking→completedと遷移することを確認
        // 【期待される動作】: `idle` → `speaking` → `completed`の順に状態が遷移する
        // 🔵 青信号: requirements.md「TTSService state (TTSState)」セクション（168-176行目）に基づく

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスがidle状態
        await service.initialize();

        // Then: 【結果検証】: 初期状態がidleであることを確認
        expect(service.state, TTSState.idle); // 【確認内容】: 初期状態がidleであることを確認 🔵

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 読み上げを開始
        await service.speak('テスト');

        // Then: 【結果検証】: 読み上げ開始直後の状態を確認
        expect(service.state,
            TTSState.speaking); // 【確認内容】: 状態がspeakingになったことを確認 🔵

        // When: 【実際の処理実行】: 読み上げ完了をシミュレート
        // 【処理内容】: 完了コールバックを発火
        await service.onComplete();

        // Then: 【結果検証】: 完了後の状態を確認
        expect(service.state,
            TTSState.completed); // 【確認内容】: 状態がcompletedになったことを確認 🔵
      });

      /// TC-048-009: 読み上げ完了後にidleに戻る
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-006
      /// 検証内容: 読み上げが完了すると、状態が自動的に`idle`に戻ることを確認
      test('TC-048-009: 読み上げ完了後にidleに戻る', () async {
        // 【テスト目的】: 読み上げが完了すると、状態が自動的に`idle`に戻ることを確認 🔵
        // 【テスト内容】: 読み上げ完了後、状態が自動的にidleに戻ることを確認
        // 【期待される動作】: `completed`状態の後、自動的に`idle`に遷移する
        // 🔵 青信号: requirements.md「状態遷移」（168-176行目）、dataflow.md「読み上げフロー」に基づく

        // Given: 【テストデータ準備】: サービスを初期化し、読み上げを開始
        // 【初期条件設定】: サービスが読み上げ中の状態
        await service.initialize();
        await service.speak('短いテキスト');

        // When: 【実際の処理実行】: 読み上げ完了をシミュレート
        // 【処理内容】: 完了コールバックを発火
        await service.onComplete();

        // Then: 【結果検証】: 完了時にcompletedになることを確認
        expect(service.state,
            TTSState.completed); // 【確認内容】: 一時的にcompletedになることを確認 🔵

        // When: 【実際の処理実行】: 時間経過をシミュレート
        // 【処理内容】: 自動的にidleに戻るのを待つ
        await Future.delayed(const Duration(milliseconds: 100));

        // Then: 【結果検証】: idleに戻ることを確認
        expect(service.state, TTSState.idle); // 【確認内容】: 状態がidleに戻ったことを確認 🔵
      });

      /// TC-048-010: 複数回のspeak()呼び出しで連続読み上げができる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-401
      /// 検証内容: 読み上げ完了後、再度speak()を呼ぶと新しいテキストの読み上げが開始されることを確認
      test('TC-048-010: 複数回のspeak()呼び出しで連続読み上げができる', () async {
        // 【テスト目的】: 読み上げ完了後、再度speak()を呼ぶと新しいテキストの読み上げが開始されることを確認 🔵
        // 【テスト内容】: 1回目の読み上げ完了後、2回目のspeak()が正常に実行されることを確認
        // 【期待される動作】: 1回目の読み上げ完了後、2回目のspeak()が正常に実行される
        // 🔵 青信号: requirements.md「パターン1: 文字入力からの読み上げ」（363-377行目）に基づく

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスがidle状態
        await service.initialize();

        // When: 【実際の処理実行】: 1回目のspeak()を呼び出す
        // 【処理内容】: 最初のテキストの読み上げを開始
        await service.speak('最初のテキスト');
        await service.onComplete();
        await Future.delayed(const Duration(milliseconds: 100));

        // When: 【実際の処理実行】: 2回目のspeak()を呼び出す
        // 【処理内容】: 次のテキストの読み上げを開始
        await service.speak('次のテキスト');

        // Then: 【結果検証】: flutter_ttsのspeak()が合計2回呼ばれることを確認
        // 【期待値確認】: speak()が2回呼ばれ、それぞれ異なるテキストで呼ばれる
        verify(() => mockFlutterTts.speak('最初のテキスト'))
            .called(1); // 【確認内容】: 1回目のspeak()が呼ばれたことを確認 🔵
        verify(() => mockFlutterTts.speak('次のテキスト'))
            .called(1); // 【確認内容】: 2回目のspeak()が呼ばれたことを確認 🔵
      });
    });

    // =========================================================================
    // 2. 異常系テストケース（エラーハンドリング）
    // =========================================================================
    group('異常系テストケース', () {
      /// TC-048-011: TTS初期化失敗時もアプリはクラッシュしない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-4, AC-009, NFR-301
      /// 検証内容: flutter_ttsの初期化が失敗した場合のエラーハンドリングを確認
      test('TC-048-011: TTS初期化失敗時もアプリはクラッシュしない', () async {
        // 【テスト目的】: flutter_ttsの初期化が失敗した場合のエラーハンドリングを確認 🔵
        // 【テスト内容】: setLanguage()が例外をスローする場合、initialize()がfalseを返すことを確認
        // 【期待される動作】: 初期化失敗時もアプリの基本機能（文字盤+テキスト表示）は継続動作する必要がある
        // 🔵 青信号: requirements.md「EDGE-4: TTS初期化失敗」（492-502行目）、NFR-301に基づく

        // Given: 【テストデータ準備】: setLanguage()が例外をスローするように設定
        // 【初期条件設定】: モックで例外をスローする設定
        when(() => mockFlutterTts.setLanguage(any()))
            .thenThrow(Exception('TTS初期化失敗'));

        // When: 【実際の処理実行】: initialize()を呼び出す
        // 【処理内容】: 初期化を試行
        final result = await service.initialize();

        // Then: 【結果検証】: 初期化が失敗することを確認
        // 【期待値確認】: falseが返され、エラーメッセージが設定される
        expect(result, isFalse); // 【確認内容】: 初期化が失敗したことを確認 🔵
        expect(
            service.errorMessage, isNotNull); // 【確認内容】: エラーメッセージが設定されたことを確認 🔵
        expect(service.errorMessage,
            contains('初期化')); // 【確認内容】: エラーメッセージに「初期化」が含まれることを確認 🔵
      });

      /// TC-048-012: 読み上げエラー時もアプリはクラッシュしない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-004, AC-010
      /// 検証内容: 読み上げ中にエラーが発生した場合のエラーハンドリングを確認
      test('TC-048-012: 読み上げエラー時もアプリはクラッシュしない', () async {
        // 【テスト目的】: 読み上げ中にエラーが発生した場合のエラーハンドリングを確認 🔵
        // 【テスト内容】: speak()が例外をスローする場合、状態がerrorになることを確認
        // 【期待される動作】: 読み上げ失敗時もテキスト表示は継続し、履歴に保存される必要がある
        // 🔵 青信号: requirements.md「エラー1: TTS読み上げ中のエラー」（517-539行目）、EDGE-004に基づく

        // Given: 【テストデータ準備】: speak()が例外をスローするように設定
        // 【初期条件設定】: モックで例外をスローする設定
        await service.initialize();
        when(() => mockFlutterTts.speak(any())).thenThrow(Exception('読み上げエラー'));

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 読み上げを試行
        await service.speak('テスト');

        // Then: 【結果検証】: 状態がerrorになることを確認
        // 【期待値確認】: 状態がerrorになり、エラーメッセージが設定される
        expect(service.state, TTSState.error); // 【確認内容】: 状態がerrorになったことを確認 🔵
        expect(
            service.errorMessage, isNotNull); // 【確認内容】: エラーメッセージが設定されたことを確認 🔵
        expect(service.errorMessage,
            contains('読み上げ')); // 【確認内容】: エラーメッセージに「読み上げ」が含まれることを確認 🔵
      });

      /// TC-048-013: 読み上げ中でない状態でstop()を呼んでもエラーにならない
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: idle状態でstop()を呼び出した場合の安全処理を確認
      test('TC-048-013: 読み上げ中でない状態でstop()を呼んでもエラーにならない', () async {
        // 【テスト目的】: idle状態でstop()を呼び出した場合の安全処理を確認 🟡
        // 【テスト内容】: idle状態でstop()を呼び出し、エラーが発生しないことを確認
        // 【期待される動作】: エラーが発生しない、状態はidleのまま変化しない
        // 🟡 黄信号: 既存テスト（input_buffer_provider_test.dart TC-013）の安全処理パターンを踏襲

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスがidle状態
        await service.initialize();

        // When: 【実際の処理実行】: stop()を呼び出す
        // 【処理内容】: idle状態でstop()を呼び出す
        // Then: 【結果検証】: エラーが発生しないことを確認
        // 【期待値確認】: 例外がスローされず、状態がidleのまま
        expect(
            () => service.stop(), returnsNormally); // 【確認内容】: エラーが発生しないことを確認 🟡
        expect(service.state, TTSState.idle); // 【確認内容】: 状態がidleのままであることを確認 🟡
      });

      /// TC-048-014: 初期化前にspeak()を呼ぶと自動初期化される
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: initialize()を呼ばずにspeak()を呼び出した場合、自動初期化されることを確認
      test('TC-048-014: 初期化前にspeak()を呼ぶと自動初期化される', () async {
        // 【テスト目的】: initialize()を呼ばずにspeak()を呼び出した場合、自動初期化されることを確認 🟡
        // 【テスト内容】: 初期化前にspeak()を呼び出し、自動初期化されて読み上げが開始されることを確認
        // 【期待される動作】: 自動初期化が実行され、正常に読み上げが開始される
        // 🟡 黄信号: NFR-301（基本機能は継続動作）の原則を適用

        // When: 【実際の処理実行】: 初期化せずにspeak()を呼び出す
        // 【処理内容】: 初期化前に読み上げを試行（自動初期化が実行される）
        await service.speak('テスト');

        // Then: 【結果検証】: 自動初期化が実行され、読み上げが開始されることを確認
        // 【期待値確認】: 状態がspeakingになり、setLanguageとspeakが呼ばれる
        expect(service.state,
            TTSState.speaking); // 【確認内容】: 自動初期化後にspeaking状態になることを確認 🟡
        verify(() => mockFlutterTts.setLanguage('ja-JP'))
            .called(1); // 【確認内容】: 自動初期化で日本語が設定されたことを確認 🟡
        verify(() => mockFlutterTts.speak('テスト'))
            .called(1); // 【確認内容】: 読み上げが実行されたことを確認 🟡
      });
    });

    // =========================================================================
    // 3. 境界値テストケース（最小値、最大値、null等）
    // =========================================================================
    group('境界値テストケース', () {
      /// TC-048-015: 1文字のテキストが正常に読み上げられる
      ///
      /// 優先度: P0（必須）
      /// 検証内容: テキスト長の最小値（1文字）での動作確認
      test('TC-048-015: 1文字のテキストが正常に読み上げられる', () async {
        // 【テスト目的】: テキスト長の最小値（1文字）での動作確認 🔵
        // 【テスト内容】: 1文字のテキストで読み上げが正常に動作することを確認
        // 【期待される動作】: 1文字でも正しく読み上げ処理が開始される
        // 🔵 青信号: requirements.md「基本的な使用パターン」に基づく

        // Given: 【テストデータ準備】: 1文字のテキストを準備
        // 【初期条件設定】: サービスが初期化済みの状態
        await service.initialize();
        const testText = 'あ';

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 1文字のテキストの読み上げを開始
        await service.speak(testText);

        // Then: 【結果検証】: flutter_ttsのspeak()が呼ばれることを確認
        // 【期待値確認】: speak('あ')が呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText))
            .called(1); // 【確認内容】: 1文字でも読み上げが開始されたことを確認 🔵
        expect(service.state,
            TTSState.speaking); // 【確認内容】: 状態がspeakingになったことを確認 🔵
      });
    });
  });
}
