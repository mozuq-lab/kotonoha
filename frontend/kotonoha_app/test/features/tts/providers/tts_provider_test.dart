/// TTSProvider テスト
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
  return TTSNotifier(serviceOverride: service);
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
      // テスト前準備: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 環境初期化: ProviderContainerとモックを作成
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
          ttsProvider.overrideWith(() => createTestTTSNotifier(mockFlutterTts)),
        ],
      );
    });

    tearDown(() {
      // テスト後処理: ProviderContainerを破棄し、メモリリークを防ぐ
      // 状態復元: 次のテストに影響しないよう、コンテナを破棄
      container.dispose();
    });

    group('境界値テストケース', () {
      /// 1000文字のテキストが正常に読み上げられる
      test('TC-048-016: 1000文字のテキストが正常に読み上げられる', () async {
        // Given: テストデータ準備: 1000文字のテキストを準備
        // 初期条件設定: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        final testText = 'あ' * 1000;

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 1000文字のテキストの読み上げを開始
        await notifier.speak(testText);

        // Then: 結果検証: flutter_ttsのspeakが呼ばれることを確認
        // speakが呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText)).called(1);
        expect(container.read(ttsProvider).state, TTSState.speaking);
      });

      /// 特殊文字（絵文字、記号）が含まれるテキストの読み上げ
      test('TC-048-017: 特殊文字（絵文字、記号）が含まれるテキストの読み上げ', () async {
        // Given: テストデータ準備: 絵文字と記号を含むテキストを準備
        // 初期条件設定: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        const testText = 'こんにちは😊！？';

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 特殊文字を含むテキストの読み上げを開始
        await notifier.speak(testText);

        // Then: 結果検証: flutter_ttsのspeakが呼ばれることを確認
        // speakが呼ばれ、状態がspeakingになる
        verify(() => mockFlutterTts.speak(testText)).called(1);
        expect(container.read(ttsProvider).state, TTSState.speaking);
      });

      /// 読み上げ速度の境界値（0.7、1.0、1.3）が正しく設定される
      test('TC-048-018: 読み上げ速度の境界値（0.7、1.0、1.3）が正しく設定される', () async {
        // Given: テストデータ準備: サービスを初期化
        // 初期条件設定: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        // モックの呼び出し履歴をクリア（initializeの呼び出しをリセット）
        clearInteractions(mockFlutterTts);

        // When: 実際の処理実行: TTSSpeed.slowを設定
        // 処理内容: 速度を「遅い」に設定
        await notifier.setSpeed(TTSSpeed.slow);

        // Then: 結果検証: setSpeechRate(0.7)が呼ばれることを確認
        verify(() => mockFlutterTts.setSpeechRate(0.7)).called(1);

        // When: 実際の処理実行: TTSSpeed.normalを設定
        // 処理内容: 速度を「普通」に設定
        await notifier.setSpeed(TTSSpeed.normal);

        // Then: 結果検証: setSpeechRate(1.0)が呼ばれることを確認
        verify(() => mockFlutterTts.setSpeechRate(1.0)).called(1);

        // When: 実際の処理実行: TTSSpeed.fastを設定
        // 処理内容: 速度を「速い」に設定
        await notifier.setSpeed(TTSSpeed.fast);

        // Then: 結果検証: setSpeechRate(1.3)が呼ばれることを確認
        verify(() => mockFlutterTts.setSpeechRate(1.3)).called(1);
      });

      /// 読み上げ中に新しいテキストの読み上げを開始すると前の読み上げが停止する
      test('TC-048-019: 読み上げ中に新しいテキストの読み上げを開始すると前の読み上げが停止する', () async {
        // Given: テストデータ準備: サービスを初期化し、1回目の読み上げを開始
        // 初期条件設定: サービスが読み上げ中の状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('長いテキストA...');

        // When: 実際の処理実行: 読み上げ中に新しいテキストの読み上げを開始
        // 処理内容: 前の読み上げを停止してから新しいテキストを読み上げ
        await notifier.speak('新しいテキストB');

        // Then: 結果検証: stopが呼ばれてから新しいspeakが呼ばれることを確認
        // stopとspeak('新しいテキストB')が呼ばれる
        verify(() => mockFlutterTts.stop()).called(1);
        verify(() => mockFlutterTts.speak('新しいテキストB')).called(1);
        expect(container.read(ttsProvider).state, TTSState.speaking);
      });
    });

    group('状態管理テストケース', () {
      /// TTSProviderが正しく定義されている
      test('TC-048-021: TTSProviderが正しく定義されている', () {
        // When: 実際の処理実行: ttsProviderの状態を読み取る
        // 処理内容: container.read(ttsProvider)で状態を取得
        final state = container.read(ttsProvider);

        // Then: 結果検証: 状態オブジェクトが取得できることを確認
        // 状態オブジェクトがTTSServiceState型である
        expect(state, isA<TTSServiceState>());
        expect(state.state, TTSState.idle);
      });

      /// 状態変更がRiverpod stateに即座に反映される
      test('TC-048-022: 状態変更がRiverpod stateに即座に反映される', () async {
        // Given: テストデータ準備: 状態変更をキャプチャするリスナーを設定
        // 初期条件設定: サービスが初期化済みの状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();

        final stateChanges = <TTSState>[];
        container.listen<TTSServiceState>(
          ttsProvider,
          (previous, next) {
            stateChanges.add(next.state);
          },
        );

        // When: 実際の処理実行: speakを呼び出す
        // 処理内容: 読み上げを開始し、状態変更を監視
        await notifier.speak('テスト');

        // Then: 結果検証: 状態変更リストにspeakingが記録されることを確認
        // idle→speakingの遷移が記録される
        expect(stateChanges, contains(TTSState.speaking));
      });
    });

    // 7. モック・スタブテストケース
    group('モック・スタブテストケース', () {
      /// FlutterTtsがモック化できる
      test('TC-048-025: FlutterTtsがモック化できる', () async {
        // Given: テストデータ準備: モックを注入したサービスを作成
        // 初期条件設定: モック化されたFlutterTtsを持つサービス
        final service = TTSService(tts: mockFlutterTts);

        // Then: 結果検証: モックが正しく注入されていることを確認
        expect(mockFlutterTts, isA<MockFlutterTts>());

        // When: 実際の処理実行: initializeを呼び出す
        // 処理内容: 初期化を実行
        await service.initialize();

        // Then: 結果検証: モックのメソッドが呼び出されることを確認
        verify(() => mockFlutterTts.setLanguage(any())).called(1);
      });

      /// FlutterTtsの各メソッドが正しい順序で呼ばれる
      test('TC-048-026: FlutterTtsの各メソッドが正しい順序で呼ばれる', () async {
        // Given: テストデータ準備: モックを注入したサービスを作成
        // 初期条件設定: モック化されたFlutterTtsを持つサービス
        final service = TTSService(tts: mockFlutterTts);

        // When: 実際の処理実行: initializeとspeakを呼び出す
        // 処理内容: 初期化と読み上げを実行
        await service.initialize();
        await service.speak('テスト');

        // Then: 結果検証: メソッドが正しい順序で呼ばれることを確認
        // setLanguage → setSpeechRate → speak の順序
        verifyInOrder([
          () => mockFlutterTts.setLanguage('ja-JP'),
          () => mockFlutterTts.setSpeechRate(1.0),
          () => mockFlutterTts.speak('テスト'),
        ]);
      });
    });

    // 8. エッジケーステストケース（追加）
    group('エッジケーステストケース', () {
      /// 連続したstop呼び出しが安全に処理される
      test('TC-048-028: 連続したstop()呼び出しが安全に処理される', () async {
        // Given: テストデータ準備: サービスを初期化し、読み上げを開始
        // 初期条件設定: サービスが読み上げ中の状態
        final notifier = container.read(ttsProvider.notifier);
        await notifier.initialize();
        await notifier.speak('テスト');

        // When: 実際の処理実行: stopを2回連続で呼び出す
        // 処理内容: 連続してstopを呼び出す
        await notifier.stop();
        await notifier.stop();

        // Then: 結果検証: エラーが発生しないことを確認
        // 状態がstoppedのまま維持される
        expect(container.read(ttsProvider).state, TTSState.stopped);
      });
    });

    // 9. リソース管理テストケース
    group('リソース管理テストケース', () {
      /// リソース解放時にFlutterTtsがdisposeされる
      test('TC-048-029: リソース解放時にFlutterTtsがdisposeされる', () async {
        // Given: テストデータ準備: モックを注入したサービスを作成
        // 初期条件設定: モック化されたFlutterTtsを持つサービス
        when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
        final service = TTSService(tts: mockFlutterTts);

        // When: 実際の処理実行: disposeを呼び出す
        // 処理内容: リソースを解放
        await service.dispose();

        // Then: 結果検証: FlutterTtsのstopが呼ばれることを確認
        // stopが呼ばれ、リソースが解放される
        verify(() => mockFlutterTts.stop()).called(1);
      });
    });
  });
}
