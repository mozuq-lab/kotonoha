/// 文字盤の列数は 5 か 10（五十音の行をそろえる）
///
/// 列数を幅から 5〜10 の間で自由に決めていたので、iPhone の横向きでは 6 列に
/// なり、「あいうえお」の段に「か」がはみ出して行がずれていた。文字の並びは
/// どの文字種も 5 列を前提に作ってある（や行・わ行の空きの位置も含む）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';

int _columns(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView));
  return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
      .crossAxisCount;
}

void main() {
  // 幅（1 個 60px＋間 8px で数えると 5〜10 列の範囲）→ 期待する列数
  for (final (width, expected) in [
    (360.0, 5),
    (450.0, 5), // iPhone 横向きの右ペイン相当。以前は 6 列
    (560.0, 5), // 以前は 8 列
    (650.0, 5), // 以前は 9 列
    (700.0, 10),
    (1000.0, 10),
  ]) {
    for (final category in CharacterCategory.values) {
      testWidgets('幅 $width・${category.name}: $expected 列', (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 600,
                child: CharacterBoardWidget(
                  onCharacterTap: (_) {},
                  initialCategory: category,
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(_columns(tester), expected, reason: '五十音の行がずれる列数');
      });
    }
  }
}
