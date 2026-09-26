/// PhraseAddDialog ウィジェットテスト
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart';

void main() {
  group('PhraseAddDialog - 正常系テスト', () {
    // 追加ダイアログが正しく表示される
    /// PhraseAddDialogが正しく表示される
    testWidgets('TC-041-011: PhraseAddDialogが正しく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 結果検証: 各UI要素の存在を確認
      expect(find.text('定型文を追加'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    // 定型文を入力して保存できる
    /// 定型文を入力して保存ボタンで追加できる
    testWidgets('TC-041-012: 定型文を入力して保存ボタンで追加できる', (tester) async {
      String? savedContent;
      String? savedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseAddDialog(
                      onSave: (content, category) async {
                        savedContent = content;
                        savedCategory = category;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // テキストを入力
      await tester.enterText(find.byType(TextField), 'ありがとうございます');
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 結果検証: コールバックが正しいデータで呼び出されることを確認
      expect(savedContent, equals('ありがとうございます'));
      expect(savedCategory, equals('daily'));
    });

    // カテゴリを選択できる
    /// カテゴリ（日常/体調/その他）を選択できる
    testWidgets('TC-041-013: カテゴリを選択できる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 結果検証: カテゴリ選択UIの存在を確認
      expect(find.text('日常'), findsOneWidget);
      expect(find.text('体調'), findsOneWidget);
      expect(find.text('その他'), findsOneWidget);
    });

    // デフォルトカテゴリが日常である
    /// カテゴリのデフォルト値が「日常」である
    testWidgets('TC-041-014: カテゴリのデフォルト値が「日常」である', (tester) async {
      String? savedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseAddDialog(
                      onSave: (content, category) async {
                        savedCategory = category;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // テキストを入力
      await tester.enterText(find.byType(TextField), 'テスト');
      await tester.pumpAndSettle();

      // 保存ボタンをタップ（カテゴリ変更なし）
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 結果検証: デフォルトカテゴリが"daily"であることを確認
      expect(savedCategory, equals('daily'));
    });

    // 文字数カウンターが表示される
    /// 入力中に文字数カウンターが表示される
    testWidgets('TC-041-015: 入力中に文字数カウンターが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // テキストを入力
      await tester.enterText(find.byType(TextField), 'おはよう');
      await tester.pumpAndSettle();

      // 結果検証: 文字数カウンターが表示されることを確認
      expect(find.text('4/500'), findsOneWidget);
    });
  });

  group('PhraseAddDialog - 異常系テスト', () {
    // 空入力で保存するとエラー表示
    /// 空入力で保存しようとするとエラーメッセージが表示される
    testWidgets('TC-041-016: 空入力で保存しようとするとエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 空のまま保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 結果検証: エラーメッセージが表示されることを確認
      expect(find.text('定型文を入力してください'), findsOneWidget);
      // ダイアログがまだ表示されていることを確認
      expect(find.byType(PhraseAddDialog), findsOneWidget);
    });

    // 500文字超過時に入力が制限される
    /// 500文字を超える入力が制限される
    testWidgets('TC-041-017: 500文字を超える入力が制限される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 600文字のテキストを入力しようとする
      final longText = 'あ' * 600;
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      // 結果検証: 500文字で制限されていることを確認
      expect(find.text('500/500'), findsOneWidget);
    });

    // 500文字到達時にカウンターが警告色になる
    /// 500文字到達時に文字数カウンターが警告色で表示される
    testWidgets('TC-041-018: 500文字到達時に文字数カウンターが警告色で表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 500文字のテキストを入力
      final maxText = 'あ' * 500;
      await tester.enterText(find.byType(TextField), maxText);
      await tester.pumpAndSettle();

      // 結果検証: カウンターがテーマのエラー色で表示されていることを確認
      final counterFinder = find.text('500/500');
      expect(counterFinder, findsOneWidget);
      final counterWidget = tester.widget<Text>(counterFinder);
      final errorColor =
          Theme.of(tester.element(counterFinder)).colorScheme.error;
      expect(counterWidget.style?.color, equals(errorColor));
    });
  });

  group('PhraseAddDialog - キャンセル操作テスト', () {
    // キャンセルボタンでダイアログが閉じる
    /// キャンセルボタンタップでダイアログが閉じる
    testWidgets('TC-041-019: キャンセルボタンタップでダイアログが閉じる', (tester) async {
      bool saveCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseAddDialog(
                      onSave: (_, __) async {
                        saveCallbackCalled = true;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // テキストを入力
      await tester.enterText(find.byType(TextField), 'テスト入力');
      await tester.pumpAndSettle();

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // 結果検証: ダイアログが閉じ、コールバックが呼ばれていないことを確認
      expect(find.byType(PhraseAddDialog), findsNothing);
      expect(saveCallbackCalled, isFalse);
    });

    // ダイアログ外タップでダイアログが閉じる
    /// ダイアログ外タップでダイアログが閉じる
    testWidgets('TC-041-020: ダイアログ外タップでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // ダイアログ外をタップ（バリアをタップ）
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 結果検証: ダイアログが閉じることを確認
      expect(find.byType(PhraseAddDialog), findsNothing);
    });
  });

  group('PhraseAddDialog - アクセシビリティテスト', () {
    // 保存ボタンのタップターゲットが44px以上
    /// 保存ボタンのタップターゲットサイズが44px以上
    testWidgets('TC-041-021: 保存ボタンのタップターゲットサイズが44px以上', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PhraseAddDialog(),
                  );
                },
                child: const Text('ダイアログを開く'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('ダイアログを開く'));
      await tester.pumpAndSettle();

      // 結果検証: 保存ボタンのサイズを確認
      final saveButtonFinder = find.widgetWithText(ElevatedButton, '保存');
      expect(saveButtonFinder, findsOneWidget);
      final buttonSize = tester.getSize(saveButtonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
    });
  });

  // 台帳 L-197: 保存が返らないと、閉じる・戻るも止まったまま凍結していた。
  // 利用者は声で助けを呼べないので、待つ時間に上限を置き、入力を残して操作を返す。
  testWidgets('保存が返らなくても、上限の時間で凍結が解け、入力を残して閉じられる', (tester) async {
    final never = Completer<bool>(); // 書込が返らない（Hive が応答しない）状況
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PhraseAddDialog(
                onSave: (_, __) {
                  calls++;
                  return never.future;
                },
              ),
            ),
            child: const Text('ダイアログを開く'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ダイアログを開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'お水をください');
    await tester.tap(find.text('保存'));
    await tester.pump();

    // 上限の直前までは待機中（二重に送らない）
    await tester
        .pump(PhraseConstants.saveTimeout - const Duration(milliseconds: 1));
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'キャンセル'))
            .onPressed,
        isNull);

    // 上限を過ぎたら操作を返す。保存されたかは分からないので、そう告げて入力を残す
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('保存を確認できませんでした。入力内容を残しています。'), findsOneWidget);
    expect(find.text('お水をください'), findsOneWidget);

    // 再試行できる（同じ key へ保存されるので、遅れて成功しても 2 件にならない：L-143）
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(calls, 2);
    await tester.pump(PhraseConstants.saveTimeout);
    await tester.pump();

    // 閉じられる
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseAddDialog), findsNothing);
  });
}
