/// EmptyHistoryWidget ウィジェットテスト
///
/// TASK-0061: 履歴一覧UI実装
/// テストフレームワーク: flutter_test
///
/// 対象: EmptyHistoryWidget（空状態表示ウィジェット）
///
/// TDD Redフェーズ: UIが未実装、テストが失敗するはず
///
/// 信頼性レベル凡例:
/// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 黄信号: 要件定義書から妥当な推測によるテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/history/presentation/widgets/empty_history_widget.dart';

void main() {
  group('EmptyHistoryWidget', () {
    // =========================================================================
    // 3.1 正常系テスト
    // =========================================================================
    group('正常系テスト', () {
      /// TC-061-033: 空状態メッセージが表示される
      testWidgets('TC-061-033: EmptyHistoryWidgetが空状態メッセージを表示する',
          (WidgetTester tester) async {
        // When: EmptyHistoryWidgetを表示する
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyHistoryWidget(),
            ),
          ),
        );

        // Then: 「履歴がありません」が画面中央に表示される
        expect(
          find.text('履歴がありません'),
          findsOneWidget,
          reason: '空状態メッセージが表示される必要がある',
        );
      });

      /// TC-061-034: 空状態アイコンが表示される
      testWidgets('TC-061-034: EmptyHistoryWidgetにアイコンが表示される',
          (WidgetTester tester) async {
        // When: EmptyHistoryWidgetを表示する
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyHistoryWidget(),
            ),
          ),
        );

        // Then: 空状態を示すアイコンが表示される
        expect(
          find.byIcon(Icons.history),
          findsOneWidget,
          reason: '空状態アイコンが表示される必要がある',
        );
      });

      /// TC-061-035: 使い方のヒントが表示される
      testWidgets('TC-061-035: EmptyHistoryWidgetに使い方のヒントが表示される',
          (WidgetTester tester) async {
        // When: EmptyHistoryWidgetを表示する
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyHistoryWidget(),
            ),
          ),
        );

        // Then: 使い方のヒントが表示される
        expect(
          find.text('読み上げた内容が履歴として保存されます'),
          findsOneWidget,
          reason: '使い方のヒントが表示される必要がある',
        );
      });
    });
  });
}
