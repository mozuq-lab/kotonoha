import 'package:hive/hive.dart';

/// データモデル定義: 履歴アイテム
/// 実装内容: 文字盤入力・定型文・AI変換結果の履歴を保存するためのデータクラス
/// Hive設定: typeId 0 として登録、各フィールドに@HiveFieldアノテーション付与
/// 信頼性レベル: 青信号 - REQ-601、interfaces.dartのHistoryエンティティに基づく
@HiveType(typeId: 0)
class HistoryItem extends HiveObject {
  /// フィールド定義: 一意識別子
  /// 実装内容: UUID形式の文字列ID（履歴の一意性を保証）
  /// 信頼性レベル: 青信号 - interfaces.dartに基づく
  @HiveField(0)
  final String id;

  /// フィールド定義: 読み上げ・表示したテキスト内容
  /// 実装内容: ユーザーが文字盤で入力したテキスト、または定型文・AI変換結果のテキスト
  /// 信頼性レベル: 青信号 - REQ-601に基づく
  @HiveField(1)
  final String content;

  /// フィールド定義: 作成日時（読み上げ・表示した日時）
  /// 実装内容: 履歴が作成された日時（最古履歴の削除に使用）
  /// 信頼性レベル: 青信号 - REQ-602（50件上限管理）に基づく
  @HiveField(2)
  final DateTime createdAt;

  /// フィールド定義: 履歴の種類
  /// 実装内容: 文字盤入力、定型文、AI変換結果等を区別
  /// 信頼性レベル: 青信号 - dataflow.mdの履歴管理フローに基づく
  @HiveField(3)
  final String type; // 'manualInput', 'preset', 'aiConverted', 'quickButton'

  // 欠番: field 4 は旧 isFavorite（Phase 3 / WP-2 / Stage 4 で削除）。
  // お気に入りの正は favoriteProvider だけ（ADR-005「1概念1真実」）。
  // 常に false しか書かれておらず UI も一度も読んでいなかったため、移行不要で削除した。
  // **番号は詰めない**（field 4 は最終フィールドなので後続への影響は無いが、
  // writeByte の総数だけ 5→4 にする）。経緯は history_item_adapter.dart と
  // test/shared/models/history_item_adapter_backward_compat_test.dart を見ること。

  /// コンストラクタ: HistoryItem生成
  /// 実装内容: 全フィールドを初期化
  /// 信頼性レベル: 青信号 - テストケースTC-004〜TC-008の要件に基づく
  HistoryItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
  });

  /// copyWithメソッド: 不変オブジェクトの部分更新
  /// 実装内容: 一部のフィールドのみ変更した新しいHistoryItemを生成
  /// テスト対応: TC-006（削除テスト）、TC-007（50件上限テスト）で使用
  /// 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
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

  /// 等価性比較: オブジェクトの等価性を判定
  /// 実装内容: idが同じであれば同じHistoryItemとみなす
  /// テスト対応: TC-004、TC-005の読み込みテストで使用
  /// 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// ハッシュコード: 等価性比較のためのハッシュ値
  /// 実装内容: idのハッシュ値を返す
  /// 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  @override
  int get hashCode => id.hashCode;

  /// 文字列表現: デバッグ用文字列表現
  /// 実装内容: 全フィールドの値を含む文字列を返す
  /// 信頼性レベル: 青信号 - デバッグ・ログ出力のため
  @override
  String toString() {
    return 'HistoryItem(id: $id, content: $content, createdAt: $createdAt, type: $type)';
  }
}
