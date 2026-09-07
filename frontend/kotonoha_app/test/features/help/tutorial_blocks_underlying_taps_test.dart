/// チュートリアル表示中の遮蔽（Issue #84 の根本原因の記録）
/// この挙動は仕様である: `TutorialOverlay` は
/// `Container(color: Colors.black54)` で画面全体を覆い、配下へのタップを
/// ヒットテストで吸収する。緊急ボタンだけは意図的に手前へ置かれ
/// チュートリアル表示中も操作できる（`app_shell.dart` の
/// 「安全性（重要）」コメント。, ）。
/// なぜテストとして残すか: E2E（Issue #84）はストレージが空のまま
/// 起動するため初回起動扱いになり、この遮蔽で**操作を伴うテストが軒並み
/// 落ちていた**。「ウィジェットは見つかる・タップは実行される・状態は変わらない」
/// という症状で、`Found 0 widgets with text` が62件。操作を一切しない
/// `app_startup_test.dart` だけが通っていた。
/// Issue #84 は原因を「ヘッドレスWebで失敗」「テストの陳腐化」としていたが
/// **どちらも誤り**だった。ホストVMのウィジェットテストで再現し
/// プラットフォームとは無関係だった。
/// 受け皿は `integration_test/helpers/test_helpers.dart` の `pumpApp`
/// （`completeTutorial` 既定 true）。ここでその前提を固定する。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 入力欄に文字が入ったかを、画面上の出現数の増加で判定する
/// 文字盤のキーと入力欄の両方に出るため、届いていれば数が増える。
int occurrencesOf(String character) => find.text(character).evaluate().length;

Future<void> pumpAppWith(
  WidgetTester tester, {
  required bool tutorialCompleted,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (tutorialCompleted) 'tutorial_completed': true,
  });

  await tester.pumpWidget(const ProviderScope(child: KotonohaApp()));
  await tester.pumpAndSettle();
}

void main() {
  group('チュートリアル表示中の遮蔽', () {
    testWidgets('未完了なら表示され、文字盤のタップが配下に届かない', (tester) async {
      await pumpAppWith(tester, tutorialCompleted: false);

      expect(
        find.textContaining('ようこそ'),
        findsOneWidget,
        reason: 'ストレージが空なら初回起動としてチュートリアルが出るはず',
      );

      final before = occurrencesOf('あ');
      await tester.tap(find.text('あ').first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        occurrencesOf('あ'),
        before,
        reason: 'チュートリアル表示中はタップが吸収されるため、入力欄に入らない',
      );
    });

    testWidgets('完了済みなら表示されず、文字盤のタップが届く', (tester) async {
      await pumpAppWith(tester, tutorialCompleted: true);

      expect(find.textContaining('ようこそ'), findsNothing);

      final before = occurrencesOf('あ');
      await tester.tap(find.text('あ').first);
      await tester.pumpAndSettle();

      expect(
        occurrencesOf('あ'),
        greaterThan(before),
        reason: 'チュートリアルが出ていなければタップが入力欄に届くはず',
      );
    });
  });
}
