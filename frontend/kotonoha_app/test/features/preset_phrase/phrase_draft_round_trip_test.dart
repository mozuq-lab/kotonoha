import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/app_state/providers/app_lifecycle_observer.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/phrase_draft_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';

// SDK境界だけを置換。false/throw時はstoreを更新せずcacheと区別する。
class DraftStore extends SharedPreferencesStorePlatform {
  DraftStore([Map<String, Object>? initial]) : values = {...?initial};
  final Map<String, Object> values;
  Completer<void>? readGate;
  Completer<void>? writeGate;
  Completer<void>? clearGate;
  bool clearStarted = false;
  bool failRead = false;
  bool failWrite = false;
  bool throwWrite = false;
  bool failClear = false;
  @override
  Future<Map<String, Object>> getAll() async {
    await readGate?.future;
    if (failRead) throw StateError('SDK read');
    return {...values};
  }

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.preset_phrase_drafts') {
      if ((jsonDecode(value as String) as Map).containsKey('add')) {
        await writeGate?.future;
      } else {
        clearStarted = true;
        await clearGate?.future;
      }
      if (throwWrite) throw StateError('SDK write');
      if (failWrite ||
          (failClear && !(jsonDecode(value) as Map).containsKey('add'))) {
        return false;
      }
    }
    values[key] = value;
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DraftStore store;
  late ProviderContainer container;
  setUp(() async {
    SharedPreferences.resetStatic();
    store = DraftStore();
    SharedPreferencesStorePlatform.instance = store;
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('phrase_draft_');
    Hive.init(directory.path);
    registerPersistedTypeAdapters();
    await Hive.openBox<HistoryItem>('history');
    await Hive.openBox<FavoriteItem>('favorites');
    final box = await Hive.openBox<PresetPhrase>('presetPhrases');
    await box.put(
        'keep',
        PresetPhrase(
            id: 'keep',
            content: '既存の本文',
            category: 'daily',
            displayOrder: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026)));
    container = ProviderContainer();
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
    SharedPreferences.resetStatic();
  });
  Future<void> open(WidgetTester tester,
      {bool observe = false, bool banner = false}) async {
    Widget home = Column(children: [
      if (banner) const PersistenceBanner(),
      const Expanded(child: PresetPhraseScreen())
    ]);
    if (observe) home = AppLifecycleObserver(child: home);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp(home: home)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> restart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    SharedPreferences.resetStatic();
    store = DraftStore(store.values);
    SharedPreferencesStorePlatform.instance = store;
    container = ProviderContainer();
    await open(tester);
  }

  Future<void> submit(WidgetTester tester, {String action = '保存'}) async {
    await tester.runAsync(() => tester.tap(find.text(action)));
    await tester.pump();
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
  }

  testWidgets('追加画面から400ms後のSDK storeだけで再起動すると本文とカテゴリが戻る', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'お水をお願いします');
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.pump(const Duration(milliseconds: 400));
    await restart(tester);
    expect(find.widgetWithText(TextField, 'お水をお願いします'), findsOneWidget);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
            .selected,
        isTrue);
  });
  for (final failure in ['false', 'throw']) {
    testWidgets('下書きflush $failure ではHive保存を止め再試行で1件保存する', (tester) async {
      await open(tester, banner: true);
      await tester.enterText(find.byType(TextField), '失敗でも保持する本文');
      store.failWrite = failure == 'false';
      store.throwWrite = failure == 'throw';
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.textContaining('入力内容を残しています'), findsOneWidget);
      expect(find.textContaining('定型文の下書き', skipOffstage: false), findsWidgets);
      expect(
          Hive.box<PresetPhrase>('presetPhrases')
              .values
              .where((p) => p.content.contains('失敗でも')),
          isEmpty);
      store.failWrite = store.throwWrite = false;
      await submit(tester);
      expect(find.byType(TextField), findsNothing);
      await tester.runAsync(() async {
        await Hive.box<PresetPhrase>('presetPhrases').close();
        final box = await Hive.openBox<PresetPhrase>('presetPhrases');
        expect(
            box.values.where((p) => p.content.contains('失敗でも')), hasLength(1));
      });
    });
  }
  testWidgets('初期read失敗は入力を止め再試行後だけ保存済みmapを復元する', (tester) async {
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      'add': {'id': 'draft-1', 'content': '未読の本文', 'category': 'health'}
    });
    store.failRead = true;
    await open(tester);
    expect(find.textContaining('読み込みに失敗'), findsOneWidget);
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存'))
            .onPressed,
        isNull);
    store.failRead = false;
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '未読の本文'), findsOneWidget);
  });
  testWidgets('初期read待機では入力を止めてロード完了後に復元する', (tester) async {
    store.readGate = Completer<void>();
    await open(tester);
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存'))
            .onPressed,
        isNull);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '読込完了後');
    await tester.pump(const Duration(milliseconds: 399));
    expect(store.values.keys, isNot(contains('flutter.preset_phrase_drafts')));
    await tester.pump(const Duration(milliseconds: 1));
    expect(store.values['flutter.preset_phrase_drafts'], contains('読込完了後'));
  });
  testWidgets('clear失敗ではHive成功済み内容をfreezeし再試行はclearのみ', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '確定保存の本文');
    store.failClear = true;
    await submit(tester);
    expect(find.textContaining('下書きの消去'), findsOneWidget);
    await submit(tester, action: 'キャンセル');
    expect(find.textContaining('保存済み'), findsOneWidget);
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    expect(tester.testTextInput.hasAnyClients, isFalse);
    final box = Hive.box<PresetPhrase>('presetPhrases');
    final saved = box.values.where((p) => p.content.contains('確定保存')).single;
    // SDK boxを閉じてもclearだけなら完了できる。再addは失敗する。
    await tester.runAsync(box.close);
    store.failClear = false;
    await submit(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.runAsync(() async {
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.get(saved.id)?.content, contains('確定保存'));
    });
    await restart(tester);
    expect(find.widgetWithText(TextField, '確定保存の本文'), findsNothing);
  });
  for (final empty in [false, true]) {
    testWidgets('古いwrite待機→破棄（空本文=$empty）→再起動で復活しない', (tester) async {
      await open(tester, observe: true);
      store.writeGate = Completer<void>();
      if (!empty) await tester.enterText(find.byType(TextField), '破棄する本文');
      await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
      await tester.pump(const Duration(milliseconds: 400));
      if (empty) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('キャンセル'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      store.writeGate!.complete();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await restart(tester);
      expect(find.widgetWithText(TextField, '破棄する本文'), findsNothing);
      expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '日常'))
              .selected,
          isTrue);
    });
  }
  testWidgets('pausedは400ms前の入力をflushしresumeで入力を上書きしない', (tester) async {
    await open(tester, observe: true);
    await tester.enterText(find.byType(TextField), '背景へ移る直前');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await restart(tester);
    expect(find.widgetWithText(TextField, '背景へ移る直前'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '復帰後の最新本文');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.widgetWithText(TextField, '復帰後の最新本文'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
  });
  for (final broken in [false, true]) {
    testWidgets('decode破損（全体=$broken）を通知し正常entryは保持する', (tester) async {
      store.values['flutter.draft_text'] = '文字盤は別';
      store.values['flutter.preset_phrase_drafts'] = broken
          ? '{broken'
          : jsonEncode({
              'add': {
                'id': 'draft-valid',
                'content': '救う追加本文',
                'category': 'health'
              },
              'edit:edit-a': {
                'id': 'edit-a',
                'content': '別の編集下書きA',
                'category': 'other'
              },
              'edit:edit-b': {
                'id': 'edit-b',
                'content': '別の編集下書きB',
                'category': 'daily'
              },
              'edit:bad': {'id': 'different', 'content': 7, 'category': 'bad'},
            });
      await open(tester, banner: true);
      if (!broken) {
        expect(find.widgetWithText(TextField, '救う追加本文'), findsOneWidget);
      }
      expect(find.textContaining('定型文の下書き', skipOffstage: false), findsWidgets);
      await tester.enterText(find.byType(TextField), '保存失敗でも喪失通知は残る');
      store.failWrite = true;
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('読み込め', skipOffstage: false), findsWidgets);
      expect(find.textContaining('保存できません', skipOffstage: false), findsWidgets);
      store.failWrite = false;
      await tester.enterText(find.byType(TextField), '保存成功でも喪失通知は残る');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('定型文の下書き', skipOffstage: false), findsWidgets);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      final map =
          jsonDecode(store.values['flutter.preset_phrase_drafts']! as String)
              as Map;
      expect(map.keys, isNot(contains('add')));
      if (!broken) {
        expect(map.keys, containsAll(['edit:edit-a', 'edit:edit-b']));
        expect((map['edit:edit-a'] as Map)['content'], contains('下書きA'));
        expect((map['edit:edit-b'] as Map)['content'], contains('下書きB'));
      }
      expect(store.values['flutter.draft_text'], contains('文字盤は別'));
      expect(find.textContaining('保存できません'), findsNothing);
      expect(find.textContaining('読み込め'), findsWidgets);
    });
  }
  testWidgets('初期loadの複数呼出は合流し閉じるだけでは未読mapを消さない', (tester) async {
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      'add': {'id': 'draft-1', 'content': '未読を保持', 'category': 'daily'}
    });
    store.readGate = Completer<void>();
    await open(tester);
    final drafts = container.read(phraseDraftProvider);
    final first = drafts.initialize();
    final second = drafts.initialize();
    expect(identical(first, second), isTrue);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    store.readGate!.complete();
    await tester.pump();
    expect(store.values['flutter.preset_phrase_drafts'], contains('未読を保持'));
    await restart(tester);
    expect(find.widgetWithText(TextField, '未読を保持'), findsOneWidget);
  });
  for (final action in ['cancel', 'back']) {
    testWidgets('明示破棄 $action が失敗したら閉じず再試行でだけ消す', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), '破棄失敗を保持');
      await tester.pump(const Duration(milliseconds: 400));
      store.failClear = true;
      if (action == 'back') {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.text('破棄する'));
      } else {
        await tester.tap(find.text('キャンセル'));
      }
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '破棄失敗を保持'), findsOneWidget);
      expect(find.textContaining('下書きの消去'), findsOneWidget);
      store.failClear = false;
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await restart(tester);
      expect(find.widgetWithText(TextField, '破棄失敗を保持'), findsNothing);
    });
  }
  for (final scenario in [
    'new',
    'matching',
    'collision',
    'box-only',
    'changed',
    'deleted'
  ]) {
    testWidgets('復元IDを保持し他の内容・削除と衝突した追加を拒否する $scenario', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final box = Hive.box<PresetPhrase>('presetPhrases');
      const restored = '復元した本文';
      final id = scenario == 'new' ? 'new-id' : 'keep';
      store.values['flutter.preset_phrase_drafts'] = jsonEncode({
        'add': {'id': id, 'content': restored, 'category': 'health'}
      });
      if (scenario != 'new' && scenario != 'collision') {
        await tester.runAsync(() => box.put('keep',
            box.get('keep')!.copyWith(content: restored, category: 'health')));
      }
      if (scenario == 'box-only') {
        await tester.runAsync(
            () => box.put('spare', box.get('keep')!.copyWith(id: 'spare')));
        await tester.runAsync(() => box.delete('keep'));
        container.read(presetPhraseNotifierProvider);
        await tester.runAsync(() => box.put(
            'keep',
            PresetPhrase(
                id: 'keep',
                content: 'boxだけにある他の本文',
                category: 'daily',
                displayOrder: 0,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026))));
      }
      await open(tester);
      expect(find.widgetWithText(TextField, restored), findsOneWidget);
      if (scenario == 'collision' || scenario == 'box-only') {
        expect(find.textContaining('コピー'), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), '今回の変更本文');
      if (scenario == 'changed') {
        // stateは復元時のまま、実boxだけ他経路で変わった場合も拒否する。
        await tester.runAsync(() =>
            box.put('keep', box.get('keep')!.copyWith(content: '別経路の変更')));
      }
      if (scenario == 'deleted') {
        await tester.runAsync(() => container
            .read(presetPhraseNotifierProvider.notifier)
            .deletePhrase('keep'));
      }
      await submit(tester);
      final allowed = scenario == 'new' || scenario == 'matching';
      expect(find.byType(TextField), allowed ? findsNothing : findsOneWidget);
      if (!allowed) {
        final notice = find.textContaining('コピー');
        expect(notice, findsOneWidget);
        expect(tester.renderObject<RenderParagraph>(notice).didExceedMaxLines,
            isFalse);
      }
      await tester.runAsync(() async {
        await box.close();
        final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
        if (allowed) {
          expect(reopened.keys, contains(id));
          expect(reopened.values.where((p) => p.content.contains('今回の変更')),
              hasLength(1));
          expect(reopened.get(id)?.category, contains('health'));
          expect(reopened.values, hasLength(scenario == 'new' ? 2 : 1));
        } else {
          expect(reopened.values.where((p) => p.content.contains('今回の変更')),
              isEmpty);
          if (scenario == 'deleted') {
            expect(reopened.keys, isNot(contains('keep')));
          }
          if (scenario == 'changed') {
            expect(reopened.get('keep')?.content, contains('別経路の変更'));
          }
          if (scenario == 'collision') {
            expect(reopened.get('keep')?.content, contains('既存の本文'));
          }
          if (scenario == 'box-only') {
            expect(reopened.get('keep')?.content, contains('boxだけにある'));
          }
        }
      });
    });
  }
  for (final delete in [false, true]) {
    testWidgets('flush待機中の実notifier変更（削除=$delete）は最後の照合で拒否する', (tester) async {
      store.values['flutter.preset_phrase_drafts'] = jsonEncode({
        'add': {'id': 'keep', 'content': '既存の本文', 'category': 'daily'}
      });
      await open(tester);
      await tester.enterText(find.byType(TextField), 'flush前の入力');
      store.writeGate = Completer<void>();
      await tester.tap(find.text('保存'));
      await tester.pump();
      final notifier = container.read(presetPhraseNotifierProvider.notifier);
      await tester.runAsync(() async {
        if (delete) {
          await notifier.deletePhrase('keep');
        } else {
          await notifier.updatePhrase('keep', content: '待機中の別経路変更');
        }
      });
      store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('コピー'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'flush前の入力'), findsOneWidget);
      await tester.runAsync(() async {
        await Hive.box<PresetPhrase>('presetPhrases').close();
        final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
        if (delete) {
          expect(reopened.keys, isNot(contains('keep')));
        } else {
          expect(reopened.get('keep')?.content, contains('待機中の別経路変更'));
        }
      });
    });
  }
  testWidgets('本体保存後のclear待機中もkeyboard・変更・cancel・back・連打を止める', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '消去待機中の本文');
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    store.clearGate = Completer<void>();
    await tester.runAsync(() => tester.tap(find.text('保存')));
    await tester.pump();
    for (var i = 0; i < 100 && !store.clearStarted; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(store.clearStarted, isTrue);
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.tap(find.text('保存'), warnIfMissed: false);
    await tester.tap(find.text('キャンセル'), warnIfMissed: false);
    await tester.tap(find.widgetWithText(ChoiceChip, 'その他'),
        warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '消去待機中の本文'), findsOneWidget);
    expect(tester.testTextInput.hasAnyClients, isFalse);
    expect(find.textContaining('破棄しますか'), findsNothing);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
            .selected,
        isTrue);
    store.clearGate!.complete();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.runAsync(() async {
      await Hive.box<PresetPhrase>('presetPhrases').close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.values.where((p) => p.content.contains('消去待機中')),
          hasLength(1));
    });
  });
}
