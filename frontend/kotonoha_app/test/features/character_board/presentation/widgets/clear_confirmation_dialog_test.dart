/// ClearConfirmationDialog ウィジェットテスト
///
/// TASK-0039: 削除ボタン・全消去ボタン実装
/// テストケース: TC-039-016〜TC-039-027
///
/// テスト対象: lib/features/character_board/presentation/widgets/clear_confirmation_dialog.dart
///
/// TDD Redフェーズ: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_confirmation_dialog.dart';

void main() {
  group('ClearConfirmationDialog - 表示テスト', () {
    // =========================================================================
    // TC-039-016: 確認ダイアログの表示確認
    // =========================================================================
    /// TC-039-016: ClearConfirmationDialogが正しく表示されることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogウィジェットがインポートされている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 確認ダイアログが画面上に表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-002
    /// 優先度: P0 必須
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

    // =========================================================================
    // TC-039-017: 確認ダイアログにタイトル「確認」が表示される
    // =========================================================================
    /// TC-039-017: ClearConfirmationDialogにタイトル「確認」が表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 「確認」というタイトルが表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-2001
    /// 優先度: P1 重要
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

    // =========================================================================
    // TC-039-018: 確認ダイアログにメッセージが表示される
    // =========================================================================
    /// TC-039-018: ClearConfirmationDialogに「入力内容をすべて消去しますか？」が表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 「入力内容をすべて消去しますか？」というメッセージが表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-2001
    /// 優先度: P1 重要
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

    // =========================================================================
    // TC-039-019: 確認ダイアログに「はい」ボタンが表示される
    // =========================================================================
    /// TC-039-019: ClearConfirmationDialogに「はい」ボタンが表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 「はい」ボタンが表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-003
    /// 優先度: P0 必須
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

    // =========================================================================
    // TC-039-020: 確認ダイアログに「いいえ」ボタンが表示される
    // =========================================================================
    /// TC-039-020: ClearConfirmationDialogに「いいえ」ボタンが表示されることを確認
    ///
    /// 前提条件:
    /// - なし
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - 「いいえ」ボタンが表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-004
    /// 優先度: P0 必須
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
    // =========================================================================
    // TC-039-021: 「はい」ボタンタップでonConfirmedコールバックが実行される
    // =========================================================================
    /// TC-039-021: 「はい」ボタンタップ時にonConfirmedコールバックが実行されることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - 「はい」ボタンをタップ
    ///
    /// 期待結果:
    /// - onConfirmedコールバックが1回実行される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-003
    /// 優先度: P0 必須
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

    // =========================================================================
    // TC-039-022: 「はい」ボタンタップでダイアログが閉じる
    // =========================================================================
    /// TC-039-022: 「はい」ボタンタップ後にダイアログが閉じることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - 「はい」ボタンをタップ
    ///
    /// 期待結果:
    /// - ダイアログが画面から消える
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-003
    /// 優先度: P0 必須
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

    // =========================================================================
    // TC-039-023: 「いいえ」ボタンタップでonCancelledコールバックが実行される
    // =========================================================================
    /// TC-039-023: 「いいえ」ボタンタップ時にonCancelledコールバックが実行されることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - 「いいえ」ボタンをタップ
    ///
    /// 期待結果:
    /// - onCancelledコールバックが1回実行される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-004
    /// 優先度: P0 必須
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

    // =========================================================================
    // TC-039-024: 「いいえ」ボタンタップでダイアログが閉じる
    // =========================================================================
    /// TC-039-024: 「いいえ」ボタンタップ後にダイアログが閉じることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - 「いいえ」ボタンをタップ
    ///
    /// 期待結果:
    /// - ダイアログが画面から消える
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: REQ-2001, AC-004
    /// 優先度: P0 必須
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

    // =========================================================================
    // TC-039-025: ダイアログ外タップでダイアログが閉じない（モーダル）
    // =========================================================================
    /// TC-039-025: ダイアログ外をタップしてもダイアログが閉じないことを確認（barrierDismissible: false）
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - ダイアログ外（バリア部分）をタップ
    ///
    /// 期待結果:
    /// - ダイアログが閉じずに表示され続ける
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-5002, AC-013
    /// 優先度: P1 重要
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
    // =========================================================================
    // TC-039-026: ダイアログの「はい」ボタンサイズが44x44px以上
    // =========================================================================
    /// TC-039-026: ダイアログの「はい」ボタンのタップターゲットが44x44px以上であることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - width >= 44.0, height >= 44.0
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-5001, AC-008
    /// 優先度: P1 重要
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

    // =========================================================================
    // TC-039-027: ダイアログの「いいえ」ボタンサイズが44x44px以上
    // =========================================================================
    /// TC-039-027: ダイアログの「いいえ」ボタンのタップターゲットが44x44px以上であることを確認
    ///
    /// 前提条件:
    /// - ClearConfirmationDialogが表示されている
    ///
    /// 入力:
    /// - なし
    ///
    /// 期待結果:
    /// - width >= 44.0, height >= 44.0
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: REQ-5001, AC-008
    /// 優先度: P1 重要
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
