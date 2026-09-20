/// 定型文の往復テスト（Phase 3 / WP-3）
/// **UI → provider → repository → 実 Hive box → 再起動相当 → UI** を1本で通す。
/// お気に入りトグルを選んだ理由: WP-2 で「定型文がお気に入りか」の真実を
/// `favoriteProvider` へ寄せた（ADR-005）。`PresetPhrase.isFavorite` は削除済みで
/// 定型文 UI は favorites box の内容から星を描く。**2つの box をまたぐ往復**なので
/// 真実が1つに寄っていることを最も外側の境界で確かめられる。
/// 制約と対処（実 Hive × testWidgets）は
/// `test/features/history/history_round_trip_test.dart` の冒頭コメントを参照。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

class _DelayedBox extends Mock implements Box<PresetPhrase> {}

Future<void> _waitForSave(WidgetTester tester) async {
  for (var i = 0;
      i < 100 && find.byType(TextField).evaluate().isNotEmpty;
      i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(find.byType(TextField), findsNothing);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const phraseId = 'p-1';
  const phraseContent = 'すこし休みたいです';

  setUp(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );

    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('preset_round_trip_');
    Hive.init(tempDir.path);
    registerPersistedTypeAdapters();
    await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
    await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
    await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

    await Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName).put(
      phraseId,
      PresetPhrase(
        id: phraseId,
        content: phraseContent,
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime(2026, 8, 31, 9),
        updatedAt: DateTime(2026, 8, 31, 9),
      ),
    );
  });

  tearDown(() async {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  for (final missingBox in [false, true]) {
    testWidgets('追加失敗（repoなし=$missingBox）でも本文とカテゴリを保持する', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          if (missingBox) presetPhraseBoxProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: PresetPhraseScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '失敗しても残す本文');
      await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
      if (!missingBox) {
        await tester.runAsync(() =>
            Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName)
                .close());
      }
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.textContaining('保存できません'), findsOneWidget);
      expect(find.widgetWithText(TextField, '失敗しても残す本文'), findsOneWidget);
      expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
              .selected,
          isTrue);
      await tester.enterText(find.byType(TextField), '再試行する本文');
      await tester.pump();
      expect(find.widgetWithText(TextField, '再試行する本文'), findsOneWidget);
      expect(
          tester
              .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存'))
              .onPressed,
          isNotNull);
    });
  }

  testWidgets('追加保存中の連打・変更・キャンセル・backを止め、完了後は1件だけ残る', (tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      final delayedBox = _DelayedBox();
      final gate = Completer<void>();
      final flushed = Completer<void>();
      registerFallbackValue(box.get(phraseId)!);
      when(() => delayedBox.values).thenAnswer((_) => box.values);
      when(() => delayedBox.put(any<dynamic>(), any()))
          .thenAnswer((call) async {
        await gate.future;
        await box.put(call.positionalArguments[0],
            call.positionalArguments[1] as PresetPhrase);
      });
      when(delayedBox.compact).thenAnswer((_) => box.compact());
      when(delayedBox.flush).thenAnswer((_) async {
        await box.flush();
        flushed.complete();
      });
      try {
        await tester.pumpWidget(ProviderScope(
          overrides: [presetPhraseBoxProvider.overrideWithValue(delayedBox)],
          child: const MaterialApp(home: PresetPhraseScreen()),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '待機中に変えない本文');
        await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
        await tester.tap(find.text('保存'));
        await tester.tap(find.text('保存'));
        await tester.pump();
        expect(find.byType(TextField), findsOneWidget);
        await tester.tap(find.text('保存'), warnIfMissed: false);
        await tester.tap(find.text('キャンセル'), warnIfMissed: false);
        await tester.tap(find.widgetWithText(ChoiceChip, 'その他'),
            warnIfMissed: false);
        await tester.tap(find.byType(TextField), warnIfMissed: false);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.textContaining('破棄しますか'), findsNothing);
        expect(find.widgetWithText(TextField, '待機中に変えない本文'), findsOneWidget);
        expect(tester.testTextInput.hasAnyClients, isFalse);
        expect(
            tester
                .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
                .selected,
            isTrue);
        gate.complete();
        for (var i = 0;
            i < 100 && find.byType(TextField).evaluate().isNotEmpty;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        {
          await box.close();
          final reopened = await Hive.openBox<PresetPhrase>(
              PersistedArea.presetPhrases.boxName);
          expect(reopened.values, hasLength(2));
          final added =
              reopened.values.where((p) => p.content.contains('待機中に変えない'));
          expect(added, hasLength(1));
          expect(added.single.category, contains('health'));
        }
      } finally {
        if (!gate.isCompleted) gate.complete();
        await flushed.future.timeout(const Duration(seconds: 5));
        await tester.pump();
      }
    });
  });

  for (final edit in [false, true]) {
    testWidgets('${edit ? '編集' : '追加'}画面が消えても保存され、box再open後も残る',
        (tester) async {
      final showScreen = ValueNotifier(true);
      addTearDown(showScreen.dispose);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showScreen,
            builder: (_, visible, __) => visible
                ? const PresetPhraseScreen()
                : const Scaffold(body: Text('ホーム相当')),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(
          edit ? find.byIcon(Icons.edit) : find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '画面が消えても保存する本文');
      await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
      showScreen.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(PresetPhraseScreen), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('保存'));
        if (edit) await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      if (!edit) await _waitForSave(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      late List<PresetPhrase> saved;
      await tester.runAsync(() async {
        await Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName)
            .close();
        saved = (await Hive.openBox<PresetPhrase>(
                PersistedArea.presetPhrases.boxName))
            .values
            .toList();
      });
      final matches = saved.where((p) => p.content.contains('画面が消えても'));
      expect(matches, hasLength(1));
      expect(matches.single.category, contains('health'));
      if (edit) expect(saved, hasLength(1));
    });
  }

  testWidgets('画面除去後の削除確認で対象だけが消え、box再open後も戻らない', (tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      await box.put(
          'keep', box.get(phraseId)!.copyWith(id: 'keep', displayOrder: 99));
    });
    final showScreen = ValueNotifier(true);
    addTearDown(showScreen.dispose);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: showScreen,
          builder: (_, visible, __) => visible
              ? const PresetPhraseScreen()
              : const Scaffold(body: Text('ホーム相当')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    showScreen.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(PresetPhraseScreen), findsNothing);
    expect(find.text('定型文の削除'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('削除'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('定型文の削除'), findsNothing);
    await tester.runAsync(() async {
      await Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName).close();
      final reopened =
          await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      expect(reopened.keys, isNot(contains(phraseId)));
      expect(reopened.keys, contains('keep'));
    });
  });

  testWidgets('定型文の星をタップすると favorites box に残り、再起動相当でも星が付いている', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PresetPhraseScreen())),
    );
    await tester.pump();

    expect(find.text(phraseContent), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget,
        reason: 'まだお気に入りではないこと（往復の出発点）');

    // When: 星をタップする
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.star_border).first);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Then: favorites box を閉じて開き直しても（＝再起動相当）残っている
    late List<FavoriteItem> persisted;
    await tester.runAsync(() async {
      await Hive.box<FavoriteItem>(PersistedArea.favorites.boxName).close();
      final reopened =
          await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);
      persisted = reopened.values.toList();
    });

    expect(persisted, hasLength(1));
    expect(persisted.single.content, phraseContent);
    expect(persisted.single.sourceType, 'preset_phrase',
        reason: '定型文由来であることが記録されていること');
    expect(persisted.single.sourceId, phraseId,
        reason: '同じ文言の定型文どうしを区別できるよう、出所は id で持つこと（ADR-005）');

    // And: 新しい ProviderScope（＝再起動相当）で星が付いた状態から描かれる
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PresetPhraseScreen())),
    );
    await tester.pump();

    expect(find.byIcon(Icons.star), findsOneWidget,
        reason: '定型文 UI が favorites box の内容から星を描いていること'
            '（PresetPhrase 側にフラグを持たない＝1概念1真実）');
    expect(find.byIcon(Icons.star_border), findsNothing);
  });
}
