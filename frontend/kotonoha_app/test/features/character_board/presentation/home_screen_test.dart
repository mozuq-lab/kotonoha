// HomeScreen表示確認 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test + flutter_riverpod
// 対象: HomeScreen（文字盤画面）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// テスト対象のウィジェット
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';

void main() {
  group('HomeScreen表示テスト', () {
    // TC-006: HomeScreen表示確認テスト
    // テストカテゴリ: Widget Test
    // 対応要件: FR-005（画面スケルトン作成）
    // 対応受け入れ基準: AC-002
    // 青信号: タスクファイルでHomeScreen作成が明示
    testWidgets('TC-006: HomeScreenが正常に表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // ProviderScope内でHomeScreenをラップ

      // When（実行フェーズ）
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // 初期化を待つ
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      // HomeScreenウィジェットが存在することを確認
      expect(
        find.byType(HomeScreen),
        findsOneWidget,
        reason: 'HomeScreenウィジェットが表示される必要がある',
      );

      // Scaffoldが存在することを確認
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'HomeScreenはScaffold構造を持つ必要がある',
      );

      // AppBarが存在することを確認
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: 'HomeScreenはAppBarを持つ必要がある',
      );

      // 入力プレースホルダーが表示されることを確認
      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: 'HomeScreenには入力プレースホルダーが表示される必要がある',
      );
    });

    // HomeScreenがconstコンストラクタを持つことを確認
    // 青信号: CLAUDE.mdで「constコンストラクタを可能な限り使用」が明示
    testWidgets('HomeScreenはconstコンストラクタを持つ', (WidgetTester tester) async {
      // Given/When（準備・実行フェーズ）
      // constコンストラクタでHomeScreenを生成
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      // constコンストラクタが使用可能であれば、上記のコードがコンパイルされる
      // ランタイムエラーなくウィジェットがビルドされることを確認
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    // HomeScreenがkeyパラメータを受け取れることを確認
    // 青信号: CLAUDE.mdで「ウィジェットはkeyパラメータを持つ」が明示
    testWidgets('HomeScreenはkeyパラメータを受け取れる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      const testKey = Key('home_screen_test_key');

      // When（実行フェーズ）
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(key: testKey),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      // 指定したキーでウィジェットが見つかることを確認
      expect(
        find.byKey(testKey),
        findsOneWidget,
        reason: 'HomeScreenは指定されたkeyで識別可能である必要がある',
      );
    });
  });
}
