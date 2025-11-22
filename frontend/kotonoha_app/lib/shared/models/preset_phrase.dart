import 'package:hive/hive.dart';

part 'preset_phrase.g.dart';

/// 【データモデル定義】: 定型文
/// 【実装内容】: ユーザーが登録・管理する定型文を保存するためのデータクラス
/// 【Hive設定】: typeId 1 として登録、各フィールドに@HiveFieldアノテーション付与
/// 🔵 信頼性レベル: 青信号 - REQ-104、REQ-106、interfaces.dartのPresetPhraseエンティティに基づく
@HiveType(typeId: 1)
class PresetPhrase extends HiveObject {
  /// 【フィールド定義】: 一意識別子
  /// 【実装内容】: UUID形式の文字列ID（定型文の一意性を保証）
  /// 🔵 信頼性レベル: 青信号 - interfaces.dartに基づく
  @HiveField(0)
  final String id;

  /// 【フィールド定義】: 定型文の内容
  /// 【実装内容】: ユーザーが設定画面で登録した定型文テキスト
  /// 🔵 信頼性レベル: 青信号 - REQ-104（定型文追加機能）に基づく
  @HiveField(1)
  final String content;

  /// 【フィールド定義】: カテゴリ（「日常」「体調」「その他」）
  /// 【実装内容】: 定型文を3種類のカテゴリに分類
  /// 🔵 信頼性レベル: 青信号 - REQ-106（カテゴリ分類）に基づく
  @HiveField(2)
  final String category; // 'daily', 'health', 'other'

  /// 【フィールド定義】: お気に入りフラグ
  /// 【実装内容】: お気に入り登録された定型文はUI上部に優先表示
  /// 🔵 信頼性レベル: 青信号 - REQ-105（お気に入り優先表示）に基づく
  @HiveField(3)
  final bool isFavorite;

  /// 【フィールド定義】: 並び順（お気に入り内での優先度）
  /// 【実装内容】: ユーザーがカスタマイズ可能な表示順序
  /// 🔵 信頼性レベル: 青信号 - interfaces.dartのdisplayOrderフィールドに基づく
  @HiveField(4)
  final int displayOrder;

  /// 【フィールド定義】: 作成日時
  /// 【実装内容】: 定型文が作成された日時
  /// 🔵 信頼性レベル: 青信号 - REQ-5003（データ永続化）に基づく
  @HiveField(5)
  final DateTime createdAt;

  /// 【フィールド定義】: 更新日時
  /// 【実装内容】: 定型文が最後に更新された日時
  /// 🔵 信頼性レベル: 青信号 - REQ-5003（データ永続化）に基づく
  @HiveField(6)
  final DateTime updatedAt;

  /// 【コンストラクタ】: PresetPhrase生成
  /// 【実装内容】: 全フィールドを初期化（isFavoriteのみデフォルト値false）
  /// 🔵 信頼性レベル: 青信号 - テストケースTC-009〜TC-015の要件に基づく
  PresetPhrase({
    required this.id,
    required this.content,
    required this.category,
    this.isFavorite = false,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 【copyWithメソッド】: 不変オブジェクトの部分更新
  /// 【実装内容】: 一部のフィールドのみ変更した新しいPresetPhraseを生成
  /// 【テスト対応】: TC-012（お気に入りフラグ更新）、TC-013（削除テスト）で使用
  /// 🔵 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  PresetPhrase copyWith({
    String? id,
    String? content,
    String? category,
    bool? isFavorite,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PresetPhrase(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 【等価性比較】: オブジェクトの等価性を判定
  /// 【実装内容】: idが同じであれば同じPresetPhraseとみなす
  /// 【テスト対応】: TC-009、TC-010の読み込みテストで使用
  /// 🔵 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetPhrase &&
          runtimeType == other.runtimeType &&
          id == other.id;

  /// 【ハッシュコード】: 等価性比較のためのハッシュ値
  /// 【実装内容】: idのハッシュ値を返す
  /// 🔵 信頼性レベル: 青信号 - Dartのベストプラクティスに基づく
  @override
  int get hashCode => id.hashCode;

  /// 【文字列表現】: デバッグ用文字列表現
  /// 【実装内容】: 全フィールドの値を含む文字列を返す
  /// 🔵 信頼性レベル: 青信号 - デバッグ・ログ出力のため
  @override
  String toString() {
    return 'PresetPhrase(id: $id, content: $content, category: $category, isFavorite: $isFavorite, displayOrder: $displayOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
