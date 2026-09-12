/// PhraseDeleteDialog ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // テストデータ準備

  /// テストデータ準備: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    int displayOrder = 0,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      displayOrder: displayOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PhraseDeleteDialog - 正常系テスト', () {
    // 削除確認ダイアログが表示される
    /// 削除操作時に確認ダイアログが表示される
    testWidgets('TC-041-028: 削除操作時に確認ダイアログが表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'テスト定型文');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseDeleteDialog(phrase: phrase),
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

      // 結果検証: 確認ダイアログの要素を確認
      expect(find.text('この定型文を削除しますか？'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    // 確認後に削除が実行される
    /// 確認ダイアログで「削除」選択後に削除が実行される
    testWidgets('TC-041-029: 確認ダイアログで「削除」選択後に削除が実行される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'テスト定型文');
      bool deleteConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseDeleteDialog(
                      phrase: phrase,
                      onConfirm: () {
                        deleteConfirmed = true;
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

      // 削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // 結果検証: 削除コールバックが呼び出されることを確認
      expect(deleteConfirmed, isTrue);
    });

    // キャンセルで削除が中止される
    /// 確認ダイアログで「キャンセル」選択後に削除が中止される
    testWidgets('TC-041-030: 確認ダイアログで「キャンセル」選択後に削除が中止される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'テスト定型文');
      bool deleteConfirmed = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PhraseDeleteDialog(
                      phrase: phrase,
                      onConfirm: () {
                        deleteConfirmed = true;
                      },
                      onCancel: () {
                        cancelCalled = true;
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

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // 結果検証: 削除コールバックが呼び出されていないことを確認
      expect(deleteConfirmed, isFalse);
      expect(cancelCalled, isTrue);
      expect(find.byType(PhraseDeleteDialog), findsNothing);
    });
  });

  group('PhraseDeleteDialog - 誤操作防止テスト', () {
    // 削除確認ダイアログ外タップで閉じない
    /// 削除確認ダイアログ外タップでダイアログが閉じない
    testWidgets('TC-041-031: 削除確認ダイアログ外タップでダイアログが閉じない', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'テスト定型文');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false, // 誤操作防止のため
                    builder: (_) => PhraseDeleteDialog(phrase: phrase),
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

      // ダイアログが表示されていることを確認
      expect(find.byType(PhraseDeleteDialog), findsOneWidget);

      // ダイアログ外をタップ
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 結果検証: ダイアログがまだ表示されていることを確認
      expect(find.byType(PhraseDeleteDialog), findsOneWidget);
    });
  });

  group('PhraseDeleteDialog - お気に入りへの影響の告知', () {
    // ADR-005（2026-09-13）: 定型文を削除してもお気に入りは残るので、
    /// 削除確認ダイアログはお気に入りに関する文言を出さない
    testWidgets('お気に入りに関する文言は出ない', (tester) async {
      final phrase = createTestPhrase(
        id: 'phrase-1',
        content: 'こんにちは',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PhraseDeleteDialog(phrase: phrase),
                ),
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('この定型文を削除しますか？'), findsOneWidget);
      // 結果検証: お気に入りに関する文言が出ないこと（残るので告知しない）
      expect(find.textContaining('お気に入り'), findsNothing);
    });
  });
}
