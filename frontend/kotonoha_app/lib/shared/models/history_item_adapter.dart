import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';

/// Hive TypeAdapter for HistoryItem
///
/// TASK-0054: Hive データベース初期化
/// 手動実装: hive_generatorとriverpod_generatorのバージョン互換性問題を回避
///
/// typeId: 0
/// Fields:
/// - 0: id (String)
/// - 1: content (String)
/// - 2: createdAt (DateTime)
/// - 3: type (String)
/// - 4: isFavorite (bool)
///
/// 🔵 信頼性レベル: 青信号 - REQ-601、REQ-5003に基づく
class HistoryItemAdapter extends TypeAdapter<HistoryItem> {
  @override
  final int typeId = 0;

  @override
  HistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryItem(
      id: fields[0] as String,
      content: fields[1] as String,
      createdAt: fields[2] as DateTime,
      type: fields[3] as String,
      isFavorite: fields[4] as bool? ?? false,
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
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
