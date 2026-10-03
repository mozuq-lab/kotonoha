import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/help/presentation/widgets/help_section_widget.dart';

void main() {
  // 中身が短いセクションでもカードは画面の幅いっぱいに広がり、
  // セクションごとにカードの幅がばらつかない
  testWidgets('中身が短くてもカードは親の幅いっぱいに広がる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HelpSectionWidget(title: 'チュートリアル', children: [Text('短い')]),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Card)).width, 800);
  });
}
