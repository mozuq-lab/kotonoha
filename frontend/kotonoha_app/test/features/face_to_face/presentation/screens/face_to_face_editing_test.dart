import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/screens/face_to_face_screen.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/face_to_face_text_display.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester,
      {String text = 'は', Size size = const Size(1024, 1366)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: FaceToFaceScreen(displayText: text)),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  String displayed(WidgetTester tester) => tester
      .widget<FaceToFaceTextDisplay>(find.byType(FaceToFaceTextDisplay))
      .text;

  testWidgets('反転中も本人向きの文字盤で編集し、隠しても入力を共有する', (tester) async {
    final container = await pump(tester);
    await tester.tap(find.byIcon(CupertinoIcons.rotate_right).first);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    final board = find.byType(CharacterBoardWidget);
    expect(board, findsOneWidget);
    expect(
        find.ancestor(
            of: board,
            matching: find.byKey(const ValueKey('rotation_transform'))),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('character_button_゛')));
    await tester.pump();
    expect(displayed(tester), 'ば');
    await tester.tap(find.byKey(const ValueKey('character_button_あ')));
    await tester.pump();
    expect(displayed(tester), 'ばあ');
    expect(container.read(inputBufferProvider), 'ばあ');
    await tester.tap(find.text('削除'));
    await tester.pump();
    expect(displayed(tester), 'ば');

    await tester.tap(find.text('編集を閉じる'));
    await tester.pumpAndSettle();
    expect(board, findsNothing);
    expect(displayed(tester), 'ば');
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(displayed(tester), 'ば');
    expect(container.read(inputBufferProvider), 'ば');
  });

  testWidgets('OSキーボードの編集と全消去の確認を同じ文章へ反映する', (tester) async {
    final container = await pump(tester, text: '履歴から表示した文');
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(container.read(inputBufferProvider), '履歴から表示した文');
    await tester.enterText(find.byType(TextField), 'ありがとう\nございます👨‍👩‍👧');
    await tester.pump();
    expect(displayed(tester), 'ありがとう\nございます👨‍👩‍👧');
    await tester.tap(find.text('削除'));
    await tester.pump();
    expect(displayed(tester), 'ありがとう\nございます');
    await tester.tap(find.text('全消去'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('いいえ'));
    await tester.pumpAndSettle();
    expect(displayed(tester), 'ありがとう\nございます');
    await tester.tap(find.text('全消去'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('はい'));
    await tester.pumpAndSettle();
    expect(displayed(tester), '');
    expect(container.read(inputBufferProvider), '');
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('$size: キーボード表示と文字倍率2でも編集欄がはみ出さない', (tester) async {
      await pump(tester, size: size);
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'ありがとう');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(displayed(tester), 'ありがとう');
    });
  }
}
