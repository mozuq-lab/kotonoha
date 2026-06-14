/// AI変換Provider・Notifier テスト
///
/// TASK-0070: AI変換Provider・状態管理
/// 【TDD Redフェーズ】: 失敗するテスト
///
/// 信頼性レベル: 🔵 青信号（interfaces.dartベース）
/// 関連要件: REQ-901, REQ-902, REQ-903, REQ-904
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/data/api/ai_conversion_api_client.dart';
import 'package:kotonoha_app/features/ai_conversion/data/models/ai_conversion_response.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_state.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:mocktail/mocktail.dart';

// モッククラス
class MockAIConversionApiClient extends Mock implements AIConversionApiClient {}

class MockDio extends Mock implements Dio {}

/// オンライン状態用のNetworkNotifierサブクラス
class _OnlineNetworkNotifier extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.online;
}

/// オフライン状態用のNetworkNotifierサブクラス
class _OfflineNetworkNotifier extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.offline;
}

void main() {
  late MockAIConversionApiClient mockApiClient;
  late ProviderContainer container;

  setUpAll(() {
    // Mocktail用のfallback値を登録
    registerFallbackValue(PolitenessLevel.normal);
  });

  setUp(() {
    mockApiClient = MockAIConversionApiClient();
  });

  tearDown(() {
    container.dispose();
  });

  /// テスト用ProviderContainerを作成
  ProviderContainer createContainer({
    NetworkState initialNetworkState = NetworkState.online,
  }) {
    return ProviderContainer(
      overrides: [
        aiConversionApiClientProvider.overrideWithValue(mockApiClient),
        networkProvider.overrideWith(() {
          return initialNetworkState == NetworkState.online
              ? _OnlineNetworkNotifier()
              : _OfflineNetworkNotifier();
        }),
      ],
    );
  }

  group('AIConversionProvider', () {
    group('初期状態', () {
      // TC-070-001: 初期状態がidleである
      test('should have idle status initially', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.idle);
        expect(state.originalText, isNull);
        expect(state.convertedText, isNull);
        expect(state.politenessLevel, isNull);
        expect(state.error, isNull);
        expect(state.isConverting, false);
        expect(state.hasResult, false);
        expect(state.hasError, false);
      });

      // TC-070-002: AIConversionState.initialと等しい
      test('should equal AIConversionState.initial', () async {
        container = createContainer();

        final state = container.read(aiConversionProvider);

        expect(state, AIConversionState.initial);
      });

      // TC-070-025: aiConversionProviderが正しく初期化される
      test('aiConversionProvider should be properly initialized', () async {
        container = createContainer();

        final state = container.read(aiConversionProvider);

        expect(state, isA<AIConversionState>());
        expect(state.status, AIConversionStatus.idle);
      });

      // TC-070-026: aiConversionProvider.notifierがNotifierを返す
      test('aiConversionProvider.notifier should return Notifier', () async {
        container = createContainer();

        final notifier = container.read(aiConversionProvider.notifier);

        expect(notifier, isA<AIConversionNotifier>());
      });
    });

    group('変換処理（convert）', () {
      // TC-070-003: convert呼び出しで状態がconvertingになる
      test('should set status to converting when convert is called', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          // 少し遅延を入れてconverting状態をキャプチャできるようにする
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return const AIConversionResponse(
            convertedText: '変換結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 100,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);

        // 非同期で変換開始（完了は後で待つ）
        final convertFuture = notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        // 少し待ってconverting状態を確認
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.converting);
        expect(state.isConverting, true);
        expect(state.originalText, 'テスト');
        expect(state.politenessLevel, PolitenessLevel.polite);

        // テスト終了（container破棄）前に変換処理の完了を待ち、
        // 破棄済みNotifierへのstate更新（failed after test completion）を防ぐ。
        await convertFuture;
      });

      // TC-070-004: convert成功で状態がsuccessになり結果が設定される
      test('should set status to success when convert succeeds', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: 'お水をぬるめでお願いします',
            originalText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 500,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: '水 ぬるく',
          politenessLevel: PolitenessLevel.polite,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.success);
        expect(state.hasResult, true);
        expect(state.originalText, '水 ぬるく');
        expect(state.convertedText, 'お水をぬるめでお願いします');
        expect(state.politenessLevel, PolitenessLevel.polite);
        expect(state.error, isNull);
      });

      // TC-070-005: convert失敗で状態がerrorになり例外が設定される
      test('should set status to error when convert fails', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenThrow(const AIConversionException(
          code: 'AI_API_ERROR',
          message: 'AI変換APIでエラーが発生しました。',
        ));

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'エラーテスト',
          politenessLevel: PolitenessLevel.normal,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.error);
        expect(state.hasError, true);
        expect(state.error, isNotNull);
        expect(state.error!.code, 'AI_API_ERROR');
        expect(state.convertedText, isNull);
      });

      // TC-070-006: オフライン時のconvertでエラー状態になる
      test('should set error status when offline', () async {
        container = createContainer(initialNetworkState: NetworkState.offline);
        await container.read(networkProvider.notifier).setOffline();

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.casual,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.error);
        expect(state.hasError, true);
        expect(state.error, isNotNull);
        expect(state.error!.code, 'NETWORK_ERROR');
      });

      // TC-070-027: NetworkNotifierとの連携確認
      test('should check network state before calling API', () async {
        container = createContainer(initialNetworkState: NetworkState.offline);
        await container.read(networkProvider.notifier).setOffline();

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        // APIクライアントは呼ばれない
        verifyNever(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            ));
      });

      // TC-070-007: 丁寧さレベルcasualでの変換
      test('should convert with casual politeness level', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: PolitenessLevel.casual,
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: 'ありがと',
            originalText: 'ありがとう',
            politenessLevel: PolitenessLevel.casual,
            processingTimeMs: 200,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'ありがとう',
          politenessLevel: PolitenessLevel.casual,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.success);
        expect(state.politenessLevel, PolitenessLevel.casual);
      });

      // TC-070-008: 丁寧さレベルnormalでの変換
      test('should convert with normal politeness level', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: PolitenessLevel.normal,
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: 'ありがとうございます',
            originalText: 'ありがとう',
            politenessLevel: PolitenessLevel.normal,
            processingTimeMs: 200,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'ありがとう',
          politenessLevel: PolitenessLevel.normal,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.success);
        expect(state.politenessLevel, PolitenessLevel.normal);
      });

      // TC-070-009: 丁寧さレベルpoliteでの変換
      test('should convert with polite politeness level', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: PolitenessLevel.polite,
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '誠にありがとうございます',
            originalText: 'ありがとう',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 200,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'ありがとう',
          politenessLevel: PolitenessLevel.polite,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.success);
        expect(state.politenessLevel, PolitenessLevel.polite);
      });
    });

    group('再生成処理（regenerate）', () {
      // TC-070-010: regenerateで前回の情報を使用して再変換が実行される
      test('should use previous info for regenerate', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        // 最初の変換
        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: 'お水をぬるめでお願いします',
            originalText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 500,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: '水 ぬるく',
          politenessLevel: PolitenessLevel.polite,
        );

        // 再生成用のモック設定
        when(() => mockApiClient.regenerate(
              inputText: '水 ぬるく',
              politenessLevel: PolitenessLevel.polite,
              previousResult: 'お水をぬるめでお願いします',
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: 'ぬるめのお水をお願いいたします',
            originalText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 400,
          );
        });

        // 再生成
        await notifier.regenerate();

        verify(() => mockApiClient.regenerate(
              inputText: '水 ぬるく',
              politenessLevel: PolitenessLevel.polite,
              previousResult: 'お水をぬるめでお願いします',
            )).called(1);
      });

      // TC-070-011: regenerate成功で新しい変換結果が設定される
      test('should set new converted text on regenerate success', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        // 最初の変換
        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '最初の結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 500,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        // 再生成
        when(() => mockApiClient.regenerate(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
              previousResult: any(named: 'previousResult'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '新しい結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 400,
          );
        });

        await notifier.regenerate();

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.success);
        expect(state.convertedText, '新しい結果');
        expect(state.originalText, 'テスト'); // 変わらない
        expect(state.politenessLevel, PolitenessLevel.polite); // 変わらない
      });

      // TC-070-012: 結果がない状態でregenerateを呼び出した場合
      test(
          'should do nothing when regenerate is called without previous result',
          () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        final notifier = container.read(aiConversionProvider.notifier);

        // 結果がない状態でregenerate
        await notifier.regenerate();

        final state = container.read(aiConversionProvider);

        // 状態は変わらない
        expect(state.status, AIConversionStatus.idle);

        // APIは呼ばれない
        verifyNever(() => mockApiClient.regenerate(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
              previousResult: any(named: 'previousResult'),
            ));
      });
    });

    group('状態クリア（clear）', () {
      // TC-070-013: clearで状態がidleに戻る
      test('should reset to idle on clear', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '変換結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 500,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        // success状態を確認
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.success);

        // clear
        notifier.clear();

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.idle);
        expect(state.originalText, isNull);
        expect(state.convertedText, isNull);
        expect(state.politenessLevel, isNull);
        expect(state.error, isNull);
      });

      // TC-070-014: エラー状態からclearでidleに戻る
      test('should reset to idle from error state on clear', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenThrow(const AIConversionException(
          code: 'AI_API_ERROR',
          message: 'エラー',
        ));

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'エラー',
          politenessLevel: PolitenessLevel.normal,
        );

        // error状態を確認
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.error);

        // clear
        notifier.clear();

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.idle);
        expect(state.error, isNull);
      });
    });

    group('状態遷移', () {
      // TC-070-016: idle → converting → success → idle (clear)
      test('should transition: idle -> converting -> success -> idle',
          () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '変換結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 500,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);

        // 初期状態: idle
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.idle);

        // 変換 → success
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.success);

        // clear → idle
        notifier.clear();
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.idle);
      });

      // TC-070-017: idle → converting → error → idle (clear)
      test('should transition: idle -> converting -> error -> idle', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenThrow(const AIConversionException(
          code: 'AI_API_ERROR',
          message: 'エラー',
        ));

        final notifier = container.read(aiConversionProvider.notifier);

        // 初期状態: idle
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.idle);

        // 変換エラー → error
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.error);

        // clear → idle
        notifier.clear();
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.idle);
      });

      // TC-070-018: success → converting → success (regenerate)
      test('should transition: success -> converting -> success on regenerate',
          () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '最初の結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 500,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        // success状態
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.success);

        when(() => mockApiClient.regenerate(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
              previousResult: any(named: 'previousResult'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: '新しい結果',
            originalText: 'テスト',
            politenessLevel: PolitenessLevel.polite,
            processingTimeMs: 400,
          );
        });

        // regenerate → success
        await notifier.regenerate();
        expect(container.read(aiConversionProvider).status,
            AIConversionStatus.success);
      });
    });

    group('エラーハンドリング', () {
      // TC-070-019: タイムアウトエラー時の状態
      test('should handle timeout error', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenThrow(const AIConversionException(
          code: 'AI_API_TIMEOUT',
          message: 'タイムアウト',
        ));

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.error);
        expect(state.error!.code, 'AI_API_TIMEOUT');
      });

      // TC-070-020: レート制限エラー時の状態
      test('should handle rate limit error', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenThrow(const AIConversionException(
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'レート制限',
        ));

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.error);
        expect(state.error!.code, 'RATE_LIMIT_EXCEEDED');
      });

      // TC-070-021: バリデーションエラー時の状態
      test('should handle validation error', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: any(named: 'inputText'),
              politenessLevel: any(named: 'politenessLevel'),
            )).thenThrow(const AIConversionException(
          code: 'VALIDATION_ERROR',
          message: 'バリデーションエラー',
        ));

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.error);
        expect(state.error!.code, 'VALIDATION_ERROR');
      });
    });

    group('境界値・エッジケース', () {
      // TC-070-028: 最小文字数（2文字）での変換
      test('should convert minimum length text (2 chars)', () async {
        container = createContainer();
        await container.read(networkProvider.notifier).setOnline();

        when(() => mockApiClient.convert(
              inputText: 'はい',
              politenessLevel: any(named: 'politenessLevel'),
            )).thenAnswer((_) async {
          return const AIConversionResponse(
            convertedText: 'はい、かしこまりました',
            originalText: 'はい',
            politenessLevel: PolitenessLevel.normal,
            processingTimeMs: 200,
          );
        });

        final notifier = container.read(aiConversionProvider.notifier);
        await notifier.convert(
          inputText: 'はい',
          politenessLevel: PolitenessLevel.normal,
        );

        final state = container.read(aiConversionProvider);

        expect(state.status, AIConversionStatus.success);
      });
    });
  });
}

/// unawaited関数（Dart 2.14+では標準ライブラリに存在）
void unawaited(Future<void> future) {}
