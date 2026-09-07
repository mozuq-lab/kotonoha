import 'package:hive/hive.dart';

/// データモデル定義: 履歴アイテム
/// 実装内容: 文字盤入力・定型文・AI変換結果の履歴を保存するためのデータクラス
/// Hive設定: typeId 0 として登録、各フィールドに@HiveFieldアノテーション付与
@HiveType(typeId: 0)
class HistoryItem extends HiveObject {
  /// 一意識別子。
  @HiveField(0)
  final String id;

  /// 読み上げ・表示したテキスト内容。
  @HiveField(1)
  final String content;

  /// 作成日時（最古履歴の削除に使用）。
  @HiveField(2)
  final DateTime createdAt;

  /// 履歴の種類。
  @HiveField(3)
  final String type; // 'manualInput', 'preset', 'aiConverted', 'quickButton'

  // 欠番: field 4 は旧 isFavorite（Phase 3 / WP-2 / Stage 4 で削除）。
  // お気に入りの正は favoriteProvider だけ（ADR-005「1概念1真実」）。
  // 常に false しか書かれておらず UI も一度も読んでいなかったため、移行不要で削除した。
  // **番号は詰めない**（field 4 は最終フィールドなので後続への影響は無いが
  // writeByte の総数だけ 5→4 にする）。経緯は history_item_adapter.dart と
  // test/shared/models/history_item_adapter_backward_compat_test.dart を見ること。

  HistoryItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
  });

  /// 一部のフィールドを更新した新しい履歴を生成する。
  HistoryItem copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    String? type,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  /// idが同じであれば同じ履歴とみなす。
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HistoryItem(id: $id, content: $content, createdAt: $createdAt, type: $type)';
  }
}
