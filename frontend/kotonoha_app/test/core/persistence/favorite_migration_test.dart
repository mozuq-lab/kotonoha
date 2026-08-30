// 定型文のお気に入りフラグ（PresetPhrase.isFavorite）を FavoriteItem へ移す
// 一度きりの移行のテスト（Phase 3 / WP-2 / Stage 2）
//
// 【なぜ testWidgets を使わないか】: testWidgets は本体を FakeAsync のスコープで
// 実行するため、時間は tester.pump() でしか進まない。一方 Hive の VM バックエンドは
// 実ファイル I/O を行い、その完了は OS スレッド経由で実イベントループへ届く。
// 互いに待ち合って原因を指す情報が一切出ないままハングする。
// この移行は runApp() の前に動く（provider も widget tree も無い）ので、
// 素の test() ＋ Hive.init(一時ディレクトリ) で、実 Hive の box を境界として検証する。
//
// 【box 名の大小文字】: Hive は box 名を小文字化してファイル名を作る
// （hive 2.2.3 hive_impl.dart の `name.toLowerCase()`）。
// ファイルパスを直接組み立てる箇所では小文字名（presetphrases.hive）を使う。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/favorite_migration.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('定型文お気に入りの FavoriteItem への移行', () {
    late Directory tempDir;

    final presetBoxName = PersistedArea.presetPhrases.boxName;
    final favoriteBoxName = PersistedArea.favorites.boxName;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('favorite_migration_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    /// 【テストヘルパー】: 現行のアダプタで PresetPhrase を presetPhrases box へ書く
    Future<Box<PresetPhrase>> openPresetBoxWith(
      List<PresetPhrase> phrases,
    ) async {
      final box = await Hive.openBox<PresetPhrase>(presetBoxName);
      for (final phrase in phrases) {
        await box.put(phrase.id, phrase);
      }
      return box;
    }

    /// 【テストヘルパー】: favorites box を開き、必要なら初期データを書く
    Future<Box<FavoriteItem>> openFavoriteBoxWith(
      List<FavoriteItem> items,
    ) async {
      final box = await Hive.openBox<FavoriteItem>(favoriteBoxName);
      for (final item in items) {
        await box.put(item.id, item);
      }
      return box;
    }

    PresetPhrase phrase({
      required String id,
      required String content,
      required bool isFavorite,
      int displayOrder = 0,
    }) {
      final now = DateTime(2026, 8, 30, 12);
      return PresetPhrase(
        id: id,
        content: content,
        category: 'daily',
        isFavorite: isFavorite,
        displayOrder: displayOrder,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('isFavorite:true の定型文が、出所つきの FavoriteItem として favorites box に現れる',
        () async {
      // 【テスト目的】: Stage 3b で PresetPhrase.isFavorite を消す前に、
      // 端末内にしか無いお気に入りが FavoriteItem 側へ移っていることを確認する。
      // 【検証の境界】: 戻り値ではなく favorites box を直接読む。

      // Given
      final presetBox = await openPresetBoxWith([
        phrase(id: 'preset-1', content: 'お茶がほしいです', isFavorite: true),
      ]);
      final favoriteBox = await openFavoriteBoxWith([]);

      // When
      await migratePresetPhraseFavorites();

      // Then
      final migrated =
          favoriteBox.values.where((f) => f.sourceId == 'preset-1').toList();
      expect(migrated, hasLength(1),
          reason: 'isFavorite:true の定型文1件に対して FavoriteItem が1件できる');
      expect(migrated.single.sourceType, 'preset_phrase',
          reason: '出所が定型文であることが記録される');
      expect(migrated.single.content, 'お茶がほしいです', reason: '利用者が見る文言が引き継がれる');
      expect(migrated.single.id, isNotEmpty,
          reason: 'FavoriteItem 自身の id が振られる');
      expect(migrated.single.id, isNot('preset-1'),
          reason: 'FavoriteItem の id は定型文の id とは別に振る（sourceId が出所）');

      // 【元データを書き換えないこと】: この移行は「読めたものを移す」もので、
      // 「消す」ものではない。isFavorite を落とすのは Stage 3b（フィールドごと削除）。
      // ここで書き戻すと、移行が途中で失敗したときに再試行できなくなる。
      expect(presetBox.get('preset-1')?.isFavorite, isTrue,
          reason: '移行は定型文側の isFavorite を書き換えない');
    });

    test('2回実行してもお気に入りは増えない（冪等）', () async {
      // 【テスト目的】: 移行済み marker を持たない設計なので、
      // sourceId の存在チェックだけで再実行に耐えることを確認する。

      // Given
      await openPresetBoxWith([
        phrase(id: 'preset-1', content: '痛みがあります', isFavorite: true),
        phrase(id: 'preset-2', content: 'ありがとう', isFavorite: true),
      ]);
      final favoriteBox = await openFavoriteBoxWith([]);

      // When
      await migratePresetPhraseFavorites();
      final countAfterFirst = favoriteBox.length;
      await migratePresetPhraseFavorites();

      // Then
      expect(countAfterFirst, 2, reason: '1回目で2件が移行される');
      expect(favoriteBox.length, countAfterFirst, reason: '2回目の実行で件数が増えない（冪等）');
      expect(
        favoriteBox.values.map((f) => f.sourceId).toSet(),
        {'preset-1', 'preset-2'},
        reason: '同じ定型文に対する FavoriteItem が重複しない',
      );
    });

    test('isFavorite:false の定型文は移行されない', () async {
      // 【テスト目的】: お気に入りにしていない定型文まで移すと、
      // 利用者のお気に入り一覧が身に覚えのない項目で埋まる。

      // Given
      await openPresetBoxWith([
        phrase(id: 'preset-on', content: '水をください', isFavorite: true),
        phrase(id: 'preset-off', content: 'テレビをつけて', isFavorite: false),
      ]);
      final favoriteBox = await openFavoriteBoxWith([]);

      // When
      await migratePresetPhraseFavorites();

      // Then
      expect(favoriteBox.values.map((f) => f.sourceId), contains('preset-on'),
          reason: 'お気に入りの定型文は移行される');
      expect(
        favoriteBox.values.map((f) => f.sourceId),
        isNot(contains('preset-off')),
        reason: 'お気に入りでない定型文は移行しない',
      );
    });

    test('同じ sourceId の FavoriteItem が既にあれば二重に作らない', () async {
      // 【テスト目的】: 既に定型文画面から登録済みのお気に入りを、
      // 移行が重複して積むことがないことを確認する。
      // 【工夫】: 未移行の定型文を1件混ぜてある。「何もしない」実装では
      // preset-2 が移行されず落ちるので、このテストは空振りしない。

      // Given
      await openPresetBoxWith([
        phrase(id: 'preset-1', content: '寒いです', isFavorite: true),
        phrase(id: 'preset-2', content: '暑いです', isFavorite: true),
      ]);
      final favoriteBox = await openFavoriteBoxWith([
        FavoriteItem(
          id: 'existing-favorite',
          content: '寒いです',
          createdAt: DateTime(2026, 8, 1),
          displayOrder: 0,
          sourceType: 'preset_phrase',
          sourceId: 'preset-1',
        ),
      ]);

      // When
      await migratePresetPhraseFavorites();

      // Then
      expect(
        favoriteBox.values.where((f) => f.sourceId == 'preset-1'),
        hasLength(1),
        reason: '同じ定型文に対する FavoriteItem は1件のまま',
      );
      expect(favoriteBox.get('existing-favorite'), isNotNull,
          reason: '既存のお気に入りを消したり置き換えたりしない');
      expect(
        favoriteBox.values.where((f) => f.sourceId == 'preset-2'),
        hasLength(1),
        reason: '既存分をスキップしても、未移行の定型文はきちんと移行される',
      );
    });

    test('box が開いていなければ、何もせず正常に返る', () async {
      // 【テスト目的】: NFR-301（基本機能継続）。Hive が使えない起動でも
      // 移行が例外を投げて起動を止めないこと。

      // Given: setUp 直後は box を1つも開いていない
      expect(Hive.isBoxOpen(presetBoxName), isFalse,
          reason: '前提: 定型文 box は未オープン');
      expect(Hive.isBoxOpen(favoriteBoxName), isFalse,
          reason: '前提: お気に入り box は未オープン');

      // When / Then: 例外を投げない
      await expectLater(migratePresetPhraseFavorites(), completes);
      expect(Hive.isBoxOpen(favoriteBoxName), isFalse,
          reason: '移行が勝手に box を開かない（開けるのは hive_init の役目）');
    });

    test('片方の box しか開いていなくても、何もせず正常に返る', () async {
      // 【テスト目的】: 復旧に失敗して片方だけ未オープンという状態は
      // openBoxWithRecovery が実際に作りうる。そこでも起動を止めない。

      // Given: 定型文 box だけ開く（お気に入り box は開かない）
      await openPresetBoxWith([
        phrase(id: 'preset-1', content: '助けてください', isFavorite: true),
      ]);

      // When / Then
      await expectLater(migratePresetPhraseFavorites(), completes);
      expect(Hive.isBoxOpen(favoriteBoxName), isFalse,
          reason: 'お気に入り box が開いていないので何も書けない');
    });

    test('displayOrder は既存の最大値の次から、定型文の displayOrder 昇順で振られる', () async {
      // 【テスト目的】: 利用者が定型文画面で見ている並びが、
      // お気に入り一覧でも保たれること。既存のお気に入りの後ろに積むこと。

      // Given: 既存お気に入りの最大 displayOrder は 5
      await openPresetBoxWith([
        phrase(
            id: 'preset-late',
            content: 'あとの文',
            isFavorite: true,
            displayOrder: 9),
        phrase(
            id: 'preset-early',
            content: 'さきの文',
            isFavorite: true,
            displayOrder: 2),
      ]);
      final favoriteBox = await openFavoriteBoxWith([
        FavoriteItem(
          id: 'existing',
          content: '既存のお気に入り',
          createdAt: DateTime(2026, 8, 1),
          displayOrder: 5,
        ),
      ]);

      // When
      await migratePresetPhraseFavorites();

      // Then
      final early =
          favoriteBox.values.firstWhere((f) => f.sourceId == 'preset-early');
      final late_ =
          favoriteBox.values.firstWhere((f) => f.sourceId == 'preset-late');
      expect(early.displayOrder, greaterThan(5), reason: '既存のお気に入りより後ろに積む');
      expect(early.displayOrder, lessThan(late_.displayOrder),
          reason: '定型文の displayOrder 昇順が保たれる');
    });

    test('移行対象がゼロ件なら favorites box のファイルに書き込まない', () async {
      // 【テスト目的】: 呼び出しごとに無駄な書き込みが起きると、
      // 起動のたびに box ファイルが成長する。
      // 【検証の境界】: box の API ではなく、実ファイルのバイト列を見る。

      // Given: お気に入りの定型文が無い
      await openPresetBoxWith([
        phrase(id: 'preset-off', content: 'まどを閉めて', isFavorite: false),
      ]);
      await openFavoriteBoxWith([]);
      final favoriteFile =
          File('${tempDir.path}/${favoriteBoxName.toLowerCase()}.hive');
      expect(favoriteFile.existsSync(), isTrue,
          reason: '前提: box を開いた時点でファイルができている');
      final before = await favoriteFile.readAsBytes();

      // When
      await migratePresetPhraseFavorites();

      // Then
      final after = await favoriteFile.readAsBytes();
      expect(after, equals(before), reason: '移行対象がゼロ件なら1バイトも書かない');
    });
  });
}
