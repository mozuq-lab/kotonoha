// 【モデル定義】: お気に入りエンティティ
// 【実装内容】: お気に入り登録したテキストを保持
// 【設計根拠】: REQ-701, REQ-702, REQ-703, REQ-704（お気に入り機能）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

/// 【クラス定義】: お気に入りエンティティ
/// 【実装内容】: お気に入り登録したテキスト情報を保持
/// 🔵 信頼性レベル: 青信号 - interfaces.dart の Favorite に基づく
class Favorite {
  /// 【フィールド定義】: 一意識別子（UUID形式）
  /// 🔵 信頼性レベル: 青信号 - interfaces.dart
  final String id;

  /// 【フィールド定義】: お気に入り登録したテキスト内容
  /// 🔵 信頼性レベル: 青信号 - REQ-701
  final String content;

  /// 【フィールド定義】: 作成日時（お気に入り登録日時）
  /// 🔵 信頼性レベル: 青信号 - interfaces.dart
  final DateTime createdAt;

  /// 【フィールド定義】: 並び順（ユーザーがカスタマイズ可能）
  /// 🔵 信頼性レベル: 青信号 - REQ-704（お気に入りの並び替え）
  final int displayOrder;

  /// 【コンストラクタ】: 全フィールドを受け取る
  const Favorite({
    required this.id,
    required this.content,
    required this.createdAt,
    this.displayOrder = 0,
  });

  /// 【ファクトリコンストラクタ】: JSONからの変換
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  /// 【メソッド定義】: JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'display_order': displayOrder,
    };
  }

  /// 【メソッド定義】: copyWithパターンでイミュータブルな更新
  Favorite copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    int? displayOrder,
  }) {
    return Favorite(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.id == id &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, createdAt, displayOrder);
  }
}
