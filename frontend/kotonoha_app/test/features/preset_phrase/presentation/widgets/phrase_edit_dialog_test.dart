/// PhraseEditDialog ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // テストデータ準備

  /// テストデータ準備: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    int displayOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      displayOrder: displayOrder,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('PhraseEditDialog - 正常系テスト', () {
    // 編集ダイアログが現在の内容で表示される
    /// PhraseEditDialogが現在の定型文内容を初期表示する
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

      // 結果検証: 初期値が表示されていることを確認
      expect(find.text('定型文を編集'), findsOneWidget);
      // TextFieldに初期値が設定されていることを確認
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('こんにちは'));
      expect(find.text('日常'), findsOneWidget);
    });

    // 定型文を編集して保存できる
    /// 定型文を編集して保存ボタンで更新できる
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

      // 結果検証: 更新されたデータでコールバックが呼び出されることを確認
      expect(savedPhrase, isNotNull);
      expect(savedPhrase?.content, equals('こんばんは'));
      expect(savedPhrase?.id, equals('1'));
    });

    // カテゴリを変更して保存できる
    /// カテゴリを変更して保存できる
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

      // 結果検証: カテゴリが更新されていることを確認
      expect(savedPhrase?.category, equals('health'));
    });

    // 編集時にupdatedAtが更新される
    /// 編集保存時にupdatedAtタイムスタンプが更新される
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

      // 結果検証: updatedAtが更新されていることを確認
      expect(savedPhrase?.updatedAt.isAfter(oldDate), isTrue);
      expect(savedPhrase?.createdAt, equals(oldDate));
    });
  });

  group('PhraseEditDialog - 異常系テスト', () {
    // 編集時に空にするとエラー表示
    /// 既存の内容を空にして保存しようとするとエラー表示
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

      // 結果検証: エラーメッセージが表示されることを確認
      expect(find.text('定型文を入力してください'), findsOneWidget);
    });

    // 編集キャンセル時に変更が破棄される
    /// 編集中にキャンセルすると変更が破棄される
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

      // 結果検証: コールバックが呼び出されていないことを確認
      expect(saveCallbackCalled, isFalse);
      expect(find.byType(PhraseEditDialog), findsNothing);
    });
  });
}
