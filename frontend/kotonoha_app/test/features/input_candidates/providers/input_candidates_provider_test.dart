/// inputCandidatesProvider テスト
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補
///
/// 対象: lib/features/input_candidates/providers/input_candidates_provider.dart
///
/// 【テスト方針】: HiveのBoxをオープンしないプレーンな[ProviderContainer]を
/// 使用する。repository_providers.dart はBox未オープン時にnullを返す設計
/// のため、historyProvider/favoriteProvider/presetPhraseNotifierProviderは
/// いずれもインメモリ動作にフォールバックする（既存のwiring testと同じ手法）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/input_candidates/providers/input_candidates_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';

void main() {
  group('inputCandidatesProvider', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('入力バッファが空のときは空リストを返す', () {
      container = ProviderContainer();

      expect(container.read(inputCandidatesProvider), isEmpty);
    });

    test('入力バッファに前方一致する履歴が候補として返る', () async {
      container = ProviderContainer();

      await container
          .read(historyProvider.notifier)
          .addHistory('おはようございます', HistoryType.manualInput);

      container.read(inputBufferProvider.notifier).setText('おは');

      final candidates = container.read(inputCandidatesProvider);
      expect(candidates.map((c) => c.text), contains('おはようございます'));
    });

    test('定型文・お気に入りの内容も候補に反映される', () async {
      container = ProviderContainer();

      await container
          .read(presetPhraseNotifierProvider.notifier)
          .addPhrase('トイレに行きたいです', 'health');
      await container.read(favoriteProvider.notifier).addFavorite('トイレを済ませました');

      container.read(inputBufferProvider.notifier).setText('トイレ');

      final candidates =
          container.read(inputCandidatesProvider).map((c) => c.text).toSet();
      expect(candidates, containsAll(['トイレに行きたいです', 'トイレを済ませました']));
    });

    test('入力バッファを変更すると候補が再計算される', () async {
      container = ProviderContainer();

      await container
          .read(historyProvider.notifier)
          .addHistory('こんにちは', HistoryType.manualInput);
      await container
          .read(historyProvider.notifier)
          .addHistory('こんばんは', HistoryType.manualInput);

      container.read(inputBufferProvider.notifier).setText('こんに');
      expect(
        container.read(inputCandidatesProvider).map((c) => c.text),
        ['こんにちは'],
      );

      container.read(inputBufferProvider.notifier).setText('こんば');
      expect(
        container.read(inputCandidatesProvider).map((c) => c.text),
        ['こんばんは'],
      );

      container.read(inputBufferProvider.notifier).clear();
      expect(container.read(inputCandidatesProvider), isEmpty);
    });

    test('候補は最大4件までに絞られる', () async {
      container = ProviderContainer();
      final notifier = container.read(historyProvider.notifier);
      for (var i = 0; i < 6; i++) {
        await notifier.addHistory('あ$i', HistoryType.manualInput);
      }

      container.read(inputBufferProvider.notifier).setText('あ');

      expect(container.read(inputCandidatesProvider).length, 4);
    });
  });
}
