/// ヘルプ画面ウィジェットテスト
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース REQ-3001, NFR-205）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/help/presentation/screens/help_screen.dart';

void main() {
  group('HelpScreen', () {
    testWidgets('ヘルプ画面が表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      // ヘルプ画面のタイトルが表示される
      expect(find.text('使い方'), findsOneWidget);
    });

    testWidgets('AppBarにタイトルが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.text('使い方'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('基本操作セクションが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.text('基本操作'), findsOneWidget);
    });

    testWidgets('文字盤の説明が表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.textContaining('文字盤'), findsAtLeastNWidgets(1));
    });

    testWidgets('定型文の説明が表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.textContaining('定型文'), findsAtLeastNWidgets(1));
    });

    testWidgets('TTS読み上げの説明が表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.textContaining('読み上げ'), findsAtLeastNWidgets(1));
    });

    testWidgets('緊急ボタンの説明が表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.textContaining('緊急'), findsAtLeastNWidgets(1));
    });

    testWidgets('誤操作防止設定セクションが表示される NFR-205', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.text('誤操作防止の設定'), findsOneWidget);
    });

    testWidgets('iOSガイド付きアクセスの説明が表示される NFR-205', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.textContaining('ガイド付きアクセス'), findsAtLeastNWidgets(1));
    });

    testWidgets('Android画面ピン留めの説明が表示される NFR-205', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.textContaining('画面ピン留め'), findsAtLeastNWidgets(1));
    });

    testWidgets('スクロール可能なコンテンツ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('アクセシビリティ対応 - Semanticsが設定されている', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      // Semanticsノードが存在することを確認
      final semantics = tester.getSemantics(find.byType(HelpScreen));
      expect(semantics, isNotNull);
    });
  });

  group('HelpScreen navigation', () {
    testWidgets('戻るボタンで前の画面に戻れる', (tester) async {
      bool navigatedBack = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpScreen(),
                  ),
                );
              },
              child: const Text('Go to Help'),
            ),
          ),
        ),
      );

      // ヘルプ画面に遷移
      await tester.tap(find.text('Go to Help'));
      await tester.pumpAndSettle();

      expect(find.text('使い方'), findsOneWidget);

      // 戻るボタンをタップ
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 元の画面に戻る
      expect(find.text('Go to Help'), findsOneWidget);
    });
  });
}
