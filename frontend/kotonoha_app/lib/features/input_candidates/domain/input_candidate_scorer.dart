/// 入力候補スコアリングロジック
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補（REQ-4002の具体化）
///
/// 履歴（最近性で重み付け）・定型文・お気に入りから、現在の入力バッファに
/// 前方一致するテキストを候補として抽出し、頻度・最近性・由来を組み合わせた
/// 単純なスコアリングで並び替える。
///
/// 【データ量】: 履歴は最大50件、定型文・お気に入りも数十〜百件程度を想定。
/// 全体で線形走査（O(件数)）しても実用上問題ない規模のため、
/// 都度全件スキャンする単純な実装とした。
///
/// 🟡 信頼性レベル: 黄信号 - 要件定義書に具体的なスコア式の定義はなく、
/// 「頻度と最近性を組み合わせた単純なスコアリング」という指示から実装した。
library;

import 'models/input_candidate.dart';

/// 入力候補スコアリング
class InputCandidateScorer {
  InputCandidateScorer._();

  /// 候補の最大表示件数
  static const int defaultMaxCandidates = 4;

  /// 頻度1回あたりの加点（履歴内で同一テキストが出現するたびに加算）
  static const int frequencyWeight = 20;

  /// 最近性の基準点（履歴の最新出現位置=index0のときの加点）
  static const int recencyBaseScore = 50;

  /// 最近性の減衰量（履歴インデックスが1増えるごとの減点）
  static const int recencyDecayPerIndex = 2;

  /// お気に入り由来であることの加点
  ///
  /// お気に入りはユーザーが明示的に選んだテキストであるため、
  /// 履歴に一度も出現していなくても候補になり得るようにする。
  static const int favoriteBonus = 15;

  /// 定型文由来であることの加点
  ///
  /// 定型文は汎用的な候補として常に使える一方、個人の使用頻度を
  /// 反映しないため、お気に入りより低い加点にとどめる。
  static const int presetBonus = 5;

  /// 入力候補を算出する
  ///
  /// [inputBuffer] が空文字の場合は常に空リストを返す（候補行を非表示にするため）。
  /// [historyContents] は最近の順（index 0 が最新）で渡すこと。
  ///
  /// 同一テキストが複数のソース（履歴・定型文・お気に入り）に存在する場合は
  /// 1つの候補に統合し、スコアを合算する。
  /// [inputBuffer] と完全一致するテキストは、置換しても意味がないため候補から除外する。
  static List<InputCandidate> computeCandidates({
    required String inputBuffer,
    List<String> historyContents = const [],
    List<String> presetPhraseContents = const [],
    List<String> favoriteContents = const [],
    int maxCandidates = defaultMaxCandidates,
  }) {
    if (inputBuffer.isEmpty) return const [];

    final accumulators = <String, _CandidateAccumulator>{};

    for (var i = 0; i < historyContents.length; i++) {
      final content = historyContents[i];
      if (content.isEmpty) continue;
      final acc = accumulators.putIfAbsent(content, _CandidateAccumulator.new);
      acc.frequency += 1;
      // 同一テキストが複数回出現する場合、最も新しい（indexが小さい）出現を採用する
      if (acc.mostRecentIndex == null || i < acc.mostRecentIndex!) {
        acc.mostRecentIndex = i;
      }
    }

    for (final content in presetPhraseContents) {
      if (content.isEmpty) continue;
      accumulators.putIfAbsent(content, _CandidateAccumulator.new).isPreset =
          true;
    }

    for (final content in favoriteContents) {
      if (content.isEmpty) continue;
      accumulators.putIfAbsent(content, _CandidateAccumulator.new).isFavorite =
          true;
    }

    final candidates = <InputCandidate>[];
    accumulators.forEach((content, acc) {
      // 完全一致は「置換」の意味がないため候補としない
      if (content == inputBuffer) return;
      if (!content.startsWith(inputBuffer)) return;

      var score = acc.frequency * frequencyWeight;

      final recentIndex = acc.mostRecentIndex;
      if (recentIndex != null) {
        final recency = recencyBaseScore - recentIndex * recencyDecayPerIndex;
        if (recency > 0) score += recency;
      }

      if (acc.isFavorite) score += favoriteBonus;
      if (acc.isPreset) score += presetBonus;

      candidates.add(InputCandidate(text: content, score: score));
    });

    // スコア降順。同点の場合はテキストの辞書順で決定的な順序にする。
    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.text.compareTo(b.text);
    });

    return candidates.take(maxCandidates).toList();
  }
}

/// 候補算出の途中集計用（1テキストごとの頻度・最近性・由来を保持）
class _CandidateAccumulator {
  int frequency = 0;
  int? mostRecentIndex;
  bool isFavorite = false;
  bool isPreset = false;
}
