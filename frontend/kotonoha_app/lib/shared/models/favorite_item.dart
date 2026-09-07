import 'package:hive/hive.dart';

/// データモデル定義: お気に入りアイテム
/// 実装内容: ユーザーが頻繁に使用する文章をお気に入りとして保存するためのデータクラス
/// Hive設定: typeId 2 として登録、各フィールドに@HiveFieldアノテーション付与
@HiveType(typeId: 2)
class FavoriteItem extends HiveObject {
  /// 一意識別子。
  @HiveField(0)
  final String id;

  /// お気に入り登録したテキスト内容。
  @HiveField(1)
  final String content;

  /// お気に入り登録日時。
  @HiveField(2)
  final DateTime createdAt;

  /// ユーザーが設定できる表示順序。
  @HiveField(3)
  final int displayOrder;

  /// 元データの種類。定型文連動に使用する。
  @HiveField(4)
  final String? sourceType;

  /// 元データのID。定型文連動に使用する。
  @HiveField(5)
  final String? sourceId;

  FavoriteItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.displayOrder,
    this.sourceType,
    this.sourceId,
  });

  /// 一部のフィールドを更新した新しいお気に入りを生成する。
  FavoriteItem copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    int? displayOrder,
    String? sourceType,
    String? sourceId,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  /// idが同じであれば同じお気に入りとみなす。
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FavoriteItem(id: $id, content: $content, createdAt: $createdAt, displayOrder: $displayOrder, sourceType: $sourceType, sourceId: $sourceId)';
  }
}
