/// StatusButtonType Enumテスト
///
/// TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装
/// テストケース: TC-SBT-001〜TC-SBT-016
///
/// テスト対象: lib/features/status_buttons/domain/status_button_type.dart
///
/// 【TDD Redフェーズ】: Enumが未実装のため、このテストは失敗する
library;

import 'package:flutter_test/flutter_test.dart';

// まだ存在しないEnumをインポート（Redフェーズ）
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';

void main() {
  group('StatusButtonType', () {
    // =========================================================================
    // 1.1 Enum定義テスト
    // =========================================================================
    group('Enum定義テスト', () {
      /// TC-SBT-001: StatusButtonTypeに必須の8個の値が定義されている
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001, FR-002
      ///
      /// 前提条件:
      /// - StatusButtonType enumがインポートされている
      ///
      /// 期待結果:
      /// - StatusButtonType.pain が存在する
      /// - StatusButtonType.toilet が存在する
      /// - StatusButtonType.hot が存在する
      /// - StatusButtonType.cold が存在する
      /// - StatusButtonType.water が存在する
      /// - StatusButtonType.sleepy が存在する
      /// - StatusButtonType.help が存在する
      /// - StatusButtonType.wait が存在する
      /// - 値の総数が8以上である
      test('TC-SBT-001: StatusButtonTypeに必須の8個の値が定義されている', () {
        // Assert
        expect(StatusButtonType.values.length, greaterThanOrEqualTo(8));
        expect(StatusButtonType.values, contains(StatusButtonType.pain));
        expect(StatusButtonType.values, contains(StatusButtonType.toilet));
        expect(StatusButtonType.values, contains(StatusButtonType.hot));
        expect(StatusButtonType.values, contains(StatusButtonType.cold));
        expect(StatusButtonType.values, contains(StatusButtonType.water));
        expect(StatusButtonType.values, contains(StatusButtonType.sleepy));
        expect(StatusButtonType.values, contains(StatusButtonType.help));
        expect(StatusButtonType.values, contains(StatusButtonType.wait));
      });

      /// TC-SBT-002: StatusButtonTypeに最大12個の値が定義されている
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      ///
      /// 期待結果:
      /// - 値の総数が12以下である
      test('TC-SBT-002: StatusButtonTypeに最大12個の値が定義されている', () {
        // Assert
        expect(StatusButtonType.values.length, lessThanOrEqualTo(12));
      });

      /// TC-SBT-003: 必須状態タイプが正しく定義されている
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001
      ///
      /// 期待結果:
      /// - 必須の8タイプ（pain, toilet, hot, cold, water, sleepy, help, wait）が存在
      test('TC-SBT-003: 必須状態タイプが正しく定義されている', () {
        // Assert - 必須の8タイプが存在することを確認
        final requiredTypes = [
          StatusButtonType.pain,
          StatusButtonType.toilet,
          StatusButtonType.hot,
          StatusButtonType.cold,
          StatusButtonType.water,
          StatusButtonType.sleepy,
          StatusButtonType.help,
          StatusButtonType.wait,
        ];

        for (final type in requiredTypes) {
          expect(
            StatusButtonType.values,
            contains(type),
            reason: '$type が StatusButtonType に定義されていません',
          );
        }
      });

      /// TC-SBT-004: オプション状態タイプが正しく定義されている
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-001
      ///
      /// 期待結果:
      /// - オプションの4タイプ（again, thanks, sorry, okay）が存在
      test('TC-SBT-004: オプション状態タイプが正しく定義されている', () {
        // Assert - オプションの4タイプが存在することを確認
        expect(StatusButtonType.values, contains(StatusButtonType.again));
        expect(StatusButtonType.values, contains(StatusButtonType.thanks));
        expect(StatusButtonType.values, contains(StatusButtonType.sorry));
        expect(StatusButtonType.values, contains(StatusButtonType.okay));
      });
    });

    // =========================================================================
    // 1.2 ラベル取得テスト
    // =========================================================================
    group('ラベル取得テスト', () {
      /// TC-SBT-005: statusButtonLabelsで「痛い」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-005: statusButtonLabelsで「痛い」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.pain], equals('痛い'));
      });

      /// TC-SBT-006: statusButtonLabelsで「トイレ」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-006: statusButtonLabelsで「トイレ」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.toilet], equals('トイレ'));
      });

      /// TC-SBT-007: statusButtonLabelsで「暑い」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-007: statusButtonLabelsで「暑い」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.hot], equals('暑い'));
      });

      /// TC-SBT-008: statusButtonLabelsで「寒い」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-008: statusButtonLabelsで「寒い」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.cold], equals('寒い'));
      });

      /// TC-SBT-009: statusButtonLabelsで「水」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-009: statusButtonLabelsで「水」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.water], equals('水'));
      });

      /// TC-SBT-010: statusButtonLabelsで「眠い」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-010: statusButtonLabelsで「眠い」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.sleepy], equals('眠い'));
      });

      /// TC-SBT-011: statusButtonLabelsで「助けて」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-011: statusButtonLabelsで「助けて」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.help], equals('助けて'));
      });

      /// TC-SBT-012: statusButtonLabelsで「待って」ラベルが取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-012: statusButtonLabelsで「待って」ラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.wait], equals('待って'));
      });

      /// TC-SBT-013: statusButtonLabelsでオプションラベルが取得できる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-005
      test('TC-SBT-013: statusButtonLabelsでオプションラベルが取得できる', () {
        expect(statusButtonLabels[StatusButtonType.again], equals('もう一度'));
        expect(statusButtonLabels[StatusButtonType.thanks], equals('ありがとう'));
        expect(statusButtonLabels[StatusButtonType.sorry], equals('ごめんなさい'));
        expect(statusButtonLabels[StatusButtonType.okay], equals('大丈夫'));
      });

      /// TC-SBT-014: 全てのStatusButtonTypeに対応するラベルが存在する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-014: 全てのStatusButtonTypeに対応するラベルが存在する', () {
        for (final type in StatusButtonType.values) {
          expect(
            statusButtonLabels.containsKey(type),
            isTrue,
            reason: '$type にラベルが定義されていません',
          );
          expect(
            statusButtonLabels[type],
            isNotNull,
            reason: '$type のラベルがnullです',
          );
          expect(
            statusButtonLabels[type]!.isNotEmpty,
            isTrue,
            reason: '$type のラベルが空文字です',
          );
        }
      });
    });

    // =========================================================================
    // 1.3 拡張メソッドテスト
    // =========================================================================
    group('拡張メソッドテスト', () {
      /// TC-SBT-015: StatusButtonType.pain.labelで「痛い」が取得できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-015: StatusButtonType.pain.labelで「痛い」が取得できる', () {
        expect(StatusButtonType.pain.label, equals('痛い'));
      });

      /// TC-SBT-016: 全StatusButtonTypeでlabel拡張が動作する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      test('TC-SBT-016: 全StatusButtonTypeでlabel拡張が動作する', () {
        // Assert - 各タイプでlabelが正しく取得できることを確認
        expect(StatusButtonType.pain.label, equals('痛い'));
        expect(StatusButtonType.toilet.label, equals('トイレ'));
        expect(StatusButtonType.hot.label, equals('暑い'));
        expect(StatusButtonType.cold.label, equals('寒い'));
        expect(StatusButtonType.water.label, equals('水'));
        expect(StatusButtonType.sleepy.label, equals('眠い'));
        expect(StatusButtonType.help.label, equals('助けて'));
        expect(StatusButtonType.wait.label, equals('待って'));
        expect(StatusButtonType.again.label, equals('もう一度'));
        expect(StatusButtonType.thanks.label, equals('ありがとう'));
        expect(StatusButtonType.sorry.label, equals('ごめんなさい'));
        expect(StatusButtonType.okay.label, equals('大丈夫'));
      });
    });
  });
}
