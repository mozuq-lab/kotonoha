/// InputCandidateScorer ユニットテスト
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補
///
/// 対象: lib/features/input_candidates/domain/input_candidate_scorer.dart
///
/// 検証内容:
/// - 入力が空の場合は候補を返さない
/// - 前方一致のみを候補とする
/// - 完全一致は候補から除外する
/// - 頻度が高いほど上位に来る
/// - 同一頻度なら最近性が高いほど上位に来る
/// - お気に入り・定型文由来は履歴になくても候補になる
/// - 上限4件に絞られる
/// - 複数ソースに存在する同一テキストは1件に統合される
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/input_candidates/domain/input_candidate_scorer.dart';

void main() {
  group('InputCandidateScorer.computeCandidates', () {
    test('入力バッファが空文字の場合は候補を返さない', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: '',
        historyContents: ['おはようございます', 'おやすみなさい'],
      );

      expect(result, isEmpty);
    });

    test('前方一致するテキストのみを候補とする', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'おは',
        historyContents: ['おはようございます', 'こんにちは', 'おなかがすいた'],
      );

      expect(result.map((c) => c.text), ['おはようございます']);
    });

    test('入力バッファと完全一致するテキストは候補から除外する', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'ありがとう',
        historyContents: ['ありがとう', 'ありがとうございます'],
      );

      expect(result.map((c) => c.text), ['ありがとうございます']);
    });

    test('履歴内で出現回数が多いテキストほど上位に来る（頻度重視）', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'あ',
        historyContents: [
          'あついです', // index0: 1回目
          'あめがふっています', // index1: 1回のみ
          'あついです', // index2: 2回目
          'あついです', // index3: 3回目
        ],
      );

      expect(result.first.text, 'あついです');
      expect(
        result.firstWhere((c) => c.text == 'あついです').score,
        greaterThan(result.firstWhere((c) => c.text == 'あめがふっています').score),
      );
    });

    test('出現回数が同じ場合、最近（indexが小さい）出現のテキストほど上位に来る', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'あ',
        // 「あついです」がindex0（最新）、「あめがふっています」がindex5（古い）で
        // それぞれ1回ずつ出現。頻度は同点なので最近性で差がつく。
        historyContents: [
          'あついです',
          'こんにちは',
          'こんばんは',
          'おやすみなさい',
          'いただきます',
          'あめがふっています',
        ],
      );

      final hot = result.firstWhere((c) => c.text == 'あついです');
      final rain = result.firstWhere((c) => c.text == 'あめがふっています');
      expect(hot.score, greaterThan(rain.score));
      expect(result.first.text, 'あついです');
    });

    test('お気に入り由来のテキストは履歴に出現していなくても候補になる', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'トイレ',
        historyContents: const [],
        favoriteContents: ['トイレに行きたいです'],
      );

      expect(result.map((c) => c.text), ['トイレに行きたいです']);
    });

    test('定型文由来のテキストは履歴に出現していなくても候補になる', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'おは',
        historyContents: const [],
        presetPhraseContents: ['おはようございます'],
      );

      expect(result.map((c) => c.text), ['おはようございます']);
    });

    test('お気に入り由来は定型文由来より優先度が高い（同一頻度・同一最近性の場合）', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'あ',
        historyContents: const [],
        presetPhraseContents: ['あついです'],
        favoriteContents: ['あめがふっています'],
      );

      expect(result.first.text, 'あめがふっています');
    });

    test('候補は最大4件に絞られる', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'あ',
        historyContents: [
          'あ1',
          'あ2',
          'あ3',
          'あ4',
          'あ5',
          'あ6',
        ],
      );

      expect(result.length, 4);
    });

    test('maxCandidatesを指定すると件数を変更できる', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'あ',
        historyContents: ['あ1', 'あ2', 'あ3'],
        maxCandidates: 2,
      );

      expect(result.length, 2);
    });

    test('複数ソース（履歴・定型文・お気に入り）に存在する同一テキストは1件に統合される', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'ありがとうご',
        historyContents: ['ありがとうございます'],
        presetPhraseContents: ['ありがとうございます'],
        favoriteContents: ['ありがとうございます'],
      );

      expect(result.length, 1);
      expect(result.first.text, 'ありがとうございます');
    });

    test('空文字のコンテンツは無視される', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'あ',
        historyContents: ['', 'あついです'],
        presetPhraseContents: [''],
        favoriteContents: [''],
      );

      expect(result.map((c) => c.text), ['あついです']);
    });

    test('前方一致しないテキストは候補にならない', () {
      final result = InputCandidateScorer.computeCandidates(
        inputBuffer: 'ありがとう',
        historyContents: ['こんにちは', 'おやすみなさい'],
      );

      expect(result, isEmpty);
    });
  });
}
