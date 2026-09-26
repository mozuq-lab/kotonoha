import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

void main() {
  testWidgets('長い文は設定した文字サイズを保って省略する', (tester) async {
    final text = '長いお気に入りの文章です' * 10;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SizedBox(
          width: 100,
          child: FavoriteShortcutButton(
            favorite: Favorite(
                id: 'long',
                content: text,
                createdAt: DateTime(2026),
                displayOrder: 0),
            onPressed: () {},
            height: 48,
            fontSize: FontSize.large,
          )),
    )));
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(paragraph.getTransformTo(null).storage[0], closeTo(1, 0.001));
    expect(tester.takeException(), isNull);
  });
}
