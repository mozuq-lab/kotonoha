// HistoryScreen表示確認 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test
// 対象: HistoryScreen（履歴画面スケルトン）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// テスト対象のウィジェット（実装後にコメント解除）
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';

void main() {
  group('HistoryScreen表示テスト', () {
    // TC-008: HistoryScreen表示確認テスト
    // テストカテゴリ: Widget Test
    // 対応要件: FR-005（画面スケルトン作成）
    // 対応受け入れ基準: AC-004
    // 青信号: タスクファイルでHistoryScreen作成が明示
    testWidgets('TC-008: HistoryScreenが正常に表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // MaterialApp内でHistoryScreenをラップ

      // When（実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Then（検証フェーズ）
      // HistoryScreenウィジェットが存在することを確認
      expect(
        find.byType(HistoryScreen),
        findsOneWidget,
        reason: 'HistoryScreenウィジェットが表示される必要がある',
      );

      // Scaffoldが存在することを確認
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'HistoryScreenはScaffold構造を持つ必要がある',
      );

      // AppBarが存在することを確認
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: 'HistoryScreenはAppBarを持つ必要がある',
      );

      // 画面識別テキストが表示されることを確認
      expect(
        find.text('履歴画面'),
        findsOneWidget,
        reason: 'HistoryScreenには「履歴画面」という識別テキストが表示される必要がある',
      );
    });

    // HistoryScreenがconstコンストラクタを持つことを確認
    // 青信号: CLAUDE.mdで「constコンストラクタを可能な限り使用」が明示
    testWidgets('HistoryScreenはconstコンストラクタを持つ', (WidgetTester tester) async {
      // Given/When（準備・実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Then（検証フェーズ）
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    // HistoryScreenがkeyパラメータを受け取れることを確認
    // 青信号: CLAUDE.mdで「ウィジェットはkeyパラメータを持つ」が明示
    testWidgets('HistoryScreenはkeyパラメータを受け取れる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      const testKey = Key('history_screen_test_key');

      // When（実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(key: testKey),
        ),
      );

      // Then（検証フェーズ）
      expect(
        find.byKey(testKey),
        findsOneWidget,
        reason: 'HistoryScreenは指定されたkeyで識別可能である必要がある',
      );
    });
  });
}
