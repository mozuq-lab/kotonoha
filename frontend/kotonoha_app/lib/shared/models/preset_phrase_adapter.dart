import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// Hive TypeAdapter for PresetPhrase
///
/// TASK-0054: Hive データベース初期化
/// 手動実装: hive_generatorとriverpod_generatorのバージョン互換性問題を回避
///
/// typeId: 1
/// Fields:
/// - 0: id (String)
/// - 1: content (String)
/// - 2: category (String)
/// - 3: **欠番**（旧 isFavorite (bool)。Phase 3 / WP-2 / Stage 3b で削除）
/// - 4: displayOrder (int)
/// - 5: createdAt (DateTime)
/// - 6: updatedAt (DateTime)
///
/// 【フィールド番号を詰めないこと】: 端末には field 3 に bool を持つ旧バイト列が
/// 既に書かれている。4,5,6 を 3,4,5 に詰めると、旧レコードで displayOrder が
/// bool を受け取って TypeError になる。この例外は
/// `openBoxWithRecovery`（lib/core/utils/hive_init.dart）の `_isCorruptionError`
/// が破損とみなさない型なので「環境起因」と判定され、box を開けないまま null を
/// 返す——**利用者から見ると定型文が全消えし、アプリは無言でインメモリ動作を続ける。**
///
/// read 側はフィールド番号をキーにした map なので、消したフィールドの値も
/// `reader.read()` が自己記述的にバイト数分だけ読み飛ばす。番号を保つ限り
/// 旧レコードも新レコードも同じコードで読める。
/// 根拠テスト: test/shared/models/preset_phrase_adapter_backward_compat_test.dart
///
/// 🔵 信頼性レベル: 青信号 - REQ-104、REQ-5003に基づく
class PresetPhraseAdapter extends TypeAdapter<PresetPhrase> {
  @override
  final int typeId = 1;

  @override
  PresetPhrase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PresetPhrase(
      id: fields[0] as String,
      content: fields[1] as String,
      category: fields[2] as String,
      // fields[3] は旧 isFavorite。読まずに捨てる（番号は詰めない）
      displayOrder: fields[4] as int,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PresetPhrase obj) {
    writer
      // 【フィールド数】: 旧形式は7。isFavorite を書かなくなったので6。
      // 番号（4,5,6）はそのまま。総数だけが減る。
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.displayOrder)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetPhraseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
