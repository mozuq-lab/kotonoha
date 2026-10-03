/// 画面タイトルの位置は、操作ボタンの数や OS によらず揃える。
/// Flutter の既定では、iOS は操作ボタンが 2 つ以上あると左寄せ、Android は常に左寄せで、
/// お気に入り（ボタン 2 つ）だけ他の画面と位置が変わっていた。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

void main() {
  for (final (name, theme) in [
    ('ライト', lightTheme),
    ('ダーク', darkTheme),
    ('高コントラスト', highContrastTheme),
  ]) {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      for (final actions in [0, 1, 2]) {
        testWidgets('$name・${platform.name}・操作ボタン$actions個: タイトルは中央',
            (tester) async {
          tester.view.physicalSize = const Size(1032, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(
            theme: theme.copyWith(platform: platform),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('お気に入り'),
                actions: [
                  for (var i = 0; i < actions; i++)
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                ],
              ),
            ),
          ));
          final center = tester.getCenter(find.text('お気に入り'));
          expect(center.dx, closeTo(1032 / 2, 1));
        });
      }
    }
  }
}
