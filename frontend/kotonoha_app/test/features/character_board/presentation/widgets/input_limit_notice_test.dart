/// 入力上限の告知（L-73、EDGE-101）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: InputLimitNotice())),
      ),
    );
    return container;
  }

  testWidgets('上限に達していなければ何も描かない', (tester) async {
    final container = await pump(tester);
    container.read(inputBufferProvider.notifier).setText('あ' * 999);
    await tester.pump();
    expect(find.textContaining('文字に達しました'), findsNothing);
  });

  testWidgets('上限に達したら、達したことと入力できないことを描く', (tester) async {
    final container = await pump(tester);
    container
        .read(inputBufferProvider.notifier)
        .setText('あ' * InputBufferNotifier.maxLength);
    await tester.pump();
    expect(find.textContaining('1000 文字に達しました'), findsOneWidget);
    expect(find.textContaining('これ以上は入力できません'), findsOneWidget);
  });

  testWidgets('1 文字消すと告知が消える', (tester) async {
    final container = await pump(tester);
    final notifier = container.read(inputBufferProvider.notifier);
    notifier.setText('あ' * InputBufferNotifier.maxLength);
    await tester.pump();
    notifier.deleteLastCharacter();
    await tester.pump();
    expect(find.textContaining('文字に達しました'), findsNothing);
  });
}
