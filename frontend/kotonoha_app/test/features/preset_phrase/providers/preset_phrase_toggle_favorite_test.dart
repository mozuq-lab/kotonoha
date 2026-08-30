/// toggleFavorite が定型文レコードを書き換えないことのテスト
///
/// Phase 3 / WP-2 / Stage 3b: お気に入りの正は favoriteProvider だけになった
/// （ADR-005「1概念1真実」）。定型文（PresetPhrase）は自分がお気に入りかを
/// 知らなくなったので、**お気に入りの切り替えで定型文レコードは変わらない。**
///
/// 【なぜ実 box で確かめるか】: 「定型文を書き換えない」は、状態オブジェクトの
/// 中身ではなくディスクに残った行で見ないと確かめたことにならない。box を
/// 閉じて開き直し、バイト列から読んだ値を検証する。
///
/// 【testWidgets を使わない理由】: 実 Hive のファイル I/O は FakeAsync と待ち合って
/// ハングするため、素の test() で書いている。
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('toggleFavorite - 定型文レコードは書き換わらない', () {
    late Directory tempDir;

    /// 【固定値】: DateTime.now() に依存させないため、時刻は定数で置く。
    /// 「更新日時が変わらない」を now() 同士の比較で見ると、
    /// 実行が速いときに偶然一致して通ってしまう。
    final createdAt = DateTime(2026, 1, 1, 9, 0);
    final updatedAt = DateTime(2026, 1, 1, 9, 0);

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_toggle_fav_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      final presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      await Hive.openBox<FavoriteItem>('favorites');

      // 【前提データ】: 固定の日時を持つ定型文を1件、直接 box に置く
      await presetBox.put(
        'phrase-001',
        PresetPhrase(
          id: 'phrase-001',
          content: 'お水をください',
          category: 'health',
          displayOrder: 3,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk('presetPhrases');
      await Hive.deleteBoxFromDisk('favorites');
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('お気に入りにしても、ディスク上の定型文レコードは変わらない', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When: お気に入りに切り替える
      await container
          .read(presetPhraseNotifierProvider.notifier)
          .toggleFavorite('phrase-001');

      // 【再読み込み】: box を閉じて開き直し、ディスクのバイト列から読む
      await Hive.box<PresetPhrase>('presetPhrases').close();
      final reopened = await Hive.openBox<PresetPhrase>('presetPhrases');
      final stored = reopened.get('phrase-001');

      // Then: 定型文レコードは1文字も変わっていない
      expect(stored, isNotNull);
      expect(stored!.content, 'お水をください');
      expect(stored.category, 'health');
      expect(stored.displayOrder, 3);
      expect(stored.createdAt, createdAt);
      expect(
        stored.updatedAt,
        updatedAt,
        reason: 'お気に入りの切り替えは定型文の更新ではないので updatedAt は動かない',
      );
    });

    test('お気に入りの切り替えは favorites box にだけ現れ、解除で消える', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(presetPhraseNotifierProvider.notifier);
      final favoriteBox = Hive.box<FavoriteItem>('favorites');

      expect(favoriteBox.values, isEmpty);

      // When: お気に入りにする
      await notifier.toggleFavorite('phrase-001');

      // Then: favorites box に定型文由来の1件が現れる
      expect(favoriteBox.values.length, 1);
      final saved = favoriteBox.values.first;
      expect(saved.content, 'お水をください');
      expect(saved.sourceType, 'preset_phrase');
      expect(saved.sourceId, 'phrase-001');

      // When: もう一度切り替えて解除する
      await notifier.toggleFavorite('phrase-001');

      // Then: favorites box から消える
      expect(favoriteBox.values, isEmpty);
    });
  });
}
