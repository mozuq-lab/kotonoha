import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
