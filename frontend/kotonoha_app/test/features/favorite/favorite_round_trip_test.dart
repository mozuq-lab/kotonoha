/// お気に入りの往復テスト（Phase 3 / WP-3）
/// **UI → provider → repository → 実 Hive box → 再起動相当 → UI** を1本で通す。
/// 層を飛ばして下だけを叩くテストは単体では合格にしない（是正計画 §Phase 3-3）。
/// `isFavorite` のバグは Hive アダプタのテストが緑のまま生き残り
/// バグはその上の変換層にあった——それがこの形のテストを要求する理由である。
/// 本番の登録経路を使う: アダプタ登録はテストで書き写さず
/// `registerPersistedTypeAdapters` を呼ぶ（台帳 L-31。本番にだけ足された
/// 永続化面や、`ignoreTypeId` で差し替えられたアダプタを見逃さないため）。
/// モックは外部 SDK の境界だけ: TTS は `flutter_tts` の**プラットフォーム
/// チャンネル**で止める。`ttsProvider` を差し替えると自分の provider を patch する
/// ことになるので採らない。Hive・repository・notifier・ウィジェットは全て実物。
/// testWidgets と実 Hive: `testWidgets` の FakeAsync は実ファイル I/O の完了を
/// 待てない（実 I/O の完了は OS スレッド経由で実イベントループへ返る。経緯は
/// `docs/archive/verification-principles.md` §3）。実 I/O は `tester.runAsync` の
/// 中だけで行う。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  const seedContent = 'みずをください';
  const seedHistoryId = 'h-1';

  /// 外部 SDK の境界: flutter_tts のチャンネルを止める
  /// （`flutter_tts-4.2.5/lib/flutter_tts.dart:330` の `MethodChannel('flutter_tts')`）
  void silenceTtsPlatformChannel() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
  }

  setUp(() async {
    silenceTtsPlatformChannel();
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('favorite_round_trip_');
    Hive.init(tempDir.path);

    // 本番と同じ登録経路
    registerPersistedTypeAdapters();

    await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
    await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
    await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

    // Given をここに置く理由: 実 Hive の I/O は setUp（実 async ゾーン）で行う。
    // testWidgets の本体は FakeAsync なので、そこで実 I/O を await すると
    // **`--timeout` すら効かないまま無限にハングする**（タイムアウトも FakeAsync の
    // 時計で駆動されるため期限が来ない。2026-08-31 に実測して機序を確認した。
    // `docs/archive/verification-principles.md` §3）。
    await Hive.box<HistoryItem>(PersistedArea.history.boxName).put(
      seedHistoryId,
      HistoryItem(
        id: seedHistoryId,
        content: seedContent,
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

  testWidgets('履歴の星をタップすると実 box に残り、再起動相当でお気に入り画面に出る', (tester) async {
    // Given: 履歴が1件、実 box にある（seed は setUp）
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(seedContent), findsOneWidget,
        reason: '実 box の履歴が UI に出ていること（往復の出発点）');

    // When: 星をタップする（UI → provider → repository → 実 box）
    // runAsync の中でタップする理由: タップの handler は呼び出し元のゾーンで動く。
    // FakeAsync の中でタップすると、handler が始めた実 Hive の書き込みが
    // FakeAsync のタイマー待ちのまま完了せず、その後の box.close が
    // 書き込みロックを待って**デッドロックする**（2026-08-31 に実測）。
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.star_border).first);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Then: box を閉じて開き直しても（＝アプリ再起動相当）残っている
    late List<FavoriteItem> persisted;
    await tester.runAsync(() async {
      await Hive.box<FavoriteItem>(PersistedArea.favorites.boxName).close();
      final reopened =
          await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);
      persisted = reopened.values.toList();
    });

    expect(persisted.map((f) => f.content), contains(seedContent),
        reason: 'UI の操作が実 box に到達していること');
    expect(persisted.single.sourceType, 'history', reason: '出所が記録されていること');
    expect(persisted.single.sourceId, seedHistoryId);

    // And: 新しい ProviderScope（＝再起動相当）でお気に入り画面に出る
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FavoritesScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(seedContent), findsOneWidget,
        reason: '再起動後の UI が、保存された値から描かれていること');
  });
}
