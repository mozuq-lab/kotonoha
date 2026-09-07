/// EmptyFavoriteWidget ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/favorites/presentation/widgets/empty_favorite_widget.dart';

void main() {
  group('EmptyFavoriteWidget', () {
    // 3.1 正常系テスト
    group('正常系テスト', () {
      /// 空状態メッセージが表示される
      testWidgets('TC-064-034: EmptyFavoriteWidgetが空状態メッセージを表示する',
          (WidgetTester tester) async {
        // When: EmptyFavoriteWidgetを表示する
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyFavoriteWidget(),
            ),
          ),
        );

        // Then: 「お気に入りがありません」が画面中央に表示される
        expect(
          find.text('お気に入りがありません'),
          findsOneWidget,
          reason: '空状態メッセージが表示される必要がある',
        );
      });

      /// 空状態アイコンが表示される
      testWidgets('TC-064-035: EmptyFavoriteWidgetにアイコンが表示される',
          (WidgetTester tester) async {
        // When: EmptyFavoriteWidgetを表示する
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyFavoriteWidget(),
            ),
          ),
        );

        // Then: 空状態を示すアイコンが表示される
        expect(
          find.byIcon(Icons.favorite_border),
          findsOneWidget,
          reason: '空状態アイコンが表示される必要がある',
        );
      });

      /// 使い方のヒントが表示される
      testWidgets('TC-064-036: EmptyFavoriteWidgetに使い方のヒントが表示される',
          (WidgetTester tester) async {
        // When: EmptyFavoriteWidgetを表示する
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyFavoriteWidget(),
            ),
          ),
        );

        // Then: 使い方のヒントが表示される
        expect(
          find.text('履歴や定型文からお気に入りを登録できます'),
          findsOneWidget,
          reason: '使い方のヒントが表示される必要がある',
        );
      });
    });
  });
}
