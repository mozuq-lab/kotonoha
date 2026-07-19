/// HomeScreen 入力候補チップ統合テスト（fix/improvement-p0-p2）
///
/// 頻度ベースの入力候補（REQ-4002の具体化）がホーム画面に正しく統合されて
/// いることを確認する。
/// - 入力が空のときは候補チップ行が表示されない（縦スペースを取らない）
/// - 前方一致する履歴があるとき、候補チップが表示される
/// - 候補タップで入力バッファが候補テキストに置換される
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/input_candidates/presentation/widgets/input_candidate_chips.dart';

void main() {
  group('HomeScreen 入力候補チップ統合', () {
    testWidgets('入力バッファが空のときは候補チップが表示されない（高さ0）', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final chipsSize = tester.getSize(find.byType(InputCandidateChips).first);
      expect(chipsSize.height, 0.0);
    });

    testWidgets('前方一致する履歴があるとき、文字盤入力に応じて候補チップが表示される', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(historyProvider.notifier)
          .addHistory('あいうえお', HistoryType.manualInput);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 文字盤から「あ」を入力する
      await tester.tap(find.text('あ').first);
      await tester.pumpAndSettle();

      expect(find.text('あいうえお'), findsOneWidget);
    });

    testWidgets('候補チップをタップすると入力バッファが候補テキストに置換される', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(historyProvider.notifier)
          .addHistory('あいうえお', HistoryType.manualInput);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('あ').first);
      await tester.pumpAndSettle();

      // 候補チップ「あいうえお」をタップ
      await tester.tap(find.text('あいうえお'));
      await tester.pumpAndSettle();

      expect(container.read(inputBufferProvider), 'あいうえお');
    });
  });
}
