/// ヘルプセクションウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/help/presentation/widgets/help_section_widget.dart';

void main() {
  group('HelpSectionWidget', () {
    testWidgets('セクションタイトルが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpSectionWidget(
              title: 'テストセクション',
              children: [
                Text('テスト内容'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('テストセクション'), findsOneWidget);
    });

    testWidgets('子ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpSectionWidget(
              title: 'セクション',
              children: [
                Text('子ウィジェット1'),
                Text('子ウィジェット2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('子ウィジェット1'), findsOneWidget);
      expect(find.text('子ウィジェット2'), findsOneWidget);
    });

    testWidgets('アイコン付きセクションが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpSectionWidget(
              title: 'アイコン付き',
              icon: Icons.help,
              children: [
                Text('内容'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('Cardでラップされている', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpSectionWidget(
              title: 'セクション',
              children: [
                Text('内容'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
