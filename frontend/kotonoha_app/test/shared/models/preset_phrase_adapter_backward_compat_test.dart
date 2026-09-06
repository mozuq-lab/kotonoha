/// PresetPhraseAdapter 後方互換テスト（旧7フィールド形式を読めること）
///
/// Phase 3 / WP-2 / Stage 3b: PresetPhrase.isFavorite（旧 field 3）を削除した。
///
/// このテストが守っているもの:
/// 旧アダプタは 0:id / 1:content / 2:category / **3:isFavorite(bool)** /
/// 4:displayOrder(int) / 5:createdAt / 6:updatedAt の7フィールドを書いていた。
/// isFavorite を消したあとも、**残るフィールドの番号（4,5,6）を詰め直してはいけない。**
/// 詰めると旧バイト列の `fields[3]`（bool）を displayOrder（int）として読むことになり
/// `TypeError` が出る。この例外は `openBoxWithRecovery`（lib/core/utils/hive_init.dart）
/// の `_isCorruptionError` が破損とみなさない型なので「環境起因」と判定され、
/// **box を開けないまま null を返す**——利用者から見ると定型文が全消えし、
/// アプリは無言でインメモリ動作を続ける。
///
/// 旧バイト列の作り方: 実 box の境界で確かめるため、旧形式（7フィールド）を書く
/// アダプタ `_LegacyPresetPhraseAdapter` を typeId 1 に登録して実際に Hive へ書き、
/// box を閉じてから `Hive.registerAdapter(..., override: true)` で現行アダプタへ
/// 差し替え、開き直して読む。`override` 引数は hive 2.2.3 の
/// `TypeRegistryImpl.registerAdapter`（lib/src/registry/type_registry_impl.dart:78-119）
/// に実在する。
///
/// testWidgets を使わない理由: 実 Hive のファイル I/O は FakeAsync と待ち合って
/// ハングするため、素の test() で書いている。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

/// テスト用フィクスチャ: Stage 3b 以前の PresetPhraseAdapter の write 側
///
/// 端末に既に書かれている「旧形式のバイト列」を再現するためだけのもの。
/// 現行実装のコピーではなく、**消えた過去の外部データ形式**を表している。
///
/// フィールド番号と型:
/// - 0: id (String)
/// - 1: content (String)
/// - 2: category (String)
/// - 3: isFavorite (bool)  ← Stage 3b で削除された
/// - 4: displayOrder (int)
/// - 5: createdAt (DateTime)
/// - 6: updatedAt (DateTime)
class _LegacyPresetPhraseAdapter extends TypeAdapter<PresetPhrase> {
  @override
  final int typeId = 1;

  @override
  PresetPhrase read(BinaryReader reader) {
    // 意図的に未実装: このアダプタは「旧バイト列を書く」ためだけに使う。
    // 読み出しは必ず現行アダプタで行うので、ここが呼ばれたらテストの前提が崩れている。
    throw UnimplementedError(
      '_LegacyPresetPhraseAdapter は書き込み専用のフィクスチャ',
    );
  }

  @override
  void write(BinaryWriter writer, PresetPhrase obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(true) // 旧 isFavorite。bool として書かれている
      ..writeByte(4)
      ..write(obj.displayOrder)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }
}

void main() {
  group('PresetPhraseAdapter 後方互換（旧7フィールド形式）', () {
    late Directory tempDir;
    const boxName = 'legacy_preset_phrases';

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_legacy_preset_');
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
      // Given: 旧形式（7フィールド、field 3 に bool）でディスクへ書く
      Hive.registerAdapter<PresetPhrase>(
        _LegacyPresetPhraseAdapter(),
        override: true,
      );
      var box = await Hive.openBox<PresetPhrase>(boxName);
      final legacyPhrase = PresetPhrase(
        id: 'legacy-001',
        content: 'お水をください',
        category: 'health',
        displayOrder: 42,
        createdAt: DateTime(2025, 11, 21, 10, 0),
        updatedAt: DateTime(2026, 1, 2, 3, 4),
      );
      await box.put(legacyPhrase.id, legacyPhrase);
      // ディスクへ確定: 閉じてから開き直すことで、確実にバイト列から読ませる
      await box.close();

      // When: 現行アダプタ（isFavorite を持たない）へ差し替えて開き直す
      Hive.registerAdapter<PresetPhrase>(
        PresetPhraseAdapter(),
        override: true,
      );
      box = await Hive.openBox<PresetPhrase>(boxName);
      final restored = box.get('legacy-001');

      // Then: 旧 isFavorite の後ろにあるフィールドが正しい値で読めること。
      // 番号を 4,5,6 → 3,4,5 と詰めると、ここで displayOrder が bool を受け取り
      // TypeError になる。
      expect(restored, isNotNull);
      expect(restored!.id, 'legacy-001');
      expect(restored.content, 'お水をください');
      expect(restored.category, 'health');
      expect(restored.displayOrder, 42);
      expect(restored.createdAt, DateTime(2025, 11, 21, 10, 0));
      expect(restored.updatedAt, DateTime(2026, 1, 2, 3, 4));

      await box.close();
    });

    test('旧形式で書いたレコードを現行アダプタで書き戻しても、読み直した値が変わらない', () async {
      // Given: 旧形式のレコードが1件ある
      Hive.registerAdapter<PresetPhrase>(
        _LegacyPresetPhraseAdapter(),
        override: true,
      );
      var box = await Hive.openBox<PresetPhrase>(boxName);
      await box.put(
        'legacy-002',
        PresetPhrase(
          id: 'legacy-002',
          content: 'ありがとう',
          category: 'daily',
          displayOrder: 7,
          createdAt: DateTime(2025, 12, 24, 9, 30),
          updatedAt: DateTime(2025, 12, 25, 20, 15),
        ),
      );
      await box.close();

      // When: 現行アダプタで開き、読み出した内容をそのまま書き戻して開き直す
      Hive.registerAdapter<PresetPhrase>(
        PresetPhraseAdapter(),
        override: true,
      );
      box = await Hive.openBox<PresetPhrase>(boxName);
      final firstRead = box.get('legacy-002')!;
      await box.put('legacy-002', firstRead);
      await box.close();

      box = await Hive.openBox<PresetPhrase>(boxName);
      final secondRead = box.get('legacy-002');

      // Then: 新形式で書き直しても値が保たれること（旧→新の移行が無損失であること）
      expect(secondRead, isNotNull);
      expect(secondRead!.content, 'ありがとう');
      expect(secondRead.category, 'daily');
      expect(secondRead.displayOrder, 7);
      expect(secondRead.createdAt, DateTime(2025, 12, 24, 9, 30));
      expect(secondRead.updatedAt, DateTime(2025, 12, 25, 20, 15));

      await box.close();
    });
  });
}
