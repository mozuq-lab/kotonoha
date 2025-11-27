/// EmergencyButton ウィジェットテスト
///
/// TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）
/// テストケース: TC-EB-001〜TC-EB-008
///
/// テスト対象: lib/shared/widgets/emergency_button.dart (未実装)
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

// まだ存在しないウィジェットをインポート（Redフェーズ）
import 'package:kotonoha_app/shared/widgets/emergency_button.dart';

void main() {
  group('EmergencyButton', () {
    // =========================================================================
    // 3.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-EB-001: ボタンが円形で表示される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - CircleBorderが適用される
      ///
      /// 優先度: 必須
      testWidgets('TC-EB-001: ボタンが円形で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final shape = button.style?.shape?.resolve({});
        expect(shape, isA<CircleBorder>());
      });

      /// TC-EB-002: 背景色が赤色である
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - backgroundColor = AppColors.emergency (#D32F2F)
      ///
      /// 優先度: 必須
      testWidgets('TC-EB-002: 背景色が赤色である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final bgColor = button.style?.backgroundColor?.resolve({});
        expect(bgColor, equals(AppColors.emergency));
        expect(bgColor, equals(const Color(0xFFD32F2F)));
      });

      /// TC-EB-003: サイズが60x60pxである
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - width = 60.0, height = 60.0
      ///
      /// 優先度: 必須
      testWidgets('TC-EB-003: サイズが60x60pxである', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
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

      /// TC-EB-004: アイコンが表示される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - notifications_activeアイコンが表示される
      ///
      /// 優先度: 高
      testWidgets('TC-EB-004: アイコンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });

      /// TC-EB-005: アイコンの色が白である
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - foregroundColor = Colors.white
      ///
      /// 優先度: 高
      testWidgets('TC-EB-005: アイコンの色が白である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final fgColor = button.style?.foregroundColor?.resolve({});
        expect(fgColor, equals(Colors.white));
      });
    });

    // =========================================================================
    // 3.2 イベントテスト
    // =========================================================================
    group('イベントテスト', () {
      /// TC-EB-006: タップ時にonPressedが呼ばれる
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - ボタンタップ
      ///
      /// 期待結果:
      /// - onPressedコールバックが実行される
      ///
      /// 優先度: 必須
      testWidgets('TC-EB-006: タップ時にonPressedが呼ばれる', (tester) async {
        // Arrange
        bool pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(EmergencyButton));

        // Assert
        expect(pressed, isTrue);
      });
    });

    // =========================================================================
    // 3.3 サイズテスト
    // =========================================================================
    group('サイズテスト', () {
      /// TC-EB-007: カスタムサイズが適用される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - size: 80.0
      ///
      /// 期待結果:
      /// - width = 80.0, height = 80.0
      ///
      /// 優先度: 高
      testWidgets('TC-EB-007: カスタムサイズが適用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () {},
                size: 80.0,
              ),
            ),
          ),
        );

        // Assert
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, equals(80.0));
        expect(sizedBox.height, equals(80.0));
      });
    });

    // =========================================================================
    // 3.4 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-EB-008: Semanticsラベルが「緊急呼び出しボタン」である
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - Semanticsラベルに「緊急」が含まれる
      ///
      /// 優先度: 高
      testWidgets('TC-EB-008: Semanticsラベルが緊急呼び出しボタンである', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButton(
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        // Semanticsツリーを確認
        final semantics = tester.getSemantics(find.byType(EmergencyButton));
        expect(semantics.label, contains('緊急'));
      });
    });
  });
}
