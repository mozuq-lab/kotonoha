/// 入力候補エンティティ
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補
///
/// 履歴・定型文・お気に入りから前方一致で算出された候補テキストと、
/// そのスコア（頻度・最近性・由来を組み合わせたもの）を保持する。
/// 🟡 信頼性レベル: 黄信号 - REQ-4002（AI変換以外の入力支援）の具体化として新規実装
library;

/// 入力候補
///
/// [text] 候補として表示するテキスト（前方一致でヒットした文字列）
/// [score] スコアリングロジックが算出した優先度（値が大きいほど上位表示）
class InputCandidate {
  /// 候補テキスト
  final String text;

  /// スコア（値が大きいほど優先表示される）
  final int score;

  /// コンストラクタ
  const InputCandidate({required this.text, required this.score});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InputCandidate &&
        other.text == text &&
        other.score == score;
  }

  @override
  int get hashCode => Object.hash(text, score);

  @override
  String toString() => 'InputCandidate(text: $text, score: $score)';
}
