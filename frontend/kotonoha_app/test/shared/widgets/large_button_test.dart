/// LargeButton ウィジェットテスト
///
/// TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）
/// テストケース: TC-LB-001〜TC-LB-012
///
/// テスト対象: lib/shared/widgets/large_button.dart (未実装)
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

// まだ存在しないウィジェットをインポート（Redフェーズ）
import 'package:kotonoha_app/shared/widgets/large_button.dart';

void main() {
  group('LargeButton', () {
    // =========================================================================
    // 1.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-LB-001: labelテキストが正しく表示される
      ///
      /// 前提条件:
      /// - LargeButtonがインポートされている
      ///
      /// 入力:
      /// - label: 'テスト'
      ///
      /// 期待結果:
      /// - 'テスト'がボタン上に表示される
      ///
      /// 優先度: 必須
      testWidgets('TC-LB-001: labelテキストが正しく表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('テスト'), findsOneWidget);
      });

      /// TC-LB-002: デフォルトサイズが60x60pxである
      ///
      /// 前提条件:
      /// - width/height未指定
      ///
      /// 入力:
      /// - デフォルト値
      ///
      /// 期待結果:
      /// - width=60.0, height=60.0
      ///
      /// 優先度: 必須
      testWidgets('TC-LB-002: デフォルトサイズが60x60pxである', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, equals(AppSizes.recommendedTapTarget));
        expect(sizedBox.height, equals(AppSizes.recommendedTapTarget));
        expect(sizedBox.width, equals(60.0));
        expect(sizedBox.height, equals(60.0));
      });
    });

    // =========================================================================
    // 1.2 サイズテスト
    // =========================================================================
    group('サイズテスト', () {
      /// TC-LB-003: カスタムサイズが適用される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - width: 100.0, height: 80.0
      ///
      /// 期待結果:
      /// - 指定したサイズが適用される
      ///
      /// 優先度: 高
      testWidgets('TC-LB-003: カスタムサイズが適用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
                width: 100.0,
                height: 80.0,
              ),
            ),
          ),
        );

        // Assert
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, equals(100.0));
        expect(sizedBox.height, equals(80.0));
      });

      /// TC-LB-004: 44px未満を指定しても44px以上が保証される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - width: 30.0, height: 30.0
      ///
      /// 期待結果:
      /// - width >= 44.0, height >= 44.0
      ///
      /// 優先度: 必須
      testWidgets('TC-LB-004: 44px未満を指定しても44px以上が保証される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
                width: 30.0,
                height: 30.0,
              ),
            ),
          ),
        );

        // Assert
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(sizedBox.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(sizedBox.width, greaterThanOrEqualTo(44.0));
        expect(sizedBox.height, greaterThanOrEqualTo(44.0));
      });
    });

    // =========================================================================
    // 1.3 イベントテスト
    // =========================================================================
    group('イベントテスト', () {
      /// TC-LB-005: タップ時にonPressedが呼ばれる
      ///
      /// 前提条件:
      /// - onPressed指定
      ///
      /// 入力:
      /// - ボタンタップ
      ///
      /// 期待結果:
      /// - onPressedコールバックが実行される
      ///
      /// 優先度: 必須
      testWidgets('TC-LB-005: タップ時にonPressedが呼ばれる', (tester) async {
        // Arrange
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(LargeButton));

        // Assert
        expect(tapped, isTrue);
      });
    });

    // =========================================================================
    // 1.4 状態テスト
    // =========================================================================
    group('状態テスト', () {
      /// TC-LB-006: onPressed: nullで無効状態になる
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - onPressed: null
      ///
      /// 期待結果:
      /// - ボタンが無効化される
      ///
      /// 優先度: 必須
      testWidgets('TC-LB-006: onPressed: nullで無効状態になる', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: null,
              ),
            ),
          ),
        );

        // Assert
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });
    });

    // =========================================================================
    // 1.5 スタイルテスト
    // =========================================================================
    group('スタイルテスト', () {
      /// TC-LB-007: backgroundColorが適用される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - backgroundColor: Colors.green
      ///
      /// 期待結果:
      /// - 背景色がColors.greenになる
      ///
      /// 優先度: 高
      testWidgets('TC-LB-007: backgroundColorが適用される', (tester) async {
        // Arrange
        const customColor = Colors.green;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
                backgroundColor: customColor,
              ),
            ),
          ),
        );

        // Assert
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style;
        expect(style?.backgroundColor?.resolve({}), equals(customColor));
      });

      /// TC-LB-008: textColorが適用される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - textColor: Colors.yellow
      ///
      /// 期待結果:
      /// - テキスト色がColors.yellowになる
      ///
      /// 優先度: 高
      testWidgets('TC-LB-008: textColorが適用される', (tester) async {
        // Arrange
        const customColor = Colors.yellow;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
                textColor: customColor,
              ),
            ),
          ),
        );

        // Assert
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style;
        expect(style?.foregroundColor?.resolve({}), equals(customColor));
      });
    });

    // =========================================================================
    // 1.6 テーマテスト
    // =========================================================================
    group('テーマテスト', () {
      /// TC-LB-009: ライトテーマで適切な色が使用される
      ///
      /// 前提条件:
      /// - ライトテーマ設定
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - ライトテーマのカラーが適用される
      ///
      /// 優先度: 高
      testWidgets('TC-LB-009: ライトテーマで適切な色が使用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(LargeButton));
        expect(Theme.of(context).brightness, equals(Brightness.light));
      });

      /// TC-LB-010: ダークテーマで適切な色が使用される
      ///
      /// 前提条件:
      /// - ダークテーマ設定
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - ダークテーマのカラーが適用される
      ///
      /// 優先度: 高
      testWidgets('TC-LB-010: ダークテーマで適切な色が使用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(LargeButton));
        expect(Theme.of(context).brightness, equals(Brightness.dark));
      });

      /// TC-LB-011: 高コントラストテーマで適切な色が使用される
      ///
      /// 前提条件:
      /// - 高コントラストテーマ設定
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - 高コントラストカラーが適用される
      ///
      /// 優先度: 高
      testWidgets('TC-LB-011: 高コントラストテーマで適切な色が使用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(LargeButton));
        final theme = Theme.of(context);
        expect(theme.colorScheme.primary, equals(AppColors.primaryHighContrast));
      });
    });

    // =========================================================================
    // 1.7 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-LB-012: Semanticsラベルが設定される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - ボタンとしてSemanticsが設定される（ElevatedButtonが内部でSemantics設定）
      ///
      /// 優先度: 高
      testWidgets('TC-LB-012: Semanticsラベルが設定される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LargeButton(
                label: 'テスト',
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        // ElevatedButtonが内部でボタンセマンティクスを設定している
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button, isNotNull);
        // ElevatedButtonは自動的にボタンセマンティクスを持つ
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });
  });
}
