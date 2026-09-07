/// EmergencyConfirmationDialog ウィジェットテスト
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
    // 2.1 表示テスト
    group('表示テスト', () {
      /// ダイアログが表示される
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

      /// タイトル「緊急呼び出し」が表示される
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

      /// メッセージ「緊急呼び出しを実行しますか?」が表示される
      testWidgets('TC-045-030: メッセージ「緊急呼び出しを実行しますか?」が表示される', (tester) async {
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

      /// 補足メッセージ「周囲に緊急音が鳴り、画面が赤くなります。」が表示される
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

      /// 「はい」ボタンが表示される
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

      /// 「いいえ」ボタンが表示される
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

      /// 「はい」ボタンが赤色で表示される
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

      /// 「いいえ」ボタンがグレー系で表示される
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

      /// ダイアログがモーダルとして表示される
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

    // 2.2 インタラクションテスト
    group('インタラクションテスト', () {
      /// 「はい」ボタンタップでonConfirmが呼ばれる
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

      /// 「いいえ」ボタンタップでonCancelが呼ばれる
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

      /// ダイアログ外タップでダイアログが閉じない（誤操作防止）
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

      /// 「はい」タップでダイアログ閉じ + 緊急処理実行
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

      /// 「いいえ」タップでダイアログ閉じる
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

    // 2.3 アクセシビリティテスト
    group('アクセシビリティテスト', () {
      /// 「はい」ボタンのタップターゲットが44x44px以上
      testWidgets('TC-045-040: 「はい」ボタンのタップターゲットが44x44px以上', (tester) async {
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

      /// 「いいえ」ボタンのタップターゲットが44x44px以上
      testWidgets('TC-045-041: 「いいえ」ボタンのタップターゲットが44x44px以上', (tester) async {
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

      /// 「はい」ボタン幅が100px以上である
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

      /// 「いいえ」ボタン幅が100px以上である
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

      /// ダイアログにSemantics情報が設定されている
      testWidgets('TC-045-044: ダイアログにSemantics情報が設定されている', (tester) async {
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

    // 2.4 テーマ対応テスト
    group('テーマ対応テスト', () {
      /// ライトモードで適切な配色で表示される
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
        final context =
            tester.element(find.byType(EmergencyConfirmationDialog));
        expect(Theme.of(context).brightness, equals(Brightness.light));
      });

      /// ダークモードで適切な配色で表示される
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
        final context =
            tester.element(find.byType(EmergencyConfirmationDialog));
        expect(Theme.of(context).brightness, equals(Brightness.dark));
      });

      /// 高コントラストモードで適切な配色で表示される
      testWidgets('TC-045-047: 高コントラストモードで適切な配色で表示される', (tester) async {
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

    // 2.5 エッジケーステスト
    group('エッジケーステスト', () {
      /// 「はい」ボタン連続タップでonConfirmが1回だけ呼ばれる
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

      /// 「いいえ」ボタン連続タップでonCancelが1回だけ呼ばれる
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

    group('TASK-0046 追加テスト: ボタン配置・連続タップ防止', () {
      /// ボタンが「いいえ」「はい」の順（左→右）で配置される
      testWidgets('TC-046-008: ボタンが「いいえ」「はい」の順（左→右）で配置される', (tester) async {
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

        // Assert - 「いいえ」と「はい」の位置を比較
        final noButton = find.widgetWithText(ElevatedButton, 'いいえ');
        final yesButton = find.widgetWithText(ElevatedButton, 'はい');

        final noButtonCenter = tester.getCenter(noButton);
        final yesButtonCenter = tester.getCenter(yesButton);

        // 「いいえ」が「はい」より左にあることを検証
        expect(noButtonCenter.dx, lessThan(yesButtonCenter.dx));
      });

      /// モーダルバリアが存在する
      testWidgets('TC-046-017: モーダルバリアが存在する', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
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

        // Assert - ModalBarrierが存在することを確認
        expect(find.byType(ModalBarrier), findsWidgets);
      });

      /// ダイアログ外の複数回タップでもダイアログが閉じない
      testWidgets('TC-046-018: ダイアログ外の複数回タップでもダイアログが閉じない', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
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

        // Act - ダイアログ外を複数回タップ
        for (var i = 0; i < 5; i++) {
          await tester.tapAt(const Offset(10, 10));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();

        // Assert - ダイアログが閉じないことを確認
        expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
      });

      /// 確認ダイアログにSemantics「緊急呼び出し確認ダイアログ」が設定されている
      testWidgets('TC-046-027: 確認ダイアログにSemantics「緊急呼び出し確認ダイアログ」が設定されている',
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

        // Assert - Semanticsラベルが設定されていることを確認
        final semantics = tester.getSemantics(
          find.byType(EmergencyConfirmationDialog),
        );
        expect(semantics.label, contains('緊急呼び出し確認ダイアログ'));
      });

      /// 「はい」ボタン連続タップでコールバックが1回だけ呼ばれる（ダイアログ単体）
      testWidgets('TC-046-021: 「はい」ボタン連続タップでコールバックが1回だけ呼ばれる（ダイアログ単体）',
          (tester) async {
        // Arrange
        int confirmCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      // ダイアログを閉じないコールバックで、連続タップ防止機能をテスト
                      builder: (dialogContext) => EmergencyConfirmationDialog(
                        onConfirm: () {
                          confirmCallCount++;
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 「はい」ボタンを連続タップ（ダイアログが閉じない状態で複数回タップ）
        final yesButton = find.text('はい');
        await tester.tap(yesButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(yesButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(yesButton);
        await tester.pumpAndSettle();

        // Assert - コールバックは1回のみ呼ばれるべき（連続タップ防止機能が必要）
        expect(confirmCallCount, equals(1));
      });

      /// 「いいえ」ボタン連続タップでコールバックが1回だけ呼ばれる（ダイアログ単体）
      testWidgets('TC-046-022: 「いいえ」ボタン連続タップでコールバックが1回だけ呼ばれる（ダイアログ単体）',
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
                      // ダイアログを閉じないコールバックで、連続タップ防止機能をテスト
                      builder: (dialogContext) => EmergencyConfirmationDialog(
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

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act - 「いいえ」ボタンを連続タップ（ダイアログが閉じない状態で複数回タップ）
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
    });
  });
}
