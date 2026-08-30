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
/// - 4: **欠番**（旧 isFavorite (bool)。Phase 3 / WP-2 / Stage 4 で削除）
///
/// 常に false しか書かれておらず、UI も一度も読んでいなかったため移行不要で削除した。
/// **フィールド番号を詰めないこと。** field 4 は最終フィールドだったので後続フィールドへの
/// 影響は無いが、旧バイト列（端末に既にあるレコード）は自己記述的（フィールド番号を
/// キーにした map）に読むため、0〜3 の番号を変えなければ旧レコードも新レコードも
/// 同じコードで読める。`writeByte` の総数だけ 5→4 にする。
/// 根拠テスト: test/shared/models/history_item_adapter_backward_compat_test.dart
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
      // fields[4] は旧 isFavorite。読まずに捨てる（番号は詰めない）
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItem obj) {
    writer
      // 【フィールド数】: 旧形式は5。isFavorite を書かなくなったので4。
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
