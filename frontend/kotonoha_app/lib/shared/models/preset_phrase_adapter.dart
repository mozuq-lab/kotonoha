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
/// - 3: isFavorite (bool)
/// - 4: displayOrder (int)
/// - 5: createdAt (DateTime)
/// - 6: updatedAt (DateTime)
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
      isFavorite: fields[3] as bool? ?? false,
      displayOrder: fields[4] as int,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
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
      ..write(obj.isFavorite)
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
