import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 定型文の手書きHive adapter（typeId 1）。
/// field 3 は旧 isFavorite の欠番として保持する。4〜6を詰めると、旧レコードの
/// boolをdisplayOrderとして読んでTypeErrorになり、保存済み定型文を開けなくなる。
/// field番号をキーにして読むことで、旧フィールドを含むレコードも復元できる。
/// 互換性はtest/shared/models/preset_phrase_adapter_backward_compat_test.dartで確認する。
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
      // フィールド数: 旧形式は7。isFavorite を書かなくなったので6。
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
