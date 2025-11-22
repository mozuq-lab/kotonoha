// FavoritesScreen表示確認 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test
// 対象: FavoritesScreen（お気に入り画面スケルトン）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// テスト対象のウィジェット（実装後にコメント解除）
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';

void main() {
  group('FavoritesScreen表示テスト', () {
    // TC-009: FavoritesScreen表示確認テスト
    // テストカテゴリ: Widget Test
    // 対応要件: FR-005（画面スケルトン作成）
    // 対応受け入れ基準: AC-005
    // 青信号: タスクファイルでFavoritesScreen作成が明示
    testWidgets('TC-009: FavoritesScreenが正常に表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // MaterialApp内でFavoritesScreenをラップ

      // When（実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesScreen(),
        ),
      );

      // Then（検証フェーズ）
      // FavoritesScreenウィジェットが存在することを確認
      expect(
        find.byType(FavoritesScreen),
        findsOneWidget,
        reason: 'FavoritesScreenウィジェットが表示される必要がある',
      );

      // Scaffoldが存在することを確認
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'FavoritesScreenはScaffold構造を持つ必要がある',
      );

      // AppBarが存在することを確認
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: 'FavoritesScreenはAppBarを持つ必要がある',
      );

      // 画面識別テキストが表示されることを確認
      expect(
        find.text('お気に入り画面'),
        findsOneWidget,
        reason: 'FavoritesScreenには「お気に入り画面」という識別テキストが表示される必要がある',
      );
    });

    // FavoritesScreenがconstコンストラクタを持つことを確認
    // 青信号: CLAUDE.mdで「constコンストラクタを可能な限り使用」が明示
    testWidgets('FavoritesScreenはconstコンストラクタを持つ', (WidgetTester tester) async {
      // Given/When（準備・実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesScreen(),
        ),
      );

      // Then（検証フェーズ）
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    // FavoritesScreenがkeyパラメータを受け取れることを確認
    // 青信号: CLAUDE.mdで「ウィジェットはkeyパラメータを持つ」が明示
    testWidgets('FavoritesScreenはkeyパラメータを受け取れる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      const testKey = Key('favorites_screen_test_key');

      // When（実行フェーズ）
      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesScreen(key: testKey),
        ),
      );

      // Then（検証フェーズ）
      expect(
        find.byKey(testKey),
        findsOneWidget,
        reason: 'FavoritesScreenは指定されたkeyで識別可能である必要がある',
      );
    });
  });
}
