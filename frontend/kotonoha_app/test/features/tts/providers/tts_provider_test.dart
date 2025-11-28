/// TTSProvider テスト
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// テストケース: TC-048-016〜TC-048-029（境界値・状態管理・モック・リソース管理）
///
/// テスト対象: lib/features/tts/providers/tts_provider.dart
///
/// 【TDD Redフェーズ】: Providerが未実装、テストが失敗するはず
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import '../../../mocks/mock_flutter_tts.dart';

/// TTSNotifierを作成するヘルパー関数（テスト用）
TTSNotifier createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(service: service);
}

void main() {
  group('TTSProvider', () {
    late ProviderContainer container;
    late MockFlutterTts mockFlutterTts;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
    });

    setUp(() {
      // 【テスト前準備】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【環境初期化】: ProviderContainerとモックを作成
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

      container = ProviderContainer(
        overrides: [
          // TTSNotifierにモックされたサービスを注入
          ttsProvider.overrideWith(
              (ref) => createTestTTSNotifier(mockFlutterTts)),
        ],
      );
    });

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄し、メモリリークを防ぐ
      // 【状態復元】: 次のテストに影響しないよう、コンテナを破棄
      container.dispose();
    });

    // =========================================================================
    // 3. 境界値テストケース（続き）
    // =========================================================================
    group('境界値テストケース', () {
      /// TC-048-016: 1000文字のテキストが正常に読み上げられる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-014
      /// 検証内容: 入力バッファの最大文字数（1000文字）での動作確認
      test('TC-048-016: 1000文字のテキストが正常に読み上げられる', () async {
        // 【テスト目的】: 入力バッファの最大文字数（1000文字）での動作確認 🔵
        // 【テスト内容】: 1000文字のテキストで読み上げが正常に動作することを確認
        // 【期待される動作】: 最大長のテキストでも正しく読み上げ処理が開始される
        // 🔵 青信号: requirements.md「TTSService.speak()の制約」（133行目: 最大1000文字）に基づく

        // Given: 【テストデータ準備】: 1000文字のテキストを準備
        // 【初期条件設定】: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        final testText = 'あ' * 1000;

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 1000文字のテキストの読み上げを開始
        await notifier.speak(testText);

        // Then: 【結果検証】: flutter_ttsのspeak()が呼ばれることを確認
        // 【期待値確認】: speak()が呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText))
            .called(1); // 【確認内容】: 1000文字のテキストで読み上げが開始されたことを確認 🔵
        expect(container.read(ttsProvider).state,
            TTSState.speaking); // 【確認内容】: 状態がspeakingになったことを確認 🔵
      });

      /// TC-048-017: 特殊文字（絵文字、記号）が含まれるテキストの読み上げ
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: 通常の文字以外の特殊文字が含まれる場合の動作確認
      test('TC-048-017: 特殊文字（絵文字、記号）が含まれるテキストの読み上げ', () async {
        // 【テスト目的】: 特殊文字（絵文字、記号）が含まれる場合の動作確認 🟡
        // 【テスト内容】: 絵文字と記号を含むテキストで読み上げが正常に動作することを確認
        // 【期待される動作】: 特殊文字を含んでも読み上げ処理が開始される
        // 🟡 黄信号: 既存テスト（input_buffer_provider_test.dart TC-026〜028）の特殊文字テストパターンを踏襲

        // Given: 【テストデータ準備】: 絵文字と記号を含むテキストを準備
        // 【初期条件設定】: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        const testText = 'こんにちは😊！？';

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 特殊文字を含むテキストの読み上げを開始
        await notifier.speak(testText);

        // Then: 【結果検証】: flutter_ttsのspeak()が呼ばれることを確認
        // 【期待値確認】: speak()が呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText))
            .called(1); // 【確認内容】: 特殊文字を含むテキストで読み上げが開始されたことを確認 🟡
        expect(container.read(ttsProvider).state,
            TTSState.speaking); // 【確認内容】: 状態がspeakingになったことを確認 🟡
      });

      /// TC-048-018: 読み上げ速度の境界値（0.7、1.0、1.3）が正しく設定される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-004
      /// 検証内容: 読み上げ速度の最小値（0.7）、標準値（1.0）、最大値（1.3）での動作確認
      test('TC-048-018: 読み上げ速度の境界値（0.7、1.0、1.3）が正しく設定される', () async {
        // 【テスト目的】: 読み上げ速度の境界値（0.7、1.0、1.3）での動作確認 🔵
        // 【テスト内容】: 各速度設定で正しい値が設定されることを確認
        // 【期待される動作】: 定義された速度範囲内で正確に設定される
        // 🔵 青信号: interfaces.dart「TTSSpeed enum」（298-319行目）、requirements.md「速度値」に基づく

        // Given: 【テストデータ準備】: サービスを初期化
        // 【初期条件設定】: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        // モックの呼び出し履歴をクリア（initialize()の呼び出しをリセット）
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: TTSSpeed.slowを設定
        // 【処理内容】: 速度を「遅い」に設定
        await notifier.setSpeed(TTSSpeed.slow);

        // Then: 【結果検証】: setSpeechRate(0.7)が呼ばれることを確認
        verify(() => mockFlutterTts.setSpeechRate(0.7))
            .called(1); // 【確認内容】: 速度0.7が設定されたことを確認 🔵

        // When: 【実際の処理実行】: TTSSpeed.normalを設定
        // 【処理内容】: 速度を「普通」に設定
        await notifier.setSpeed(TTSSpeed.normal);

        // Then: 【結果検証】: setSpeechRate(1.0)が呼ばれることを確認
        verify(() => mockFlutterTts.setSpeechRate(1.0))
            .called(1); // 【確認内容】: 速度1.0が設定されたことを確認 🔵

        // When: 【実際の処理実行】: TTSSpeed.fastを設定
        // 【処理内容】: 速度を「速い」に設定
        await notifier.setSpeed(TTSSpeed.fast);

        // Then: 【結果検証】: setSpeechRate(1.3)が呼ばれることを確認
        verify(() => mockFlutterTts.setSpeechRate(1.3))
            .called(1); // 【確認内容】: 速度1.3が設定されたことを確認 🔵
      });

      /// TC-048-019: 読み上げ中に新しいテキストの読み上げを開始すると前の読み上げが停止する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-2, AC-013
      /// 検証内容: 状態遷移の境界（speaking状態でのspeak()呼び出し）での動作確認
      test('TC-048-019: 読み上げ中に新しいテキストの読み上げを開始すると前の読み上げが停止する', () async {
        // 【テスト目的】: 読み上げ中に新しいテキストの読み上げを開始すると前の読み上げが停止することを確認 🔵
        // 【テスト内容】: 読み上げ中に新規読み上げリクエストが発生した場合、前の読み上げが停止し新しい読み上げが開始されることを確認
        // 【期待される動作】: 前の読み上げが確実に停止し、新しい読み上げが開始される
        // 🔵 青信号: requirements.md「EDGE-2: 読み上げ中に新しいテキストを読み上げ」（468-481行目）に基づく

        // Given: 【テストデータ準備】: サービスを初期化し、1回目の読み上げを開始
        // 【初期条件設定】: サービスが読み上げ中の状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('長いテキストA...');

        // When: 【実際の処理実行】: 読み上げ中に新しいテキストの読み上げを開始
        // 【処理内容】: 前の読み上げを停止してから新しいテキストを読み上げ
        await notifier.speak('新しいテキストB');

        // Then: 【結果検証】: stop()が呼ばれてから新しいspeak()が呼ばれることを確認
        // 【期待値確認】: stop()とspeak('新しいテキストB')が呼ばれる
        verify(() => mockFlutterTts.stop())
            .called(1); // 【確認内容】: 前の読み上げが停止されたことを確認 🔵
        verify(() => mockFlutterTts.speak('新しいテキストB'))
            .called(1); // 【確認内容】: 新しいテキストで読み上げが開始されたことを確認 🔵
        expect(container.read(ttsProvider).state,
            TTSState.speaking); // 【確認内容】: 状態がspeakingのまま維持されていることを確認 🔵
      });
    });

    // =========================================================================
    // 4. 状態管理テストケース（Riverpod StateNotifier）
    // =========================================================================
    group('状態管理テストケース', () {
      /// TC-048-021: TTSProviderが正しく定義されている
      ///
      /// 優先度: P0（必須）
      /// 検証内容: ttsProviderがStateNotifierProvider型であることを確認
      test('TC-048-021: TTSProviderが正しく定義されている', () {
        // 【テスト目的】: ttsProviderがStateNotifierProvider型であることを確認 🔵
        // 【テスト内容】: Providerから状態を読み取れることを確認
        // 【期待される動作】: Providerから状態オブジェクトを読み取れる
        // 🔵 青信号: architecture.md「Riverpod 2.x必須」、既存テストパターンに基づく

        // When: 【実際の処理実行】: ttsProviderの状態を読み取る
        // 【処理内容】: container.read(ttsProvider)で状態を取得
        final state = container.read(ttsProvider);

        // Then: 【結果検証】: 状態オブジェクトが取得できることを確認
        // 【期待値確認】: 状態オブジェクトがTTSServiceState型である
        expect(state,
            isA<TTSServiceState>()); // 【確認内容】: 状態がTTSServiceState型であることを確認 🔵
        expect(state.state, TTSState.idle); // 【確認内容】: 初期状態がidleであることを確認 🔵
      });

      /// TC-048-022: 状態変更がRiverpod stateに即座に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-003
      /// 検証内容: speak()呼び出し時に状態変更がリスナーに通知されることを確認
      test('TC-048-022: 状態変更がRiverpod stateに即座に反映される', () async {
        // 【テスト目的】: speak()呼び出し時に状態変更がリスナーに通知されることを確認 🔵
        // 【テスト内容】: container.listen()で状態監視し、状態変更をキャプチャできることを確認
        // 【期待される動作】: container.listen()で状態変更をキャプチャできる
        // 🔵 青信号: NFR-003（100ms以内応答）、既存テスト（input_buffer_provider_test.dart TC-011）のパターンを踏襲

        // Given: 【テストデータ準備】: 状態変更をキャプチャするリスナーを設定
        // 【初期条件設定】: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        final stateChanges = <TTSState>[];
        container.listen<TTSServiceState>(
          ttsProvider,
          (previous, next) {
            stateChanges.add(next.state);
          },
        );

        // When: 【実際の処理実行】: speak()を呼び出す
        // 【処理内容】: 読み上げを開始し、状態変更を監視
        await notifier.speak('テスト');

        // Then: 【結果検証】: 状態変更リストにspeakingが記録されることを確認
        // 【期待値確認】: idle→speakingの遷移が記録される
        expect(stateChanges,
            contains(TTSState.speaking)); // 【確認内容】: 状態変更がリスナーに通知されたことを確認 🔵
      });
    });

    // =========================================================================
    // 7. モック・スタブテストケース
    // =========================================================================
    group('モック・スタブテストケース', () {
      /// TC-048-025: FlutterTtsがモック化できる
      ///
      /// 優先度: P0（必須）
      /// 検証内容: mocktailを使ってFlutterTtsをモック化し、TTSServiceに注入できることを確認
      test('TC-048-025: FlutterTtsがモック化できる', () async {
        // 【テスト目的】: mocktailを使ってFlutterTtsをモック化し、TTSServiceに注入できることを確認 🔵
        // 【テスト内容】: モックが正しく注入され、メソッド呼び出しをモニタリングできることを確認
        // 【期待される動作】: モックが正しく注入され、メソッド呼び出しをモニタリングできる
        // 🔵 青信号: 既存テスト（emergency_audio_service_test.dart TC-047-006）のパターンを踏襲

        // Given: 【テストデータ準備】: モックを注入したサービスを作成
        // 【初期条件設定】: モック化されたFlutterTtsを持つサービス
        final service = TTSService(tts: mockFlutterTts);

        // Then: 【結果検証】: モックが正しく注入されていることを確認
        expect(mockFlutterTts,
            isA<MockFlutterTts>()); // 【確認内容】: モックがMockFlutterTts型であることを確認 🔵

        // When: 【実際の処理実行】: initialize()を呼び出す
        // 【処理内容】: 初期化を実行
        await service.initialize();

        // Then: 【結果検証】: モックのメソッドが呼び出されることを確認
        verify(() => mockFlutterTts.setLanguage(any()))
            .called(1); // 【確認内容】: モックのメソッドが呼び出されたことを確認 🔵
      });

      /// TC-048-026: FlutterTtsの各メソッドが正しい順序で呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 検証内容: initialize()やspeak()の呼び出し時に、FlutterTtsのメソッドが正しい順序で呼ばれることを確認
      test('TC-048-026: FlutterTtsの各メソッドが正しい順序で呼ばれる', () async {
        // 【テスト目的】: initialize()やspeak()の呼び出し時に、FlutterTtsのメソッドが正しい順序で呼ばれることを確認 🔵
        // 【テスト内容】: setLanguage → setSpeechRate → speak の順で呼び出されることを確認
        // 【期待される動作】: setLanguage → setSpeechRate → speak の順で呼び出される
        // 🔵 青信号: requirements.md「初期化フロー」（189-199行目）、既存テスト（emergency_audio_service_test.dart TC-047-007）のパターンを踏襲

        // Given: 【テストデータ準備】: モックを注入したサービスを作成
        // 【初期条件設定】: モック化されたFlutterTtsを持つサービス
        final service = TTSService(tts: mockFlutterTts);

        // When: 【実際の処理実行】: initialize()とspeak()を呼び出す
        // 【処理内容】: 初期化と読み上げを実行
        await service.initialize();
        await service.speak('テスト');

        // Then: 【結果検証】: メソッドが正しい順序で呼ばれることを確認
        // 【期待値確認】: setLanguage → setSpeechRate → speak の順序
        verifyInOrder([
          () => mockFlutterTts.setLanguage('ja-JP'),
          () => mockFlutterTts.setSpeechRate(1.0),
          () => mockFlutterTts.speak('テスト'),
        ]); // 【確認内容】: メソッドが正しい順序で呼ばれたことを確認 🔵
      });
    });

    // =========================================================================
    // 8. エッジケーステストケース（追加）
    // =========================================================================
    group('エッジケーステストケース', () {
      /// TC-048-028: 連続したstop()呼び出しが安全に処理される
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: stop()を連続で呼び出してもエラーにならないことを確認
      test('TC-048-028: 連続したstop()呼び出しが安全に処理される', () async {
        // 【テスト目的】: stop()を連続で呼び出してもエラーにならないことを確認 🟡
        // 【テスト内容】: stop()を2回連続で呼び出し、エラーが発生しないことを確認
        // 【期待される動作】: 冪等性が保たれ、エラーが発生しない
        // 🟡 黄信号: 防御的プログラミングの原則に基づく

        // Given: 【テストデータ準備】: サービスを初期化し、読み上げを開始
        // 【初期条件設定】: サービスが読み上げ中の状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('テスト');

        // When: 【実際の処理実行】: stop()を2回連続で呼び出す
        // 【処理内容】: 連続してstop()を呼び出す
        await notifier.stop();
        await notifier.stop();

        // Then: 【結果検証】: エラーが発生しないことを確認
        // 【期待値確認】: 状態がstoppedのまま維持される
        expect(container.read(ttsProvider).state,
            TTSState.stopped); // 【確認内容】: 状態がstoppedのまま維持されることを確認 🟡
      });
    });

    // =========================================================================
    // 9. リソース管理テストケース
    // =========================================================================
    group('リソース管理テストケース', () {
      /// TC-048-029: リソース解放時にFlutterTtsがdisposeされる
      ///
      /// 優先度: P0（必須）
      /// 検証内容: TTSService.dispose()を呼ぶと、FlutterTtsのdispose()が呼ばれることを確認
      test('TC-048-029: リソース解放時にFlutterTtsがdisposeされる', () async {
        // 【テスト目的】: TTSService.dispose()を呼ぶと、FlutterTtsのdispose()が呼ばれることを確認 🔵
        // 【テスト内容】: dispose()を呼び出し、FlutterTtsのdispose()が呼ばれることを確認
        // 【期待される動作】: リソースが適切に解放される
        // 🔵 青信号: 既存テスト（emergency_audio_service_test.dart TC-047-009）のパターンを踏襲

        // Given: 【テストデータ準備】: モックを注入したサービスを作成
        // 【初期条件設定】: モック化されたFlutterTtsを持つサービス
        when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
        final service = TTSService(tts: mockFlutterTts);

        // When: 【実際の処理実行】: dispose()を呼び出す
        // 【処理内容】: リソースを解放
        await service.dispose();

        // Then: 【結果検証】: FlutterTtsのstop()が呼ばれることを確認
        // 【期待値確認】: stop()が呼ばれ、リソースが解放される
        verify(() => mockFlutterTts.stop()).called(
            1); // 【確認内容】: stop()が呼ばれたことを確認（FlutterTtsはdispose()の代わりにstop()を使用） 🔵
      });
    });
  });
}
