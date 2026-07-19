/// CharacterBoardWidget fit-to-height ウィジェットテスト
///
/// スマホレイアウト修正（fix/improvement-p0-p2）
/// 対象: lib/features/character_board/presentation/widgets/character_board_widget.dart
///
/// 可視高さが乏しい場合でも、セルの実高さが44px未満に縮小されないこと
/// （下回る場合はGridView標準のスクロールに委ねる）を検証する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';

void main() {
  group('CharacterBoardWidget fit-to-heightテスト', () {
    testWidgets(
      '可視高さが乏しい場合でもセルの実高さは44px未満に縮小されない',
      (tester) async {
        // 幅700px・高さ200pxという、高さ基準では1セルあたり30px程度しか
        // 割り当てられない極端に低い領域に配置する
        // （5行 × 高さ200pxの領域では、単純な高さ按分だと44pxを下回る）。
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 700,
                height: 200,
                child: CharacterBoardWidget(onCharacterTap: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // GridViewが内部スクロールで吸収するため、レイアウト例外は発生しない
        expect(tester.takeException(), isNull);

        final buttonSize = tester.getSize(
          find.byType(CharacterButton).first,
        );

        // 高さ基準の理論値(約30px)まで縮小されず、44px下限で底上げされている
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );
        // 幅より高さが小さい（正方形固定ではなく、高さ方向のみ押し縮められて
        // いること）を確認し、fit-to-height処理が実際に働いていることを示す
        expect(buttonSize.height, lessThan(buttonSize.width));
      },
    );

    testWidgets(
      '可視高さが十分な場合は幅基準の正方形セル（従来動作）が維持される',
      (tester) async {
        // 高さに余裕がある場合、従来通り幅基準の正方形セル(aspectRatio≒1.0)
        // のままであることを確認する（タブレット等での回帰防止）。
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: CharacterBoardWidget(onCharacterTap: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final buttonSize = tester.getSize(
          find.byType(CharacterButton).first,
        );

        expect(
          (buttonSize.width - buttonSize.height).abs(),
          lessThan(1.0),
          reason: '高さに余裕がある場合はセルは正方形のままであるべき',
        );
      },
    );
  });
}
