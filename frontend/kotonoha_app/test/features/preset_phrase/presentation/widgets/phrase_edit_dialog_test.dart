/// PhraseEditDialog ウィジェットテスト
///
/// TASK-0041: 定型文CRUD機能実装
/// テストケース: TC-041-022〜TC-041-027
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart
///
/// 【TDD Redフェーズ】: ダイアログが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // ==========================================================================
  // テストデータ準備
  // ==========================================================================

  /// 【テストデータ準備】: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    bool isFavorite = false,
    int displayOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      isFavorite: isFavorite,
      displayOrder: displayOrder,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('PhraseEditDialog - 正常系テスト', () {
    // =========================================================================
    // TC-041-022: 編集ダイアログが現在の内容で表示される
    // =========================================================================
    /// TC-041-022: PhraseEditDialogが現在の定型文内容を初期表示する
    ///
    /// 【テスト目的】: 初期表示の確認
    /// 【テスト内容】: 編集ダイアログの初期表示
    /// 【期待される動作】: 既存の内容とカテゴリが入力済みで表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-004, CRUD-005, AC-003
    /// 優先度: P0 必須
    testWidgets('TC-041-022: PhraseEditDialogが現在の定型文内容を初期表示する', (tester) async {
      final phrase =
          createTestPhrase(id: '1', content: 'こんにちは', category: 'daily');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseEditDialog(phrase: phrase),
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

      // 【結果検証】: 初期値が表示されていることを確認
      expect(find.text('定型文を編集'), findsOneWidget); // 【確認内容】: タイトル 🔵
      // TextFieldに初期値が設定されていることを確認
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('こんにちは')); // 【確認内容】: 内容の初期値 🔵
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: カテゴリの初期値 🔵
    });

    // =========================================================================
    // TC-041-023: 定型文を編集して保存できる
    // =========================================================================
    /// TC-041-023: 定型文を編集して保存ボタンで更新できる
    ///
    /// 【テスト目的】: 編集操作の確認
    /// 【テスト内容】: 編集操作の基本フロー
    /// 【期待される動作】: 編集→保存→ダイアログ閉じる→コールバック発火
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-004
    /// 優先度: P0 必須
    testWidgets('TC-041-023: 定型文を編集して保存ボタンで更新できる', (tester) async {
      final phrase =
          createTestPhrase(id: '1', content: 'こんにちは', category: 'daily');
      PresetPhrase? savedPhrase;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseEditDialog(
                      phrase: phrase,
                      onSave: (updated) {
                        savedPhrase = updated;
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

      // テキストを変更
      await tester.enterText(find.byType(TextField), 'こんばんは');
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 【結果検証】: 更新されたデータでコールバックが呼び出されることを確認
      expect(savedPhrase, isNotNull); // 【確認内容】: コールバック発火 🔵
      expect(savedPhrase?.content, equals('こんばんは')); // 【確認内容】: 内容が更新されている 🔵
      expect(savedPhrase?.id, equals('1')); // 【確認内容】: IDは変更されない 🔵
    });

    // =========================================================================
    // TC-041-024: カテゴリを変更して保存できる
    // =========================================================================
    /// TC-041-024: カテゴリを変更して保存できる
    ///
    /// 【テスト目的】: カテゴリ変更の確認
    /// 【テスト内容】: カテゴリ変更機能
    /// 【期待される動作】: カテゴリ変更が反映される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-004
    /// 優先度: P0 必須
    testWidgets('TC-041-024: カテゴリを変更して保存できる', (tester) async {
      final phrase =
          createTestPhrase(id: '1', content: 'テスト', category: 'daily');
      PresetPhrase? savedPhrase;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseEditDialog(
                      phrase: phrase,
                      onSave: (updated) {
                        savedPhrase = updated;
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

      // カテゴリを変更（体調を選択）
      await tester.tap(find.text('体調'));
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 【結果検証】: カテゴリが更新されていることを確認
      expect(savedPhrase?.category,
          equals('health')); // 【確認内容】: コールバックのcategory引数 🔵
    });

    // =========================================================================
    // TC-041-025: 編集時にupdatedAtが更新される
    // =========================================================================
    /// TC-041-025: 編集保存時にupdatedAtタイムスタンプが更新される
    ///
    /// 【テスト目的】: タイムスタンプ更新の確認
    /// 【テスト内容】: タイムスタンプ更新
    /// 【期待される動作】: updatedAtが現在時刻に更新される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: CRUD-008
    /// 優先度: P1 重要
    testWidgets('TC-041-025: 編集保存時にupdatedAtタイムスタンプが更新される', (tester) async {
      final oldDate = DateTime(2023, 1, 1);
      final phrase = createTestPhrase(
        id: '1',
        content: 'テスト',
        category: 'daily',
        createdAt: oldDate,
        updatedAt: oldDate,
      );
      PresetPhrase? savedPhrase;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseEditDialog(
                      phrase: phrase,
                      onSave: (updated) {
                        savedPhrase = updated;
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

      // テキストを変更
      await tester.enterText(find.byType(TextField), '更新後のテスト');
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 【結果検証】: updatedAtが更新されていることを確認
      expect(savedPhrase?.updatedAt.isAfter(oldDate),
          isTrue); // 【確認内容】: updatedAtの値 🟡
      expect(savedPhrase?.createdAt,
          equals(oldDate)); // 【確認内容】: createdAtは変更されない 🟡
    });
  });

  group('PhraseEditDialog - 異常系テスト', () {
    // =========================================================================
    // TC-041-026: 編集時に空にするとエラー表示
    // =========================================================================
    /// TC-041-026: 既存の内容を空にして保存しようとするとエラー表示
    ///
    /// 【テスト目的】: 編集時バリデーションの確認
    /// 【テスト内容】: 編集時の空入力チェック
    /// 【期待される動作】: エラーメッセージ表示
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-105
    /// 優先度: P0 必須
    testWidgets('TC-041-026: 既存の内容を空にして保存しようとするとエラー表示', (tester) async {
      final phrase =
          createTestPhrase(id: '1', content: 'テスト', category: 'daily');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseEditDialog(phrase: phrase),
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

      // テキストを空にする
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 【結果検証】: エラーメッセージが表示されることを確認
      expect(find.text('定型文を入力してください'), findsOneWidget); // 【確認内容】: エラーメッセージ 🔵
    });

    // =========================================================================
    // TC-041-027: 編集キャンセル時に変更が破棄される
    // =========================================================================
    /// TC-041-027: 編集中にキャンセルすると変更が破棄される
    ///
    /// 【テスト目的】: キャンセル時の動作確認
    /// 【テスト内容】: キャンセル時の状態復元
    /// 【期待される動作】: 元の内容が維持される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: EDGE-014
    /// 優先度: P0 必須
    testWidgets('TC-041-027: 編集中にキャンセルすると変更が破棄される', (tester) async {
      final phrase =
          createTestPhrase(id: '1', content: 'テスト', category: 'daily');
      bool saveCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseEditDialog(
                      phrase: phrase,
                      onSave: (_) {
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

      // テキストを変更
      await tester.enterText(find.byType(TextField), '変更後のテスト');
      await tester.pumpAndSettle();

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // 【結果検証】: コールバックが呼び出されていないことを確認
      expect(saveCallbackCalled, isFalse); // 【確認内容】: コールバック未発火 🔵
      expect(find.byType(PhraseEditDialog),
          findsNothing); // 【確認内容】: ダイアログが閉じている 🔵
    });
  });
}
