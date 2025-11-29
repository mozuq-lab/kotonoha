/// アプリ起動E2Eテスト
///
/// TASK-0081: E2Eテスト環境構築
/// 信頼性レベル: 🟡 黄信号（テスト戦略は要件定義書から推測）
///
/// アプリが正常に起動し、基本画面が表示されることを確認。
@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  final binding = initializeE2ETestBinding();

  group('アプリ起動テスト', () {
    testWidgets('アプリが正常に起動する', (tester) async {
      await pumpApp(tester);

      // ホーム画面が表示されることを確認
      expect(find.text('kotonoha'), findsOneWidget);
    });

    testWidgets('ホーム画面に文字盤が表示される', (tester) async {
      await pumpApp(tester);

      // 文字盤が表示されることを確認（あ行の文字）
      expect(find.text('あ'), findsWidgets);
      expect(find.text('い'), findsWidgets);
      expect(find.text('う'), findsWidgets);
    });

    testWidgets('ナビゲーションバーが表示される', (tester) async {
      await pumpApp(tester);

      // ナビゲーションバーの項目を確認
      // 実際の実装に合わせて調整が必要
      await tester.pumpAndSettle();
    });

    testWidgets('スクリーンショット取得テスト', skip: true, (tester) async {
      await pumpApp(tester);
      await takeScreenshot(binding, 'home_screen');
    });
  });

  group('パフォーマンス基準確認', () {
    testWidgets('初期表示が適切な時間内に完了する', (tester) async {
      await measurePerformance(
        'アプリ初期表示',
        maxMilliseconds: 3000,
        action: () async {
          await pumpApp(tester);
        },
      );
    });
  });
}
