/// PhraseDeleteDialog ウィジェットテスト
///
/// TASK-0041: 定型文CRUD機能実装
/// テストケース: TC-041-028〜TC-041-031
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart
///
/// 【TDD Redフェーズ】: ダイアログが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
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
    // =========================================================================
    // TC-041-028: 削除確認ダイアログが表示される
    // =========================================================================
    /// TC-041-028: 削除操作時に確認ダイアログが表示される
    ///
    /// 【テスト目的】: 削除確認の表示確認
    /// 【テスト内容】: 削除確認ダイアログの表示
    /// 【期待される動作】: "この定型文を削除しますか？" メッセージと削除・キャンセルボタン
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-101, CRUD-204, AC-005
    /// 優先度: P0 必須
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

      // 【結果検証】: 確認ダイアログの要素を確認
      expect(find.text('この定型文を削除しますか？'), findsOneWidget); // 【確認内容】: メッセージ 🔵
      expect(find.text('削除'), findsOneWidget); // 【確認内容】: 削除ボタン 🔵
      expect(find.text('キャンセル'), findsOneWidget); // 【確認内容】: キャンセルボタン 🔵
    });

    // =========================================================================
    // TC-041-029: 確認後に削除が実行される
    // =========================================================================
    /// TC-041-029: 確認ダイアログで「削除」選択後に削除が実行される
    ///
    /// 【テスト目的】: 削除実行の確認
    /// 【テスト内容】: 削除の実行
    /// 【期待される動作】: 定型文が削除される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-102, AC-006
    /// 優先度: P0 必須
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

      // 【結果検証】: 削除コールバックが呼び出されることを確認
      expect(deleteConfirmed, isTrue); // 【確認内容】: コールバック呼び出し 🔵
    });

    // =========================================================================
    // TC-041-030: キャンセルで削除が中止される
    // =========================================================================
    /// TC-041-030: 確認ダイアログで「キャンセル」選択後に削除が中止される
    ///
    /// 【テスト目的】: キャンセル操作の確認
    /// 【テスト内容】: 削除のキャンセル
    /// 【期待される動作】: 定型文が削除されない
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-103
    /// 優先度: P0 必須
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

      // 【結果検証】: 削除コールバックが呼び出されていないことを確認
      expect(deleteConfirmed, isFalse); // 【確認内容】: 削除コールバック未発火 🔵
      expect(cancelCalled, isTrue); // 【確認内容】: キャンセルコールバック発火 🔵
      expect(find.byType(PhraseDeleteDialog),
          findsNothing); // 【確認内容】: ダイアログが閉じている 🔵
    });
  });

  group('PhraseDeleteDialog - 誤操作防止テスト', () {
    // =========================================================================
    // TC-041-031: 削除確認ダイアログ外タップで閉じない
    // =========================================================================
    /// TC-041-031: 削除確認ダイアログ外タップでダイアログが閉じない
    ///
    /// 【テスト目的】: 誤操作防止の確認
    /// 【テスト内容】: 誤操作防止
    /// 【期待される動作】: バリアタップでダイアログが閉じない
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: EDGE-013, REQ-5002
    /// 優先度: P0 必須
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

      // 【結果検証】: ダイアログがまだ表示されていることを確認
      expect(find.byType(PhraseDeleteDialog),
          findsOneWidget); // 【確認内容】: ダイアログ状態 🔵
    });
  });
}
