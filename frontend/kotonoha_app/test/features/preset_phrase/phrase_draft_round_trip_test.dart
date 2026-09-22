import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/app_state/providers/app_lifecycle_observer.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/phrase_draft_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';

/// putは届くが例外で返る（1回目だけ）実box境界。L-143の形。
class _AfterPutFailureBox extends Mock implements Box<PresetPhrase> {}

// SDK境界だけを置換。false/throw時はstoreを更新せずcacheと区別する。
class DraftStore extends SharedPreferencesStorePlatform {
  DraftStore([Map<String, Object>? initial]) : values = {...?initial};
  final Map<String, Object> values;
  Completer<void>? readGate;
  Completer<void>? writeGate;
  Completer<void>? clearGate;
  bool clearStarted = false;
  int writes = 0;
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
      writes++;
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

/// 定型文の下書きのSharedPreferencesキー（SDK境界での実体名）。
const String draftKey = 'flutter.$phraseDraftWriteKey';

/// 本文欄そのもののセマンティクス。`find.byType(TextField)` から取ると
/// 祖先のルートノード（scopesRoute）が返り、どの状態でも同じ値になる。
SemanticsData textFieldSemantics(WidgetTester tester) =>
    tester.getSemantics(find.byType(EditableText)).getSemanticsData();

/// 支援技術と同じ経路で本文欄へ focus を送り、出た例外を返す（無ければ null）。
/// `AbsorbPointer` は action に印を付けるだけで、`performAction` は素通りする。
Future<Object?> sendSemanticsFocus(WidgetTester tester) async {
  final node = tester.getSemantics(find.byType(EditableText));
  Object? thrown;
  try {
    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(node.id, SemanticsAction.focus);
    await tester.pumpAndSettle();
  } catch (e) {
    thrown = e;
  }
  return thrown ?? tester.takeException();
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
  testWidgets('初期read失敗でも追加はでき、未読mapへは1回も書かない', (tester) async {
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      'add': {'id': 'draft-1', 'content': '未読の本文', 'category': 'health'}
    });
    store.failRead = true;
    await open(tester);
    expect(find.text('再読み込み'), findsOneWidget);
    // 下書きは補助。読めなくても主機能（定型文の追加）は止めない。
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    await tester.enterText(find.byType(TextField), '未読でも保存する本文');
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存'))
            .onPressed,
        isNotNull);
    // 保存できることを告知に含める（できないと読ませない）。
    expect(find.textContaining('下書きは残りません'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await submit(tester);
    expect(find.byType(PhraseAddDialog), findsNothing);
    // 未読のmapは1回も上書きしない。
    expect(store.writes, 0);
    expect(store.values['flutter.preset_phrase_drafts'], contains('未読の本文'));
    await tester.runAsync(() async {
      await Hive.box<PresetPhrase>('presetPhrases').close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.values.where((p) => p.content.contains('未読でも保存する')),
          hasLength(1));
    });
    // 読めるようになれば、残したままの下書きがそのまま戻る。
    store.failRead = false;
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '未読の本文'), findsOneWidget);
  });
  testWidgets('初期read失敗でも再試行は同じ固定IDで、重複を作らない', (tester) async {
    // 下書きが読めないダイアログでも、一次putが届いてから失敗した再試行が
    // 2件目を作らない（L-143。固定IDはダイアログごとに1つ）。
    final box = Hive.box<PresetPhrase>('presetPhrases');
    final boundary = _AfterPutFailureBox();
    var puts = 0;
    registerFallbackValue(box.get('keep')!);
    when(() => boundary.values).thenAnswer((_) => box.values);
    when(() => boundary.put(any<dynamic>(), any())).thenAnswer((call) async {
      puts++;
      await box.put(call.positionalArguments[0],
          call.positionalArguments[1] as PresetPhrase);
      if (puts == 1) throw StateError('SDK: after put');
    });
    when(boundary.compact).thenAnswer((_) => box.compact());
    when(boundary.flush).thenAnswer((_) => box.flush());
    store.failRead = true;
    container.dispose();
    container = ProviderContainer(
        overrides: [presetPhraseBoxProvider.overrideWithValue(boundary)]);
    await open(tester);
    await tester.enterText(find.byType(TextField), '固定IDで再試行する本文');
    await submit(tester);
    expect(find.textContaining('保存を確認できません'), findsOneWidget);
    await submit(tester);
    expect(find.byType(PhraseAddDialog), findsNothing);
    expect(store.writes, 0);
    await tester.runAsync(() async {
      await box.close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.values.where((p) => p.content.contains('固定IDで再試行')),
          hasLength(1));
    });
  });
  testWidgets('読込失敗中に打った本文は「再読み込み」で消えない', (tester) async {
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      'add': {'id': 'draft-1', 'content': '未読の本文', 'category': 'health'}
    });
    store.failRead = true;
    await open(tester);
    expect(find.text('再読み込み'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '未読中に打った本文');
    await tester.pump();
    // 未読の間に打った文はどこにも控えが無い。読み直して置き換える道を出さない。
    final reload = find.widgetWithText(TextButton, '再読み込み');
    expect(
        reload.evaluate().isEmpty ||
            tester.widget<TextButton>(reload).onPressed == null,
        isTrue,
        reason: '打った文があるうちは読み直せない');
    store.failRead = false;
    if (reload.evaluate().isNotEmpty) {
      await tester.tap(reload, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(find.widgetWithText(TextField, '未読中に打った本文'), findsOneWidget);
    expect(store.writes, 0);
    expect(store.values['flutter.preset_phrase_drafts'], contains('未読の本文'));
    // 捨てるものが無くなれば読み直せる。
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '未読の本文'), findsOneWidget);
    expect(store.writes, 0);
  });
  testWidgets('読込失敗中はカテゴリだけ選び直しても「再読み込み」を出さない', (tester) async {
    // L-170(b): 「まだ何も打っていない」は本文だけでなくカテゴリも見る。
    // 未読の間に選び直したカテゴリはstoreに控えが無く、読み直すと消える。
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      'add': {'id': 'draft-1', 'content': '未読の本文', 'category': 'health'}
    });
    store.failRead = true;
    await open(tester);
    expect(find.text('再読み込み'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'その他'));
    await tester.pumpAndSettle();
    final reload = find.widgetWithText(TextButton, '再読み込み');
    expect(
        reload.evaluate().isEmpty ||
            tester.widget<TextButton>(reload).onPressed == null,
        isTrue,
        reason: '選び直したカテゴリがあるうちは読み直せない');
    // 読めていないことはカテゴリ変更でも消えない事実として残す。
    expect(find.textContaining('下書きは残りません'), findsOneWidget);
    expect(store.writes, 0);
    expect(store.values['flutter.preset_phrase_drafts'], contains('未読の本文'));
    // 既定へ戻せば捨てるものが無いので読み直せる。
    store.failRead = false;
    await tester.tap(find.widgetWithText(ChoiceChip, '日常'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '未読の本文'), findsOneWidget);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
            .selected,
        isTrue);
    expect(store.writes, 0);
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
  testWidgets('初期read待機中の本文欄は支援技術のfocusを拒み、解けたら受ける', (tester) async {
    // L-169 / QA R-6: `ExcludeFocus`＋`AbsorbPointer` は action に印を付ける
    // だけで `SemanticsOwner.performAction` は素通りする。凍結を `TextField`
    // 自身へ渡さないと `text_field.dart` の `canRequestFocus` assertion に
    // 当たる（debug は例外、release は黙って失敗）。
    final handle = tester.ensureSemantics();
    store.readGate = Completer<void>();
    await open(tester);
    var data = textFieldSemantics(tester);
    expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse,
        reason: '読込待機中の本文欄が支援技術に「有効」と見えている');
    expect(data.hasFlag(SemanticsFlag.isReadOnly), isTrue);
    expect(await sendSemanticsFocus(tester), isNull,
        reason: '読込待機中にfocusを送るとframeworkのassertionに当たる');
    store.readGate!.complete();
    await tester.pumpAndSettle();
    // 凍結が解けたら、支援技術からも普通に打てる。
    data = textFieldSemantics(tester);
    expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue,
        reason: '凍結が解けても本文欄が無効のままになっている');
    expect(data.hasFlag(SemanticsFlag.isReadOnly), isFalse);
    expect(await sendSemanticsFocus(tester), isNull);
    await tester.enterText(find.byType(TextField), '凍結解除後の本文');
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.values['flutter.preset_phrase_drafts'], contains('凍結解除後の本文'));
    handle.dispose();
  });
  testWidgets('clear失敗ではHive成功済み内容をfreezeし再試行はclearのみ', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '確定保存の本文');
    store.failClear = true;
    await submit(tester);
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
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
    testWidgets('古いwrite待機→${empty ? '空本文のback' : '明示破棄'}→再起動（空本文=$empty）',
        (tester) async {
      await open(tester, observe: true);
      store.writeGate = Completer<void>();
      if (!empty) await tester.enterText(find.byType(TextField), '破棄する本文');
      await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
      await tester.pump(const Duration(milliseconds: 400));
      if (empty) {
        // 本文が空でも、システムbackは確認なしに下書きを消さない。閉じるだけ。
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        store.writeGate!.complete();
        for (var i = 0;
            i < 100 &&
                !store.values.containsKey('flutter.preset_phrase_drafts');
            i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
        await restart(tester);
        expect(
            tester
                .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
                .selected,
            isTrue);
        return;
      }
      await tester.tap(find.text('キャンセル'));
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
  testWidgets('下書きを1度も打たずにpausedしても書かず、失敗も告知しない', (tester) async {
    // L-159: `flush()` が無条件に map 全体を書いていたため、下書きを
    // 打っていない利用者が、背景へ回るたびに存在しないものについての
    // 「定型文の下書きを保存できません」を見ていた（誤発報）。
    await open(tester, observe: true, banner: true);
    store.failWrite = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect(store.writes, 0, reason: '下書きが無いのにmap全体を書いている');
    expect(container.read(settingsWriteFailureProvider),
        isNot(contains(phraseDraftWriteKey)),
        reason: '書いてもいない下書きの保存失敗を報告している');
    expect(find.textContaining('定型文の下書きを保存できません', skipOffstage: false),
        findsNothing);
  });
  testWidgets('書込中に打ち直した本文は次のpausedで必ず書かれる', (tester) async {
    // L-159: dirty を「書込の完了」で降ろすと、snapshotを取った後に打ち直した
    // 分が「保存済み」に見え、次のflushが黙って skip する＝打ち直した文が
    // 書かれないまま背景へ回る（下書きが黙って消える）。
    await open(tester, observe: true);
    store.writeGate = Completer<void>();
    await tester.enterText(find.byType(TextField), '書込中のA');
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.writes, 1, reason: 'Aのflushが始まっていない');
    // Aの書込が止まっている間にBへ打ち直す（Bのtimerはまだ鳴らない）。
    await tester.enterText(find.byType(TextField), '打ち直したB');
    await tester.pump(const Duration(milliseconds: 100));
    // Aだけを完了させる。
    store.writeGate!.complete();
    store.writeGate = null;
    for (var i = 0; i < 50 && !store.values.containsKey(draftKey); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect(store.values[draftKey], contains('書込中のA'));
    // Bのtimerが鳴る前に背景へ回す。
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    for (var i = 0; i < 100 && store.writes < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect(store.writes, 2, reason: '打ち直したBが書かれないまま背景へ回った');
    expect(store.values[draftKey], contains('打ち直したB'));
    await restart(tester);
    expect(find.widgetWithText(TextField, '打ち直したB'), findsOneWidget);
  });
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
    testWidgets('明示破棄 $action の失敗後も $action で閉じられ、下書きは残る', (tester) async {
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
      expect(find.textContaining('下書きを消せません'), findsOneWidget);
      // 書込が失敗し続けても閉じる手段がある（モーダルの下の緊急ボタンへ戻れる）。
      // backは再試行で止まらず閉じる。
      if (action == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.text('閉じる'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PhraseAddDialog), findsNothing);
      // 閉じただけなので消えていない。次に開くと戻る。
      await restart(tester);
      expect(find.widgetWithText(TextField, '破棄失敗を保持'), findsOneWidget);
      store.failClear = false;
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await restart(tester);
      expect(find.widgetWithText(TextField, '破棄失敗を保持'), findsNothing);
    });
  }
  testWidgets('空本文の「キャンセル」はカテゴリだけの下書きも消す', (tester) async {
    await open(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.values['flutter.preset_phrase_drafts'], contains('health'));
    // 本文が空でも「キャンセル」は明示破棄。backと違って消す。
    await submit(tester, action: 'キャンセル');
    expect(find.byType(PhraseAddDialog), findsNothing);
    final map =
        jsonDecode(store.values['flutter.preset_phrase_drafts']! as String)
            as Map;
    expect(map.keys, isNot(contains('add')));
    await restart(tester);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
            .selected,
        isFalse);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '日常'))
            .selected,
        isTrue);
  });
  testWidgets('clear失敗の後に打ち直した本文はbackの確認を取り戻す', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '破棄したかった本文');
    await tester.pump(const Duration(milliseconds: 400));
    store.failClear = true;
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
    // 考え直して打ち直した文は、まだ守る対象。backで黙って消さない。
    await tester.enterText(find.byType(TextField), '打ち直した本文');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('破棄しますか'), findsOneWidget);
    await tester.tap(find.text('書き続ける'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '打ち直した本文'), findsOneWidget);
  });
  testWidgets('clear失敗の告知はカテゴリを選び直しても本文と同じ規則で消える', (tester) async {
    // L-170(a): `_onCategoryChanged` だけ `_errorMessage` を残していたため
    // 「閉じる」が消えたのに消去失敗の告知だけが残った。
    await open(tester);
    await tester.enterText(find.byType(TextField), '破棄したかった本文');
    await tester.pump(const Duration(milliseconds: 400));
    store.failClear = true;
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
    store.failClear = false;
    // 選び直したカテゴリも、打ち直した本文と同じくまだ守る対象。
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.pumpAndSettle();
    expect(find.textContaining('下書きを消せません'), findsNothing);
    expect(find.text('閉じる'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('破棄しますか'), findsOneWidget);
    await tester.tap(find.text('書き続ける'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '破棄したかった本文'), findsOneWidget);
  });
  testWidgets('保存済み＋clear失敗でも閉じられ、開き直しても本体は重複しない', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '閉じても重複しない本文');
    store.failClear = true;
    await submit(tester);
    expect(find.textContaining('保存済み'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseAddDialog), findsNothing);
    expect(
        store.values['flutter.preset_phrase_drafts'], contains('閉じても重複しない本文'));
    // 開き直して保存を押しても、固定IDのままなので本体は増えない。
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await submit(tester);
    store.failClear = false;
    await submit(tester);
    expect(find.byType(PhraseAddDialog), findsNothing);
    await tester.runAsync(() async {
      await Hive.box<PresetPhrase>('presetPhrases').close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.values.where((p) => p.content.contains('閉じても重複しない')),
          hasLength(1));
    });
  });
  testWidgets('保存済みの凍結中も本文欄は支援技術のfocusを拒む', (tester) async {
    // L-169: `_committed` の凍結。ここで打てると保存済みの本体を書き換える。
    final handle = tester.ensureSemantics();
    await open(tester);
    await tester.enterText(find.byType(TextField), '凍結される本文');
    store.failClear = true;
    await submit(tester);
    expect(find.textContaining('保存済み'), findsOneWidget);
    final data = textFieldSemantics(tester);
    expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse,
        reason: '保存済みの凍結中に本文欄が支援技術に「有効」と見えている');
    expect(data.hasFlag(SemanticsFlag.isReadOnly), isTrue);
    expect(await sendSemanticsFocus(tester), isNull,
        reason: '保存済みの凍結中にfocusを送るとframeworkのassertionに当たる');
    // 打てなくしても読めなくはしない（何が凍結されたのか分からなくなる）。
    expect(data.value, contains('凍結される本文'));
    // 出口（「閉じる」）は凍結の外に残す。
    expect(find.text('閉じる'), findsOneWidget);
    handle.dispose();
  });
  testWidgets('本体保存後のremoveAddが例外でも、消えたことにせず閉じない', (tester) async {
    // 失敗の報告そのものが壊れる経路。`removeAdd` が投げても
    // 「保存できた」と誤判定して下書きを残したまま閉じない。
    var armed = false;
    final drafts = PhraseDrafts((key, succeeded) {
      if (armed) throw StateError('report failed');
    });
    addTearDown(drafts.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => PhraseAddDialog(
                drafts: drafts,
                onSave: (content, category) async {
                  armed = true; // 本体保存の直後＝消去の手前で壊す
                  return true;
                },
              ),
            ),
            child: const Text('開く'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '例外でも残す本文');
    await submit(tester);
    expect(find.byType(PhraseAddDialog), findsOneWidget);
    expect(find.textContaining('保存済み'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
  });
  testWidgets('キャンセルの消去が例外で返っても閉じ込めない', (tester) async {
    // 報告そのものが壊れる経路。`_saving` を戻さないと全操作が塞がる。
    var armed = false;
    final drafts = PhraseDrafts((key, succeeded) {
      if (armed) throw StateError('report failed');
    });
    addTearDown(drafts.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => PhraseAddDialog(drafts: drafts),
            ),
            child: const Text('開く'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    armed = true;
    await submit(tester, action: 'キャンセル');
    expect(find.byType(PhraseAddDialog), findsOneWidget);
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseAddDialog), findsNothing);
  });
  for (final scenario in [
    'new',
    'saved',
    'saved-box-only',
    'collision',
    'box-only',
    'changed',
    'deleted'
  ]) {
    testWidgets('復元IDを保存のたびに実boxで照合し直す $scenario', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final box = Hive.box<PresetPhrase>('presetPhrases');
      const restored = '復元した本文';
      // new/changed の下書きIDは、復元の時点で実boxに無い。
      final id = scenario == 'new' || scenario == 'changed' ? 'new-id' : 'keep';
      // 同じIDで本文・カテゴリまで一致＝その下書きは既に保存された後。
      final alreadySaved =
          scenario.startsWith('saved') || scenario == 'deleted';
      final stateless = scenario == 'box-only' || scenario == 'saved-box-only';
      store.values['flutter.preset_phrase_drafts'] = jsonEncode({
        'add': {'id': id, 'content': restored, 'category': 'health'}
      });
      if (alreadySaved) {
        await tester.runAsync(() => box.put('keep',
            box.get('keep')!.copyWith(content: restored, category: 'health')));
      }
      if (stateless) {
        // provider stateには無く、実boxにだけある状態を作る。
        await tester.runAsync(
            () => box.put('spare', box.get('keep')!.copyWith(id: 'spare')));
        await tester.runAsync(() => box.delete('keep'));
        container.read(presetPhraseNotifierProvider);
        await tester.runAsync(() => box.put(
            'keep',
            PresetPhrase(
                id: 'keep',
                content: scenario == 'box-only' ? 'boxだけにある他の本文' : restored,
                category: scenario == 'box-only' ? 'daily' : 'health',
                displayOrder: 0,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026))));
      }
      await open(tester);
      if (alreadySaved) {
        // 保存済みの下書きは復元せず、消して空の追加フォームとして開く。
        expect(find.widgetWithText(TextField, restored), findsNothing);
        expect(store.values['flutter.preset_phrase_drafts'],
            isNot(contains(restored)));
      } else {
        expect(find.widgetWithText(TextField, restored), findsOneWidget);
      }
      if (scenario == 'collision' || scenario == 'box-only') {
        expect(find.textContaining('コピー'), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), '今回の変更本文');
      if (scenario == 'changed') {
        // stateは復元時のまま、実boxだけ他経路で埋まった場合も拒否する。
        await tester.runAsync(() => box.put(
            'new-id',
            PresetPhrase(
                id: 'new-id',
                content: '別経路の変更',
                category: 'daily',
                displayOrder: 9,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026))));
      }
      if (scenario == 'deleted') {
        await tester.runAsync(() => container
            .read(presetPhraseNotifierProvider.notifier)
            .deletePhrase('keep'));
      }
      await submit(tester);
      const refused = ['collision', 'box-only', 'changed'];
      final allowed = !refused.contains(scenario);
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
        final added = reopened.values.where((p) => p.content.contains('今回の変更'));
        if (!allowed) {
          expect(added, isEmpty);
        } else {
          expect(added, hasLength(1));
          // 保存済みの下書きを消した後は、カテゴリも既定に戻った空フォーム。
          expect(added.single.category,
              contains(alreadySaved ? 'daily' : 'health'));
        }
        if (scenario == 'new') {
          expect(added.single.id, contains('new-id'));
          expect(reopened.values, hasLength(2));
        }
        if (alreadySaved && scenario != 'deleted') {
          // 保存済みの本体は書き換わらない。追加は別IDで増える。
          expect(reopened.get('keep')?.content, contains(restored));
          expect(added.single.id, isNot('keep'));
          expect(reopened.values, hasLength(stateless ? 3 : 2));
        }
        if (scenario == 'deleted') {
          expect(reopened.keys, isNot(contains('keep')));
          expect(added.single.id, isNot('keep'));
        }
        if (scenario == 'changed') {
          expect(reopened.get('new-id')?.content, contains('別経路の変更'));
        }
        if (scenario == 'collision') {
          expect(reopened.get('keep')?.content, contains('既存の本文'));
        }
        if (scenario == 'box-only') {
          expect(reopened.get('keep')?.content, contains('boxだけにある'));
        }
      });
      if (scenario == 'saved-box-only') {
        await restart(tester);
        expect(find.widgetWithText(TextField, restored), findsNothing);
      }
    });
  }
  testWidgets('衝突で拒否された下書きを相手と同じ本文に打ち替えても無言で閉じない', (tester) async {
    // L-168: saved は「レコードが自分の書いた／復元した内容と一致する」ときだけ。
    // 拒否されている下書き(A)を、ぶつかっている相手(B)の本文・カテゴリへ
    // 打ち替えると、`pending` だけで比べる判定が saved に化け、衝突の出口
    // （コピー案内）が無言の成功になっていた。
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final box = Hive.box<PresetPhrase>('presetPhrases');
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      'add': {'id': 'keep', 'content': '復元した本文', 'category': 'health'}
    });
    await open(tester);
    expect(find.widgetWithText(TextField, '復元した本文'), findsOneWidget);
    expect(find.textContaining('コピー'), findsOneWidget);
    // ぶつかっている相手（boxのkeep）と同じ本文・カテゴリへ打ち替える。
    await tester.enterText(find.byType(TextField), '既存の本文');
    await tester.tap(find.widgetWithText(ChoiceChip, '日常'));
    await tester.pumpAndSettle();
    await submit(tester);
    // 自分が保存したのではないのだから閉じない。コピー案内も出たまま。
    expect(find.byType(PhraseAddDialog), findsOneWidget);
    expect(find.textContaining('コピー'), findsOneWidget);
    final map =
        jsonDecode(store.values['flutter.preset_phrase_drafts']! as String)
            as Map;
    expect(map.keys, contains('add'), reason: '拒否されたのに下書きが消えている');
    expect((map['add'] as Map)['content'], '既存の本文');
    await tester.runAsync(() async {
      await box.close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      // 本体は元のまま1件。増えも書き換わりもしない。
      expect(reopened.values, hasLength(1));
      expect(reopened.get('keep')?.content, '既存の本文');
      expect(reopened.get('keep')?.category, 'daily');
    });
  });
  for (final route in ['notifier', 'box']) {
    testWidgets('flush待機中に同じIDが埋まったら（$route経由）最後の照合で拒否する', (tester) async {
      final box = Hive.box<PresetPhrase>('presetPhrases');
      // 復元の時点ではこのIDは実boxに無い＝通常の追加として受理される。
      store.values['flutter.preset_phrase_drafts'] = jsonEncode({
        'add': {'id': 'pending-id', 'content': '復元した本文', 'category': 'daily'}
      });
      await open(tester);
      await tester.enterText(find.byType(TextField), 'flush前の入力');
      store.writeGate = Completer<void>();
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.runAsync(() async {
        if (route == 'notifier') {
          await container
              .read(presetPhraseNotifierProvider.notifier)
              .addPhrase('待機中の別経路本文', 'daily', id: 'pending-id');
        } else {
          // stateには現れない、実boxだけの変化。
          await box.put(
              'pending-id',
              PresetPhrase(
                  id: 'pending-id',
                  content: '待機中の別経路本文',
                  category: 'daily',
                  displayOrder: 0,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026)));
        }
      });
      store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('コピー'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'flush前の入力'), findsOneWidget);
      await tester.runAsync(() async {
        await Hive.box<PresetPhrase>('presetPhrases').close();
        final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
        expect(reopened.get('pending-id')?.content, contains('待機中の別経路本文'));
        expect(reopened.values.where((p) => p.content.contains('flush前の入力')),
            isEmpty);
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
