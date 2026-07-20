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

    testWidgets('長文候補（200文字級）でもチップ幅が上限以下に収まり、後続候補チップが表示される', (tester) async {
      // 【テスト目的】: Codexレビュー指摘（P2）- 長い履歴文がヒットした際に
      // チップが全文幅（数千px）に伸びて後続候補が実質届かなくなる問題の回帰防止。
      // 【前提】: 画面幅を広め(1000px)に取ることで、画面幅の60%(600px)が
      // AppSizes.candidateChipMaxWidth(280px)を上回り、絶対上限280pxの方が
      // 採用される状況を作る。これにより後続候補チップの表示スペースも十分確保される。
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final longText = 'あ' * 200;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputCandidateChips(
              candidates: [
                InputCandidate(text: longText, score: 10),
                const InputCandidate(text: '後続候補', score: 5),
              ],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // オーバーフロー等のレイアウト例外が発生していないこと
      expect(tester.takeException(), isNull);

      // 長文候補チップの幅がAppSizes.candidateChipMaxWidth(280px)以下に
      // 収まっていること（全文幅まで伸びていないこと）
      final longChipSize = tester.getSize(find.byType(ElevatedButton).first);
      expect(
        longChipSize.width,
        lessThanOrEqualTo(AppSizes.candidateChipMaxWidth),
      );

      // 後続候補チップがリスト内に存在し、表示できる状態であること
      expect(find.text('後続候補'), findsOneWidget);

      // Semanticsラベルには全文が保持されていること（省略表示は見た目のみ）
      expect(find.bySemanticsLabel('候補: $longText'), findsOneWidget);
    });
  });
}
