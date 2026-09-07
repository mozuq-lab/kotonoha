library;

import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';

void main() {
  group('QuickResponseType', () {
    // 1. Enum定義テスト
    group('Enum定義テスト', () {
      /// QuickResponseTypeに3つの値が定義されている
      test('TC-QR-001: QuickResponseTypeに3つの値が定義されている', () {
        // Assert
        expect(QuickResponseType.values.length, equals(3));
        expect(QuickResponseType.values, contains(QuickResponseType.yes));
        expect(QuickResponseType.values, contains(QuickResponseType.no));
        expect(QuickResponseType.values, contains(QuickResponseType.unknown));
      });

      /// quickResponseLabelsで正しいラベルが取得できる
      test('TC-QR-002: quickResponseLabelsで正しいラベルが取得できる', () {
        // Assert
        expect(quickResponseLabels[QuickResponseType.yes], equals('はい'));
        expect(quickResponseLabels[QuickResponseType.no], equals('いいえ'));
        expect(
          quickResponseLabels[QuickResponseType.unknown],
          equals('わからない'),
        );
      });

      /// 全てのQuickResponseTypeにラベルが定義されている
      test('TC-QR-002b: 全てのQuickResponseTypeにラベルが定義されている', () {
        // Assert
        for (final type in QuickResponseType.values) {
          expect(
            quickResponseLabels.containsKey(type),
            isTrue,
            reason: '$type にラベルが定義されていません',
          );
          expect(
            quickResponseLabels[type],
            isNotNull,
            reason: '$type のラベルがnullです',
          );
          expect(
            quickResponseLabels[type]!.isNotEmpty,
            isTrue,
            reason: '$type のラベルが空文字です',
          );
        }
      });
    });

    // 2. getLabelメソッドテスト（拡張機能）
    group('getLabelメソッドテスト', () {
      /// 各タイプでgetLabelが正しいラベルを返す
      test('QuickResponseType.yes.labelは「はい」を返す', () {
        expect(QuickResponseType.yes.label, equals('はい'));
      });

      test('QuickResponseType.no.labelは「いいえ」を返す', () {
        expect(QuickResponseType.no.label, equals('いいえ'));
      });

      test('QuickResponseType.unknown.labelは「わからない」を返す', () {
        expect(QuickResponseType.unknown.label, equals('わからない'));
      });
    });
  });
}
