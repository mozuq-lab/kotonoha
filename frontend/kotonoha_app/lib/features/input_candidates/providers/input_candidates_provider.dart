/// 入力候補プロバイダー
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補
///
/// 入力バッファ・履歴・定型文・お気に入りを監視し、
/// [InputCandidateScorer] で算出した候補リストを提供する。
///
/// 【依存設計の注意】: 入力バッファは1文字入力ごとに変化するため、
/// このProviderは毎キー再計算される。ただし対象データは履歴50件+定型文+
/// お気に入り程度であり、線形走査でも100ms要件に対して十分高速なため、
/// キャッシュ等の追加最適化は行わない。入力バッファが空の場合は
/// 早期リターンし、無駄な走査を避ける。
/// 🟡 信頼性レベル: 黄信号 - 新規実装
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/input_candidates/domain/input_candidate_scorer.dart';
import 'package:kotonoha_app/features/input_candidates/domain/models/input_candidate.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';

/// 入力候補プロバイダー
///
/// 入力バッファが空の場合は空リストを返す（候補チップ行は非表示になる）。
final inputCandidatesProvider = Provider<List<InputCandidate>>((ref) {
  final inputBuffer = ref.watch(inputBufferProvider);

  // 【早期リターン】: 入力が空の間は他のProviderを走査する必要がないため、
  // ここで打ち切る（無駄な依存購読・計算を避ける）。
  if (inputBuffer.isEmpty) return const [];

  final historyContents = ref
      .watch(historyProvider.select((state) => state.histories))
      .map((history) => history.content)
      .toList(growable: false);

  final presetPhraseContents = ref
      .watch(presetPhraseNotifierProvider.select((state) => state.phrases))
      .map((phrase) => phrase.content)
      .toList(growable: false);

  final favoriteContents = ref
      .watch(favoriteProvider.select((state) => state.favorites))
      .map((favorite) => favorite.content)
      .toList(growable: false);

  return InputCandidateScorer.computeCandidates(
    inputBuffer: inputBuffer,
    historyContents: historyContents,
    presetPhraseContents: presetPhraseContents,
    favoriteContents: favoriteContents,
  );
});
