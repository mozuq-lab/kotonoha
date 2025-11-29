/// AI変換状態クラス テスト
///
/// TASK-0070: AI変換Provider・状態管理
/// 【TDD Redフェーズ】: 失敗するテスト
///
/// 信頼性レベル: 🔵 青信号（interfaces.dartベース）
/// 関連要件: REQ-901, REQ-902, REQ-903, REQ-904
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_state.dart';

void main() {
  group('AIConversionStatus', () {
    // TC-070-022: ステータスの種類確認
    test('should have 4 status values', () {
      expect(AIConversionStatus.values.length, 4);
      expect(AIConversionStatus.values, contains(AIConversionStatus.idle));
      expect(AIConversionStatus.values, contains(AIConversionStatus.converting));
      expect(AIConversionStatus.values, contains(AIConversionStatus.success));
      expect(AIConversionStatus.values, contains(AIConversionStatus.error));
    });
  });

  group('AIConversionState', () {
    group('初期状態', () {
      // TC-070-001: 初期状態がidleである
      test('should have idle status by default', () {
        const state = AIConversionState();

        expect(state.status, AIConversionStatus.idle);
        expect(state.originalText, isNull);
        expect(state.convertedText, isNull);
        expect(state.politenessLevel, isNull);
        expect(state.error, isNull);
      });

      // TC-070-002: AIConversionState.initialと等しい
      test('should equal AIConversionState.initial', () {
        const state = AIConversionState();

        expect(state, AIConversionState.initial);
        expect(state.status, AIConversionState.initial.status);
      });
    });

    group('ヘルパープロパティ', () {
      // TC-070-022: isConvertingプロパティ
      test('isConverting should return true only when status is converting', () {
        expect(const AIConversionState().isConverting, false);
        expect(
          const AIConversionState(status: AIConversionStatus.idle).isConverting,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.converting)
              .isConverting,
          true,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.success)
              .isConverting,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.error).isConverting,
          false,
        );
      });

      // TC-070-023: hasResultプロパティ
      test('hasResult should return true only when status is success', () {
        expect(const AIConversionState().hasResult, false);
        expect(
          const AIConversionState(status: AIConversionStatus.idle).hasResult,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.converting)
              .hasResult,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.success).hasResult,
          true,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.error).hasResult,
          false,
        );
      });

      // TC-070-024: hasErrorプロパティ
      test('hasError should return true only when status is error', () {
        expect(const AIConversionState().hasError, false);
        expect(
          const AIConversionState(status: AIConversionStatus.idle).hasError,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.converting)
              .hasError,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.success).hasError,
          false,
        );
        expect(
          const AIConversionState(status: AIConversionStatus.error).hasError,
          true,
        );
      });
    });

    group('copyWith', () {
      test('should copy state with new status', () {
        const original = AIConversionState();
        final copied = original.copyWith(status: AIConversionStatus.converting);

        expect(copied.status, AIConversionStatus.converting);
        expect(copied.originalText, isNull);
      });

      test('should copy state with all new values', () {
        const original = AIConversionState();
        final copied = original.copyWith(
          status: AIConversionStatus.success,
          originalText: '水 ぬるく',
          convertedText: 'お水をぬるめでお願いします',
          politenessLevel: PolitenessLevel.polite,
        );

        expect(copied.status, AIConversionStatus.success);
        expect(copied.originalText, '水 ぬるく');
        expect(copied.convertedText, 'お水をぬるめでお願いします');
        expect(copied.politenessLevel, PolitenessLevel.polite);
        expect(copied.error, isNull);
      });

      test('should clear values when clear flags are set', () {
        const original = AIConversionState(
          status: AIConversionStatus.success,
          originalText: '水 ぬるく',
          convertedText: 'お水をぬるめでお願いします',
          politenessLevel: PolitenessLevel.polite,
          error: AIConversionException(
            code: 'TEST',
            message: 'test',
          ),
        );

        final cleared = original.copyWith(
          status: AIConversionStatus.idle,
          clearOriginalText: true,
          clearConvertedText: true,
          clearPolitenessLevel: true,
          clearError: true,
        );

        expect(cleared.status, AIConversionStatus.idle);
        expect(cleared.originalText, isNull);
        expect(cleared.convertedText, isNull);
        expect(cleared.politenessLevel, isNull);
        expect(cleared.error, isNull);
      });
    });

    group('equality', () {
      test('should be equal when all properties are same', () {
        const state1 = AIConversionState(
          status: AIConversionStatus.success,
          originalText: 'テスト',
          convertedText: '変換結果',
          politenessLevel: PolitenessLevel.polite,
        );
        const state2 = AIConversionState(
          status: AIConversionStatus.success,
          originalText: 'テスト',
          convertedText: '変換結果',
          politenessLevel: PolitenessLevel.polite,
        );

        expect(state1, state2);
        expect(state1.hashCode, state2.hashCode);
      });

      test('should not be equal when status is different', () {
        const state1 = AIConversionState(status: AIConversionStatus.idle);
        const state2 = AIConversionState(status: AIConversionStatus.converting);

        expect(state1, isNot(equals(state2)));
      });

      test('should not be equal when originalText is different', () {
        const state1 = AIConversionState(originalText: 'テスト1');
        const state2 = AIConversionState(originalText: 'テスト2');

        expect(state1, isNot(equals(state2)));
      });
    });

    group('toString', () {
      test('should return readable string', () {
        const state = AIConversionState(
          status: AIConversionStatus.success,
          originalText: 'テスト',
          convertedText: '変換結果',
          politenessLevel: PolitenessLevel.polite,
        );

        final str = state.toString();

        expect(str, contains('AIConversionState'));
        expect(str, contains('success'));
        expect(str, contains('テスト'));
        expect(str, contains('変換結果'));
        expect(str, contains('polite'));
      });
    });
  });
}
