/// ClearConfirmationDialog ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_confirmation_dialog.dart';

void main() {
  group('ClearConfirmationDialog - 表示テスト', () {
    // 確認ダイアログの表示確認
    /// ClearConfirmationDialogが正しく表示されることを確認
    /// 前提条件
    /// ClearConfirmationDialogウィジェットがインポートされている
    /// 入力
    /// なし
    /// 期待結果
    /// 確認ダイアログが画面上に表示される
    testWidgets('TC-039-016: ClearConfirmationDialogが正しく表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ClearConfirmationDialog), findsOneWidget);
    });

    // 確認ダイアログにタイトル「確認」が表示される
    /// ClearConfirmationDialogにタイトル「確認」が表示されることを確認
    /// 前提条件
    /// なし
    /// 入力
    /// なし
    /// 期待結果
    /// 「確認」というタイトルが表示される
    testWidgets('TC-039-017: ClearConfirmationDialogにタイトル「確認」が表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('確認'), findsOneWidget);
    });

    // 確認ダイアログにメッセージが表示される
    /// ClearConfirmationDialogに「入力内容をすべて消去しますか？」が表示されることを確認
    /// 前提条件
    /// なし
    /// 入力
    /// なし
    /// 期待結果
    /// 「入力内容をすべて消去しますか？」というメッセージが表示される
    testWidgets(
        'TC-039-018: ClearConfirmationDialogに「入力内容をすべて消去しますか？」が表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('入力内容をすべて消去しますか？'), findsOneWidget);
    });

    // 確認ダイアログに「はい」ボタンが表示される
    /// ClearConfirmationDialogに「はい」ボタンが表示されることを確認
    /// 前提条件
    /// なし
    /// 入力
    /// なし
    /// 期待結果
    /// 「はい」ボタンが表示される
    testWidgets('TC-039-019: ClearConfirmationDialogに「はい」ボタンが表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('はい'), findsOneWidget);
    });

    // 確認ダイアログに「いいえ」ボタンが表示される
    /// ClearConfirmationDialogに「いいえ」ボタンが表示されることを確認
    /// 前提条件
    /// なし
    /// 入力
    /// なし
    /// 期待結果
    /// 「いいえ」ボタンが表示される
    testWidgets('TC-039-020: ClearConfirmationDialogに「いいえ」ボタンが表示されることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('いいえ'), findsOneWidget);
    });
  });

  group('ClearConfirmationDialog - インタラクションテスト', () {
    // 「はい」ボタンタップでonConfirmedコールバックが実行される
    /// 「はい」ボタンタップ時にonConfirmedコールバックが実行されることを確認
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// 「はい」ボタンをタップ
    /// 期待結果
    /// onConfirmedコールバックが1回実行される
    testWidgets('TC-039-021: 「はい」ボタンタップ時にonConfirmedコールバックが実行されることを確認',
        (tester) async {
      // Arrange
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {
                          confirmed = true;
                          Navigator.of(context).pop();
                        },
                        onCancelled: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - 「はい」ボタンをタップ
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      // Assert
      expect(confirmed, isTrue);
    });

    // 「はい」ボタンタップでダイアログが閉じる
    /// 「はい」ボタンタップ後にダイアログが閉じることを確認
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// 「はい」ボタンをタップ
    /// 期待結果
    /// ダイアログが画面から消える
    testWidgets('TC-039-022: 「はい」ボタンタップ後にダイアログが閉じることを確認', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {
                          Navigator.of(context).pop();
                        },
                        onCancelled: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.byType(ClearConfirmationDialog), findsOneWidget);

      // Act - 「はい」ボタンをタップ
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      // Assert - ダイアログが閉じていることを確認
      expect(find.byType(ClearConfirmationDialog), findsNothing);
    });

    // 「いいえ」ボタンタップでonCancelledコールバックが実行される
    /// 「いいえ」ボタンタップ時にonCancelledコールバックが実行されることを確認
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// 「いいえ」ボタンをタップ
    /// 期待結果
    /// onCancelledコールバックが1回実行される
    testWidgets('TC-039-023: 「いいえ」ボタンタップ時にonCancelledコールバックが実行されることを確認',
        (tester) async {
      // Arrange
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {
                          Navigator.of(context).pop();
                        },
                        onCancelled: () {
                          cancelled = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - 「いいえ」ボタンをタップ
      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();

      // Assert
      expect(cancelled, isTrue);
    });

    // 「いいえ」ボタンタップでダイアログが閉じる
    /// 「いいえ」ボタンタップ後にダイアログが閉じることを確認
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// 「いいえ」ボタンをタップ
    /// 期待結果
    /// ダイアログが画面から消える
    testWidgets('TC-039-024: 「いいえ」ボタンタップ後にダイアログが閉じることを確認', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {
                          Navigator.of(context).pop();
                        },
                        onCancelled: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.byType(ClearConfirmationDialog), findsOneWidget);

      // Act - 「いいえ」ボタンをタップ
      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();

      // Assert - ダイアログが閉じていることを確認
      expect(find.byType(ClearConfirmationDialog), findsNothing);
    });

    // ダイアログ外タップでダイアログが閉じない（モーダル）
    /// ダイアログ外をタップしてもダイアログが閉じないことを確認（barrierDismissible: false）
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// ダイアログ外（バリア部分）をタップ
    /// 期待結果
    /// ダイアログが閉じずに表示され続ける
    testWidgets(
        'TC-039-025: ダイアログ外をタップしてもダイアログが閉じないことを確認（barrierDismissible: false）',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false, // モーダルダイアログ
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {
                          Navigator.of(context).pop();
                        },
                        onCancelled: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.byType(ClearConfirmationDialog), findsOneWidget);

      // Act - ダイアログ外（バリア部分）をタップ
      // バリアはダイアログの背景全体なので、画面の隅をタップ
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Assert - ダイアログがまだ表示されていることを確認
      expect(find.byType(ClearConfirmationDialog), findsOneWidget);
    });
  });

  group('ClearConfirmationDialog - アクセシビリティテスト', () {
    // ダイアログの「はい」ボタンサイズが44x44px以上
    /// ダイアログの「はい」ボタンのタップターゲットが44x44px以上であることを確認
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// なし
    /// 期待結果
    /// width >= 44.0, height >= 44.0
    testWidgets('TC-039-026: ダイアログの「はい」ボタンのタップターゲットが44x44px以上であることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert - 「はい」ボタンのサイズを確認
      final yesButtonFinder = find.widgetWithText(TextButton, 'はい');
      final size = tester.getSize(yesButtonFinder);
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });

    // ダイアログの「いいえ」ボタンサイズが44x44px以上
    /// ダイアログの「いいえ」ボタンのタップターゲットが44x44px以上であることを確認
    /// 前提条件
    /// ClearConfirmationDialogが表示されている
    /// 入力
    /// なし
    /// 期待結果
    /// width >= 44.0, height >= 44.0
    testWidgets('TC-039-027: ダイアログの「いいえ」ボタンのタップターゲットが44x44px以上であることを確認',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ClearConfirmationDialog(
                        onConfirmed: () {},
                        onCancelled: () {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert - 「いいえ」ボタンのサイズを確認
      final noButtonFinder = find.widgetWithText(TextButton, 'いいえ');
      final size = tester.getSize(noButtonFinder);
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.width, greaterThanOrEqualTo(44.0));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });
  });
}
