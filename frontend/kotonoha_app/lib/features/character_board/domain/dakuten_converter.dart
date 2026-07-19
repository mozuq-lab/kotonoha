/// 濁音・半濁音変換ロジック
///
/// 文字盤の「゛」「゜」キーが押されたときに、入力バッファ末尾の文字を
/// 濁音・半濁音に変換する（か→が、は→ぱ 等）ためのドメインロジック。
///
/// 設計方針:
/// - 変換不能な文字（母音や既に対象外の文字等）はnullを返し、呼び出し側で無視する。
/// - 濁音化された文字に対して再度「゛」を押すと清音に戻す（トグル動作）。
/// - は行は清音・濁音・半濁音の3状態を持つため、「゛」「゜」どちらのキーからも
///   相互に変換できるようにする（ば→ぱ、ぱ→ば）。
///
/// 対応要件: TASK改善（濁音・半濁音の3タップ問題解消）
library;

class DakutenConverter {
  DakutenConverter._();

  /// 清音→濁音の変換マップ（か行・さ行・た行・は行、20文字）
  static const Map<String, String> _seionToDakuon = {
    'か': 'が',
    'き': 'ぎ',
    'く': 'ぐ',
    'け': 'げ',
    'こ': 'ご',
    'さ': 'ざ',
    'し': 'じ',
    'す': 'ず',
    'せ': 'ぜ',
    'そ': 'ぞ',
    'た': 'だ',
    'ち': 'ぢ',
    'つ': 'づ',
    'て': 'で',
    'と': 'ど',
    'は': 'ば',
    'ひ': 'び',
    'ふ': 'ぶ',
    'へ': 'べ',
    'ほ': 'ぼ',
  };

  /// 清音→半濁音の変換マップ（は行のみ、5文字）
  static const Map<String, String> _seionToHandakuon = {
    'は': 'ぱ',
    'ひ': 'ぴ',
    'ふ': 'ぷ',
    'へ': 'ぺ',
    'ほ': 'ぽ',
  };

  /// 濁音→清音の逆引きマップ（トグルで戻す用）
  static final Map<String, String> _dakuonToSeion = {
    for (final entry in _seionToDakuon.entries) entry.value: entry.key,
  };

  /// 半濁音→清音の逆引きマップ（トグルで戻す用）
  static final Map<String, String> _handakuonToSeion = {
    for (final entry in _seionToHandakuon.entries) entry.value: entry.key,
  };

  /// 「゛」キー押下時の変換処理
  ///
  /// - 清音（か等）→ 濁音（が等）
  /// - 濁音（が等）→ 清音（か等）（トグルで戻す）
  /// - 半濁音（ぱ等、は行のみ）→ 濁音（ば等）（は行内での相互変換）
  /// - 上記以外（変換不能な文字）→ null
  static String? applyDakuten(String lastChar) {
    final toDakuon = _seionToDakuon[lastChar];
    if (toDakuon != null) return toDakuon;

    final toSeion = _dakuonToSeion[lastChar];
    if (toSeion != null) return toSeion;

    final handakuonSeion = _handakuonToSeion[lastChar];
    if (handakuonSeion != null) return _seionToDakuon[handakuonSeion];

    return null;
  }

  /// 「゜」キー押下時の変換処理
  ///
  /// - 清音（は行のみ）→ 半濁音（ぱ等）
  /// - 半濁音（ぱ等）→ 清音（は等）（トグルで戻す）
  /// - 濁音（ば等、は行のみ）→ 半濁音（ぱ等）（は行内での相互変換）
  /// - 上記以外（変換不能な文字）→ null
  static String? applyHandakuten(String lastChar) {
    final toHandakuon = _seionToHandakuon[lastChar];
    if (toHandakuon != null) return toHandakuon;

    final toSeion = _handakuonToSeion[lastChar];
    if (toSeion != null) return toSeion;

    final dakuonSeion = _dakuonToSeion[lastChar];
    if (dakuonSeion != null) return _seionToHandakuon[dakuonSeion];

    return null;
  }
}
