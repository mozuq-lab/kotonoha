import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  testWidgets('OS キーボード入力と文字盤からの更新を同じ入力欄に反映する', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: HomeInputField(onFavoritePressed: null)),
        ),
      ),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('favorite_current_input')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('home_input_field')), 'ありがとう');
    expect(container.read(inputBufferProvider), 'ありがとう');
    container.read(inputBufferProvider.notifier).addCharacter('。');
    await tester.pump();
    expect(find.text('ありがとう。'), findsOneWidget);

    container.read(inputBufferProvider.notifier).deleteLastCharacter();
    await tester.pump();
    expect(find.text('ありがとう'), findsOneWidget);
    container.read(inputBufferProvider.notifier).clear();
    await tester.pump();
    expect(find.text('ありがとう'), findsNothing);
  });

  testWidgets('キーボードの絵文字を削除・上限で途中から壊さない', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: HomeInputField(onFavoritePressed: null)),
      ),
    ));
    await tester.enterText(
        find.byKey(const Key('home_input_field')), 'あ👨‍👩‍👧');
    container.read(inputBufferProvider.notifier).deleteLastCharacter();
    await tester.pump();
    expect(container.read(inputBufferProvider), 'あ');
    expect(find.text('あ'), findsOneWidget);

    final text = '😀' * InputBufferNotifier.maxLength;
    await tester.enterText(find.byKey(const Key('home_input_field')), text);
    await tester.pump();
    expect(container.read(inputBufferProvider), text);
  });

  // 入力欄の枠はホームの外側の囲み（home_input_area）が描く。入力欄自身が
  // テーマの枠を引き継ぐと、高コントラストで枠が二重になる。
  for (final (name, theme) in [
    ('ライト', lightTheme),
    ('ダーク', darkTheme),
    ('高コントラスト', highContrastTheme),
  ]) {
    testWidgets('$name: 入力欄自身は枠を描かない（外側の囲みと二重にならない）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(body: HomeInputField(onFavoritePressed: null)),
          ),
        ),
      );
      final field = find.byKey(const Key('home_input_field'));
      InputBorder? painted() {
        final decorator = tester.widget<InputDecorator>(
          find.descendant(of: field, matching: find.byType(InputDecorator)),
        );
        final d = decorator.decoration;
        return decorator.isFocused
            ? (d.focusedBorder ?? d.border)
            : (d.enabledBorder ?? d.border);
      }

      expect(painted()?.borderSide.style ?? BorderStyle.none, BorderStyle.none,
          reason: '入力していないときに枠がある');
      await tester.tap(field);
      await tester.pump();
      expect(painted()?.borderSide.style ?? BorderStyle.none, BorderStyle.none,
          reason: '入力中に枠がある');
    });
  }
}
