import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';

/// Hive TypeAdapter for FavoriteItem
///
/// TASK-0065: お気に入りHiveモデル・リポジトリ実装
/// 手動実装: hive_generatorとriverpod_generatorのバージョン互換性問題を回避
///
/// typeId: 2
/// Fields:
/// - 0: id (String)
/// - 1: content (String)
/// - 2: createdAt (DateTime)
/// - 3: displayOrder (int)
///
/// 🔵 信頼性レベル: 青信号 - REQ-701、FR-065-001に基づく
class FavoriteItemAdapter extends TypeAdapter<FavoriteItem> {
  @override
  final int typeId = 2;

  @override
  FavoriteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteItem(
      id: fields[0] as String,
      content: fields[1] as String,
      createdAt: fields[2] as DateTime,
      displayOrder: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.displayOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
