import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  final controls = find.byKey(const ValueKey('home-controls-scroll'));
  Finder button(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is ElevatedButton));
  Finder cell(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(InkWell));
  Finder action(Type type) => find.descendant(
      of: find.byType(type), matching: find.byType(ElevatedButton));

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'fontSize': 'large',
      'tutorial_completed': true,
    });
    directory = await Directory.systemTemp.createTemp('home_overflow_');
    Hive.init(directory.path);
    registerPersistedTypeAdapters();
    await openPersistedBoxes(hivePath: directory.path);
    container = ProviderContainer();
    for (final name in ['connectivity', 'connectivity_status']) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('dev.fluttercommunity.plus/$name'),
        (call) async => call.method == 'check' ? ['wifi'] : null,
      );
    }
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
    for (final name in ['connectivity', 'connectivity_status']) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel('dev.fluttercommunity.plus/$name'), null);
    }
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (controls.evaluate().isNotEmpty) {
      final position =
          tester.widget<SingleChildScrollView>(controls).controller!.position;
      expect(position.pixels, greaterThanOrEqualTo(position.minScrollExtent));
      expect(position.pixels, lessThanOrEqualTo(position.maxScrollExtent));
    }
  }

  Future<void> pump(WidgetTester tester, Size size,
      {bool shell = false, double scale = 2}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(
          builder: (context, ref, child) => MaterialApp(
                theme: ref.watch(currentThemeProvider),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: shell
                    ? const AppShell(child: HomeScreen())
                    : const HomeScreen(),
              )),
    ));
    await settle(tester);
  }

  bool encloses(Rect outer, Rect inner) =>
      outer.inflate(.01).contains(inner.topLeft) &&
      outer.inflate(.01).contains(inner.bottomRight);
  void visible(WidgetTester tester, Finder target, Rect viewport,
      {bool tappable = true}) {
    final rect = tester.getRect(target);
    expect(encloses(viewport, rect), isTrue,
        reason: '$target: $rect in $viewport');
    if (tappable) {
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
      expect(target.hitTestable(), findsOneWidget);
    }
  }

  Future<void> reach(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 20; i++) {
      if (encloses(tester.getRect(controls), tester.getRect(target))) return;
      final direction =
          tester.getRect(target).top < tester.getRect(controls).top
              ? '上へ'
              : '下へ';
      visible(
          tester, button(direction), tester.getRect(find.byType(HomeScreen)));
      await tester.tap(button(direction));
      await settle(tester);
    }
    fail('上下タップで全体を表示できない: $target');
  }

  void boardVisible(WidgetTester tester) {
    final viewport = tester.getRect(find.byType(GridView));
    expect(encloses(Offset.zero & tester.view.physicalSize, viewport), isTrue);
    visible(tester, find.widgetWithText(ChoiceChip, '基本'),
        tester.getRect(find.byType(CharacterBoardWidget)));
    for (final label in ['あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ']) {
      visible(tester, cell(label), viewport);
    }
  }

  testWidgets('通常タブレットに不要な上下補助を出さない', (tester) async {
    await pump(tester, const Size(768, 1024), scale: 1);
    expect(button('上へ'), findsNothing);
    expect(button('下へ'), findsNothing);
  });

  // 高さ予約を外すと文字盤が潰れる。例外だけでなく2行の全矩形と入力を見る。
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('標準 $width 大×OS2.0で告知中も2行から入力できる', (tester) async {
      await pump(tester, Size(width, 844));
      final input = container.read(inputBufferProvider.notifier);
      for (final length in [1000, 1001]) {
        input.setText('あ' * length);
        await settle(tester);
        expect(container.read(inputBufferProvider), hasLength(1000));
        boardVisible(tester);
        final notice = find.descendant(
            of: find.byType(InputLimitNotice), matching: find.byType(Text));
        await reach(tester, notice);
        visible(tester, notice, tester.getRect(controls), tappable: false);
        final paragraph = tester.renderObject<RenderParagraph>(notice);
        expect(paragraph.didExceedMaxLines, isFalse);
        final boxes = paragraph.getBoxesForSelection(TextSelection(
            baseOffset: 0, extentOffset: paragraph.text.toPlainText().length));
        expect(boxes, isNotEmpty);
        for (final box in boxes) {
          expect(encloses(Offset.zero & paragraph.size, box.toRect()), isTrue);
        }
        await reach(tester, action(DeleteButton));
        await tester.tap(action(DeleteButton));
        await settle(tester);
        expect(container.read(inputBufferProvider), hasLength(999));
        await tester.tap(cell('あ'));
        await settle(tester);
        expect(container.read(inputBufferProvider), hasLength(1000));
      }
    });
  }

  // 上下補助のcallbackを外すと失敗する。ensureVisible/dragは使わない。
  testWidgets('実AppShellで上下タップだけで操作に到達し短縮後も戻れる', (tester) async {
    await pump(tester, const Size(320, 844), shell: true);
    expect(container.read(persistenceStateProvider), isA<PersistenceReady>());
    expect(container.read(networkProvider), NetworkState.online);
    expect(container.read(tutorialProvider).shouldShowTutorial, isFalse);
    final input = container.read(inputBufferProvider.notifier);
    input.setText('あ' * 1000);
    await settle(tester);
    final board = tester.getRect(find.byType(CharacterBoardWidget));
    final targets = [
      find.byType(InputLimitNotice),
      action(DeleteButton),
      action(ClearAllButton),
      button('AI変換'),
      button('読み上げ'),
    ];
    for (final target in targets) {
      await reach(tester, target);
      visible(tester, target, tester.getRect(controls),
          tappable: target != targets.first);
      expect(tester.getRect(find.byType(CharacterBoardWidget)), board);
      boardVisible(tester);
    }
    expect(tester.widget<ElevatedButton>(button('AI変換')).onPressed, isNotNull);
    expect(tester.widget<ElevatedButton>(button('読み上げ')).onPressed, isNotNull);
    for (var i = 0; i < 3; i++) {
      await tester.tap(button('下へ'));
      await settle(tester);
    }
    expect(tester.widget<ElevatedButton>(button('下へ')).onPressed, isNull);
    await reach(tester, action(ClearAllButton));
    await tester.tap(action(ClearAllButton));
    await settle(tester);
    await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('いいえ')));
    await settle(tester);
    expect(container.read(inputBufferProvider), hasLength(1000));
    await reach(tester, action(DeleteButton));
    await tester.tap(action(DeleteButton));
    await settle(tester);
    expect(container.read(inputBufferProvider), hasLength(999));
    await tester.tap(cell('あ'));
    await settle(tester);
    expect(container.read(inputBufferProvider), hasLength(1000));
    await reach(tester, find.text('はい'));
    for (var i = 0; i < 3; i++) {
      await tester.tap(button('上へ'));
      await settle(tester);
    }
    expect(tester.widget<ElevatedButton>(button('上へ')).onPressed, isNull);
    tester.view.physicalSize = const Size(1000, 1800);
    await settle(tester);
    expect(button('上へ'), findsNothing);
    expect(button('下へ'), findsNothing);
    expect(container.read(persistenceStateProvider), isA<PersistenceReady>());
  });
}
