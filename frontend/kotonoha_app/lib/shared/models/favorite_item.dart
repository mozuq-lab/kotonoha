import 'package:hive/hive.dart';

/// 【データモデル定義】: お気に入りアイテム
/// 【実装内容】: ユーザーが頻繁に使用する文章をお気に入りとして保存するためのデータクラス
/// 【Hive設定】: typeId 2 として登録、各フィールドに@HiveFieldアノテーション付与
/// 🔵 信頼性レベル: 青信号 - REQ-701、interfaces.dartのFavoriteエンティティに基づく
@HiveType(typeId: 2)
class FavoriteItem extends HiveObject {
  /// 【フィールド定義】: 一意識別子
  /// 【実装内容】: UUID形式の文字列ID（お気に入りの一意性を保証）
  /// 🔵 信頼性レベル: 青信号 - interfaces.dartに基づく
  @HiveField(0)
  final String id;

  /// 【フィールド定義】: お気に入り登録したテキスト内容
  /// 【実装内容】: 履歴または定型文から登録されたテキスト
  /// 🔵 信頼性レベル: 青信号 - REQ-701（お気に入り登録機能）に基づく
  @HiveField(1)
  final String content;

  /// 【フィールド定義】: お気に入り登録日時
  /// 【実装内容】: お気に入りが作成された日時
  /// 🔵 信頼性レベル: 青信号 - REQ-701に基づく
  @HiveField(2)
  final DateTime createdAt;

  /// 【フィールド定義】: 並び順（表示順序）
  /// 【実装内容】: ユーザーがカスタマイズ可能な表示順序
  /// 🔵 信頼性レベル: 青信号 - REQ-703（並び順変更機能）に基づく
  @HiveField(3)
  final int displayOrder;

  /// 【フィールド定義】: 元データの種類（'preset_phrase' | 'history' | null）
  /// 【実装内容】: お気に入りの由来を保持（定型文連動の永続化に使用）
  /// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件に基づく拡張
  @HiveField(4)
  final String? sourceType;

  /// 【フィールド定義】: 元データのID（定型文IDまたは履歴ID）
  /// 【実装内容】: 連動元のIDを保持（定型文連動の永続化に使用）
  /// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件に基づく拡張
  @HiveField(5)
  final String? sourceId;

  /// 【コンストラクタ】: FavoriteItem生成
  /// 【実装内容】: 全フィールドを初期化
  /// 🔵 信頼性レベル: 青信号 - テストケースTC-065-001〜TC-065-005の要件に基づく
  FavoriteItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.displayOrder,
    this.sourceType,
    this.sourceId,
  });

  /// 【copyWithメソッド】: 不変オブジェクトの部分更新
  /// 【実装内容】: 一部のフィールドのみ変更した新しいFavoriteItemを生成
  /// 【テスト対応】: TC-065-002（copyWithテスト）で使用
  /// 🔵 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
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

  /// 【等価性比較】: オブジェクトの等価性を判定
  /// 【実装内容】: idが同じであれば同じFavoriteItemとみなす
  /// 【テスト対応】: TC-065-003の等価性比較テストで使用
  /// 🔵 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// 【ハッシュコード】: 等価性比較のためのハッシュ値
  /// 【実装内容】: idのハッシュ値を返す
  /// 【テスト対応】: TC-065-004のhashCodeテストで使用
  /// 🔵 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  @override
  int get hashCode => id.hashCode;

  /// 【文字列表現】: デバッグ用文字列表現
  /// 【実装内容】: 全フィールドの値を含む文字列を返す
  /// 【テスト対応】: TC-065-005のtoStringテストで使用
  /// 🔵 信頼性レベル: 青信号 - デバッグ・ログ出力のため
  @override
  String toString() {
    return 'FavoriteItem(id: $id, content: $content, createdAt: $createdAt, displayOrder: $displayOrder, sourceType: $sourceType, sourceId: $sourceId)';
  }
}
