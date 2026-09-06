/// HistoryItemAdapter 後方互換テスト（旧5フィールド形式を読めること）
///
/// Phase 3 / WP-2 / Stage 4: HistoryItem.isFavorite（旧 field 4）を削除した。
///
/// このテストが守っているもの:
/// 旧アダプタは 0:id / 1:content / 2:createdAt / 3:type / **4:isFavorite(bool)** の
/// 5フィールドを書いていた。isFavorite を消したあとも、**残るフィールドの番号
/// （0,1,2,3）を詰め直してはいけない。** isFavorite は最終フィールドなので後続の
/// 番号を持つフィールドは無いが、`writeByte` の総数（フィールド数）だけは
/// 5→4 に変える。旧バイト列は自己記述的（フィールド番号をキーにした map）なので、
/// 新アダプタは fields[4] を読まないだけで、0〜3 はそのまま同じコードで読める。
///
/// 旧バイト列の作り方: 実 box の境界で確かめるため、旧形式（5フィールド）を書く
/// アダプタ `_LegacyHistoryItemAdapter` を typeId 0 に登録して実際に Hive へ書き、
/// box を閉じてから `Hive.registerAdapter(..., override: true)` で現行アダプタへ
/// 差し替え、開き直して読む。手本は
/// test/shared/models/preset_phrase_adapter_backward_compat_test.dart（Stage 3b）。
///
/// testWidgets を使わない理由: 実 Hive のファイル I/O は FakeAsync と待ち合って
/// ハングするため、素の test() で書いている。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';

/// テスト用フィクスチャ: Stage 4 以前の HistoryItemAdapter の write 側
///
/// 端末に既に書かれている「旧形式のバイト列」を再現するためだけのもの。
/// 現行実装のコピーではなく、**消えた過去の外部データ形式**を表している。
///
/// フィールド番号と型:
/// - 0: id (String)
/// - 1: content (String)
/// - 2: createdAt (DateTime)
/// - 3: type (String)
/// - 4: isFavorite (bool)  ← Stage 4 で削除された
class _LegacyHistoryItemAdapter extends TypeAdapter<HistoryItem> {
  @override
  final int typeId = 0;

  @override
  HistoryItem read(BinaryReader reader) {
    // 意図的に未実装: このアダプタは「旧バイト列を書く」ためだけに使う。
    // 読み出しは必ず現行アダプタで行うので、ここが呼ばれたらテストの前提が崩れている。
    throw UnimplementedError(
      '_LegacyHistoryItemAdapter は書き込み専用のフィクスチャ',
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(true); // 旧 isFavorite。bool として書かれている
  }
}

void main() {
  group('HistoryItemAdapter 後方互換（旧5フィールド形式）', () {
    late Directory tempDir;
    const boxName = 'legacy_history_items';

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_legacy_history_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('旧アダプタが書いたレコードを現行アダプタで開き直しても値がずれない', () async {
      // Given: 旧形式（5フィールド、field 4 に bool）でディスクへ書く
      Hive.registerAdapter<HistoryItem>(
        _LegacyHistoryItemAdapter(),
        override: true,
      );
      var box = await Hive.openBox<HistoryItem>(boxName);
      final legacyItem = HistoryItem(
        id: 'legacy-001',
        content: 'お水をください',
        createdAt: DateTime(2025, 11, 21, 10, 0),
        type: 'manualInput',
      );
      await box.put(legacyItem.id, legacyItem);
      // ディスクへ確定: 閉じてから開き直すことで、確実にバイト列から読ませる
      await box.close();

      // When: 現行アダプタ（isFavorite を持たない）へ差し替えて開き直す
      Hive.registerAdapter<HistoryItem>(
        HistoryItemAdapter(),
        override: true,
      );
      box = await Hive.openBox<HistoryItem>(boxName);
      final restored = box.get('legacy-001');

      // Then: 旧 isFavorite より前にあるフィールドが正しい値で読めること。
      expect(restored, isNotNull);
      expect(restored!.id, 'legacy-001');
      expect(restored.content, 'お水をください');
      expect(restored.createdAt, DateTime(2025, 11, 21, 10, 0));
      expect(restored.type, 'manualInput');

      await box.close();
    });

    test('旧形式で書いたレコードを現行アダプタで書き戻しても、読み直した値が変わらない', () async {
      // Given: 旧形式のレコードが1件ある
      Hive.registerAdapter<HistoryItem>(
        _LegacyHistoryItemAdapter(),
        override: true,
      );
      var box = await Hive.openBox<HistoryItem>(boxName);
      await box.put(
        'legacy-002',
        HistoryItem(
          id: 'legacy-002',
          content: 'ありがとう',
          createdAt: DateTime(2025, 12, 24, 9, 30),
          type: 'preset',
        ),
      );
      await box.close();

      // When: 現行アダプタで開き、読み出した内容をそのまま書き戻して開き直す
      Hive.registerAdapter<HistoryItem>(
        HistoryItemAdapter(),
        override: true,
      );
      box = await Hive.openBox<HistoryItem>(boxName);
      final firstRead = box.get('legacy-002')!;
      await box.put('legacy-002', firstRead);
      await box.close();

      box = await Hive.openBox<HistoryItem>(boxName);
      final secondRead = box.get('legacy-002');

      // Then: 新形式で書き直しても値が保たれること（旧→新の移行が無損失であること）
      expect(secondRead, isNotNull);
      expect(secondRead!.content, 'ありがとう');
      expect(secondRead.createdAt, DateTime(2025, 12, 24, 9, 30));
      expect(secondRead.type, 'preset');

      await box.close();
    });
  });
}
