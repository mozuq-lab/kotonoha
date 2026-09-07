import 'package:hive/hive.dart';

/// データモデル定義: 定型文
/// 実装内容: ユーザーが登録・管理する定型文を保存するためのデータクラス
/// Hive設定: typeId 1 として登録、各フィールドに@HiveFieldアノテーション付与
@HiveType(typeId: 1)
class PresetPhrase extends HiveObject {
  /// 一意識別子。
  @HiveField(0)
  final String id;

  /// 定型文の内容。
  @HiveField(1)
  final String content;

  /// カテゴリ。
  @HiveField(2)
  final String category; // 'daily', 'health', 'other'

  // 欠番: field 3 は旧 isFavorite（Phase 3 / WP-2 / Stage 3b で削除）。
  // お気に入りの正は favoriteProvider だけ（ADR-005「1概念1真実」）。
  // **後続フィールドの番号は詰めない。** 詰めると、端末に既にある旧バイト列で
  // fields[3]（bool）を displayOrder（int）として読むことになり TypeError が出る。
  // 経緯は preset_phrase_adapter.dart と
  // test/shared/models/preset_phrase_adapter_backward_compat_test.dart を見ること。

  /// ユーザーが設定できる表示順序。
  @HiveField(4)
  final int displayOrder;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  PresetPhrase({
    required this.id,
    required this.content,
    required this.category,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 一部のフィールドを更新した新しい定型文を生成する。
  PresetPhrase copyWith({
    String? id,
    String? content,
    String? category,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PresetPhrase(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// idが同じであれば同じ定型文とみなす。
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetPhrase &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PresetPhrase(id: $id, content: $content, category: $category, displayOrder: $displayOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
