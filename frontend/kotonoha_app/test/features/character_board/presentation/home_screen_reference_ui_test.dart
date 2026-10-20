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
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';
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

  // 他の画面のタイトルは中央に揃えるが、ホームのロゴは左端に置く
  for (final size in const [Size(1032, 1376), Size(390, 844)]) {
    testWidgets('$size: ホームのロゴは左端にある', (tester) async {
      await pumpHome(tester, size);
      final logo = tester.getTopLeft(find.bySemanticsLabel('ことのは'));
      expect(logo.dx, lessThan(32));
    });
  }

  // 電話では文字盤の高さを優先し、お気に入り・入力欄・操作ボタンを詰める
  // （iPhone で文字盤が画面の半分を切って窮屈だった。2026-10-20 の人の依頼）。
  // 文字「大」で名前が切れるのは受け入れる。
  for (final font in [FontSize.medium, FontSize.large]) {
    testWidgets('402x874・文字${font.name}: 電話ではお気に入りを1行・高さ48に詰める',
        (tester) async {
      await pumpHome(tester, const Size(402, 874), font: font, ai: true);
      container.read(inputBufferProvider.notifier).setText('ありがとう');
      await tester.pumpAndSettle();
      final shortcuts = find.byType(FavoriteShortcutButton);
      expect(shortcuts, findsNWidgets(8));
      for (var i = 0; i < 8; i++) {
        expect(tester.getRect(shortcuts.at(i)).height, 48, reason: 'お気に入り$i');
        final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: shortcuts.at(i), matching: find.byType(Text)));
        expect(paragraph.maxLines, 1, reason: 'お気に入り$i');
      }
      final input = tester.getRect(find
          .descendant(
            of: find.byKey(const Key('home_input_area')),
            matching: find.byType(DecoratedBox),
          )
          .first);
      expect(
          input.height, lessThanOrEqualTo(font == FontSize.medium ? 64 : 70));
      for (final button in [
        find.byType(DeleteButton),
        find.byType(ClearAllButton),
        find.byType(TTSButton),
      ]) {
        expect(tester.getRect(button).height, inInclusiveRange(44, 45));
      }
      // 文字種のタブは押せる範囲 44（REQ-5001 の下限）で、下の文字盤との間は 4
      final tabs = find.byType(ChoiceChip);
      final tab = tester.getRect(tabs.at(1));
      expect(tab.height, 44);
      expect(tester.getRect(find.byType(GridView)).top - tab.bottom, 4);
      // オンライン（オフラインの表示が出ない）とき、読み上げとタブの間は 4
      await container.read(networkProvider.notifier).setOnline();
      await tester.pumpAndSettle();
      expect(
          tester.getRect(tabs.first).top -
              tester.getRect(find.byType(TTSButton)).bottom,
          4);
      // 見た目の縁の外でも、44 の範囲の端を押せば切り替わる
      await tester.tapAt(Offset(tab.center.dx, tab.top + 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('character_button_が')), findsOneWidget);
      await capture(tester, 'phone-compact-${font.name}');
      expect(tester.takeException(), isNull);
    });
  }

  // 横持ちの電話（2 ペイン）の左の列も詰める（2026-10-20 の人の依頼）
  for (final font in [FontSize.medium, FontSize.large]) {
    testWidgets('874x402・文字${font.name}: 横持ちの左の列のボタンを詰める', (tester) async {
      await pumpHome(tester, const Size(874, 402), font: font, ai: true);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(QuickResponseButton), findsNWidgets(3));
      for (final quick in find.byType(QuickResponseButton).evaluate()) {
        expect(tester.getRect(find.byWidget(quick.widget)).height, 44);
      }
      final shortcuts = find.byType(FavoriteShortcutButton);
      for (var i = 0; i < 8; i++) {
        expect(tester.getRect(shortcuts.at(i)).height, 48, reason: 'お気に入り$i');
        final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: shortcuts.at(i), matching: find.byType(Text)));
        expect(paragraph.maxLines, 1, reason: 'お気に入り$i');
      }
      await capture(tester, 'phone-landscape-${font.name}');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('電話では長いお気に入りを1行で省略し、全文をtooltipで確認できる', (tester) async {
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
    expect(paragraph.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isTrue, reason: '「…」で省略されていない');
    expect(paragraph.getTransformTo(null).storage[0], closeTo(1, 0.001));
    expect(find.byTooltip(text), findsOneWidget);
    await capture(tester, 'phone-long-favorite');
    expect(tester.takeException(), isNull);
  });

  testWidgets('タブレットでは文字種のタブを 48 のまま、文字盤との間を 8 に保つ', (tester) async {
    await pumpHome(tester, const Size(820, 1180));
    final tab = tester.getRect(find.byType(ChoiceChip).first);
    expect(tab.height, 48);
    expect(tester.getRect(find.byType(GridView)).top - tab.bottom, 8);
  });

  testWidgets('タブレットでは長いお気に入りを2行で表示する', (tester) async {
    await pumpHome(tester, const Size(820, 1180));
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
      if (size.width < size.height) {
        expect(paragraph.didExceedMaxLines, isFalse);
      } else {
        // 横持ちの左の列は高さを優先して 1 行。文字「大」で切れるのは受け入れる
        // （2026-10-20 の人の依頼）
        expect(paragraph.maxLines, 1);
      }
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
