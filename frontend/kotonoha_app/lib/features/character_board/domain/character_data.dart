/// 文字データ定義
///
/// TASK-0037: 五十音文字盤UI実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-001, REQ-002
library;

/// 文字カテゴリ列挙型
///
/// 五十音文字盤のカテゴリを定義
enum CharacterCategory {
  /// 基本五十音（あ〜ん）
  basic('基本'),

  /// 濁音（が〜ぼ）
  dakuon('濁音'),

  /// 半濁音（ぱ〜ぽ）
  handakuon('半濁音'),

  /// 小文字・拗音（ゃゅょ、ぁぃぅぇぉ、っ）
  komoji('小文字'),

  /// 記号（ー、。？！）
  kigou('記号');

  /// カテゴリの表示名
  final String displayName;

  const CharacterCategory(this.displayName);
}

/// 文字データクラス
///
/// 各カテゴリの文字リストを提供する
class CharacterData {
  CharacterData._();

  /// 基本五十音（あ〜ん）46文字
  ///
  /// 五十音表の配列順に並べる
  /// 空文字列は表示しないスペーサーとして使用
  static const List<String> basic = [
    'あ', 'い', 'う', 'え', 'お',
    'か', 'き', 'く', 'け', 'こ',
    'さ', 'し', 'す', 'せ', 'そ',
    'た', 'ち', 'つ', 'て', 'と',
    'な', 'に', 'ぬ', 'ね', 'の',
    'は', 'ひ', 'ふ', 'へ', 'ほ',
    'ま', 'み', 'む', 'め', 'も',
    'や', '', 'ゆ', '', 'よ',
    'ら', 'り', 'る', 'れ', 'ろ',
    'わ', 'を', 'ん', '', '',
  ];

  /// 濁音（が〜ぼ）20文字
  static const List<String> dakuon = [
    'が', 'ぎ', 'ぐ', 'げ', 'ご',
    'ざ', 'じ', 'ず', 'ぜ', 'ぞ',
    'だ', 'ぢ', 'づ', 'で', 'ど',
    'ば', 'び', 'ぶ', 'べ', 'ぼ',
  ];

  /// 半濁音（ぱ〜ぽ）5文字
  static const List<String> handakuon = [
    'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ',
  ];

  /// 小文字・拗音 9文字
  static const List<String> komoji = [
    'ゃ', 'ゅ', 'ょ', '', '',
    'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ',
    'っ', '', '', '', '',
  ];

  /// 記号 5文字
  static const List<String> kigou = [
    'ー', '、', '。', '？', '！',
  ];

  /// カテゴリに対応する文字リストを取得
  static List<String> getCharacters(CharacterCategory category) {
    switch (category) {
      case CharacterCategory.basic:
        return basic;
      case CharacterCategory.dakuon:
        return dakuon;
      case CharacterCategory.handakuon:
        return handakuon;
      case CharacterCategory.komoji:
        return komoji;
      case CharacterCategory.kigou:
        return kigou;
    }
  }

  /// カテゴリに対応する文字リストを取得（空文字を除外）
  static List<String> getCharactersFiltered(CharacterCategory category) {
    return getCharacters(category).where((c) => c.isNotEmpty).toList();
  }
}
