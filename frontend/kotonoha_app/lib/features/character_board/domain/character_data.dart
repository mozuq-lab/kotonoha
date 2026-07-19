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

  /// 濁音化キー（文字盤専用の特殊トークン）
  ///
  /// タップすると入力バッファ末尾の文字を濁音化する（か→が等）。
  /// 濁音化された文字に対して再度タップするとトグルで清音に戻す。
  /// 見た目上も「゛」記号そのものを表示する実在文字のため、通常の
  /// 文字ボタンと同じ描画で表示できる。
  ///
  /// 対応要件: TASK改善（濁音・半濁音の3タップ問題解消）
  static const String dakutenKey = '゛';

  /// 半濁音化キー（文字盤専用の特殊トークン）
  ///
  /// タップすると入力バッファ末尾の文字を半濁音化する（は→ぱ等）。
  /// 半濁音化された文字に対して再度タップするとトグルで清音に戻す。
  static const String handakutenKey = '゜';

  /// 空白キー
  ///
  /// タップすると全角スペース（U+3000）を入力バッファに追加する。
  /// 実際の値がそのまま挿入されるため、他の特殊キーと異なり
  /// InputBufferNotifier.addCharacter()にそのまま渡せばよい。
  static const String spaceKey = '　';

  /// 基本五十音（あ〜ん）46文字 + 特殊キー3種（濁点・半濁点・空白）
  ///
  /// 五十音表の配列順に並べる
  /// 空文字列は表示しないスペーサーとして使用
  ///
  /// 【改善】: 濁音・半濁音の入力に従来はタブ切替（基本→濁音/半濁音→基本の
  /// 3タップ）が必要だった。五十音表上もともと文字が存在しない
  /// スペーサー位置（や行・わ行の空きセル）を活用し、行数を増やさずに
  /// 「゛」「゜」「空白」キーを配置する。
  static const List<String> basic = [
    'あ',
    'い',
    'う',
    'え',
    'お',
    'か',
    'き',
    'く',
    'け',
    'こ',
    'さ',
    'し',
    'す',
    'せ',
    'そ',
    'た',
    'ち',
    'つ',
    'て',
    'と',
    'な',
    'に',
    'ぬ',
    'ね',
    'の',
    'は',
    'ひ',
    'ふ',
    'へ',
    'ほ',
    'ま',
    'み',
    'む',
    'め',
    'も',
    'や',
    dakutenKey,
    'ゆ',
    handakutenKey,
    'よ',
    'ら',
    'り',
    'る',
    'れ',
    'ろ',
    'わ',
    'を',
    'ん',
    spaceKey,
    '',
  ];

  /// 濁音（が〜ぼ）20文字
  static const List<String> dakuon = [
    'が',
    'ぎ',
    'ぐ',
    'げ',
    'ご',
    'ざ',
    'じ',
    'ず',
    'ぜ',
    'ぞ',
    'だ',
    'ぢ',
    'づ',
    'で',
    'ど',
    'ば',
    'び',
    'ぶ',
    'べ',
    'ぼ',
  ];

  /// 半濁音（ぱ〜ぽ）5文字
  static const List<String> handakuon = [
    'ぱ',
    'ぴ',
    'ぷ',
    'ぺ',
    'ぽ',
  ];

  /// 小文字・拗音 9文字
  static const List<String> komoji = [
    'ゃ',
    'ゅ',
    'ょ',
    '',
    '',
    'ぁ',
    'ぃ',
    'ぅ',
    'ぇ',
    'ぉ',
    'っ',
    '',
    '',
    '',
    '',
  ];

  /// 記号 5文字
  static const List<String> kigou = [
    'ー',
    '、',
    '。',
    '？',
    '！',
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

  /// 文字が濁音化キーかどうかを判定する
  static bool isDakutenKey(String character) => character == dakutenKey;

  /// 文字が半濁音化キーかどうかを判定する
  static bool isHandakutenKey(String character) => character == handakutenKey;

  /// 文字が空白キーかどうかを判定する
  static bool isSpaceKey(String character) => character == spaceKey;

  /// ボタンに表示する文字列を取得する
  ///
  /// 空白キーは実際の値が全角スペース（見た目上は空白）のため、
  /// そのままボタンに表示すると視覚的に判別できない。表示専用の
  /// ラベルに差し替える。濁点・半濁点キーはそれ自体が可視文字のため
  /// そのまま表示する。それ以外の文字はそのまま返す。
  static String getDisplayLabel(String character) {
    if (isSpaceKey(character)) return '空白';
    return character;
  }

  /// アクセシビリティ用のSemanticsラベルを取得する
  ///
  /// スクリーンリーダーで読み上げても意味が伝わるよう、
  /// 特殊キーには専用ラベルを設定する。
  static String getAccessibilityLabel(String character) {
    if (isDakutenKey(character)) return '濁点';
    if (isHandakutenKey(character)) return '半濁点';
    if (isSpaceKey(character)) return '空白';
    return character;
  }
}
