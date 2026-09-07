/// AI変換結果ダイアログのShellRoute構造下での動作確認テスト（P0回帰防止）
/// 背景（バグの再現条件）
/// showDialogはデフォルトでroot Navigatorにダイアログを積む一方
/// 呼び出し元contextはgo_routerのShellRoute配下branch Navigatorに属する。
/// 旧実装ではコールバック内でNavigator.of(呼び出し元context).popしていたため
/// ダイアログではなくbranch Navigatorの背後ページがpopされ
/// リリースビルドで画面が空白になり再操作不能になっていた。
/// 本テストはShellRoute（branch Navigator）+ showDialog（root Navigator）の
/// 実機と同じ二重Navigator構造を再現し、ボタンタップ後に
/// 「ダイアログが閉じる」「コールバックが正しい引数で1回だけ呼ばれる」
/// 「背後ページが残る」ことを検証する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';

void main() {
  group('AIConversionResultDialog.show（ShellRoute二重Navigator構造）', () {
    late GoRouter router;
    late int adoptCallCount;
    late int regenerateCallCount;
    late int useOriginalCallCount;
    late String? adoptedText;
    late String? usedOriginalText;

    /// 実機と同じ「単一ShellRoute配下にGoRoute」の構造を構築する。
    /// branch Navigator上のページに配置したボタンから
    /// AIConversionResultDialog.show を呼び出す。
    Widget buildTestApp() {
      return MaterialApp.router(routerConfig: router);
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('ShowDialog'));
      await tester.pumpAndSettle();
    }

    /// ダイアログのアクションボタンをAlertDialog配下に限定して検索する
    /// （branchページ側にも同名テキストが存在しうるため）。
    /// 「採用」「再生成」はElevatedButton、「元の文を使う」はOutlinedButton。
    Finder actionButton(String label) => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(label),
        );

    setUp(() {
      adoptCallCount = 0;
      regenerateCallCount = 0;
      useOriginalCallCount = 0;
      adoptedText = null;
      usedOriginalText = null;

      router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => Scaffold(body: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Builder(
                  builder: (pageContext) => Scaffold(
                    appBar: AppBar(title: const Text('Home')),
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          AIConversionResultDialog.show(
                            context: pageContext,
                            originalText: '水 ぬるく',
                            convertedText: 'お水をぬるめでお願いします',
                            politenessLevel: PolitenessLevel.polite,
                            onAdopt: (result) {
                              adoptCallCount++;
                              adoptedText = result;
                            },
                            onRegenerate: () => regenerateCallCount++,
                            onUseOriginal: (original) {
                              useOriginalCallCount++;
                              usedOriginalText = original;
                            },
                          );
                        },
                        child: const Text('ShowDialog'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });

    tearDown(() {
      router.dispose();
    });

    testWidgets('採用タップでダイアログのみ閉じ、背後ページは維持される', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await openDialog(tester);

      expect(find.byType(AIConversionResultDialog), findsOneWidget);

      await tester.tap(actionButton('採用'));
      await tester.pumpAndSettle();

      // ダイアログが閉じていること
      expect(
        find.byType(AIConversionResultDialog),
        findsNothing,
        reason: '採用タップでダイアログ自身が閉じられる必要がある',
      );
      // 背後のbranchページがpopされておらず表示されたままであること
      expect(
        find.text('Home'),
        findsOneWidget,
        reason: 'branch Navigatorの背後ページが誤ってpopされてはならない',
      );
      expect(adoptCallCount, 1);
      expect(regenerateCallCount, 0);
      expect(useOriginalCallCount, 0);
      expect(adoptedText, 'お水をぬるめでお願いします');
    });

    testWidgets('再生成タップでダイアログのみ閉じ、背後ページは維持される', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await openDialog(tester);

      await tester.tap(actionButton('再生成'));
      await tester.pumpAndSettle();

      expect(find.byType(AIConversionResultDialog), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(regenerateCallCount, 1);
      expect(adoptCallCount, 0);
      expect(useOriginalCallCount, 0);
    });

    testWidgets('元の文を使うタップでダイアログのみ閉じ、背後ページは維持される', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await openDialog(tester);

      await tester.tap(actionButton('元の文を使う'));
      await tester.pumpAndSettle();

      expect(find.byType(AIConversionResultDialog), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(useOriginalCallCount, 1);
      expect(adoptCallCount, 0);
      expect(usedOriginalText, '水 ぬるく');
    });
  });
}
