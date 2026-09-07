// モデル定義: お気に入りエンティティ
// 実装内容: お気に入り登録したテキストを保持
// 設計根拠: , , , （お気に入り機能）

/// クラス定義: お気に入りエンティティ
/// 実装内容: お気に入り登録したテキスト情報を保持
class Favorite {
  /// フィールド定義: 一意識別子（UUID形式）
  final String id;

  /// フィールド定義: お気に入り登録したテキスト内容
  final String content;

  /// フィールド定義: 作成日時（お気に入り登録日時）
  final DateTime createdAt;

  /// フィールド定義: 並び順（ユーザーがカスタマイズ可能）
  final int displayOrder;

  /// フィールド定義: 元データの種類（'preset_phrase' | 'history' | null）
  final String? sourceType;

  /// フィールド定義: 元データのID（定型文IDまたは履歴ID）
  final String? sourceId;

  /// コンストラクタ: 全フィールドを受け取る
  const Favorite({
    required this.id,
    required this.content,
    required this.createdAt,
    this.displayOrder = 0,
    this.sourceType,
    this.sourceId,
  });

  /// メソッド定義: copyWithパターンでイミュータブルな更新
  Favorite copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    int? displayOrder,
    String? sourceType,
    String? sourceId,
  }) {
    return Favorite(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.id == id &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.displayOrder == displayOrder &&
        other.sourceType == sourceType &&
        other.sourceId == sourceId;
  }

  @override
  int get hashCode {
    return Object.hash(
        id, content, createdAt, displayOrder, sourceType, sourceId);
  }
}
