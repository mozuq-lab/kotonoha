import 'package:hive/hive.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';

/// 履歴の手書きHive adapter（typeId 0）。
/// field 4 は旧 isFavorite の欠番として保持し、0〜3を詰め直さない。
/// 旧レコードはfield番号をキーにして読むため、新旧どちらも同じコードで復元できる。
/// 互換性はtest/shared/models/history_item_adapter_backward_compat_test.dartで確認する。
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
      // fields[4] は旧 isFavorite。読まずに捨てる（番号は詰めない）
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer
      // フィールド数: 旧形式は5。isFavorite を書かなくなったので4。
      // 番号（0,1,2,3）はそのまま。総数だけが減る。
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.type);
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
