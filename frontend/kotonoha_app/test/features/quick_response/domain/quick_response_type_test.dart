/// QuickResponseType Enumテスト
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
/// テストケース: TC-QR-001, TC-QR-002
///
/// テスト対象: lib/features/quick_response/domain/quick_response_type.dart
///
/// 【TDD Redフェーズ】: Enumが未実装のため、このテストは失敗する
library;

import 'package:flutter_test/flutter_test.dart';

// まだ存在しないEnumをインポート（Redフェーズ）
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';

void main() {
  group('QuickResponseType', () {
    // =========================================================================
    // 1. Enum定義テスト
    // =========================================================================
    group('Enum定義テスト', () {
      /// TC-QR-001: QuickResponseTypeに3つの値が定義されている
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001
      ///
      /// 前提条件:
      /// - QuickResponseType enumがインポートされている
      ///
      /// 期待結果:
      /// - QuickResponseType.yes が存在する
      /// - QuickResponseType.no が存在する
      /// - QuickResponseType.unknown が存在する
      /// - 値の総数が3である
      test('TC-QR-001: QuickResponseTypeに3つの値が定義されている', () {
        // Assert
        expect(QuickResponseType.values.length, equals(3));
        expect(QuickResponseType.values, contains(QuickResponseType.yes));
        expect(QuickResponseType.values, contains(QuickResponseType.no));
        expect(QuickResponseType.values, contains(QuickResponseType.unknown));
      });

      /// TC-QR-002: quickResponseLabelsで正しいラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-006
      ///
      /// 前提条件:
      /// - quickResponseLabels定数が定義されている
      ///
      /// 期待結果:
      /// - QuickResponseType.yes → 'はい'
      /// - QuickResponseType.no → 'いいえ'
      /// - QuickResponseType.unknown → 'わからない'
      test('TC-QR-002: quickResponseLabelsで正しいラベルが取得できる', () {
        // Assert
        expect(quickResponseLabels[QuickResponseType.yes], equals('はい'));
        expect(quickResponseLabels[QuickResponseType.no], equals('いいえ'));
        expect(
          quickResponseLabels[QuickResponseType.unknown],
          equals('わからない'),
        );
      });

      /// TC-QR-002b: 全てのQuickResponseTypeにラベルが定義されている
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-006
      ///
      /// 期待結果:
      /// - 全てのEnum値に対応するラベルが存在する
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

    // =========================================================================
    // 2. getLabelメソッドテスト（拡張機能）
    // =========================================================================
    group('getLabelメソッドテスト', () {
      /// 各タイプでgetLabelが正しいラベルを返す
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-006
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
