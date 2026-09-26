import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late Directory storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await Directory.systemTemp.createTemp('home_reference_ui_');
    Hive.init(storage.path);
    registerPersistedTypeAdapters();
    await openPersistedBoxes(hivePath: storage.path);
    container = ProviderContainer();
    await container.read(favoriteRepositoryProvider)!.ensureInitialFavorites();
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await storage.delete(recursive: true);
  });
  const boundaryKey = Key('home-ui-capture');

  Future<void> pumpHome(WidgetTester tester, Size size,
      {double scale = 1,
      FontSize font = FontSize.medium,
      AppTheme theme = AppTheme.light,
      bool ai = false}) async {
    SharedPreferences.setMockInitialValues({
      'fontSize': font.name,
      'theme': theme.name,
      'tutorial_completed': true,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(builder: (context, ref, _) {
        return MaterialApp(
          theme: ref.watch(currentThemeProvider),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: boundaryKey, child: child!),
          ),
          home: AppShell(child: HomeScreen(enableAIConversion: ai)),
        );
      }),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final directory = Platform.environment['HOME_UI_SCREENSHOT_DIR'];
    if (directory == null) return;
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await tester.runAsync(() async {
      await Directory(directory).create(recursive: true);
      await File('$directory/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
    image.dispose();
  }

  for (final theme in AppTheme.values) {
    testWidgets('$theme: お気に入りの色と順序を変更してもホームに反映する', (tester) async {
      await pumpHome(tester, const Size(390, 844), theme: theme);
      final notifier = container.read(favoriteProvider.notifier);
      final favorites = container.read(favoriteProvider).favorites;
      final last = favorites.last;
      await tester.runAsync(() async {
        await notifier.updateFavoriteColor(last.id, 0xFFB39DDB);
        await notifier.reorderFavorite(last.id, 0);
      });
      await tester.pumpAndSettle();
      final shortcuts = find.byType(FavoriteShortcutButton);
      expect(tester.widget<FavoriteShortcutButton>(shortcuts.first).favorite.id,
          last.id);
      final button = tester.widget<ElevatedButton>(find.descendant(
          of: shortcuts.first, matching: find.byType(ElevatedButton)));
      final background = button.style!.backgroundColor!.resolve({})!;
      final foreground = button.style!.foregroundColor!.resolve({})!;
      expect(
          wcagContrastRatio(background, foreground), greaterThanOrEqualTo(4.5));
      // 選択した紫の色相は淡くしても保つ。
      expect(background.b, greaterThan(background.g));
      expect(tester.takeException(), isNull);
      await capture(tester, 'phone-${theme.name}');
    });
  }

  testWidgets('長いお気に入りは2行で表示し、全文をtooltipで確認できる', (tester) async {
    await pumpHome(tester, const Size(390, 844));
    const text = '体の向きを変えてください。右側を下にしてください。';
    final notifier = container.read(favoriteProvider.notifier);
    await tester.runAsync(() async {
      await notifier.addFavorite(text);
      final favorite = container.read(favoriteProvider).favorites.last;
      await notifier.reorderFavorite(favorite.id, 0);
    });
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
    expect(paragraph.maxLines, 2);
    expect(paragraph.getTransformTo(null).storage[0], closeTo(1, 0.001));
    expect(find.byTooltip(text), findsOneWidget);
    await capture(tester, 'phone-long-favorite');
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 844), const Size(844, 390)]) {
    testWidgets('$size: 大きい文字でもお気に入りと操作が切れず入力できる', (tester) async {
      await pumpHome(tester, size, scale: 2, font: FontSize.large, ai: true);
      final shortcuts = find.byType(FavoriteShortcutButton);
      final first = tester.getRect(shortcuts.first);
      expect(first.height, greaterThanOrEqualTo(76));
      expect(first.width, greaterThanOrEqualTo(44));
      final text =
          find.descendant(of: shortcuts.first, matching: find.byType(Text));
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(paragraph.didExceedMaxLines, isFalse);
      final grid = find.byType(GridView);
      expect(tester.getRect(grid).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(const ValueKey('character_button_あ')));
      await tester.pumpAndSettle();
      expect(container.read(inputBufferProvider), 'あ');
      await capture(tester, 'large-${size.width.toInt()}');
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('$size: 削除と全消去の文字ラベルを表示し操作する', (tester) async {
      await pumpHome(tester, size, ai: true);
      container.read(inputBufferProvider.notifier).setText('お水をください。');
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byType(DeleteButton), matching: find.text('削除')),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(ClearAllButton), matching: find.text('全消去')),
          findsOneWidget);
      await capture(tester, size.width < 600 ? 'phone-ai' : 'tablet-ai');
      await tester.tap(find.byType(DeleteButton));
      await tester.pumpAndSettle();
      expect(container.read(inputBufferProvider), 'お水をください');
      expect(find.byType(TTSButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('中間幅タブレットで大きい読み上げラベルの全行が切れない', (tester) async {
    await pumpHome(tester, const Size(680, 1000),
        scale: 1.5, font: FontSize.large, ai: true);
    final label = find.descendant(
        of: find.byType(TTSButton), matching: find.text('読み上げ'));
    final paragraph = tester.renderObject<RenderParagraph>(label);
    final lines = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 4));
    expect(lines, isNotEmpty);
    for (final line in lines) {
      expect(line.bottom, lessThanOrEqualTo(paragraph.size.height + 0.5));
    }
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('横持ち・文字倍率$scaleで入力の1行全体を表示する', (tester) async {
      await pumpHome(tester, const Size(844, 390),
          scale: scale, font: FontSize.large, ai: true);
      container.read(inputBufferProvider.notifier).setText('お水をください。');
      await tester.pumpAndSettle();
      final editable = tester
          .state<EditableTextState>(find.descendant(
              of: find.byKey(const Key('home_input_field')),
              matching: find.byType(EditableText)))
          .renderEditable;
      expect(editable.size.height,
          greaterThanOrEqualTo(editable.preferredLineHeight));
      expect(tester.takeException(), isNull);
    });
  }
}
