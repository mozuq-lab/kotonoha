/// 定型文のお気に入りフラグを FavoriteItem へ移す一度きりの移行
/// （Phase 3 / WP-2 Stage 2、ADR-005「1概念1真実」）
///
/// 【なぜ要るか】: `PresetPhrase.isFavorite` は Hive の field 3 として
/// 永続化されている。Stage 3b でこのフィールドを削除すると、
/// ディスク上のそのフラグは以後読まれなくなる。危険なのは read ではなく
/// **write** で、フィールドを削除したビルドが一度でも定型文を保存すると、
/// そのレコードは field 3 が消えた形で再直列化される。
/// **したがってこの移行は、Stage 3b が配布されるより前に配布されていなければ
/// ならない。** 検証端末には実データがあり、利用者は発話で訂正できず、
/// データは端末内にしか無い。
///
/// 【冪等性】: 「移行済み」を示す marker・フラグ・box・設定キーは**足していない**。
/// それは永続化面の追加であり、AGENTS.md「負債を作る行為には理由が要る」に
/// 該当する。favorites box に `sourceId == phrase.id` の [FavoriteItem] が
/// あるかどうかだけで判定できるので、足さない。
///
/// 【NFR-301（基本機能継続）】: box が開いていなければ何もせず正常に返る。
/// 途中で例外が出ても外へ投げない。移行が失敗しても文字盤・TTS は使えること。
library;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:uuid/uuid.dart';

/// [FavoriteItem.sourceType] に入れる、定型文由来であることを示す値
///
/// `favorite_provider.dart` の `addFavoriteFromPresetPhrase` と同じ値。
const _presetPhraseSourceType = 'preset_phrase';

/// UUID 生成用インスタンス（`favorite_provider.dart` と同じ `uuid` パッケージ）
const _uuid = Uuid();

/// `isFavorite: true` の定型文を、対応する [FavoriteItem] として favorites box へ移す
///
/// `runApp()` の前、provider が1つも存在しない時点で呼ばれる。したがって
/// `favoriteRepositoryProvider` も [FavoriteNotifier] も使えず、
/// `Hive.isBoxOpen` / `Hive.box<T>()` で box を直接取る。box 名は
/// [PersistedAreaNames.boxName] から取り、文字列リテラルは書かない
/// （名前の出所を1つにするため）。
///
/// 元の `PresetPhrase.isFavorite` は**書き換えない**。この移行は
/// 「読めたものを移す」ものであって「消す」ものではない。
/// フラグを落とすのは Stage 3b（フィールドごと削除）の仕事である。
///
/// 生成される [FavoriteItem]:
/// - `sourceType`: `'preset_phrase'`、`sourceId`: 定型文の id
/// - `content`: 定型文の content
/// - `id`: 新しい UUID、`createdAt`: 実行時刻
/// - `displayOrder`: 既存 favorites の最大値の次から、
///   定型文の `displayOrder` 昇順で連番（利用者が定型文画面で見ている並びを保つ）
///
/// 移行対象がゼロ件のときは box へ1バイトも書かない。
Future<void> migratePresetPhraseFavorites() async {
  try {
    final presetBoxName = PersistedArea.presetPhrases.boxName;
    final favoriteBoxName = PersistedArea.favorites.boxName;

    // 【NFR-301】: どちらかでも開いていなければ、何もせず正常に返る。
    // Hive が使えない起動（破損・ディスクフル・権限）でも、
    // 移行が起動をブロックしてはいけない。
    if (!Hive.isBoxOpen(presetBoxName) || !Hive.isBoxOpen(favoriteBoxName)) {
      debugPrint(
        '[favorite_migration] box が開いていないため移行をスキップします '
        '(presetPhrases: ${Hive.isBoxOpen(presetBoxName)}, '
        'favorites: ${Hive.isBoxOpen(favoriteBoxName)})',
      );
      return;
    }

    final presetBox = Hive.box<PresetPhrase>(presetBoxName);
    final favoriteBox = Hive.box<FavoriteItem>(favoriteBoxName);

    // 【冪等性】: 既にお気に入りとして存在する出所を集める。
    // marker を持たない代わりに、これが「移行済みか」の唯一の判定材料になる。
    final migratedSourceIds =
        favoriteBox.values.map((f) => f.sourceId).whereType<String>().toSet();

    // 【移行対象】: お気に入りフラグが立っていて、まだ FavoriteItem が無いもの。
    // 並びは定型文の displayOrder 昇順（利用者が定型文画面で見ている順）。
    final pending = presetBox.values
        .where((p) => p.isFavorite && !migratedSourceIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // 【ゼロ件は無書き込み】: 起動のたびに box を触らない。
    if (pending.isEmpty) return;

    // 【採番】: 既存お気に入りの最大 displayOrder の次から連番。
    // 既存が空なら 0 から始まる。
    var nextDisplayOrder = favoriteBox.values.fold<int>(
          -1,
          (max, f) => f.displayOrder > max ? f.displayOrder : max,
        ) +
        1;

    final now = DateTime.now();
    final migrated = <String, FavoriteItem>{};
    for (final phrase in pending) {
      // 【キー】: FavoriteRepository.save と同じく id をキーにする。
      // キーが揃っていないと getById / delete が効かない。
      final id = _uuid.v4();
      migrated[id] = FavoriteItem(
        id: id,
        content: phrase.content,
        createdAt: now,
        displayOrder: nextDisplayOrder++,
        sourceType: _presetPhraseSourceType,
        sourceId: phrase.id,
      );
    }

    await favoriteBox.putAll(migrated);
    debugPrint('[favorite_migration] 定型文のお気に入り ${migrated.length} 件を移行しました');
  } catch (error, stackTrace) {
    // 【NFR-301】: 移行の失敗で起動を止めない。失敗はログに残して継続する。
    // 元の isFavorite は書き換えていないので、次回起動で再試行できる。
    debugPrint('[favorite_migration] 定型文お気に入りの移行に失敗しました: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
