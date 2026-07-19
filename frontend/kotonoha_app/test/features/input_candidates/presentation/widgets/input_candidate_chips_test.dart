/// InputCandidateChips ウィジェットテスト
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補
///
/// 対象: lib/features/input_candidates/presentation/widgets/input_candidate_chips.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/input_candidates/domain/models/input_candidate.dart';
import 'package:kotonoha_app/features/input_candidates/presentation/widgets/input_candidate_chips.dart';

void main() {
  group('InputCandidateChips', () {
    testWidgets('候補が空の場合は高さ0（SizedBox.shrink）になり何も表示しない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                InputCandidateChips(candidates: const [], onSelect: (_) {}),
              ],
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(InputCandidateChips));
      expect(size.height, 0.0);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('候補があるとき、テキストとSemanticsラベルが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputCandidateChips(
              candidates: const [
                InputCandidate(text: 'おはようございます', score: 10),
                InputCandidate(text: 'おはよう', score: 5),
              ],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('おはようございます'), findsOneWidget);
      expect(find.text('おはよう'), findsOneWidget);
      expect(
        find.bySemanticsLabel('候補: おはようございます'),
        findsOneWidget,
      );
    });

    testWidgets('チップをタップするとonSelectが候補テキストを引数に呼ばれる', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputCandidateChips(
              candidates: const [
                InputCandidate(text: 'ありがとうございます', score: 10),
              ],
              onSelect: (text) => selected = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ありがとうございます'));
      await tester.pump();

      expect(selected, 'ありがとうございます');
    });

    testWidgets('各チップのタップターゲットは44px以上である', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputCandidateChips(
              candidates: const [
                InputCandidate(text: 'はい', score: 10),
              ],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      expect(buttonSize.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(buttonSize.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
    });

    testWidgets('行全体の高さはinputCandidateRowHeightである', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputCandidateChips(
              candidates: const [
                InputCandidate(text: 'はい', score: 10),
              ],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(InputCandidateChips));
      expect(size.height, AppSizes.inputCandidateRowHeight);
    });
  });
}
