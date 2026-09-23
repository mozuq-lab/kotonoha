import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import '../character_board/presentation/home_layout_test_support.dart';

/// putは届くが例外で返る（1回目だけ）実box境界。L-143の形。
class _AfterPutFailureBox extends Mock implements Box<PresetPhrase> {}

/// 読取（`values`）がErrorを投げる実box境界。L-162(a)の形。
class _ReadFailureBox extends Mock implements Box<PresetPhrase> {}

/// 一括保存が終わらない実box境界。既定の定型文の投入中＝一覧が読込中のまま。
class _PendingSaveBox extends Mock implements Box<PresetPhrase> {}

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

  /// 消去を見分ける対象entry。他のentryが残るmapでも、対象の有無で判定する。
  String targetEntry = 'add';
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
      if ((jsonDecode(value as String) as Map).containsKey(targetEntry)) {
        await writeGate?.future;
      } else {
        clearStarted = true;
        await clearGate?.future;
      }
      if (throwWrite) throw StateError('SDK write');
      if (failWrite ||
          (failClear && !(jsonDecode(value) as Map).containsKey(targetEntry))) {
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

/// 共通ケースの追加/編集 variant。素の `ValueVariant` は `currentValue` を
/// tearDown で戻さず、後続の variant 無しケースへ漏れる（追加のつもりで編集を開く）。
class FormVariant extends ValueVariant<String> {
  FormVariant() : super({'add', 'edit:keep'});
  String? form;
  @override
  Future<String> setUp(String value) async => form = value;
  @override
  Future<void> tearDown(String value, String memento) async => form = null;
}

/// [action] の間に `FlutterError.reportError` へ出た例外を全部集める。
/// `tester.takeException()` は複数を「Multiple exceptions (N)」1本に畳んで
/// しまい、1件ずつ判定できない（`home_layout_test_support.dart` と同じ理由）。
Future<List<Object>> reportedDuring(
    WidgetTester tester, Future<void> Function() action) async {
  final reported = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => reported.add(details.exception);
  try {
    await action();
  } finally {
    FlutterError.onError = previous;
  }
  // 差し替えの網から漏れた分（binding が先に受けたもの）も拾う。
  final pending = tester.takeException();
  if (pending != null) reported.add(pending);
  return reported;
}

/// 報告側が投げた `Error` が握り潰されず、端末内のログへ出ていること（F-1）。
void expectReportedStateErrors(List<Object> reported) {
  expect(reported, isNotEmpty, reason: '報告側のErrorが握り潰されている');
  expect(reported, everyElement(isA<StateError>()),
      reason: '想定外の例外まで出ている: $reported');
}

/// 定型文の下書きのSharedPreferencesキー（SDK境界での実体名）。
const String draftKey = 'flutter.$phraseDraftWriteKey';

/// 本文欄そのもののセマンティクス。`find.byType(TextField)` から取ると
/// 祖先のルートノード（scopesRoute）が返り、どの状態でも同じ値になる。
SemanticsData textFieldSemantics(WidgetTester tester) =>
    tester.getSemantics(find.byType(EditableText)).getSemanticsData();

/// 凍結中でも本文が有効時と同じ濃さで読めること（F-2）。
/// `enabled: false` の M3 既定は `bodyLarge.color.withOpacity(0.38)`
/// （text_field.dart:1875-1879）で、38% では AA を満たさず
/// 「何が保存されるのか」が読めない。`widget.style` は
/// `_getInputStyleForState(...).merge(providedStyle)` で**最後に** merge
/// される（:1537-1539）ので、明示した色が disabled の既定に勝つ。
void expectContentReadable(WidgetTester tester) {
  final editable = tester.widget<EditableText>(find.byType(EditableText));
  final enabledColor = Theme.of(tester.element(find.byType(PhraseFormContent)))
      .textTheme
      .bodyLarge
      ?.color;
  expect(enabledColor, isNotNull);
  expect(editable.style.color, enabledColor,
      reason: '凍結中の本文が薄字（disabled の既定）で読めない');
}

/// 支援技術と同じ経路で本文欄へ focus を送り、出た例外を返す（無ければ null）。
/// `AbsorbPointer` は action に印を付けるだけで、`performAction` は素通りする。
Future<Object?> sendSemanticsFocus(WidgetTester tester) async {
  final node = tester.getSemantics(find.byType(EditableText));
  Object? thrown;
  try {
    node.owner!.performAction(node.id, SemanticsAction.focus);
    await tester.pumpAndSettle();
  } catch (e) {
    thrown = e;
  }
  return thrown ?? tester.takeException();
}

/// 常設バナーに出ている文（ダイアログの告知と取り違えない）。
Finder bannerText(String text) => find.descendant(
    of: find.byType(PersistenceBanner),
    matching: find.textContaining(text),
    skipOffstage: false);

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
  final formVariant = FormVariant();

  /// [form] は開くフォーム: 'add'＝FAB、'edit:keep'＝実 `Icons.edit`、
  /// 'drafts'＝本番の「下書き」入口。省略時は variant（無ければ追加）。
  Future<void> open(WidgetTester tester,
      {bool observe = false, bool banner = false, String? form}) async {
    Widget home = Column(children: [
      if (banner) const PersistenceBanner(),
      const Expanded(child: PresetPhraseScreen())
    ]);
    if (observe) home = AppLifecycleObserver(child: home);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp(home: home)));
    await tester.pumpAndSettle();
    final entry = form ?? formVariant.form ?? 'add';
    store.targetEntry = entry == 'drafts' ? 'edit:keep' : entry;
    await tester.tap(switch (entry) {
      'add' => find.byType(FloatingActionButton),
      'drafts' => find.text('下書き'),
      _ => find.byIcon(Icons.edit).first,
    });
    await tester.pumpAndSettle();
  }

  Future<void> restart(WidgetTester tester, {String? form}) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    SharedPreferences.resetStatic();
    store = DraftStore(store.values);
    SharedPreferencesStorePlatform.instance = store;
    container = ProviderContainer();
    await open(tester, form: form);
  }

  /// 孤立下書きの「下書きを破棄」を押し、確認で「破棄する」を選ぶ。
  Future<void> discardOrphan(WidgetTester tester) async {
    await tester.tap(find.text('下書きを破棄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄する'));
    await tester.pumpAndSettle();
  }

  /// SDK storeに届いた下書きmap（raw JSON）。
  Map<String, dynamic> storedDrafts() =>
      jsonDecode(store.values[draftKey] as String? ?? '{}')
          as Map<String, dynamic>;

  /// 実boxを閉じて開き直した中身。UIを触り終えてから呼ぶ。
  Future<Box<PresetPhrase>> reopened(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        await Hive.box<PresetPhrase>('presetPhrases').close();
        return Hive.openBox<PresetPhrase>('presetPhrases');
      }))!;

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

  testWidgets('400ms後のSDK storeだけで再起動すると本文とカテゴリが戻り、保存で確定する', (tester) async {
    await open(tester);
    final entry = store.targetEntry;
    await tester.enterText(find.byType(TextField), 'お水をお願いします');
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.pump(const Duration(milliseconds: 399));
    expect(storedDrafts().keys, isNot(contains(entry)));
    await tester.pump(const Duration(milliseconds: 1));
    expect(storedDrafts().keys, contains(entry));
    await restart(tester);
    expect(find.widgetWithText(TextField, 'お水をお願いします'), findsOneWidget);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
            .selected,
        isTrue);
    await submit(tester);
    expect(find.byType(TextField), findsNothing);
    expect(storedDrafts().keys, isNot(contains(entry)));
    // 開き直すと、編集は確定した本文（古い本文や空と取り違えない）、追加は空。
    await open(tester);
    expect(find.widgetWithText(TextField, 'お水をお願いします'),
        entry == 'add' ? findsNothing : findsOneWidget);
    final box = await reopened(tester);
    final saved = box.values.where((p) => p.content.contains('お水をお願いします'));
    expect(saved.single.category, contains('health'));
    expect(box.values, hasLength(entry == 'add' ? 2 : 1));
    if (entry != 'add') expect(saved.single.id, contains('keep'));
  }, variant: formVariant);
  for (final failure in ['false', 'throw']) {
    testWidgets('下書きflush $failure では追加は保存を止め、編集は保存し、再試行で1件になる',
        (tester) async {
      final add = formVariant.form == 'add';
      await open(tester, banner: true);
      await tester.enterText(find.byType(TextField), '失敗でも保持する本文');
      store.failWrite = failure == 'false';
      store.throwWrite = failure == 'throw';
      await submit(tester);
      // 編集は下書きを書けなくても本体を保存し、再試行は消去だけ（L-171 決定 B）。
      expect(
          find.textContaining(add ? '入力内容を残しています' : '保存済みですが'), findsOneWidget);
      // 編集で書けなかったのは保存済みの本文だけなので「消えます」と言わない（P2）。
      expect(bannerText('保存できません'), add ? findsOneWidget : findsNothing);
      expect(
          Hive.box<PresetPhrase>('presetPhrases')
              .values
              .where((p) => p.content.contains('失敗でも')),
          hasLength(add ? 0 : 1));
      store.failWrite = store.throwWrite = false;
      await submit(tester);
      expect(find.byType(TextField), findsNothing);
      await tester.runAsync(() async {
        await Hive.box<PresetPhrase>('presetPhrases').close();
        final box = await Hive.openBox<PresetPhrase>('presetPhrases');
        expect(
            box.values.where((p) => p.content.contains('失敗でも')), hasLength(1));
      });
    }, variant: formVariant);
  }
  testWidgets('初期read失敗でも追加・編集はでき、未読mapへは1回も書かない', (tester) async {
    final entry = formVariant.form!;
    store.values['flutter.preset_phrase_drafts'] = jsonEncode({
      entry: {
        'id': entry == 'add' ? 'draft-1' : 'keep',
        'content': '未読の本文',
        'category': 'health'
      }
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
    // 打った内容を読み直しで置き換える道を出さない。
    expect(find.text('再読み込み'), findsNothing);
    await submit(tester);
    expect(find.byType(TextField), findsNothing);
    // 未読のmapは1回も上書きしない。
    expect(store.writes, 0);
    expect(store.values['flutter.preset_phrase_drafts'], contains('未読の本文'));
    // 読めるようになれば、残したままの下書きがそのまま戻る。
    store.failRead = false;
    await open(tester);
    expect(find.widgetWithText(TextField, '未読の本文'), findsOneWidget);
    // 編集では保存済みの本文より古い下書きが出る。黙って出さず、そう告げる（F-1）。
    expect(find.textContaining('保存されていない下書き'),
        entry == 'add' ? findsNothing : findsOneWidget);
    // box再openによる永続化の確認は最後に。閉じたままUIを触ると、実アプリには
    // 無い「閉じたboxを読む」状態を作る（`ownsId` がHiveErrorを投げる）。
    await tester.runAsync(() async {
      await Hive.box<PresetPhrase>('presetPhrases').close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.values.where((p) => p.content.contains('未読でも保存する')),
          hasLength(1));
    });
  }, variant: formVariant);
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
    expect(data.flagsCollection.isEnabled, Tristate.isFalse,
        reason: '読込待機中の本文欄が支援技術に「有効」と見えている');
    expect(data.flagsCollection.isReadOnly, isTrue);
    expect(await sendSemanticsFocus(tester), isNull,
        reason: '読込待機中にfocusを送るとframeworkのassertionに当たる');
    // 打てなくしても読めなくはしない（F-2）。
    expectContentReadable(tester);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    // 凍結が解けたら、支援技術からも普通に打てる。
    data = textFieldSemantics(tester);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue,
        reason: '凍結が解けても本文欄が無効のままになっている');
    expect(data.flagsCollection.isReadOnly, isFalse);
    expect(await sendSemanticsFocus(tester), isNull);
    expectContentReadable(tester);
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
    // SDK boxを閉じてもclearだけなら完了できる。再add・再updateは失敗する。
    await tester.runAsync(box.close);
    store.failClear = false;
    await submit(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.runAsync(() async {
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      expect(reopened.get(saved.id)?.content, contains('確定保存'));
    });
    await restart(tester);
    // 下書きは消えている。編集は確定した本文を開く（追加は空）。
    expect(storedDrafts().keys, isNot(contains(store.targetEntry)));
    expect(find.widgetWithText(TextField, '確定保存の本文'),
        store.targetEntry == 'add' ? findsNothing : findsOneWidget);
  }, variant: formVariant);
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
      // 編集はカテゴリを変えただけでも元と違うので、空本文のbackは追加だけ。
    }, variant: empty ? const DefaultTestVariant() : formVariant);
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
  testWidgets('読み込みで落とした不正entryは、打たなくても次のpausedで掃除される', (tester) async {
    // F-10 / 監査 P1-1: `_load` が落とした不正 entry は store との差＝「変更」。
    // dirty にしないと L-159 以降、入力しないまま背景へ回しても書き戻されず、
    // 読込エラーの告知が起動のたびに出続ける（BASE では paused の無条件書込で
    // 一掃されていた。公開文「次に書き込みに成功したとき」の実態）。
    store.values[draftKey] = jsonEncode({
      'add': {'id': 'draft-1', 'content': '正常な下書き', 'category': 'daily'},
      'bogus': 1,
    });
    await open(tester, observe: true, banner: true);
    expect(find.widgetWithText(TextField, '正常な下書き'), findsOneWidget);
    expect(find.textContaining('読み込め', skipOffstage: false), findsWidgets);
    // 何も打たずに背景へ回すだけ。
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    for (var i = 0; i < 100 && store.writes < 1; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect(store.writes, 1, reason: '落とした不正entryが書き戻されていない');
    final map = jsonDecode(store.values[draftKey]! as String) as Map;
    expect(map.keys, isNot(contains('bogus')));
    expect((map['add'] as Map)['content'], '正常な下書き');
  });
  testWidgets('書込に失敗した下書きは、入力を変えなくても次のpausedで再試行する', (tester) async {
    // L-159 が約束した「失敗後は dirty のまま＝次の paused で再試行される」。
    // `_written` を**成功したときだけ**進めることが効いている（F-3）。
    await open(tester, observe: true, banner: true);
    await tester.enterText(find.byType(TextField), '失敗しても次で書く本文');
    store.failWrite = true;
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.writes, 1);
    expect(store.values.keys, isNot(contains(draftKey)), reason: '失敗したのに書けている');
    expect(find.textContaining('定型文の下書きを保存できません', skipOffstage: false),
        findsWidgets);
    // 入力は一切変えない。書けるようになってから背景へ回すだけ。
    store.failWrite = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    for (var i = 0; i < 100 && store.writes < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect(store.writes, 2, reason: '失敗した下書きが次のpausedで再試行されていない');
    final map = jsonDecode(store.values[draftKey]! as String) as Map;
    expect((map['add'] as Map)['content'], '失敗しても次で書く本文');
    // 書けたので告知も消える。
    await tester.pumpAndSettle();
    expect(container.read(settingsWriteFailureProvider),
        isNot(contains(phraseDraftWriteKey)));
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
  }, variant: formVariant);
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
      expect(find.byType(TextField), findsNothing);
      // 閉じただけなので消えていない。次に開くと戻る。
      await restart(tester);
      expect(find.widgetWithText(TextField, '破棄失敗を保持'), findsOneWidget);
      store.failClear = false;
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await restart(tester);
      expect(find.widgetWithText(TextField, '破棄失敗を保持'), findsNothing);
    }, variant: formVariant);
  }
  testWidgets('下書きが無いキャンセルは書かず、事実と逆の告知も出さない', (tester) async {
    // F-11 / 監査 P1-4: L-159 と同じ誤発報が明示操作側に残っていた。消すものが
    // 無いのに書きに行き、失敗すると「下書きを消せませんでした。閉じると次回も
    // 残ります」が出る（残る下書きは存在しない）。
    await open(tester, banner: true);
    store.failWrite = true;
    await submit(tester, action: 'キャンセル');
    expect(find.byType(PhraseAddDialog), findsNothing, reason: '閉じられていない');
    expect(find.textContaining('下書きを消せません'), findsNothing);
    expect(find.textContaining('定型文の下書き', skipOffstage: false), findsNothing);
    expect(store.writes, 0, reason: '消すものが無いのに書いている');
    expect(container.read(settingsWriteFailureProvider),
        isNot(contains(phraseDraftWriteKey)));
  });
  testWidgets('消去の失敗は「消せません」と告げ、捨てる打鍵や消去の再失敗で「消えます」と言わない', (tester) async {
    // L-182: 消去と保存の失敗を同じkeyで報告し、下書きが残るのに常設バナーが
    // 「アプリを閉じると消えます」と告げていた（ダイアログの「次回も残ります」と逆）。
    await open(tester, banner: true);
    await tester.enterText(find.byType(TextField), '消せない本文');
    await tester.pump(const Duration(milliseconds: 400));
    store.failClear = true;
    // 失敗した消去の試行は、続けて失敗しても書けていない入力に数えない（C-1）。
    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(bannerText('消えます'), findsNothing,
          reason: '$attempt 回目: 下書きは残るのに消えると告げている');
      expect(bannerText('消せません'), findsOneWidget);
    }
    // 次の書込が成功すれば解消する。
    store.failClear = false;
    await tester.enterText(find.byType(TextField), '打ち直した本文');
    await tester.pump(const Duration(milliseconds: 400));
    expect(bannerText('定型文の下書き'), findsNothing);
    // 書けた後にさらに打ち、400ms 以内に「キャンセル」して消去も失敗した（P1）。
    // 書けていないのは捨てると決めた打鍵だけなので「消えます」とは言わない。
    await tester.enterText(find.byType(TextField), '捨てる打鍵');
    await tester.pump(const Duration(milliseconds: 100));
    store.failClear = true;
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(bannerText('消えます'), findsNothing, reason: '捨てた打鍵を理由に消えると告げている');
    expect(bannerText('消せません'), findsOneWidget);
  }, variant: formVariant);
  testWidgets('一度も書けていない下書きの消去が失敗しても「次回も残ります」と言わない', (tester) async {
    // P3: 残るものが無いのに、バナーが「消せませんでした。次回も残ります」と告げていた。
    await open(tester, banner: true);
    store.failWrite = true;
    await tester.enterText(find.byType(TextField), '書けたことの無い本文');
    await tester.pump(const Duration(milliseconds: 400));
    expect(bannerText('消えます'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(bannerText('次回も残ります'), findsNothing, reason: '残るものが無いのに残ると告げている');
    // 書けていないのは捨てると決めた本文だけなので「消えます」も言わない。
    expect(bannerText('消えます'), findsNothing);
    await restart(tester);
    expect(find.widgetWithText(TextField, '書けたことの無い本文'), findsNothing);
  }, variant: formVariant);
  testWidgets('書込の待機中に「キャンセル」した消去の失敗は、先の書込が届いた後の store で判定する', (tester) async {
    // F-2: 消せなかった entry が store にあるかは、直列の queue の中で先行する
    // 書込の結果を反映してから見る（書けて残った下書きなら「次回も残ります」）。
    await open(tester, banner: true);
    await tester.enterText(find.byType(TextField), '書込待ちの本文');
    store.writeGate = Completer<void>();
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.writes, 1, reason: '書込が待機に入っていない');
    store.failClear = true;
    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    store.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(storedDrafts().keys, contains(store.targetEntry));
    expect(bannerText('消せません'), findsOneWidget, reason: '残った下書きの消去失敗を告げていない');
  }, variant: formVariant);
  testWidgets('破損の掃除だけが書けていないときの消去失敗では「消えます」と言わない', (tester) async {
    // A-5: 読込で落とした entry の掃除は入力ではない（掃除の書き戻しは L-159 のまま）。
    final entry = formVariant.form!;
    store.values[draftKey] = jsonEncode({
      entry: {
        'id': entry == 'add' ? 'draft-1' : 'keep',
        'content': '読めた下書き',
        'category': 'daily'
      },
      'bogus': 1,
    });
    await open(tester, banner: true);
    store.failClear = true;
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(bannerText('消せません'), findsOneWidget);
    expect(bannerText('消えます'), findsNothing, reason: '失うのは破損の掃除だけなのに消えると告げている');
  }, variant: formVariant);
  testWidgets('他のentryに書けていない入力があるうちは、消去が失敗しても「消えます」を出し続ける', (tester) async {
    // R-A の後半: この消去以外の未書込は、閉じると消えるのが事実なので告げ続ける。
    await open(tester, banner: true, form: 'add');
    store.failWrite = true;
    // 本文が空でカテゴリだけ選んだ追加は、戻る操作で下書きを消さずに閉じる。
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(bannerText('消えます'), findsOneWidget);
    store.targetEntry = 'edit:keep';
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '捨てる編集');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('閉じる'), findsOneWidget, reason: '消去が失敗していない');
    expect(bannerText('消えます'), findsOneWidget, reason: '追加の未書込が残るのに告知が消えた');
  });
  testWidgets('読めない下書きは読み直せると、壊れていた下書きは戻せないと分けて告げる', (tester) async {
    // L-176: 読込失敗（読み直せる）と破損（落とした分は戻らない）が同じ文で、
    // 一覧は破損で落とした分があっても「ありません」とだけ言っていた。
    store.failRead = true;
    await open(tester, banner: true, form: 'drafts');
    expect(bannerText('開き直すと読み直します'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    store.failRead = false;
    store.values[draftKey] = jsonEncode({'bogus': 1});
    await tester.tap(find.text('下書き'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ありません'), findsOneWidget);
    expect(find.textContaining('壊れていて読み込めなかった下書き'), findsOneWidget);
    expect(bannerText('戻せません'), findsOneWidget);
    expect(bannerText('読み直します'), findsNothing, reason: '戻らない破損に読み直しを案内');
    // 読めた下書きが並ぶときも添える（落ちたのが追加か編集かは判別できない）。
    store.values[draftKey] = jsonEncode({
      'bogus': 1,
      'edit:keep': {'id': 'keep', 'content': '読めた下書き', 'category': 'daily'}
    });
    await restart(tester, form: 'drafts');
    expect(find.textContaining('読めた下書き'), findsOneWidget);
    expect(find.textContaining('壊れていて読み込めなかった下書き'), findsOneWidget);
  });
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
    expect(data.flagsCollection.isEnabled, Tristate.isFalse,
        reason: '保存済みの凍結中に本文欄が支援技術に「有効」と見えている');
    expect(data.flagsCollection.isReadOnly, isTrue);
    expect(await sendSemanticsFocus(tester), isNull,
        reason: '保存済みの凍結中にfocusを送るとframeworkのassertionに当たる');
    // 打てなくしても読めなくはしない（何が凍結されたのか分からなくなる）。
    expect(data.value, contains('凍結される本文'));
    expectContentReadable(tester);
    // 出口（「閉じる」）は凍結の外に残す。
    expect(find.text('閉じる'), findsOneWidget);
    handle.dispose();
  });
  testWidgets('保存の待機が複数フレームにまたがっても本文欄は支援技術のfocusを拒み、スクロール位置を保つ',
      (tester) async {
    // L-177: `_saving` 中も本文欄は enabled のままで、focus を送ると
    // `canRequestFocus` assertion に当たった。I/O を gate で止めて待機を伸ばす
    // （gate は開けない。開けると FakeAsync の中で実 Hive の I/O が走って止まる）。
    final handle = tester.ensureSemantics();
    await open(tester);
    await tester.enterText(
        find.byType(TextField), '${'保存を待つ本文'.padRight(300, 'あ')}末尾');
    // 末尾の caret を見せるスクロール（100ms）を、400ms 後の書込より前に終える。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    // 待機中に包みの型が替わると本文欄の State が作り直され、先頭へ戻る（M-1）。
    final inner = find
        .descendant(
            of: find.byType(EditableText), matching: find.byType(Scrollable))
        .first;
    double offset() => tester.state<ScrollableState>(inner).position.pixels;
    final end = offset();
    expect(end, greaterThan(0));
    store.writeGate = Completer<void>();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();
    expect(store.writes, 1, reason: '下書きの書込が待機に入っていない');
    expect(offset(), closeTo(end, 1), reason: '保存の待機中に本文欄が先頭へ戻った');
    expect(await sendSemanticsFocus(tester), isNull,
        reason: '保存の待機中にfocusを送るとframeworkのassertionに当たる');
    expectContentReadable(tester);
    handle.dispose();
  }, variant: formVariant);
  testWidgets('消去の再試行の待機中は、確認なしで閉じる状態でも戻る操作で閉じない', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), '再試行を待つ本文');
    await tester.pump(const Duration(milliseconds: 400));
    store.failClear = true;
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('閉じる'), findsOneWidget);
    store.failClear = false;
    store.clearGate = Completer<void>();
    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget, reason: '消去の待機中に戻る操作で閉じた');
    store.clearGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  }, variant: formVariant);
  testWidgets('孤立の閲覧は破棄の待機が複数フレームにまたがってもスクロール位置を保つ', (tester) async {
    // L-185: 待機中の描画で根の widget の型が替わり、スクロールの State が
    // 作り直されて先頭へ戻っていた（I/O が同じフレームで終わる mock では見えない）。
    tester.view.physicalSize = const Size(400, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = '${'長い孤立の下書き'.padRight(498, 'あ')}末尾';
    store.values[draftKey] = jsonEncode({
      'edit:gone': {'id': 'gone', 'content': long, 'category': 'daily'}
    });
    await open(tester, form: 'drafts');
    await tester.tap(find.textContaining('長い孤立の下書き'));
    await tester.pumpAndSettle();
    final scroll = find
        .ancestor(of: find.text(long), matching: find.byType(Scrollable))
        .first;
    double offset() => tester.state<ScrollableState>(scroll).position.pixels;
    await tester.drag(scroll, const Offset(0, -2000));
    await tester.pumpAndSettle();
    final end = offset();
    expect(end, greaterThan(100));
    store.clearGate = Completer<void>();
    await tester.tap(find.text('下書きを破棄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄する'));
    await tester.pump();
    await tester.pump();
    expect(store.clearStarted, isTrue, reason: '消去が待機に入っていない');
    expect(offset(), closeTo(end, 1), reason: '待機中にスクロール位置が先頭へ戻った');
    store.clearGate!.complete();
    await tester.pumpAndSettle();
    expect(storedDrafts().keys, isNot(contains('edit:gone')));
  });
  testWidgets('onSaveが投げたErrorも穏当な文に隠さず報告し、入力を残す', (tester) async {
    // F-4: `_onSave` の catch は利用者を閉じ込めないために広いままにするが、
    // Error は端末内のログへ出す。画面側（`ownsId`）の経路しか見ていなかった
    // ので、`_onSave` 側の `reportDraftProgrammingError` を消しても赤に
    // ならなかった（Codex Important 3）。
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => PhraseAddDialog(
                onSave: (content, category) async =>
                    throw StateError('onSave exploded'),
              ),
            ),
            child: const Text('開く'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '保存が壊れても残す本文');
    final reported = await reportedDuring(tester, () => submit(tester));
    expectReportedStateErrors(reported);
    // 利用者には穏当な文のまま、入力は残り、同じ場所で再試行できる。
    expect(find.byType(PhraseAddDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, '保存が壊れても残す本文'), findsOneWidget);
    expect(find.textContaining('保存を確認できませんでした'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存'))
            .onPressed,
        isNotNull,
        reason: '`_saving` が戻らず再試行できない');
  });
  testWidgets('読込の報告が壊れてもフォームは凍結せず、下書きは書ける', (tester) async {
    // 監査 P1-5 / F-1: `_load` の `_record` が try の外だったため、報告側が
    // 投げると `initialize()` が reject し、ダイアログが `_loading` のまま
    // 永久に固まった（本文欄は `enabled:false` のまま＝1文字も打てない）。
    final drafts = PhraseDrafts((key, succeeded) {
      if (key == phraseDraftReadKey) throw StateError('read report failed');
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
    final reported = await reportedDuring(tester, () async {
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
    });
    // 凍結が解けている＝打てる。ここが今は false のまま固まる。
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue,
        reason: '読込の報告が壊れただけでフォームが凍結したまま');
    await tester.enterText(find.byType(TextField), '読込報告が壊れても打てる本文');
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.values[draftKey], contains('読込報告が壊れても打てる本文'));
    expectReportedStateErrors(reported);
  });
  testWidgets('報告側が壊れても消去の実結果で判定し、次の操作も塞がらない', (tester) async {
    // L-162(b): `_record` を try の外で呼んでいたため、報告が1度throwすると
    // `_tail` が rejected になり、以後の flush / removeAdd が全部 error に
    // なった。SDKへの書込は成功しているのに「下書きを消せませんでした」
    // （事実と逆）を出し、そのセッションの下書き操作が全部失敗になる。
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
    await tester.enterText(find.byType(TextField), '報告が壊れても消える本文');
    var reported = await reportedDuring(tester, () => submit(tester));
    // 書込は成功しているのだから、消えたものとして閉じる。
    expect(find.byType(PhraseAddDialog), findsNothing);
    expectReportedStateErrors(reported);
    var map = jsonDecode(store.values[draftKey]! as String) as Map;
    expect(map.keys, isNot(contains('add')), reason: '消えているのに下書きが残っている');
    // `_tail` が壊れていない＝同じ `PhraseDrafts` で次の操作も通る。
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '報告が壊れた後の本文');
    reported = await reportedDuring(tester, () => submit(tester));
    expect(find.byType(PhraseAddDialog), findsNothing);
    expectReportedStateErrors(reported);
    map = jsonDecode(store.values[draftKey]! as String) as Map;
    expect(map.keys, isNot(contains('add')));
  });
  testWidgets('報告が壊れて消去も失敗した後でも、再試行まで塞がらない', (tester) async {
    // 上と同じ壊し方で、SDKの書込そのものも失敗させる。書込が本当に失敗した
    // ときは今までどおり「消せませんでした」。そのうえで、報告が1度壊れた
    // ことが後続の再試行を巻き添えにしない（`_tail` が rejected にならない）。
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
    await tester.enterText(find.byType(TextField), '消去も失敗する本文');
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.values[draftKey], contains('消去も失敗する本文'));
    armed = true;
    store.failClear = true;
    var reported =
        await reportedDuring(tester, () => submit(tester, action: 'キャンセル'));
    expect(find.byType(PhraseAddDialog), findsOneWidget);
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
    expect(find.text('閉じる'), findsOneWidget);
    expectReportedStateErrors(reported);
    // 書込が通るようになれば、同じ場所の再試行でちゃんと消える。
    store.failClear = false;
    reported =
        await reportedDuring(tester, () => submit(tester, action: 'キャンセル'));
    expect(find.byType(PhraseAddDialog), findsNothing);
    expectReportedStateErrors(reported);
    final map = jsonDecode(store.values[draftKey]! as String) as Map;
    expect(map.keys, isNot(contains('add')));
  });
  testWidgets('キャンセルは報告が壊れても、消えていれば閉じる', (tester) async {
    // L-162(b): 報告そのものが壊れる経路。`_saving` を戻さないと全操作が
    // 塞がる。書込は成功しているので「消せませんでした」も出さない。
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
    await tester.enterText(find.byType(TextField), 'キャンセルで消える本文');
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.values[draftKey], contains('キャンセルで消える本文'));
    armed = true;
    final reported =
        await reportedDuring(tester, () => submit(tester, action: 'キャンセル'));
    expect(find.byType(PhraseAddDialog), findsNothing);
    expect(find.textContaining('下書きを消せません'), findsNothing);
    expectReportedStateErrors(reported);
    final map = jsonDecode(store.values[draftKey]! as String) as Map;
    expect(map.keys, isNot(contains('add')));
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
        expectNoticeReadable(tester, notice,
            tester.getRect(find.byType(PhraseFormContent)), '衝突の案内');
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
    final notice = find.textContaining('コピー');
    expect(notice, findsOneWidget);
    expectNoticeReadable(tester, notice,
        tester.getRect(find.byType(PhraseFormContent)), '衝突の案内');
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
  testWidgets('所有権の照合が投げたErrorは穏当な文に隠さず報告する', (tester) async {
    // L-162(a): `ownsId` の `catch (_)` は `loadAllSync` などが投げた
    // Error（HiveError は Error）も conflict に化かし、プログラムの誤りが
    // 利用者向けの穏当な文に隠れて開発者に届かなかった。
    final box = Hive.box<PresetPhrase>('presetPhrases');
    final boundary = _ReadFailureBox();
    var armed = false;
    registerFallbackValue(box.get('keep')!);
    when(() => boundary.values).thenAnswer((_) {
      if (armed) throw StateError('SDK: values');
      return box.values;
    });
    when(() => boundary.put(any<dynamic>(), any())).thenAnswer((call) =>
        box.put(call.positionalArguments[0],
            call.positionalArguments[1] as PresetPhrase));
    when(boundary.compact).thenAnswer((_) => box.compact());
    when(boundary.flush).thenAnswer((_) => box.flush());
    container.dispose();
    container = ProviderContainer(
        overrides: [presetPhraseBoxProvider.overrideWithValue(boundary)]);
    await open(tester);
    await tester.enterText(find.byType(TextField), '照合が壊れる本文');
    armed = true;
    await submit(tester);
    // 利用者には今までどおり穏当な文で、入力は残す（閉じ込めない）。
    expect(find.byType(PhraseAddDialog), findsOneWidget);
    expect(find.textContaining('保存を確認できません'), findsOneWidget);
    expect(find.widgetWithText(TextField, '照合が壊れる本文'), findsOneWidget);
    // そのうえでプログラムの誤りは端末内のログへ出す（送信はしない）。
    final reported = tester.takeException();
    expect(reported, isA<StateError>(), reason: '照合で投げたErrorが穏当な文に隠れたまま消えている');
    expect((reported as StateError).message, contains('SDK: values'));
    armed = false;
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
  testWidgets('元の定型文が消えた編集の下書きは残り、入口から読む・コピー・破棄できる', (tester) async {
    // keepを消しても一覧を空にしない（空だと既定の定型文の投入が走る）。
    final box = Hive.box<PresetPhrase>('presetPhrases');
    await tester.runAsync(() => box.put(
        'other',
        box
            .get('keep')!
            .copyWith(id: 'other', content: '残る定型文', displayOrder: 1)));
    final copied = <String>[];
    var copyFails = true;
    Completer<void>? copyGate;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'Clipboard.setData') return null;
      await copyGate?.future;
      if (copyFails) throw PlatformException(code: 'clipboard');
      copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester, form: 'edit:keep');
    await tester.enterText(find.byType(TextField), '消えた定型文の下書き');
    await tester.tap(find.widgetWithText(ChoiceChip, 'その他'));
    await tester.pump(const Duration(milliseconds: 400));
    // 開き直すと、保存済みと違う下書きだという告知が出る。
    await restart(tester, form: 'edit:keep');
    expect(find.textContaining('保存されていない下書き'), findsOneWidget);
    await tester.runAsync(() => container
        .read(presetPhraseNotifierProvider.notifier)
        .deletePhrase('keep'));
    await submit(tester);
    // missing を保存済みにも追加にも変えず、保存ボタンの無い閲覧へ移る。
    // 前の告知（フォームの入力についての文）は持ち込まない（F-9）。
    expect(find.textContaining('元の定型文が見つかりません'), findsOneWidget);
    expect(find.textContaining('保存されていない下書き'), findsNothing);
    expect(find.text('保存'), findsNothing);
    await restart(tester, form: 'drafts');
    final option = find.textContaining('消えた定型文の下書き');
    await tester.tap(option);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(find.text('消えた定型文の下書き'), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('その他')),
        findsOneWidget);
    // 「下書きを破棄」と「コピー」を隣り合わせない。間に「閉じる」（F-2）。
    final copyAt = tester.getCenter(find.text('コピー'));
    final closeAt = tester.getCenter(find.text('閉じる'));
    final discardAt = tester.getCenter(find.text('下書きを破棄'));
    bool between(double a, double b, double c) =>
        (a < b && b < c) || (c < b && b < a);
    expect(
        between(copyAt.dx, closeAt.dx, discardAt.dx) ||
            between(copyAt.dy, closeAt.dy, discardAt.dy),
        isTrue,
        reason: '「下書きを破棄」が「コピー」の隣にある');
    // コピーは成功するまで成功を告げず、失敗しても閉じない。
    await tester.tap(find.text('コピー'));
    await tester.pumpAndSettle();
    expect(find.textContaining('コピーできません'), findsOneWidget);
    expect(find.textContaining('コピーしました'), findsNothing);
    // コピーの待機中は破棄できない。失敗すれば唯一の本文を失う（F-3）。
    // 待っていることを告知の場所に出し（QA C-4）、前の結果はいったん消す。
    // 同じ失敗が続いても告知が出直す＝読み上げが届く（G-2）。
    copyGate = Completer<void>();
    await tester.tap(find.text('コピー'));
    await tester.pump();
    expect(find.textContaining('コピーしています'), findsOneWidget);
    expect(find.textContaining('コピーできません'), findsNothing);
    await tester.tap(find.text('下書きを破棄'), warnIfMissed: false);
    await tester.pump();
    expect(find.textContaining('戻せません'), findsNothing);
    expect(storedDrafts().keys, contains('edit:keep'));
    copyGate.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('コピーできません'), findsOneWidget);
    copyGate = null;
    copyFails = false;
    await tester.tap(find.text('コピー'));
    await tester.pumpAndSettle();
    expect(copied.single, contains('消えた定型文の下書き'));
    expect(find.textContaining('コピーしました'), findsOneWidget);
    // 「閉じる」は閉じるだけ。入口からもう一度開ける。
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    await tester.tap(find.text('下書き'));
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
    // 破棄は確認を挟む。取り消せば何も消さない（F-2）。
    await tester.tap(find.text('下書きを破棄'));
    await tester.pumpAndSettle();
    expect(find.textContaining('戻せません'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('消えた定型文の下書き'), findsOneWidget);
    expect(storedDrafts().keys, contains('edit:keep'));
    store.failClear = true;
    await discardOrphan(tester);
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
    expect(storedDrafts().keys, contains('edit:keep'));
    store.failClear = false;
    await discardOrphan(tester);
    expect(dialog, findsNothing);
    expect(storedDrafts().keys, isNot(contains('edit:keep')));
    // 元IDを復活させていない。
    expect((await reopened(tester)).keys, isNot(contains('keep')));
  });
  testWidgets('編集Aの破棄は追加・編集B・文字盤の下書きを巻き込まない', (tester) async {
    store.values['flutter.draft_text'] = '文字盤は別';
    store.values[draftKey] = jsonEncode({
      'add': {'id': 'add-1', 'content': '追加の下書き', 'category': 'health'},
      'edit:keep': {'id': 'keep', 'content': '編集Aの下書き', 'category': 'other'},
      'edit:gone': {'id': 'gone', 'content': '編集Bの下書き', 'category': 'daily'},
    });
    await open(tester, form: 'edit:keep');
    expect(find.widgetWithText(TextField, '編集Aの下書き'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await restart(tester, form: 'add');
    expect(find.widgetWithText(TextField, '追加の下書き'), findsOneWidget);
    expect(storedDrafts().keys, isNot(contains('edit:keep')));
    expect((storedDrafts()['edit:gone'] as Map)['content'], contains('編集B'));
    expect(store.values['flutter.draft_text'], contains('文字盤は別'));
  });
  testWidgets('一覧から元の定型文がある下書きを選ぶと、通常の編集フォームで開いて保存できる', (tester) async {
    // 元が残っているのに孤立と告げると、編集を続けられず破棄しか選べない
    // （最終レビュー I-1）。取り違えを赤にするため、別の定型文も置く。
    final box = Hive.box<PresetPhrase>('presetPhrases');
    await tester.runAsync(() => box.put(
        'other',
        box
            .get('keep')!
            .copyWith(id: 'other', content: '別の定型文', displayOrder: 1)));
    store.values[draftKey] = jsonEncode({
      'edit:keep': {'id': 'keep', 'content': '一覧から戻す下書き', 'category': 'health'}
    });
    await open(tester, form: 'drafts');
    await tester.tap(find.textContaining('一覧から戻す下書き'));
    await tester.pumpAndSettle();
    expect(find.text('定型文を編集'), findsOneWidget);
    expect(find.text('定型文の下書き'), findsNothing);
    expect(find.widgetWithText(TextField, '一覧から戻す下書き'), findsOneWidget);
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '体調'))
            .selected,
        isTrue);
    expect(find.textContaining('保存されていない下書き'), findsOneWidget);
    await submit(tester);
    expect(find.byType(TextField), findsNothing);
    expect(storedDrafts().keys, isNot(contains('edit:keep')));
    // 同じIDのまま本体を更新し、件数は変わらず、別の定型文には触れない。
    final saved = await reopened(tester);
    expect(saved.values, hasLength(2));
    expect(saved.get('keep')?.content, contains('一覧から戻す下書き'));
    expect(saved.get('keep')?.category, contains('health'));
    expect(saved.get('other')?.content, contains('別の定型文'));
  });
  testWidgets('入口は元の定型文を確認できなければ孤立で開かず、開けば全文を読めbackでは残す', (tester) async {
    tester.view.physicalSize = const Size(400, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // OS の文字拡大も掛ける。等倍では告知の隠れ方が数 px で、見張りが弱い。
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final box = Hive.box<PresetPhrase>('presetPhrases');
    final boundary = _ReadFailureBox();
    var armed = false;
    when(() => boundary.values).thenAnswer((_) {
      if (armed) throw StateError('SDK: values');
      return box.values;
    });
    container.dispose();
    container = ProviderContainer(
        overrides: [presetPhraseBoxProvider.overrideWithValue(boundary)]);
    final long = '${'消えた定型文の長い下書き'.padRight(498, 'あ')}末尾';
    store.values[draftKey] = jsonEncode({
      'edit:gone': {'id': 'gone', 'content': long, 'category': 'health'}
    });
    var copyFails = true;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method != 'Clipboard.setData') return null;
      if (copyFails) throw PlatformException(code: 'clipboard');
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final handle = tester.ensureSemantics();
    store.failRead = true;
    await open(tester, form: 'drafts');
    // 読めないことを「下書きが無い」にしない。閉じるまで残し、再押下で読み直す。
    expect(find.textContaining('読み込めませんでした'), findsOneWidget);
    expect(find.textContaining('ありません'), findsNothing);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    store.failRead = false;
    await tester.tap(find.text('下書き'));
    await tester.pumpAndSettle();
    armed = true;
    final option = find.textContaining('消えた定型文の長い下書き');
    await tester.tap(option);
    await tester.pumpAndSettle();
    // 確かめられないことを「元の定型文が無い」に変えない。Errorは報告する。
    expect(tester.takeException(), isA<StateError>());
    expect(find.textContaining('確認できませんでした'), findsOneWidget);
    expect(find.text(long), findsNothing);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    armed = false;
    await tester.tap(find.text('下書き'));
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();
    // 最初のフレームから孤立の表示。編集フォームの見出しを一瞬も出さない（F-11）。
    expect(find.text('定型文を編集'), findsNothing);
    expect(find.text('定型文の下書き'), findsOneWidget);
    await tester.pumpAndSettle();
    // 500字を4行の枠に押し込めず、スクロールで末尾まで読める（R4）。
    final text = find.text(long);
    final paragraph = tester.renderObject<RenderParagraph>(text);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
        paragraph.size.height,
        greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 1));
    final scroll = find.ancestor(of: text, matching: find.byType(Scrollable));
    Future<void> scrollTo(double dy) async {
      await tester.drag(scroll.first, Offset(0, dy));
      await tester.pumpAndSettle();
    }

    await scrollTo(-2000);
    expect(tester.getRect(text).bottom,
        lessThanOrEqualTo(tester.getRect(scroll.first).bottom));
    // 結果の告知は、本文の末尾にいても先頭にいても画面内に出て、読み上げにも
    // 届く（F-4）。閉じない操作なので、見えないと成否を区別できない。
    void expectNoticeVisible(String notice) {
      final found = find.textContaining(notice);
      expect(found, findsOneWidget);
      final rect = tester.getRect(found);
      final viewport = tester.getRect(scroll.first);
      expect(rect.top, greaterThanOrEqualTo(viewport.top), reason: notice);
      expect(rect.bottom, lessThanOrEqualTo(viewport.bottom), reason: notice);
      expect(tester.getSemantics(found), containsSemantics(isLiveRegion: true));
    }

    await tester.tap(find.text('コピー'));
    await tester.pumpAndSettle();
    expectNoticeVisible('コピーできません');
    await scrollTo(2000);
    copyFails = false;
    await tester.tap(find.text('コピー'));
    await tester.pumpAndSettle();
    expectNoticeVisible('コピーしました');
    store.failClear = true;
    await discardOrphan(tester);
    expectNoticeVisible('下書きを消せません');
    await scrollTo(-2000);
    // 同じ失敗が続いても、試すたびに告知をいったん消して出し直す（G-2）。
    store.clearGate = Completer<void>();
    await tester.tap(find.text('下書きを破棄'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄する'));
    await tester.pump();
    expect(find.textContaining('下書きを消せません'), findsNothing);
    store.clearGate!.complete();
    await tester.pumpAndSettle();
    expectNoticeVisible('下書きを消せません');
    store.failClear = false;
    // system back は閉じるだけで、下書きを消さない。
    final writes = store.writes;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(text, findsNothing);
    expect(storedDrafts().keys, contains('edit:gone'));
    expect(store.writes, writes);
    handle.dispose();
  });
  for (final failRead in [true, false]) {
    testWidgets('孤立で開いた下書きが読めない・無いときは、そう告げて閉じられる（読めない=$failRead）',
        (tester) async {
      store.failRead = failRead;
      final drafts = PhraseDrafts((key, succeeded) {});
      addTearDown(drafts.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    PhraseEditDialog(draftId: 'gone', drafts: drafts),
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      // 読めないことを「見つからない」にしない（F-10）。無いなら無いと言う（F-12）。
      expect(find.textContaining('読み込めませんでした'),
          failRead ? findsOneWidget : findsNothing);
      expect(find.textContaining('見つかりません'),
          failRead ? findsNothing : findsOneWidget);
      expect(find.text('コピー'), findsNothing);
      expect(find.text('下書きを破棄'), findsNothing);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.byType(PhraseEditDialog), findsNothing);
      expect(store.writes, 0);
    });
  }
  for (final unconfirmed in ['loading', 'mismatch']) {
    testWidgets('入口は一覧の読込中・stateと実boxの食い違いでも孤立で開かない（$unconfirmed）',
        (tester) async {
      store.values[draftKey] = jsonEncode({
        'edit:keep': {
          'id': 'keep',
          'content': '確かめられない下書き',
          'category': 'other'
        }
      });
      final saving = Completer<void>();
      if (unconfirmed == 'loading') {
        // 実boxが空に見え、既定の定型文の一括保存が終わらない＝一覧は読込中のまま。
        final boundary = _PendingSaveBox();
        registerFallbackValue(<dynamic, PresetPhrase>{});
        when(() => boundary.values).thenReturn(<PresetPhrase>[]);
        when(() => boundary.putAll(any())).thenAnswer((_) => saving.future);
        when(boundary.compact).thenAnswer((_) async {});
        when(boundary.flush).thenAnswer((_) async {});
        container.dispose();
        container = ProviderContainer(
            overrides: [presetPhraseBoxProvider.overrideWithValue(boundary)]);
      } else {
        // stateにはあり、実boxからは（notifierを通さず）消えている。
        container.read(presetPhraseNotifierProvider);
        await tester.runAsync(
            () => Hive.box<PresetPhrase>('presetPhrases').delete('keep'));
      }
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PresetPhraseScreen())));
      await tester.pump();
      await tester.tap(find.text('下書き'));
      await tester.pump(const Duration(seconds: 1));
      // 一覧はダイアログの中で読込の完了を受けて出る（1 フレーム後）。
      await tester.pump();
      await tester.tap(find.textContaining('確かめられない下書き'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('確認できませんでした'), findsOneWidget);
      expect(find.text('定型文の下書き'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(storedDrafts().keys, contains('edit:keep'));
      expect(store.writes, 0);
      saving.complete();
      await tester.pump(const Duration(seconds: 1));
    });
  }
  testWidgets('一覧を開いたまま画面が破棄されても（Webの戻る）、選んだ下書きを開いて保存できる', (tester) async {
    // L-186: 本番と同じく画面は ShellRoute の内側、一覧は root に積む。戻るで
    // 画面だけが破棄され、選んでも `!mounted` で何も開かなかった。
    store.values[draftKey] = jsonEncode({
      'edit:keep': {'id': 'keep', 'content': '戻った後の下書き', 'category': 'daily'}
    });
    final router = GoRouter(initialLocation: '/presets', routes: [
      ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const Text('ホーム')),
            GoRoute(
                path: '/presets',
                builder: (context, state) => const PresetPhraseScreen()),
          ]),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下書き'));
    await tester.pumpAndSettle();
    // Web の戻るは popRoute ではなく pushRouteInformation として届く（L-143）。
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
            const MethodCall('pushRouteInformation', {'location': '/'})),
        (_) {});
    await tester.pumpAndSettle();
    expect(find.text('ホーム'), findsOneWidget);
    expect(find.byType(PresetPhraseScreen), findsNothing);
    await tester.tap(find.textContaining('戻った後の下書き'));
    await tester.pumpAndSettle();
    expect(find.text('定型文を編集'), findsOneWidget, reason: '選んでも何も開かない');
    await tester.enterText(find.byType(TextField), '戻った後に保存した本文');
    await submit(tester);
    expect(find.byType(TextField), findsNothing);
    expect(storedDrafts().keys, isNot(contains('edit:keep')));
    expect((await reopened(tester)).get('keep')?.content, contains('戻った後に保存'));
  });
  testWidgets('「下書き」の読込待機中は一覧のダイアログが覆い、別のフォームを開けない', (tester) async {
    store.values[draftKey] = jsonEncode({
      'edit:keep': {'id': 'keep', 'content': '重ならない下書き', 'category': 'other'}
    });
    store.readGate = Completer<void>();
    await open(tester, form: 'drafts');
    // 先に一覧のダイアログを開き、その中で読み込む（G-1）。待機中の FAB・
    // 編集アイコン・「下書き」の再押下はモーダルのバリアに当たる。
    expect(find.textContaining('読み込んでいます'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
    await tester.tap(find.byIcon(Icons.edit).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(PhraseAddDialog), findsNothing);
    expect(find.text('定型文を編集'), findsNothing);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('読み込んでいます'), findsNothing);
    expect(find.textContaining('重ならない下書き'), findsOneWidget);
  });
  testWidgets('コピーの待機中は閉じられず、応答が無くても上限で失敗として閉じられる', (tester) async {
    // 閉じて開き直すと新しい画面は待機中を知らず、確認経由で破棄できてしまう
    // （Codex I-1 PARTIAL）。ただし閉じ込めない（G-8）。
    store.values[draftKey] = jsonEncode({
      'edit:gone': {'id': 'gone', 'content': '返事の無いコピー', 'category': 'daily'}
    });
    final copyGate = Completer<void>();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') await copyGate.future;
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      if (!copyGate.isCompleted) copyGate.complete();
    });
    await open(tester, form: 'drafts');
    await tester.tap(find.textContaining('返事の無いコピー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('コピー'));
    await tester.pump();
    TextButton close() =>
        tester.widget<TextButton>(find.widgetWithText(TextButton, '閉じる'));
    expect(close().onPressed, isNull, reason: '待機中に閉じられる');
    await tester.binding.handlePopRoute();
    // 閉じる動きが終わるまで進める（上限の5秒よりずっと短い）。
    await tester.pumpAndSettle();
    expect(find.text('定型文の下書き'), findsOneWidget, reason: 'backで閉じた');
    // 上限まで応答が無ければ失敗として告げ、「閉じる」を戻す。
    await tester.pump(PhraseEditDialog.copyTimeout);
    await tester.pump();
    expect(find.textContaining('コピーできません'), findsOneWidget);
    expect(close().onPressed, isNotNull, reason: '上限を過ぎても閉じられない');
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('定型文の下書き'), findsNothing);
    expect(storedDrafts().keys, contains('edit:gone'));
  });
  testWidgets('下書きの無い消去は、他のentryの400ms待ちのtimerを止めない', (tester) async {
    // F-6 の後半を独立に見る（Codex Minor）。pausedは起こさず、時間だけ進める。
    await open(tester, form: 'add');
    // 本文が空なので、戻る操作は下書きを消さずに閉じる。timerはまだ鳴っていない。
    await tester.tap(find.widgetWithText(ChoiceChip, '体調'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pump();
    await tester.pump();
    // 閉じかけの追加フォームも木に残っているので、編集フォームの側を押す。
    await tester.tap(find.descendant(
        of: find.byType(PhraseEditDialog), matching: find.text('キャンセル')));
    await tester.pump();
    expect(storedDrafts().keys, isNot(contains('add')), reason: '400ms前に書いた');
    await tester.pump(const Duration(milliseconds: 400));
    expect((storedDrafts()['add'] as Map?)?['category'], contains('health'),
        reason: '他のentryの消去で追加の下書きのtimerが止まった');
  });
  testWidgets('下書きの無い編集のキャンセルは、他のentryの書込失敗で「消せません」と言わない', (tester) async {
    await open(tester, observe: true, form: 'add');
    store.failWrite = true;
    await tester.enterText(find.byType(TextField), '書けない追加の本文');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.textContaining('下書きを消せません'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    // 下書きの無い編集フォームを開いて、何も打たずにキャンセルする。
    final writes = store.writes;
    store.targetEntry = 'edit:keep';
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    // 消すものが無いのだから書かず、事実と逆の告知で止めない（F-6）。
    expect(find.byType(TextField), findsNothing, reason: '消すものが無いのに閉じられない');
    expect(find.textContaining('下書きを消せません'), findsNothing);
    expect(store.writes, writes, reason: '消すものが無いのに書いている');
    // 追加の未書込は失われず、書けるようになれば次のpausedで書く。
    store.failWrite = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    for (var i = 0; i < 100 && store.writes == writes; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
    }
    expect((storedDrafts()['add'] as Map)['content'], contains('書けない追加の本文'));
  });
}
