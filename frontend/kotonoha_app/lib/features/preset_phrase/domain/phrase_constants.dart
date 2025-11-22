/// PhraseConstants - 定型文関連の定数定義
///
/// TASK-0041: 定型文CRUD機能実装
/// TDD Refactorフェーズ: 共通化
///
/// 定型文機能で共通して使用する定数を集約。
/// カテゴリ定義、ラベルマッピング等を一元管理する。
///
/// 関連要件:
/// - 入力仕様2.1.1: カテゴリは「日常」「体調」「その他」の3種類
library;

/// 【機能概要】: 定型文関連の定数定義
/// 【実装方針】: 静的定数でカテゴリ定義を集約
/// 🔵 信頼性レベル: 青信号 - 入力仕様2.1.1に基づく
///
/// 定型文機能で使用する定数（カテゴリ、ラベル等）を定義。
/// 追加・編集ダイアログ、一覧表示で共通利用する。
class PhraseConstants {
  PhraseConstants._();

  /// 【定数定義】: 有効なカテゴリ一覧
  /// 🔵 信頼性レベル: 青信号 - 入力仕様2.1.1に基づく
  static const List<String> validCategories = ['daily', 'health', 'other'];

  /// 【定数定義】: デフォルトカテゴリ
  /// 🔵 信頼性レベル: 青信号 - 入力仕様に基づく
  static const String defaultCategory = 'daily';

  /// 【定数定義】: カテゴリのラベルマッピング
  /// 🔵 信頼性レベル: 青信号 - 入力仕様2.1.1に基づく
  static const Map<String, String> categoryLabels = {
    'daily': '日常',
    'health': '体調',
    'other': 'その他',
  };

  /// 【メソッド】: カテゴリコードからラベルを取得
  /// 🔵 信頼性レベル: 青信号 - 共通ユーティリティ
  ///
  /// カテゴリコード（daily, health, other）を日本語ラベルに変換。
  /// 未知のカテゴリの場合はコードをそのまま返す。
  static String getCategoryLabel(String category) {
    return categoryLabels[category] ?? category;
  }
}
