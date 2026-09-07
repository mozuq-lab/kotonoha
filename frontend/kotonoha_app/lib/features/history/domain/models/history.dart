// モデル定義: 履歴エンティティ
// 実装内容: 読み上げ・表示したテキストの履歴を保持
// 設計根拠: , , , （履歴機能）

import 'history_type.dart';

/// クラス定義: 履歴エンティティ
/// 実装内容: 読み上げ・表示したテキストの履歴情報を保持
class History {
  /// フィールド定義: 一意識別子（UUID形式）
  final String id;

  /// フィールド定義: 読み上げ・表示したテキスト内容
  final String content;

  /// フィールド定義: 作成日時（読み上げ・表示した日時）
  final DateTime createdAt;

  /// フィールド定義: 履歴の種類
  final HistoryType type;

  /// コンストラクタ: 全フィールドを受け取る
  const History({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
  });

  /// ファクトリコンストラクタ: JSONからの変換
  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: HistoryType.values.byName(json['type'] as String),
    );
  }

  /// メソッド定義: JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'type': type.name,
    };
  }

  /// メソッド定義: copyWithパターンでイミュータブルな更新
  History copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    HistoryType? type,
  }) {
    return History(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is History &&
        other.id == id &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, createdAt, type);
  }
}
