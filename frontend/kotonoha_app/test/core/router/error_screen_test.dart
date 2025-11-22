// ErrorScreen表示確認 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test
// 対象: ErrorScreen（エラー画面）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// テスト対象のウィジェット（実装後にコメント解除）
import 'package:kotonoha_app/core/router/error_screen.dart';

void main() {
  group('ErrorScreen表示テスト', () {
    // TC-010: ErrorScreen表示確認テスト
    // テストカテゴリ: Widget Test
    // 対応要件: FR-004（エラーページ対応）, FR-005（画面スケルトン作成）
    // 対応受け入れ基準: AC-006
    // 黄信号: NFR-204から推測（エラーメッセージを分かりやすい日本語で表示）
    testWidgets('TC-010: ErrorScreenが正常に表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // MaterialApp内でErrorScreenをラップ
      // テスト用のエラー情報を渡す

      // When（実行フェーズ）
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: Exception('テストエラー')),
        ),
      );

      // Then（検証フェーズ）
      // ErrorScreenウィジェットが存在することを確認
      expect(
        find.byType(ErrorScreen),
        findsOneWidget,
        reason: 'ErrorScreenウィジェットが表示される必要がある',
      );

      // Scaffoldが存在することを確認
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'ErrorScreenはScaffold構造を持つ必要がある',
      );
    });

    // エラーメッセージが日本語で表示されることを確認
    // 黄信号: NFR-204（エラーメッセージを分かりやすい日本語で表示）
    testWidgets('ErrorScreenにはエラーメッセージが日本語で表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // When（実行フェーズ）
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: Exception('ページが見つかりません')),
        ),
      );

      // Then（検証フェーズ）
      // エラー関連のテキストが存在することを確認
      // 「エラー」または「見つかりません」等のテキストを探す
      expect(
        find.textContaining('エラー'),
        findsWidgets,
        reason: 'ErrorScreenにはエラーに関するメッセージが表示される必要がある',
      );
    });

    // ホーム画面への復帰ボタンが表示されることを確認
    // 黄信号: NFR-204（復旧方法を示す）
    testWidgets('ErrorScreenにはホームへの復帰ボタンが表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // When（実行フェーズ）
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: Exception('テストエラー')),
        ),
      );

      // Then（検証フェーズ）
      // ホームに戻るボタンが存在することを確認
      expect(
        find.text('ホームに戻る'),
        findsOneWidget,
        reason: 'ErrorScreenにはホームへの復帰ボタンが必要（NFR-204準拠）',
      );
    });

    // ホーム復帰ボタンがタップ可能であることを確認
    // 黄信号: NFR-204（復旧方法を示す）
    testWidgets('ホームに戻るボタンはタップ可能である', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // When（実行フェーズ）
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(error: Exception('テストエラー')),
        ),
      );

      // Then（検証フェーズ）
      // ボタンまたはタップ可能なウィジェットとして存在することを確認
      final button = find.widgetWithText(ElevatedButton, 'ホームに戻る');
      final textButton = find.widgetWithText(TextButton, 'ホームに戻る');
      final outlinedButton = find.widgetWithText(OutlinedButton, 'ホームに戻る');
      final inkWell = find.widgetWithText(InkWell, 'ホームに戻る');
      final gestureDetector = find.widgetWithText(GestureDetector, 'ホームに戻る');

      // いずれかのタップ可能なウィジェットが存在することを確認
      final hasButton = button.evaluate().isNotEmpty ||
          textButton.evaluate().isNotEmpty ||
          outlinedButton.evaluate().isNotEmpty ||
          inkWell.evaluate().isNotEmpty ||
          gestureDetector.evaluate().isNotEmpty;

      expect(
        hasButton,
        isTrue,
        reason: 'ホームに戻るボタンはタップ可能なウィジェットである必要がある',
      );
    });

    // ErrorScreenがkeyパラメータを受け取れることを確認
    // 青信号: CLAUDE.mdで「ウィジェットはkeyパラメータを持つ」が明示
    testWidgets('ErrorScreenはkeyパラメータを受け取れる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      const testKey = Key('error_screen_test_key');

      // When（実行フェーズ）
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(
            key: testKey,
            error: Exception('テストエラー'),
          ),
        ),
      );

      // Then（検証フェーズ）
      expect(
        find.byKey(testKey),
        findsOneWidget,
        reason: 'ErrorScreenは指定されたkeyで識別可能である必要がある',
      );
    });

    // ErrorScreenがnullのエラーでも表示可能であることを確認
    // 黄信号: エッジケースへの対応
    testWidgets('ErrorScreenはnullエラーでも表示可能である', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // When（実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorScreen(error: null),
        ),
      );

      // Then（検証フェーズ）
      // エラーなくウィジェットがビルドされることを確認
      expect(
        find.byType(ErrorScreen),
        findsOneWidget,
        reason: 'ErrorScreenはnullエラーでもクラッシュせず表示される必要がある',
      );
    });
  });
}
