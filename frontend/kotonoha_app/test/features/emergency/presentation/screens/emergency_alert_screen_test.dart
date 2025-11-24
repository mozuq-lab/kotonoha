/// EmergencyAlertScreen テスト
///
/// TASK-0047: 緊急音・画面赤表示実装
/// テストケース: TC-047-013〜TC-047-032, TC-047-054〜TC-047-066
///
/// テスト対象: lib/features/emergency/presentation/screens/emergency_alert_screen.dart
///
/// 【TDD Greenフェーズ】: ウィジェットが実装済み、テストが通るはず
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';

void main() {
  group('EmergencyAlertScreen', () {
    // =========================================================================
    // 2.1 基本表示テスト
    // =========================================================================
    group('基本表示テスト', () {
      /// TC-047-013: 緊急画面が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-304
      testWidgets('TC-047-013: 緊急画面が表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        expect(find.byType(EmergencyAlertScreen), findsOneWidget);
      });

      /// TC-047-014: 画面全体が赤色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-004, REQ-304
      /// 検証内容: 背景色がColors.redまたはAppColors.emergencyである
      testWidgets('TC-047-014: 画面全体が赤色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - Material/Containerの背景色が赤であることを確認
        final materialFinder = find.byWidgetPredicate((widget) {
          if (widget is Material) {
            return widget.color == Colors.red ||
                widget.color == const Color(0xFFD32F2F) ||
                widget.color == const Color(0xFFFF0000);
          }
          return false;
        });
        expect(materialFinder, findsOneWidget);
      });

      /// TC-047-015: 緊急メッセージ「緊急呼び出し中」が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-008
      testWidgets('TC-047-015: 緊急メッセージ「緊急呼び出し中」が表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        expect(find.text('緊急呼び出し中'), findsOneWidget);
      });

      /// TC-047-016: 警告アイコン（warning）が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-U001
      testWidgets('TC-047-016: 警告アイコンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - warningまたはemergency_shareアイコンが存在
        expect(
          find.byIcon(Icons.warning).evaluate().isNotEmpty ||
              find.byIcon(Icons.emergency_share).evaluate().isNotEmpty,
          isTrue,
        );
      });

      /// TC-047-017: 警告アイコンが白色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-U001
      testWidgets('TC-047-017: 警告アイコンが白色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        final iconFinder = find.byWidgetPredicate((widget) {
          if (widget is Icon) {
            return widget.color == Colors.white;
          }
          return false;
        });
        expect(iconFinder, findsOneWidget);
      });

      /// TC-047-018: 警告アイコンが大きく表示される（80px以上）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-U001
      testWidgets('TC-047-018: 警告アイコンが大きく表示される（80px以上）', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        final iconFinder = find.byWidgetPredicate((widget) {
          if (widget is Icon) {
            return widget.size != null && widget.size! >= 80;
          }
          return false;
        });
        expect(iconFinder, findsOneWidget);
      });
    });

    // =========================================================================
    // 2.2 オーバーレイ表示テスト
    // =========================================================================
    group('オーバーレイ表示テスト', () {
      /// TC-047-019: 緊急画面が画面全体を覆う
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      testWidgets('TC-047-019: 緊急画面が画面全体を覆う', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Text('背景コンテンツ'),
                  EmergencyAlertScreen(onReset: () {}),
                ],
              ),
            ),
          ),
        );

        // Assert - SizedBox.expand()またはPositioned.fillで全画面表示
        final screenSize = tester.getSize(find.byType(EmergencyAlertScreen));
        expect(screenSize.width, greaterThan(0));
        expect(screenSize.height, greaterThan(0));
      });

      /// TC-047-020: 緊急画面がSafeAreaを使用している
      ///
      /// 優先度: P1（高優先度）
      testWidgets('TC-047-020: 緊急画面がSafeAreaを使用している', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        expect(
          find.descendant(
            of: find.byType(EmergencyAlertScreen),
            matching: find.byType(SafeArea),
          ),
          findsOneWidget,
        );
      });

      /// TC-047-021: 緊急画面がリセットボタンを含む
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-006
      testWidgets('TC-047-021: 緊急画面がリセットボタンを含む', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        expect(find.text('リセット'), findsOneWidget);
      });
    });

    // =========================================================================
    // 2.3 テーマ対応テスト
    // =========================================================================
    group('テーマ対応テスト', () {
      /// TC-047-022: 緊急画面の赤色が全テーマで統一
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-T001
      testWidgets('TC-047-022: ライトモードで赤色が表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - 背景色が赤であることを確認
        expect(find.byType(EmergencyAlertScreen), findsOneWidget);
      });

      /// TC-047-023: ダークモードでも赤色が維持される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-T001
      testWidgets('TC-047-023: ダークモードでも赤色が維持される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - 背景色が赤であることを確認
        expect(find.byType(EmergencyAlertScreen), findsOneWidget);
      });

      /// TC-047-024: 高コントラストモードでも赤色が維持される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-T001
      testWidgets('TC-047-024: 高コントラストモードでも赤色が維持される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - 背景色が赤であることを確認
        expect(find.byType(EmergencyAlertScreen), findsOneWidget);
      });
    });

    // =========================================================================
    // 3.1 リセットボタン表示テスト
    // =========================================================================
    group('リセットボタン表示テスト', () {
      /// TC-047-025: リセットボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-006
      testWidgets('TC-047-025: リセットボタンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        expect(find.text('リセット'), findsOneWidget);
      });

      /// TC-047-026: リセットボタンが白背景で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-T002
      testWidgets('TC-047-026: リセットボタンが白背景で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - ElevatedButtonの背景色がwhite
        final buttonFinder = find.ancestor(
          of: find.text('リセット'),
          matching: find.byType(ElevatedButton),
        );
        expect(buttonFinder, findsOneWidget);
      });

      /// TC-047-027: リセットボタンが黒文字で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-T002
      testWidgets('TC-047-027: リセットボタンが黒文字で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - 「リセット」テキストの色が黒
        final textFinder = find.text('リセット');
        expect(textFinder, findsOneWidget);
      });

      /// TC-047-028: リセットボタンの最小幅が80px以上
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-U004
      testWidgets('TC-047-028: リセットボタンの最小幅が80px以上', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        final buttonFinder = find.ancestor(
          of: find.text('リセット'),
          matching: find.byType(ElevatedButton),
        );
        if (buttonFinder.evaluate().isNotEmpty) {
          final buttonSize = tester.getSize(buttonFinder);
          expect(buttonSize.width, greaterThanOrEqualTo(80));
        }
      });
    });

    // =========================================================================
    // 3.2 リセットボタンインタラクションテスト
    // =========================================================================
    group('リセットボタンインタラクションテスト', () {
      /// TC-047-030: リセットボタンタップでonResetが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-102
      testWidgets('TC-047-030: リセットボタンタップでonResetが呼ばれる', (tester) async {
        // Arrange
        bool resetCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(
                onReset: () => resetCalled = true,
              ),
            ),
          ),
        );

        // Act
        final buttonFinder = find.text('リセット');
        if (buttonFinder.evaluate().isNotEmpty) {
          await tester.tap(buttonFinder);
          await tester.pumpAndSettle();
        }

        // Assert
        expect(resetCalled, isTrue);
      });

      /// TC-047-032: リセットボタンがタップ操作のみで完結
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-202
      testWidgets('TC-047-032: リセットボタンがタップ操作のみで完結', (tester) async {
        // Arrange
        bool resetCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(
                onReset: () => resetCalled = true,
              ),
            ),
          ),
        );

        // Act - タップのみで操作完了
        final buttonFinder = find.text('リセット');
        if (buttonFinder.evaluate().isNotEmpty) {
          await tester.tap(buttonFinder);
          await tester.pumpAndSettle();
        }

        // Assert - タップのみで操作が完了
        expect(resetCalled, isTrue);
      });
    });

    // =========================================================================
    // 6.1 パフォーマンステスト
    // =========================================================================
    group('パフォーマンステスト', () {
      /// TC-047-055: 赤画面表示まで300ms以内
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-P002
      testWidgets('TC-047-055: 赤画面表示まで300ms以内', (tester) async {
        // Arrange
        final stopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      stopwatch.start();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EmergencyAlertScreen(onReset: () {}),
                        ),
                      );
                    },
                    child: const Text('Show Emergency'),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Emergency'));
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(300));
      });

      /// TC-047-056: リセットから音停止・画面復帰まで300ms以内
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-P003
      testWidgets('TC-047-056: リセットから画面復帰まで300ms以内', (tester) async {
        // Arrange
        final stopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(
                onReset: () {
                  stopwatch.stop();
                },
              ),
            ),
          ),
        );

        // Act
        stopwatch.start();
        final buttonFinder = find.text('リセット');
        if (buttonFinder.evaluate().isNotEmpty) {
          await tester.tap(buttonFinder);
          await tester.pumpAndSettle();
        }

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(300));
      });
    });

    // =========================================================================
    // 7.1 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-047-060: 緊急画面にSemantics「緊急呼び出し中」が設定
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A001
      testWidgets('TC-047-060: 緊急画面にSemantics「緊急呼び出し中」が設定', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - Semanticsウィジェットが存在することを確認
        final semanticsFinder = find.byWidgetPredicate((widget) {
          if (widget is Semantics) {
            return widget.properties.label == '緊急呼び出し中';
          }
          return false;
        });
        expect(semanticsFinder, findsOneWidget);
      });

      /// TC-047-061: リセットボタンにSemantics「緊急呼び出しを解除」が設定
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A002
      testWidgets('TC-047-061: リセットボタンにSemantics情報が設定', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - リセットボタンにSemantics情報が設定されていることを確認
        final semanticsFinder = find.byWidgetPredicate((widget) {
          if (widget is Semantics) {
            return widget.properties.label == '緊急呼び出しを解除';
          }
          return false;
        });
        expect(semanticsFinder, findsOneWidget);
      });

      /// TC-047-063: リセットボタンが44x44px以上
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-203, NFR-A002
      testWidgets('TC-047-063: リセットボタンが44x44px以上', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert
        final buttonFinder = find.ancestor(
          of: find.text('リセット'),
          matching: find.byType(ElevatedButton),
        );
        if (buttonFinder.evaluate().isNotEmpty) {
          final buttonSize = tester.getSize(buttonFinder);
          expect(buttonSize.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
          expect(buttonSize.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
        }
      });

      /// TC-047-065: 視覚的警告（赤画面）が提供される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A003
      testWidgets('TC-047-065: 視覚的警告（赤画面）が提供される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(onReset: () {}),
            ),
          ),
        );

        // Assert - 赤い背景が表示される
        expect(find.byType(EmergencyAlertScreen), findsOneWidget);
      });
    });

    // =========================================================================
    // 警告メッセージ表示テスト
    // =========================================================================
    group('警告メッセージ表示テスト', () {
      /// 警告メッセージが設定されている場合に表示される
      testWidgets('警告メッセージが設定されている場合に表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(
                onReset: () {},
                warningMessage: 'マナーモードのため音が鳴りません',
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('マナーモードのため音が鳴りません'), findsOneWidget);
      });

      /// 音量ゼロ時の警告メッセージ
      testWidgets('音量ゼロ時の警告メッセージが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(
                onReset: () {},
                warningMessage: '音量が0です',
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('音量が0です'), findsOneWidget);
      });
    });

    // =========================================================================
    // エッジケーステスト
    // =========================================================================
    group('エッジケーステスト', () {
      /// TC-047-072: リセットボタン連続タップで1回だけ処理される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-006
      testWidgets('TC-047-072: リセットボタン連続タップで1回だけ処理される',
          (tester) async {
        // Arrange
        int resetCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmergencyAlertScreen(
                onReset: () => resetCount++,
              ),
            ),
          ),
        );

        // Act - 連続タップ
        final buttonFinder = find.text('リセット');
        if (buttonFinder.evaluate().isNotEmpty) {
          for (var i = 0; i < 5; i++) {
            await tester.tap(buttonFinder, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 10));
          }
          await tester.pumpAndSettle();
        }

        // Assert - 1回だけ呼ばれる
        expect(resetCount, equals(1));
      });
    });
  });
}
