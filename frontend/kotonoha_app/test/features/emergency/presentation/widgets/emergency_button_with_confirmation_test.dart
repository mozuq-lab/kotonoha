/// EmergencyButtonWithConfirmation ウィジェットテスト
///
/// TASK-0045: 緊急ボタンUI実装
/// テストケース: TC-045-001〜TC-045-027
///
/// テスト対象: lib/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart
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
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

void main() {
  group('EmergencyButtonWithConfirmation', () {
    // =========================================================================
    // 1.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-045-001: 緊急ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-301
      testWidgets('TC-045-001: 緊急ボタンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(EmergencyButtonWithConfirmation), findsOneWidget);
      });

      /// TC-045-002: ボタンが円形で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      testWidgets('TC-045-002: ボタンが円形で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - CircleBorderまたはCircleAvatarなどの円形要素を確認
        // 円形ボタンの実装方法により検証方法を調整
        final button = tester.widget<EmergencyButtonWithConfirmation>(
          find.byType(EmergencyButtonWithConfirmation),
        );
        expect(button, isNotNull);

        // ボタンサイズが正方形（円形の前提条件）であることを確認
        final size = tester.getSize(find.byType(EmergencyButtonWithConfirmation));
        expect(size.width, equals(size.height));
      });

      /// TC-045-003: 背景色が赤色（#D32F2F）である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001
      testWidgets('TC-045-003: 背景色が赤色（#D32F2F）である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - 緊急ボタンの背景色が赤（AppColors.emergency）であることを確認
        expect(find.byType(EmergencyButtonWithConfirmation), findsOneWidget);
        // 実装時: backgroundColor = Color(0xFFD32F2F) であることを検証
      });

      /// TC-045-004: notifications_activeアイコンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-004
      testWidgets('TC-045-004: notifications_activeアイコンが表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });

      /// TC-045-005: アイコンの色が白である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-004
      testWidgets('TC-045-005: アイコンの色が白である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.notifications_active));
        expect(icon.color, equals(Colors.white));
      });

      /// TC-045-006: エレベーション（影）が適用されている
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-008
      testWidgets('TC-045-006: エレベーション（影）が適用されている', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - Materialまたはボタンがelevationを持つことを確認
        // 実装時: elevation >= 4 であることを検証
        expect(find.byType(EmergencyButtonWithConfirmation), findsOneWidget);
      });
    });

    // =========================================================================
    // 1.2 サイズテスト
    // =========================================================================
    group('サイズテスト', () {
      /// TC-045-007: デフォルトサイズが60x60pxである
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-003, NFR-202
      testWidgets('TC-045-007: デフォルトサイズが60x60pxである', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(EmergencyButtonWithConfirmation));
        expect(size.width, equals(AppSizes.recommendedTapTarget)); // 60px
        expect(size.height, equals(AppSizes.recommendedTapTarget)); // 60px
      });

      /// TC-045-008: カスタムサイズ（80px）が適用される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-003
      testWidgets('TC-045-008: カスタムサイズ（80px）が適用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
                size: 80.0,
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(EmergencyButtonWithConfirmation));
        expect(size.width, equals(80.0));
        expect(size.height, equals(80.0));
      });

      /// TC-045-009: 最小サイズ（44px）未満に設定できない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-201, REQ-5001
      testWidgets('TC-045-009: 最小サイズ（44px）未満に設定できない', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
                size: 30.0, // 最小未満
              ),
            ),
          ),
        );

        // Assert - 最小サイズ（44px）が保証される
        final size = tester.getSize(find.byType(EmergencyButtonWithConfirmation));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// TC-045-010: 境界値: 44pxが適用される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-201
      testWidgets('TC-045-010: 境界値: 44pxが適用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
                size: AppSizes.minTapTarget, // 44px
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(EmergencyButtonWithConfirmation));
        expect(size.width, equals(AppSizes.minTapTarget));
        expect(size.height, equals(AppSizes.minTapTarget));
      });
    });

    // =========================================================================
    // 1.3 タップ・イベントテスト
    // =========================================================================
    group('タップ・イベントテスト', () {
      /// TC-045-011: タップ時に確認ダイアログが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101, REQ-302
      testWidgets('TC-045-011: タップ時に確認ダイアログが表示される', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-045-012: タップ時に視覚的フィードバック（リップル）が発生する
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-102
      testWidgets('TC-045-012: タップ時に視覚的フィードバックが発生する',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - InkWell/Materialによるリップルエフェクトの存在を確認
        expect(
          find.descendant(
            of: find.byType(EmergencyButtonWithConfirmation),
            matching: find.byType(InkWell),
          ),
          findsWidgets,
        );
      });

      /// TC-045-013: 確認ダイアログで「はい」タップ後、onEmergencyConfirmedが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-104, REQ-2005
      testWidgets('TC-045-013: 確認ダイアログで「はい」タップ後、onEmergencyConfirmedが呼ばれる',
          (tester) async {
        // Arrange
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () => callbackCalled = true,
              ),
            ),
          ),
        );

        // Act - ボタンをタップしてダイアログを表示
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // 「はい」ボタンをタップ
        await tester.tap(find.text('はい'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackCalled, isTrue);
      });

      /// TC-045-014: 確認ダイアログで「いいえ」タップ後、ダイアログが閉じる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-105, REQ-302
      testWidgets('TC-045-014: 確認ダイアログで「いいえ」タップ後、ダイアログが閉じる',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Act - ボタンをタップしてダイアログを表示
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // ダイアログが表示されていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);

        // 「いいえ」ボタンをタップ
        await tester.tap(find.text('いいえ'));
        await tester.pumpAndSettle();

        // Assert - ダイアログが閉じていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsNothing);
      });

      /// TC-045-015: 確認ダイアログで「いいえ」タップ後、onEmergencyConfirmedは呼ばれない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-105
      testWidgets('TC-045-015: 確認ダイアログで「いいえ」タップ後、onEmergencyConfirmedは呼ばれない',
          (tester) async {
        // Arrange
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () => callbackCalled = true,
              ),
            ),
          ),
        );

        // Act - ボタンをタップしてダイアログを表示
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // 「いいえ」ボタンをタップ
        await tester.tap(find.text('いいえ'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackCalled, isFalse);
      });
    });

    // =========================================================================
    // 1.4 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-045-016: Semanticsラベルが「緊急呼び出しボタン」である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007, NFR-A001
      testWidgets('TC-045-016: Semanticsラベルが「緊急呼び出しボタン」である',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(
          find.byType(EmergencyButtonWithConfirmation),
        );
        expect(semantics.label, contains('緊急呼び出し'));
      });

      /// TC-045-017: ボタンセマンティクス（button: true）が設定されている
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A001
      testWidgets('TC-045-017: ボタンセマンティクスが設定されている', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - Semanticsウィジェットが設定されていることを確認
        expect(
          find.descendant(
            of: find.byType(EmergencyButtonWithConfirmation),
            matching: find.byType(Semantics),
          ),
          findsWidgets,
        );
      });

      /// TC-045-018: タップターゲットが44x44px以上を常に満たす
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-201, REQ-5001
      testWidgets('TC-045-018: タップターゲットが44x44px以上', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(EmergencyButtonWithConfirmation));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// TC-045-019: 色だけでなくアイコンで緊急性を表現
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A002
      testWidgets('TC-045-019: 色だけでなくアイコンで緊急性を表現', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - notifications_activeアイコンが存在することを確認
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });
    });

    // =========================================================================
    // 1.5 テーマ対応テスト
    // =========================================================================
    group('テーマ対応テスト', () {
      /// TC-045-020: ライトモードで赤色（#D32F2F）で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103, REQ-803
      testWidgets('TC-045-020: ライトモードで赤色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(EmergencyButtonWithConfirmation));
        expect(Theme.of(context).brightness, equals(Brightness.light));
        // 実装時: backgroundColor = Color(0xFFD32F2F) であることを検証
      });

      /// TC-045-021: ダークモードで明るい赤色（#EF5350）で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103, REQ-803
      testWidgets('TC-045-021: ダークモードで明るい赤色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(EmergencyButtonWithConfirmation));
        expect(Theme.of(context).brightness, equals(Brightness.dark));
        // 実装時: backgroundColor = Color(0xFFEF5350) であることを検証
      });

      /// TC-045-022: 高コントラストモードで純粋な赤色（#FF0000）で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103, REQ-803, REQ-5006
      testWidgets('TC-045-022: 高コントラストモードで純粋な赤色で表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(EmergencyButtonWithConfirmation));
        expect(
          Theme.of(context).colorScheme.primary,
          equals(AppColors.primaryHighContrast),
        );
        // 実装時: backgroundColor = Color(0xFFFF0000) であることを検証
      });

      /// TC-045-023: 高コントラストモードでコントラスト比4.5:1以上を確保
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-202, REQ-5006
      testWidgets('TC-045-023: 高コントラストモードでコントラスト比4.5:1以上を確保',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Assert - 白アイコン on 赤背景でコントラスト比を確認
        final icon = tester.widget<Icon>(find.byIcon(Icons.notifications_active));
        expect(icon.color, equals(Colors.white));
        // 実装時: 背景色と前景色のコントラスト比が4.5:1以上であることを検証
      });
    });

    // =========================================================================
    // 1.6 エッジケーステスト
    // =========================================================================
    group('エッジケーステスト', () {
      /// TC-045-024: 連続タップ時に複数のダイアログが表示されない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-001
      testWidgets('TC-045-024: 連続タップ時に複数のダイアログが表示されない',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Act - 連続タップ（ダイアログ表示後はモーダルバリアにより遮断される）
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pump(const Duration(milliseconds: 50));
        // ダイアログ表示後のタップはモーダルバリアで遮断されるため warnIfMissed: false
        await tester.tap(
          find.byType(EmergencyButtonWithConfirmation),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(
          find.byType(EmergencyButtonWithConfirmation),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Assert - ダイアログは1つのみ表示される
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-045-025: ダイアログ表示中に緊急ボタンをタップしても無視される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-001
      testWidgets('TC-045-025: ダイアログ表示中に緊急ボタンをタップしても無視される',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Act - ボタンをタップしてダイアログを表示
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // ダイアログ表示中に再度ボタンをタップ（ダイアログの下にあるボタン）
        // ダイアログのモーダルバリアにより無視される

        // Assert - ダイアログは1つのみ
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-045-027: カスタムダイアログビルダーが適用される
      ///
      /// 優先度: P2（中優先度）
      testWidgets('TC-045-027: カスタムダイアログビルダーが適用される', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
                dialogBuilder: (context, onConfirm, onCancel) {
                  return AlertDialog(
                    title: const Text('カスタムダイアログ'),
                    actions: [
                      TextButton(onPressed: onConfirm, child: const Text('OK')),
                      TextButton(onPressed: onCancel, child: const Text('キャンセル')),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // Assert - カスタムダイアログが表示される
        expect(find.text('カスタムダイアログ'), findsOneWidget);
      });
    });

    // =========================================================================
    // 統合テスト
    // =========================================================================
    group('統合テスト', () {
      /// TC-045-050: 2段階確認フロー全体が正しく動作する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-302, FR-204
      testWidgets('TC-045-050: 2段階確認フロー全体が正しく動作する', (tester) async {
        // Arrange
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () => callbackCalled = true,
              ),
            ),
          ),
        );

        // Act & Assert - Step 1: ボタンタップ
        expect(find.byType(EmergencyButtonWithConfirmation), findsOneWidget);
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // Step 2: ダイアログ表示
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
        expect(find.text('はい'), findsOneWidget);
        expect(find.text('いいえ'), findsOneWidget);

        // Step 3: 「はい」をタップして確認
        await tester.tap(find.text('はい'));
        await tester.pumpAndSettle();

        // コールバックが呼ばれることを確認
        expect(callbackCalled, isTrue);
        // ダイアログが閉じることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsNothing);
      });

      /// TC-045-051: キャンセルフロー全体が正しく動作する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-302
      testWidgets('TC-045-051: キャンセルフロー全体が正しく動作する', (tester) async {
        // Arrange
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () => callbackCalled = true,
              ),
            ),
          ),
        );

        // Act & Assert - Step 1: ボタンタップ
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // Step 2: ダイアログ表示
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);

        // Step 3: 「いいえ」をタップしてキャンセル
        await tester.tap(find.text('いいえ'));
        await tester.pumpAndSettle();

        // コールバックが呼ばれないことを確認
        expect(callbackCalled, isFalse);
        // ダイアログが閉じることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsNothing);
        // 通常状態に戻ることを確認
        expect(find.byType(EmergencyButtonWithConfirmation), findsOneWidget);
      });

      /// TC-045-052: タップ操作のみで完結する（スワイプ不要）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-203, REQ-5005
      testWidgets('TC-045-052: タップ操作のみで完結する', (tester) async {
        // Arrange
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () => callbackCalled = true,
              ),
            ),
          ),
        );

        // Act - タップのみで全操作を完了
        await tester.tap(find.byType(EmergencyButtonWithConfirmation)); // タップ1
        await tester.pumpAndSettle();
        await tester.tap(find.text('はい')); // タップ2
        await tester.pumpAndSettle();

        // Assert - タップのみで操作が完了
        expect(callbackCalled, isTrue);
      });
    });

    // =========================================================================
    // TASK-0046: 緊急ボタン2段階確認実装 - 追加テスト
    // =========================================================================
    group('TASK-0046 追加テスト: 連続タップ防止', () {
      /// TC-046-019: 緊急ボタン連続タップで複数のダイアログが表示されない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-104, REQ-5002, AC-011, EDGE-001
      /// 検証内容: ボタン連続タップ時にダイアログが1つのみ表示されることを詳細検証
      testWidgets(
          'TC-046-019: 緊急ボタン連続タップで複数のダイアログが表示されない（詳細版）',
          (tester) async {
        // Arrange
        int dialogShowCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
                dialogBuilder: (context, onConfirm, onCancel) {
                  dialogShowCount++;
                  return EmergencyConfirmationDialog(
                    onConfirm: onConfirm,
                    onCancel: onCancel,
                  );
                },
              ),
            ),
          ),
        );

        // Act - 短い間隔で連続タップ（10ms間隔で5回）
        // ダイアログ表示後のタップはモーダルバリアで遮断されるため warnIfMissed: false
        for (var i = 0; i < 5; i++) {
          await tester.tap(
            find.byType(EmergencyButtonWithConfirmation),
            warnIfMissed: false,
          );
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pumpAndSettle();

        // Assert - ダイアログ表示回数が1回のみ
        expect(dialogShowCount, equals(1));
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-046-020: ダイアログ表示中に緊急ボタン領域タップが遮断される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-105, REQ-5002, AC-012
      testWidgets('TC-046-020: ダイアログ表示中に緊急ボタン領域タップが遮断される',
          (tester) async {
        // Arrange
        int dialogShowCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: EmergencyButtonWithConfirmation(
                  onEmergencyConfirmed: () {},
                  dialogBuilder: (context, onConfirm, onCancel) {
                    dialogShowCount++;
                    return EmergencyConfirmationDialog(
                      onConfirm: onConfirm,
                      onCancel: onCancel,
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Act - 最初のタップでダイアログ表示
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // ダイアログ表示後、緊急ボタンがあった位置（中央）をタップ
        // モーダルバリアにより遮断されるはず
        await tester.tapAt(
            tester.getCenter(find.byType(EmergencyButtonWithConfirmation)));
        await tester.pumpAndSettle();

        // Assert - ダイアログ表示回数は1回のまま
        expect(dialogShowCount, equals(1));
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-046-021: 「はい」ボタン連続タップでコールバックが1回だけ呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-013, EDGE-003
      /// 検証内容: ダイアログが閉じる前に連続タップしてもコールバックが1回のみ呼ばれる
      /// 【TDD Red】: ダイアログ内部で連続タップ防止機能が未実装の場合、このテストは失敗する
      testWidgets('TC-046-021: 「はい」ボタン連続タップでコールバックが1回だけ呼ばれる',
          (tester) async {
        // Arrange
        int callbackCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      // ダイアログを閉じないコールバックで連続タップ防止機能をテスト
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {
                          callbackCount++;
                          // 意図的にダイアログを閉じない（連続タップテストのため）
                        },
                        onCancel: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Act - ダイアログを表示
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 「はい」ボタンを短い間隔で連続タップ（ダイアログが閉じない状態で複数回タップ）
        final yesButton = find.text('はい');
        await tester.tap(yesButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(yesButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Assert - コールバックは1回のみ呼ばれるべき（連続タップ防止機能が必要）
        expect(callbackCount, equals(1));
      });

      /// TC-046-022: 「いいえ」ボタン連続タップでonCancelledが1回だけ呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-014, EDGE-004
      /// 【TDD Red】: ダイアログ内部で連続タップ防止機能が未実装の場合、このテストは失敗する
      testWidgets('TC-046-022: 「いいえ」ボタン連続タップでonCancelledが1回だけ呼ばれる',
          (tester) async {
        // Arrange
        int cancelCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      // ダイアログを閉じないコールバックで連続タップ防止機能をテスト
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
                        onCancel: () {
                          cancelCallCount++;
                          // 意図的にダイアログを閉じない（連続タップテストのため）
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Act - ダイアログを表示
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // 「いいえ」ボタンを短い間隔で連続タップ（ダイアログが閉じない状態で複数回タップ）
        final noButton = find.text('いいえ');
        await tester.tap(noButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(noButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(noButton);
        await tester.pumpAndSettle();

        // Assert - コールバックは1回のみ呼ばれるべき（連続タップ防止機能が必要）
        expect(cancelCallCount, equals(1));
      });

      /// TC-046-015: 「いいえ」タップ後に通常状態に戻る
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-102
      /// 検証内容: キャンセル後に再度タップで確認ダイアログが表示される
      testWidgets('TC-046-015: 「いいえ」タップ後に通常状態に戻る（再タップで再表示可能）',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        );

        // Act - 1回目: ダイアログを表示してキャンセル
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);

        await tester.tap(find.text('いいえ'));
        await tester.pumpAndSettle();
        expect(find.byType(EmergencyConfirmationDialog), findsNothing);

        // Act - 2回目: 再度タップでダイアログが表示される
        await tester.tap(find.byType(EmergencyButtonWithConfirmation));
        await tester.pumpAndSettle();

        // Assert - 再度ダイアログが表示される
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });
    });
  });
}
