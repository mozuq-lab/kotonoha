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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
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
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('一次put後失敗→次のput前失敗→再試行でも自分の反映済み本文を拒否しない', (tester) async {
    final box = Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName);
    final boundary = _DelayedBox();
    var puts = 0;
    String? savedId;
    registerFallbackValue(box.get(phraseId)!);
    when(() => boundary.values).thenAnswer((_) => box.values);
    when(() => boundary.put(any<dynamic>(), any())).thenAnswer((call) async {
      puts++;
      savedId ??= call.positionalArguments[0] as String;
      if (puts == 2) throw StateError('SDK: before put');
      await box.put(call.positionalArguments[0],
          call.positionalArguments[1] as PresetPhrase);
      if (puts == 1) throw StateError('SDK: after put');
    });
    when(boundary.compact).thenAnswer((_) => box.compact());
    when(boundary.flush).thenAnswer((_) => box.flush());
    await tester.pumpWidget(ProviderScope(
      overrides: [presetPhraseBoxProvider.overrideWithValue(boundary)],
      child: const MaterialApp(home: PresetPhraseScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    for (final text in ['初回本文A', '修正本文B', '修正本文C']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.runAsync(() => tester.tap(find.text('保存')));
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
        if (find.byType(TextField).evaluate().isEmpty ||
            tester
                    .widget<ElevatedButton>(
                        find.widgetWithText(ElevatedButton, '保存'))
                    .onPressed !=
                null) {
          break;
        }
      }
      await tester.pumpAndSettle();
      if (text != '修正本文C') {
        expect(find.textContaining('入力内容を残しています'), findsOneWidget);
      }
    }
    expect(find.byType(TextField), findsNothing,
        reason: 'SDK障害は2回目まで。自分のAを別内容と誤判定せずCを保存して閉じる');
    await tester.runAsync(() async {
      await box.close();
      final reopened =
          await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      expect(reopened.values.where((p) => p.content.contains('修正本文C')),
          hasLength(1));
      expect(reopened.keys, contains(savedId));
      expect(reopened.get(savedId)?.content, contains('修正本文C'));
      expect(reopened.values, hasLength(2));
    });
  });
  final editVariant = ValueVariant<bool>({false, true});
  testWidgets('保存後のcompact失敗から同じフォームで再試行しても重複しない', (tester) async {
    final edit = editVariant.currentValue!;
    late Box<PresetPhrase> box;
    late Directory blockedCompact;
    await tester.runAsync(() async {
      await Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName).close();
      box = await Hive.openBox<PresetPhrase>(
          PersistedArea.presetPhrases.boxName,
          compactionStrategy: (_, __) => false);
      for (var i = 0; i < 61; i++) {
        await box.put(phraseId, box.get(phraseId)!);
      }
      await box.close();
      box =
          await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      blockedCompact = await Directory(
              '${box.path!.replaceFirst(RegExp(r'\.hive$'), '')}.hivec')
          .create();
    });
    addTearDown(() async {
      if (await blockedCompact.exists()) await blockedCompact.delete();
    });
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PresetPhraseScreen())));
    await tester.pumpAndSettle();
    await tester.tap(
        edit ? find.byIcon(Icons.edit) : find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '初回の保存本文');
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.runAsync(() => tester.tap(find.text('保存')));
    for (var i = 0;
        i < 100 && find.textContaining('入力内容を残しています').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.textContaining('入力内容を残しています'), findsOneWidget);
    expect(find.widgetWithText(TextField, '初回の保存本文'), findsOneWidget);
    if (edit) {
      final state = ProviderScope.containerOf(
              tester.element(find.byType(PresetPhraseScreen)))
          .read(presetPhraseNotifierProvider);
      expect(state.phrases.single.content, contains('すこし休みたい'));
    }
    await tester.runAsync(blockedCompact.delete);
    await tester.enterText(find.byType(TextField), '再試行した最新本文');
    await tester.runAsync(() => tester.tap(find.text('保存')));
    await _waitForSave(tester);
    await tester.runAsync(() async {
      await box.close();
      final reopened =
          await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      expect(reopened.values, hasLength(edit ? 1 : 2));
      expect(
          reopened.values.where((p) => p.content.contains('初回の保存')), isEmpty);
      final saved = reopened.values.where((p) => p.content.contains('再試行した最新'));
      expect(saved, hasLength(1));
      expect(saved.single.category, contains('health'));
      if (edit) expect(saved.single.id, contains(phraseId));
    });
  }, variant: editVariant);

  for (final missingBox in [false, true]) {
    testWidgets('保存失敗（repoなし=$missingBox）でも本文とカテゴリを保持する', (tester) async {
      final edit = editVariant.currentValue!;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          if (missingBox) presetPhraseBoxProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: PresetPhraseScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(edit
          ? find.byIcon(Icons.edit).first
          : find.byType(FloatingActionButton));
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
      expect(find.textContaining('保存を確認できません'), findsOneWidget);
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
    }, variant: editVariant);
  }

  testWidgets('保存中の連打・変更・キャンセル・backを止め、完了後は1件だけ残る', (tester) async {
    final edit = editVariant.currentValue!;
    await tester.runAsync(() async {
      final box = Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      final delayedBox = _DelayedBox();
      final gate = Completer<void>();
      final flushed = Completer<void>();
      final writes = <PresetPhrase>[];
      registerFallbackValue(box.get(phraseId)!);
      when(() => delayedBox.values).thenAnswer((_) => box.values);
      when(() => delayedBox.put(any<dynamic>(), any()))
          .thenAnswer((call) async {
        await gate.future;
        writes.add(call.positionalArguments[1] as PresetPhrase);
        await box.put(call.positionalArguments[0], writes.last);
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
        await tester.tap(
            edit ? find.byIcon(Icons.edit) : find.byType(FloatingActionButton));
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
        expect(writes, hasLength(1));
        {
          await box.close();
          final reopened = await Hive.openBox<PresetPhrase>(
              PersistedArea.presetPhrases.boxName);
          expect(reopened.values, hasLength(edit ? 1 : 2));
          final added =
              reopened.values.where((p) => p.content.contains('待機中に変えない'));
          expect(added, hasLength(1));
          expect(added.single.category, contains('health'));
          if (edit) expect(added.single.id, contains(phraseId));
        }
      } finally {
        if (!gate.isCompleted) gate.complete();
        await flushed.future.timeout(const Duration(seconds: 5));
        await tester.pump();
      }
    });
  }, variant: editVariant);

  for (final race in ['before', 'during', 'during-failed', 'other']) {
    testWidgets('編集と削除・追加の競合 $race は入力と最新一覧を失わない', (tester) async {
      await tester.runAsync(() async {
        final box = Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName);
        await box.put(
            'keep', box.get(phraseId)!.copyWith(id: 'keep', displayOrder: 99));
        final delayed = _DelayedBox();
        final gate = Completer<void>();
        registerFallbackValue(box.get(phraseId)!);
        when(() => delayed.values).thenAnswer((_) => box.values);
        when(() => delayed.put(any<dynamic>(), any())).thenAnswer((call) async {
          await gate.future;
          if (race == 'during-failed') throw StateError('SDK put failed');
          await box.put(call.positionalArguments[0],
              call.positionalArguments[1] as PresetPhrase);
        });
        when(() => delayed.delete(any<dynamic>()))
            .thenAnswer((call) => box.delete(call.positionalArguments[0]));
        when(delayed.compact).thenAnswer((_) => box.compact());
        when(delayed.flush).thenAnswer((_) => box.flush());
        final container = ProviderContainer(overrides: [
          presetPhraseBoxProvider.overrideWithValue(delayed),
        ]);
        addTearDown(container.dispose);
        final notifier = container.read(presetPhraseNotifierProvider.notifier);
        Future<void>? deletion;
        Future<bool>? addition;
        try {
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: PresetPhraseScreen()),
          ));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.edit).first);
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), '競合しても残す本文');
          await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
          if (race == 'before') await notifier.deletePhrase(phraseId);
          if (race == 'other') {
            addition = notifier.addPhrase('別の追加本文', 'daily', id: 'added');
          }
          await tester.tap(find.text('保存'));
          if (race != 'before') {
            deletion =
                notifier.deletePhrase(race == 'other' ? 'keep' : phraseId);
          }
          gate.complete();
          await addition;
          await deletion;
          for (var i = 0; i < 100; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
            if (find.textContaining('見つかりません').evaluate().isNotEmpty ||
                find.byType(TextField).evaluate().isEmpty) {
              break;
            }
          }
          await tester.pumpAndSettle();
          final phrases = container.read(presetPhraseNotifierProvider).phrases;
          if (race == 'other') {
            expect(find.byType(TextField), findsNothing);
            expect(phrases.map((p) => p.id), containsAll([phraseId, 'added']));
            expect(phrases.map((p) => p.id), isNot(contains('keep')));
          } else {
            expect(find.textContaining('見つかりません'), findsOneWidget);
            expect(find.widgetWithText(TextField, '競合しても残す本文'), findsOneWidget);
            expect(
                tester
                    .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
                    .selected,
                isTrue);
            expect(phrases.map((p) => p.id), isNot(contains(phraseId)));
          }
          await box.close();
          final reopened = await Hive.openBox<PresetPhrase>(
              PersistedArea.presetPhrases.boxName);
          if (race == 'other') {
            expect(reopened.keys, containsAll([phraseId, 'added']));
            expect(reopened.keys, isNot(contains('keep')));
            expect(reopened.get(phraseId)!.content, contains('競合しても残す'));
            expect(reopened.get(phraseId)!.category, contains('health'));
          } else {
            expect(reopened.keys, isNot(contains(phraseId)));
            expect(reopened.keys, contains('keep'));
          }
        } finally {
          if (!gate.isCompleted) gate.complete();
          await addition;
          await deletion;
        }
      });
    });
  }

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
      });
      await _waitForSave(tester);
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
      if (edit) {
        expect(saved, hasLength(1));
        expect(matches.single.id, contains(phraseId));
      }
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
