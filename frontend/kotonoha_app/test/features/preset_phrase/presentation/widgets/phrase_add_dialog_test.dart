/// PhraseAddDialog ウィジェットテスト
///
/// TASK-0041: 定型文CRUD機能実装
/// テストケース: TC-041-011〜TC-041-021
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart
///
/// 【TDD Redフェーズ】: ダイアログが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart';

void main() {
  group('PhraseAddDialog - 正常系テスト', () {
    // =========================================================================
    // TC-041-011: 追加ダイアログが正しく表示される
    // =========================================================================
    /// TC-041-011: PhraseAddDialogが正しく表示される
    ///
    /// 【テスト目的】: ダイアログ表示の確認
    /// 【テスト内容】: ダイアログの基本表示
    /// 【期待される動作】: タイトル、入力フィールド、ボタンが表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-001, CRUD-002, AC-001
    /// 優先度: P0 必須
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

      // 【結果検証】: 各UI要素の存在を確認
      expect(find.text('定型文を追加'), findsOneWidget); // 【確認内容】: タイトル表示 🔵
      expect(find.byType(TextField), findsOneWidget); // 【確認内容】: テキストフィールド 🔵
      expect(find.text('保存'), findsOneWidget); // 【確認内容】: 保存ボタン 🔵
      expect(find.text('キャンセル'), findsOneWidget); // 【確認内容】: キャンセルボタン 🔵
    });

    // =========================================================================
    // TC-041-012: 定型文を入力して保存できる
    // =========================================================================
    /// TC-041-012: 定型文を入力して保存ボタンで追加できる
    ///
    /// 【テスト目的】: 追加操作の確認
    /// 【テスト内容】: 追加操作の基本フロー
    /// 【期待される動作】: 入力→保存→ダイアログ閉じる→コールバック発火
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-002
    /// 優先度: P0 必須
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
                      onSave: (content, category) {
                        savedContent = content;
                        savedCategory = category;
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

      // 【結果検証】: コールバックが正しいデータで呼び出されることを確認
      expect(savedContent, equals('ありがとうございます')); // 【確認内容】: 内容が正しい 🔵
      expect(savedCategory, equals('daily')); // 【確認内容】: デフォルトカテゴリ 🔵
    });

    // =========================================================================
    // TC-041-013: カテゴリを選択できる
    // =========================================================================
    /// TC-041-013: カテゴリ（日常/体調/その他）を選択できる
    ///
    /// 【テスト目的】: カテゴリ選択の確認
    /// 【テスト内容】: カテゴリ選択機能
    /// 【期待される動作】: ドロップダウンまたはラジオボタンでカテゴリ選択可能
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-002
    /// 優先度: P0 必須
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

      // 【結果検証】: カテゴリ選択UIの存在を確認
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: 日常カテゴリ 🔵
      expect(find.text('体調'), findsOneWidget); // 【確認内容】: 体調カテゴリ 🔵
      expect(find.text('その他'), findsOneWidget); // 【確認内容】: その他カテゴリ 🔵
    });

    // =========================================================================
    // TC-041-014: デフォルトカテゴリが日常である
    // =========================================================================
    /// TC-041-014: カテゴリのデフォルト値が「日常」である
    ///
    /// 【テスト目的】: デフォルト値の確認
    /// 【テスト内容】: 初期値設定
    /// 【期待される動作】: ダイアログ表示時に「日常」が選択済み
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: CRUD-002
    /// 優先度: P1 重要
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
                      onSave: (content, category) {
                        savedCategory = category;
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

      // 【結果検証】: デフォルトカテゴリが"daily"であることを確認
      expect(savedCategory, equals('daily')); // 【確認内容】: 初期選択状態 🟡
    });

    // =========================================================================
    // TC-041-015: 文字数カウンターが表示される
    // =========================================================================
    /// TC-041-015: 入力中に文字数カウンターが表示される
    ///
    /// 【テスト目的】: 文字数カウンターの確認
    /// 【テスト内容】: 文字数表示機能
    /// 【期待される動作】: "XX/500" 形式で文字数が表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: CRUD-104
    /// 優先度: P1 重要
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

      // 【結果検証】: 文字数カウンターが表示されることを確認
      expect(find.text('4/500'), findsOneWidget); // 【確認内容】: カウンター表示 🟡
    });
  });

  group('PhraseAddDialog - 異常系テスト', () {
    // =========================================================================
    // TC-041-016: 空入力で保存するとエラー表示
    // =========================================================================
    /// TC-041-016: 空入力で保存しようとするとエラーメッセージが表示される
    ///
    /// 【テスト目的】: エラー表示の確認
    /// 【テスト内容】: 空入力のエラーハンドリング
    /// 【期待される動作】: エラーメッセージ表示、ダイアログは閉じない
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-009, CRUD-105
    /// 優先度: P0 必須
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

      // 【結果検証】: エラーメッセージが表示されることを確認
      expect(
          find.text('定型文を入力してください'), findsOneWidget); // 【確認内容】: エラーメッセージの存在 🔵
      // ダイアログがまだ表示されていることを確認
      expect(
          find.byType(PhraseAddDialog), findsOneWidget); // 【確認内容】: ダイアログ状態 🔵
    });

    // =========================================================================
    // TC-041-017: 500文字超過時に入力が制限される
    // =========================================================================
    /// TC-041-017: 500文字を超える入力が制限される
    ///
    /// 【テスト目的】: 入力制限の確認
    /// 【テスト内容】: 文字数制限機能
    /// 【期待される動作】: 500文字で入力がストップする
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-010, CRUD-104
    /// 優先度: P0 必須
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

      // 【結果検証】: 500文字で制限されていることを確認
      expect(find.text('500/500'), findsOneWidget); // 【確認内容】: 実際の入力文字数 🔵
    });

    // =========================================================================
    // TC-041-018: 500文字到達時にカウンターが赤くなる
    // =========================================================================
    /// TC-041-018: 500文字到達時に文字数カウンターが赤く表示される
    ///
    /// 【テスト目的】: 警告表示の確認
    /// 【テスト内容】: 警告表示
    /// 【期待される動作】: "500/500" が赤色で表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: CRUD-104
    /// 優先度: P1 重要
    testWidgets('TC-041-018: 500文字到達時に文字数カウンターが赤く表示される', (tester) async {
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

      // 【結果検証】: カウンターが赤色で表示されていることを確認
      final counterFinder = find.text('500/500');
      expect(counterFinder, findsOneWidget);
      final counterWidget = tester.widget<Text>(counterFinder);
      expect(
          counterWidget.style?.color, equals(Colors.red)); // 【確認内容】: テキストの色 🟡
    });
  });

  group('PhraseAddDialog - キャンセル操作テスト', () {
    // =========================================================================
    // TC-041-019: キャンセルボタンでダイアログが閉じる
    // =========================================================================
    /// TC-041-019: キャンセルボタンタップでダイアログが閉じる
    ///
    /// 【テスト目的】: キャンセル操作の確認
    /// 【テスト内容】: キャンセル操作
    /// 【期待される動作】: ダイアログが閉じ、データは保存されない
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: EDGE-014
    /// 優先度: P0 必須
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
                      onSave: (_, __) {
                        saveCallbackCalled = true;
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

      // 【結果検証】: ダイアログが閉じ、コールバックが呼ばれていないことを確認
      expect(find.byType(PhraseAddDialog), findsNothing); // 【確認内容】: ダイアログ状態 🔵
      expect(saveCallbackCalled, isFalse); // 【確認内容】: コールバック 🔵
    });

    // =========================================================================
    // TC-041-020: ダイアログ外タップでダイアログが閉じる
    // =========================================================================
    /// TC-041-020: ダイアログ外タップでダイアログが閉じる
    ///
    /// 【テスト目的】: バリアタップの確認
    /// 【テスト内容】: バリアタップ動作
    /// 【期待される動作】: ダイアログが閉じる
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: EDGE-012
    /// 優先度: P1 重要
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

      // 【結果検証】: ダイアログが閉じることを確認
      expect(find.byType(PhraseAddDialog), findsNothing); // 【確認内容】: ダイアログ状態 🟡
    });
  });

  group('PhraseAddDialog - アクセシビリティテスト', () {
    // =========================================================================
    // TC-041-021: 保存ボタンのタップターゲットが44px以上
    // =========================================================================
    /// TC-041-021: 保存ボタンのタップターゲットサイズが44px以上
    ///
    /// 【テスト目的】: タップターゲットサイズ確認
    /// 【テスト内容】: アクセシビリティ要件
    /// 【期待される動作】: ボタンサイズが44px以上
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-203, AC-014
    /// 優先度: P0 必須
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

      // 【結果検証】: 保存ボタンのサイズを確認
      final saveButtonFinder = find.widgetWithText(ElevatedButton, '保存');
      expect(saveButtonFinder, findsOneWidget);
      final buttonSize = tester.getSize(saveButtonFinder);
      expect(buttonSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget)); // 【確認内容】: ウィジェットサイズ 🔵
    });
  });
}
