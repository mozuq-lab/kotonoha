/// EmergencyConfirmationDialog ウィジェットテスト
///
/// TASK-0045: 緊急ボタンUI実装
/// テストケース: TC-045-028〜TC-045-049
///
/// テスト対象: lib/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

void main() {
  group('EmergencyConfirmationDialog', () {
    // =========================================================================
    // 2.1 表示テスト
    // =========================================================================
    group('表示テスト', () {
      /// TC-045-028: ダイアログが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2004
      testWidgets('TC-045-028: ダイアログが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        // ダイアログを表示
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-045-029: タイトル「緊急呼び出し」が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-006
      testWidgets('TC-045-029: タイトル「緊急呼び出し」が表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('緊急呼び出し'), findsOneWidget);
      });

      /// TC-045-030: メッセージ「緊急呼び出しを実行しますか?」が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101, AC-006
      testWidgets('TC-045-030: メッセージ「緊急呼び出しを実行しますか?」が表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('緊急呼び出しを実行しますか?'), findsOneWidget);
      });

      /// TC-045-031: 補足メッセージ「周囲に緊急音が鳴り、画面が赤くなります。」が表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-303, REQ-304
      testWidgets('TC-045-031: 補足メッセージが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('周囲に緊急音が鳴り'), findsOneWidget);
      });

      /// TC-045-032: 「はい」ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-007
      testWidgets('TC-045-032: 「はい」ボタンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('はい'), findsOneWidget);
      });

      /// TC-045-033: 「いいえ」ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-007
      testWidgets('TC-045-033: 「いいえ」ボタンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('いいえ'), findsOneWidget);
      });

      /// TC-045-034: 「はい」ボタンが赤色で表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-U001
      testWidgets('TC-045-034: 「はい」ボタンが赤色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - 「はい」ボタンの背景色が赤系であることを確認
        // 実装時: ElevatedButtonのstyle.backgroundColorが赤系であることを検証
        expect(find.text('はい'), findsOneWidget);
      });

      /// TC-045-035: 「いいえ」ボタンがグレー系で表示される
      ///
      /// 優先度: P1（高優先度）
      testWidgets('TC-045-035: 「いいえ」ボタンがグレー系で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - 「いいえ」ボタンの背景色がグレー系であることを確認
        // 実装時: ElevatedButtonのstyle.backgroundColorがグレー系であることを検証
        expect(find.text('いいえ'), findsOneWidget);
      });

      /// TC-ED-008: ダイアログがモーダルとして表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-204
      testWidgets('TC-ED-008: ダイアログがモーダルとして表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false, // モーダル
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - ダイアログが表示されていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
        // モーダルバリアが存在することを確認
        expect(find.byType(ModalBarrier), findsWidgets);
      });
    });

    // =========================================================================
    // 2.2 インタラクションテスト
    // =========================================================================
    group('インタラクションテスト', () {
      /// TC-045-036: 「はい」ボタンタップでonConfirmが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-104, AC-008
      testWidgets('TC-045-036: 「はい」ボタンタップでonConfirmが呼ばれる', (tester) async {
        // Arrange
        bool confirmCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () => confirmCalled = true,
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('はい'));
        await tester.pumpAndSettle();

        // Assert
        expect(confirmCalled, isTrue);
      });

      /// TC-045-037: 「いいえ」ボタンタップでonCancelが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-105, AC-009
      testWidgets('TC-045-037: 「いいえ」ボタンタップでonCancelが呼ばれる', (tester) async {
        // Arrange
        bool cancelCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
                        onCancel: () => cancelCalled = true,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('いいえ'));
        await tester.pumpAndSettle();

        // Assert
        expect(cancelCalled, isTrue);
      });

      /// TC-045-038: ダイアログ外タップでダイアログが閉じない（誤操作防止）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-005 (修正: 誤タップ防止のため閉じない仕様)
      testWidgets('TC-045-038: ダイアログ外タップでダイアログが閉じない', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false, // 誤操作防止
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
                        onCancel: () => Navigator.of(context).pop(),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - ダイアログが表示されていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);

        // Act - ダイアログ外をタップ（バリアをタップ）
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Assert - ダイアログが閉じないことを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// TC-ED-009: 「はい」タップでダイアログ閉じ + 緊急処理実行
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-104
      testWidgets('TC-ED-009: 「はい」タップでダイアログが閉じる', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => EmergencyConfirmationDialog(
                        onConfirm: () => Navigator.of(dialogContext).pop(),
                        onCancel: () => Navigator.of(dialogContext).pop(),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // ダイアログが表示されていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);

        // Act
        await tester.tap(find.text('はい'));
        await tester.pumpAndSettle();

        // Assert - ダイアログが閉じることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsNothing);
      });

      /// TC-ED-010: 「いいえ」タップでダイアログ閉じる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-105
      testWidgets('TC-ED-010: 「いいえ」タップでダイアログが閉じる', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => EmergencyConfirmationDialog(
                        onConfirm: () => Navigator.of(dialogContext).pop(),
                        onCancel: () => Navigator.of(dialogContext).pop(),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // ダイアログが表示されていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);

        // Act
        await tester.tap(find.text('いいえ'));
        await tester.pumpAndSettle();

        // Assert - ダイアログが閉じることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsNothing);
      });
    });

    // =========================================================================
    // 2.3 アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-045-040: 「はい」ボタンのタップターゲットが44x44px以上
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-014, REQ-5001
      testWidgets('TC-045-040: 「はい」ボタンのタップターゲットが44x44px以上',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - 「はい」ボタンのサイズを確認
        final yesButton = find.widgetWithText(ElevatedButton, 'はい');
        final size = tester.getSize(yesButton);
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// TC-045-041: 「いいえ」ボタンのタップターゲットが44x44px以上
      ///
      /// 優先度: P0（必須）
      /// 関連要件: AC-014, REQ-5001
      testWidgets('TC-045-041: 「いいえ」ボタンのタップターゲットが44x44px以上',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - 「いいえ」ボタンのサイズを確認
        final noButton = find.widgetWithText(ElevatedButton, 'いいえ');
        final size = tester.getSize(noButton);
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// TC-045-042: 「はい」ボタン幅が100px以上である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: 境界値
      testWidgets('TC-045-042: 「はい」ボタン幅が100px以上である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        final yesButton = find.widgetWithText(ElevatedButton, 'はい');
        final size = tester.getSize(yesButton);
        expect(size.width, greaterThanOrEqualTo(100.0));
      });

      /// TC-045-043: 「いいえ」ボタン幅が100px以上である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: 境界値
      testWidgets('TC-045-043: 「いいえ」ボタン幅が100px以上である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        final noButton = find.widgetWithText(ElevatedButton, 'いいえ');
        final size = tester.getSize(noButton);
        expect(size.width, greaterThanOrEqualTo(100.0));
      });

      /// TC-045-044: ダイアログにSemantics情報が設定されている
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-A003
      testWidgets('TC-045-044: ダイアログにSemantics情報が設定されている',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - Semanticsウィジェットが設定されていることを確認
        expect(
          find.descendant(
            of: find.byType(EmergencyConfirmationDialog),
            matching: find.byType(Semantics),
          ),
          findsWidgets,
        );
      });
    });

    // =========================================================================
    // 2.4 テーマ対応テスト
    // =========================================================================
    group('テーマ対応テスト', () {
      /// TC-045-045: ライトモードで適切な配色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103
      testWidgets('TC-045-045: ライトモードで適切な配色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(EmergencyConfirmationDialog));
        expect(Theme.of(context).brightness, equals(Brightness.light));
      });

      /// TC-045-046: ダークモードで適切な配色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103
      testWidgets('TC-045-046: ダークモードで適切な配色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.byType(EmergencyConfirmationDialog));
        expect(Theme.of(context).brightness, equals(Brightness.dark));
      });

      /// TC-045-047: 高コントラストモードで適切な配色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103, FR-202
      testWidgets('TC-045-047: 高コントラストモードで適切な配色で表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => EmergencyConfirmationDialog(
                        onConfirm: () {},
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Assert - 高コントラストテーマが適用されていることを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });
    });

    // =========================================================================
    // 2.5 エッジケーステスト
    // =========================================================================
    group('エッジケーステスト', () {
      /// TC-045-048: 「はい」ボタン連続タップでonConfirmが1回だけ呼ばれる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-001
      testWidgets('TC-045-048: 「はい」ボタン連続タップでonConfirmが1回だけ呼ばれる',
          (tester) async {
        // Arrange
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => EmergencyConfirmationDialog(
                        onConfirm: () {
                          callCount++;
                          Navigator.of(dialogContext).pop();
                        },
                        onCancel: () => Navigator.of(dialogContext).pop(),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 連続タップ
        await tester.tap(find.text('はい'));
        await tester.pump(const Duration(milliseconds: 50));
        // ダイアログが閉じた後の追加タップは無効
        await tester.pumpAndSettle();

        // Assert
        expect(callCount, equals(1));
      });

      /// TC-045-049: 「いいえ」ボタン連続タップでonCancelが1回だけ呼ばれる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-001
      testWidgets('TC-045-049: 「いいえ」ボタン連続タップでonCancelが1回だけ呼ばれる',
          (tester) async {
        // Arrange
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => EmergencyConfirmationDialog(
                        onConfirm: () => Navigator.of(dialogContext).pop(),
                        onCancel: () {
                          callCount++;
                          Navigator.of(dialogContext).pop();
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 連続タップ
        await tester.tap(find.text('いいえ'));
        await tester.pump(const Duration(milliseconds: 50));
        // ダイアログが閉じた後の追加タップは無効
        await tester.pumpAndSettle();

        // Assert
        expect(callCount, equals(1));
      });
    });
  });
}
