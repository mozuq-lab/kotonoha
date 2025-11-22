/// PresetPhraseValidator - 定型文バリデーションロジック
///
/// TASK-0041: 定型文CRUD機能実装
/// TDD Refactorフェーズ: ドキュメント改善
///
/// 関連要件:
/// - CRUD-201: 最大500文字制限
/// - CRUD-202: 最小1文字
/// - CRUD-105: 空入力拒否
/// - EDGE-005: 空白のみ拒否
library;

import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';

/// 【機能概要】: 定型文バリデーター
/// 【実装方針】: 静的メソッドでバリデーション実行
/// 🔵 信頼性レベル: 青信号 - CRUD-201, CRUD-202に基づく
///
/// 定型文の内容とカテゴリをバリデーションする。
/// エラー時はエラーメッセージを返し、正常時はnullを返す。
class PresetPhraseValidator {
  PresetPhraseValidator._();

  /// 【定数定義】: 最小文字数
  /// 🔵 信頼性レベル: 青信号 - CRUD-202に基づく
  static const int minLength = 1;

  /// 【定数定義】: 最大文字数
  /// 🔵 信頼性レベル: 青信号 - CRUD-201に基づく
  static const int maxLength = 500;

  /// 【バリデーション】: 定型文内容のバリデーション
  /// 【実装内容】: 空チェック、文字数制限チェック
  /// 【テスト対応】: TC-041-001〜TC-041-009
  /// 🔵 信頼性レベル: 青信号 - CRUD-105, CRUD-201, CRUD-202に基づく
  ///
  /// 正常時はnullを返し、エラー時はエラーメッセージを返す。
  static String? validateContent(String? content) {
    // 空チェック (CRUD-105, EDGE-001)
    if (content == null || content.trim().isEmpty) {
      return '定型文を入力してください';
    }

    // 文字数上限チェック (CRUD-104, CRUD-201, EDGE-004)
    if (content.length > maxLength) {
      return '定型文は500文字以内で入力してください';
    }

    // バリデーション成功
    return null;
  }

  /// 【バリデーション】: カテゴリのバリデーション
  /// 【実装内容】: 有効なカテゴリ値かどうかをチェック
  /// 【テスト対応】: TC-041-010
  /// 🔵 信頼性レベル: 青信号 - 入力仕様に基づく
  ///
  /// 正常時はnullを返し、エラー時はエラーメッセージを返す。
  static String? validateCategory(String? category) {
    // 空チェック
    if (category == null || category.isEmpty) {
      return '無効なカテゴリです';
    }

    // 有効なカテゴリかどうかチェック（PhraseConstantsを参照）
    if (!PhraseConstants.validCategories.contains(category)) {
      return '無効なカテゴリです';
    }

    // バリデーション成功
    return null;
  }
}
