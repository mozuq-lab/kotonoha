/// iPhone を横にしたホームで、文字が部品からはみ出したり重なったりしない
///
/// - 文字サイズ「中」で、3 文字のお気に入り（「助けて」など）がボタンの幅に
///   収まらず 2 行に折り返し、1 行分の高さのボタンからはみ出していた
/// - 文字サイズ「大」で、入力欄の文字と「入力欄」のラベルが重なっていた
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iPhone 17 を横にした画面（論理ピクセル）と安全領域
const _size = Size(874, 402);
const _safeArea = FakeViewPadding(left: 62, right: 62, bottom: 21);

Future<ProviderContainer> _pump(WidgetTester tester, String fontSize) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = _safeArea;
  tester.view.viewPadding = _safeArea;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(
      {'tutorial_completed': true, 'fontSize': fontSize});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // 初期のお気に入りと同じ 8 件（本番は Hive から作る）
  for (final content in ['トイレ', '暑い', '寒い', '水', '眠い', '助けて', '待って', '痛い']) {
    await container.read(favoriteProvider.notifier).addFavorite(content);
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: AppShell(child: HomeScreen())),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('文字サイズ「中」: お気に入りの名前がボタンからはみ出さず、短い名前は折り返さない', (tester) async {
    await _pump(tester, 'medium');

    final buttons = find.byType(FavoriteShortcutButton);
    expect(buttons, findsNWidgets(8));
    for (final element in buttons.evaluate()) {
      final button = element.widget as FavoriteShortcutButton;
      final name = button.favorite.content;
      final label = tester.renderObject<RenderParagraph>(find.descendant(
        of: find.byWidget(button),
        matching: find.text(name),
      ));
      // 1 行で描くのに要る幅より狭く描かれていれば、折り返している。
      // テスト用のフォントは 1 行が低く、2 行でも 1 行分の箱に収まって
      // 見えてしまうので、はみ出しは高さでなく「折り返したのに 2 行分の
      // 高さが無いか」で見る（実機のフォントでは 2 行で約 60px 要る）。
      final wraps =
          label.size.width < label.getMaxIntrinsicWidth(double.infinity) - 0.5;
      if (name.characters.length <= 3) {
        expect(wraps, isFalse, reason: '3 文字までの「$name」が語の途中で 2 行に折り返す');
      }
      if (wraps) {
        final textSize = label.text.style!.fontSize!;
        expect(button.height, greaterThanOrEqualTo(textSize * 2.4 + 12),
            reason: '「$name」が 2 行に折り返すのに、ボタンが 1 行分の高さ'
                '（${button.height}）しかなく、はみ出す');
      }
    }
  });

  testWidgets('文字サイズ「大」: 入力欄の文字と「入力欄」のラベルが重ならない', (tester) async {
    final container = await _pump(tester, 'large');
    container.read(inputBufferProvider.notifier).setText('すこしやすみたい');
    await tester.pumpAndSettle();

    final label = tester.getRect(find.text('入力欄'));
    final text = tester.getRect(find.descendant(
      of: find.byType(HomeInputField),
      matching: find.byType(EditableText),
    ));
    expect(label.bottom <= text.top + 0.5, isTrue,
        reason: 'ラベル $label と入力の文字 $text が重なる');
  });
}
