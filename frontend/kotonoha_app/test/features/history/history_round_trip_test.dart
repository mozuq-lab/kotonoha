/// 履歴の往復テスト（Phase 3 / WP-3）
///
/// **UI → provider → repository → 実 Hive box → 再起動相当 → UI** を1本で通す。
/// 層を飛ばして下だけを叩くテストは単体では合格にしない（是正計画 §Phase 3-3）。
///
/// 削除を選んだ理由: B-2「操作の取り消し」「データ喪失」に直結する。
/// 発話で訂正できない利用者にとって、消したつもりが残る／残したつもりが消えるは
/// どちらも重い。
///
/// 本番の登録経路を使う: `registerPersistedTypeAdapters()`（台帳 L-31）。
///
/// 実 Hive × testWidgets の制約（2026-08-31 に実測）:
/// - 実 I/O を `testWidgets` 本体で await すると**`--timeout` も効かずハングする**
///   → seed は `setUp`（実 async ゾーン）で行う
/// - UI 操作が始めた実 I/O も FakeAsync では完了しない
///   → タップは `tester.runAsync()` の中で行う
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const keptContent = 'ありがとう';
  const deletedContent = 'みずをください';

  setUp(() async {
    // 外部 SDK の境界: flutter_tts のチャンネルだけを止める。
    // ttsProvider を差し替えると自分の provider を patch することになるので採らない。
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );

    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('history_round_trip_');
    Hive.init(tempDir.path);
    registerPersistedTypeAdapters();
    await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
    await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
    await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

    final box = Hive.box<HistoryItem>(PersistedArea.history.boxName);
    await box.put(
      'h-old',
      HistoryItem(
        id: 'h-old',
        content: deletedContent,
        createdAt: DateTime(2026, 8, 31, 9),
        type: 'manualInput',
      ),
    );
    await box.put(
      'h-new',
      HistoryItem(
        id: 'h-new',
        content: keptContent,
        createdAt: DateTime(2026, 8, 31, 10),
        type: 'manualInput',
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

  testWidgets('履歴を削除すると実 box からも消え、再起動相当でも戻らない', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HistoryScreen())),
    );
    await tester.pump();

    expect(find.text(deletedContent), findsOneWidget);
    expect(find.text(keptContent), findsOneWidget);

    // When: 消したい方の削除ボタンを押す
    final deleteButtons = find.byIcon(Icons.delete);
    expect(deleteButtons, findsNWidgets(2), reason: '2件とも削除できること');

    // どちらを消すか: 対象のカードの中の削除ボタンに限定する。
    // 一覧の並び順に依存すると、並び替えの変更でテストの意味が変わる。
    final targetDelete = find.descendant(
      of: find.ancestor(
        of: find.text(deletedContent),
        matching: find.byType(Card),
      ),
      matching: find.byIcon(Icons.delete),
    );
    expect(targetDelete, findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(targetDelete);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Then: box を閉じて開き直しても（＝再起動相当）消えたまま
    late List<String> persisted;
    await tester.runAsync(() async {
      await Hive.box<HistoryItem>(PersistedArea.history.boxName).close();
      final reopened =
          await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
      persisted = reopened.values.map((h) => h.content).toList();
    });

    expect(persisted, isNot(contains(deletedContent)),
        reason: 'UI の削除が実 box に到達していること');
    expect(persisted, contains(keptContent), reason: '消していない履歴まで巻き添えにしていないこと');

    // And: 新しい ProviderScope（＝再起動相当）でも戻らない
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HistoryScreen())),
    );
    await tester.pump();

    expect(find.text(deletedContent), findsNothing,
        reason: '再起動後の UI が、保存された内容から描かれていること');
    expect(find.text(keptContent), findsOneWidget);
  });
}
