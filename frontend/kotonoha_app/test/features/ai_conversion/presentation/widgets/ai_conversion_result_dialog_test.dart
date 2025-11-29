/// AI変換結果表示・選択ダイアログ ウィジェットテスト
///
/// TASK-0069: AI変換結果表示・選択UI
/// テストケース: TC-069-001〜TC-069-022
///
/// テスト対象: lib/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';

void main() {
  group('TASK-0069: AI変換結果表示・選択UIテスト', () {
    // =========================================================================
    // テスト用ヘルパーメソッド
    // =========================================================================

    /// ダイアログ表示用のテストウィジェットを構築
    Widget buildTestWidget({
      required String originalText,
      required String convertedText,
      required PolitenessLevel politenessLevel,
      required void Function(String) onAdopt,
      required VoidCallback onRegenerate,
      required void Function(String) onUseOriginal,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme ?? lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AIConversionResultDialog.show(
                  context: context,
                  originalText: originalText,
                  convertedText: convertedText,
                  politenessLevel: politenessLevel,
                  onAdopt: onAdopt,
                  onRegenerate: onRegenerate,
                  onUseOriginal: onUseOriginal,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    /// ダイアログを開くヘルパーメソッド
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    // =========================================================================
    // 1. 正常系テストケース（表示テスト）
    // =========================================================================
    group('1. 正常系テストケース（表示テスト）', () {
      /// TC-069-001: ダイアログが正しく表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      /// 検証内容: AIConversionResultDialogがshowDialogで正しく表示されること
      testWidgets('TC-069-001: ダイアログが正しく表示される', (tester) async {
        // 【テスト目的】: AI変換結果ダイアログが正しくレンダリングされることを確認 🔵
        // 【テスト内容】: AIConversionResultDialogをshowDialogで表示し、ウィジェットが存在することを検証
        // 【期待される動作】: ダイアログがモーダルとして表示される
        // 🔵 青信号: REQ-902「AI変換結果を自動的に表示」に基づく

        // Given: 【テストデータ準備】: 標準的なAI変換データでダイアログを構築
        // 【初期条件設定】: 典型的なAI変換の入出力パターン
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: ダイアログが表示されていることを確認
        // 【期待値確認】: REQ-902に基づく
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        ); // 【確認内容】: ダイアログウィジェットが存在すること 🔵
      });

      /// TC-069-002: タイトル「AI変換結果」が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      testWidgets('TC-069-002: タイトル「AI変換結果」が表示される', (tester) async {
        // 【テスト目的】: ダイアログのタイトルが正しく表示されることを確認 🔵
        // 【テスト内容】: ダイアログを表示し、「AI変換結果」というタイトルが存在することを検証
        // 【期待される動作】: 「AI変換結果」テキストが表示される
        // 🔵 青信号: UI設計に基づく

        // Given: 【テストデータ準備】: ダイアログ表示用のウィジェットを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: タイトルが表示されていることを確認
        expect(
          find.text('AI変換結果'),
          findsOneWidget,
        ); // 【確認内容】: タイトルテキストが存在すること 🔵
      });

      /// TC-069-003: 元の文が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      testWidgets('TC-069-003: 元の文が表示される', (tester) async {
        // 【テスト目的】: originalTextがダイアログ内に表示されることを確認 🔵
        // 【テスト内容】: 「元の文」ラベルと入力テキストが表示されることを検証
        // 【期待される動作】: 「元の文」セクションに元の入力テキストが表示される
        // 🔵 青信号: REQ-902の比較表示機能に基づく

        // Given: 【テストデータ準備】: 元のテキストを設定
        const testOriginalText = '水 ぬるく';

        await tester.pumpWidget(
          buildTestWidget(
            originalText: testOriginalText,
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: ラベルとテキストが表示されていることを確認
        expect(
          find.text('元の文'),
          findsOneWidget,
        ); // 【確認内容】: 「元の文」ラベルが存在すること 🔵
        expect(
          find.text(testOriginalText),
          findsOneWidget,
        ); // 【確認内容】: 元のテキストが表示されていること 🔵
      });

      /// TC-069-004: 変換結果が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      testWidgets('TC-069-004: 変換結果が表示される', (tester) async {
        // 【テスト目的】: convertedTextがダイアログ内に表示されることを確認 🔵
        // 【テスト内容】: 「変換結果」ラベルと変換後テキストが表示されることを検証
        // 【期待される動作】: 変換結果が強調表示される
        // 🔵 青信号: REQ-902の変換結果表示に基づく

        // Given: 【テストデータ準備】: 変換結果テキストを設定
        const testConvertedText = 'お水をぬるめでお願いします';

        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: testConvertedText,
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: 変換結果が表示されていることを確認
        expect(
          find.text('変換結果'),
          findsOneWidget,
        ); // 【確認内容】: 「変換結果」ラベルが存在すること 🔵
        expect(
          find.text(testConvertedText),
          findsOneWidget,
        ); // 【確認内容】: 変換後テキストが表示されていること 🔵
      });

      /// TC-069-005: 丁寧さレベルが表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-903
      testWidgets('TC-069-005: 丁寧さレベルが表示される', (tester) async {
        // 【テスト目的】: 使用した丁寧さレベルがUIに表示されることを確認 🔵
        // 【テスト内容】: PolitenessLevel.politeの場合、「丁寧」と表示されることを検証
        // 【期待される動作】: 丁寧さレベルが日本語で表示される
        // 🔵 青信号: REQ-903の丁寧さレベル表示に基づく

        // Given: 【テストデータ準備】: 丁寧レベルでダイアログを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: 丁寧さレベルが表示されていることを確認
        expect(
          find.text('丁寧'),
          findsOneWidget,
        ); // 【確認内容】: 「丁寧」が表示されていること 🔵
      });

      /// TC-069-006: 「採用」ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      testWidgets('TC-069-006: 「採用」ボタンが表示される', (tester) async {
        // 【テスト目的】: プライマリアクションボタン「採用」が表示されることを確認 🔵
        // 【テスト内容】: 「採用」ボタンが存在し、タップ可能であることを検証
        // 【期待される動作】: 「採用」ボタンが表示される
        // 🔵 青信号: REQ-902の採用選択機能に基づく

        // Given: 【テストデータ準備】: ダイアログ表示用のウィジェットを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: 「採用」ボタンが表示されていることを確認
        expect(
          find.text('採用'),
          findsOneWidget,
        ); // 【確認内容】: 「採用」ボタンが存在すること 🔵
      });

      /// TC-069-007: 「再生成」ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-904
      testWidgets('TC-069-007: 「再生成」ボタンが表示される', (tester) async {
        // 【テスト目的】: 再生成アクションボタンが表示されることを確認 🔵
        // 【テスト内容】: 「再生成」ボタンが存在することを検証
        // 【期待される動作】: 「再生成」ボタンが表示される
        // 🔵 青信号: REQ-904の再生成機能に基づく

        // Given: 【テストデータ準備】: ダイアログ表示用のウィジェットを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: 「再生成」ボタンが表示されていることを確認
        expect(
          find.text('再生成'),
          findsOneWidget,
        ); // 【確認内容】: 「再生成」ボタンが存在すること 🔵
      });

      /// TC-069-008: 「元の文を使う」ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-904
      testWidgets('TC-069-008: 「元の文を使う」ボタンが表示される', (tester) async {
        // 【テスト目的】: 元の文使用アクションボタンが表示されることを確認 🔵
        // 【テスト内容】: 「元の文を使う」ボタンが存在することを検証
        // 【期待される動作】: 「元の文を使う」ボタンが表示される
        // 🔵 青信号: REQ-904の元の文使用機能に基づく

        // Given: 【テストデータ準備】: ダイアログ表示用のウィジェットを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        // When: 【ユーザー操作実行】: ダイアログを開く
        await openDialog(tester);

        // Then: 【結果検証】: 「元の文を使う」ボタンが表示されていることを確認
        expect(
          find.text('元の文を使う'),
          findsOneWidget,
        ); // 【確認内容】: 「元の文を使う」ボタンが存在すること 🔵
      });
    });

    // =========================================================================
    // 2. 正常系テストケース（インタラクションテスト）
    // =========================================================================
    group('2. 正常系テストケース（インタラクションテスト）', () {
      /// TC-069-009: 「採用」ボタンタップでコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-902
      testWidgets('TC-069-009: 「採用」ボタンタップでコールバックが呼ばれる', (tester) async {
        // 【テスト目的】: onAdoptコールバックが正しく呼び出されることを確認 🔵
        // 【テスト内容】: 「採用」ボタンをタップし、コールバックに変換結果が渡されることを検証
        // 【期待される動作】: コールバックに変換結果のテキストが渡される
        // 🔵 青信号: REQ-902の採用機能に基づく

        // Given: 【テストデータ準備】: コールバック確認用の変数を準備
        String? adoptedText;
        const testConvertedText = 'お水をぬるめでお願いします';

        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: testConvertedText,
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (text) => adoptedText = text,
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // When: 【ユーザー操作実行】: 「採用」ボタンをタップ
        await tester.tap(find.text('採用'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: コールバックが正しいテキストで呼ばれたことを確認
        expect(
          adoptedText,
          equals(testConvertedText),
        ); // 【確認内容】: コールバックに変換結果が渡されること 🔵
      });

      /// TC-069-010: 「再生成」ボタンタップでコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-904
      testWidgets('TC-069-010: 「再生成」ボタンタップでコールバックが呼ばれる', (tester) async {
        // 【テスト目的】: onRegenerateコールバックが正しく呼び出されることを確認 🔵
        // 【テスト内容】: 「再生成」ボタンをタップし、コールバックが呼び出されることを検証
        // 【期待される動作】: コールバックが呼び出される
        // 🔵 青信号: REQ-904の再生成機能に基づく

        // Given: 【テストデータ準備】: コールバック確認用の変数を準備
        bool regenerateCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () => regenerateCalled = true,
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // When: 【ユーザー操作実行】: 「再生成」ボタンをタップ
        await tester.tap(find.text('再生成'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: コールバックが呼ばれたことを確認
        expect(
          regenerateCalled,
          isTrue,
        ); // 【確認内容】: onRegenerateが呼び出されること 🔵
      });

      /// TC-069-011: 「元の文を使う」ボタンタップでコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-904
      testWidgets('TC-069-011: 「元の文を使う」ボタンタップでコールバックが呼ばれる', (tester) async {
        // 【テスト目的】: onUseOriginalコールバックが正しく呼び出されることを確認 🔵
        // 【テスト内容】: 「元の文を使う」ボタンをタップし、コールバックに元の文が渡されることを検証
        // 【期待される動作】: コールバックに元の文テキストが渡される
        // 🔵 青信号: REQ-904の元の文使用機能に基づく

        // Given: 【テストデータ準備】: コールバック確認用の変数を準備
        String? usedOriginalText;
        const testOriginalText = '水 ぬるく';

        await tester.pumpWidget(
          buildTestWidget(
            originalText: testOriginalText,
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (text) => usedOriginalText = text,
          ),
        );

        await openDialog(tester);

        // When: 【ユーザー操作実行】: 「元の文を使う」ボタンをタップ
        await tester.tap(find.text('元の文を使う'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: コールバックが正しいテキストで呼ばれたことを確認
        expect(
          usedOriginalText,
          equals(testOriginalText),
        ); // 【確認内容】: コールバックに元の文が渡されること 🔵
      });

      /// TC-069-012a: casualレベルが正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-903
      testWidgets('TC-069-012a: casualレベルが正しく表示される', (tester) async {
        // 【テスト目的】: PolitenessLevel.casualが「カジュアル」と表示されることを確認 🔵
        // 🔵 青信号: REQ-903の丁寧さレベル表示に基づく

        // Given: 【テストデータ準備】: カジュアルレベルでダイアログを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願い',
            politenessLevel: PolitenessLevel.casual,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: 「カジュアル」が表示されていることを確認
        expect(
          find.text('カジュアル'),
          findsOneWidget,
        ); // 【確認内容】: カジュアルが表示されていること 🔵
      });

      /// TC-069-012b: normalレベルが正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-903
      testWidgets('TC-069-012b: normalレベルが正しく表示される', (tester) async {
        // 【テスト目的】: PolitenessLevel.normalが「普通」と表示されることを確認 🔵
        // 🔵 青信号: REQ-903の丁寧さレベル表示に基づく

        // Given: 【テストデータ準備】: 普通レベルでダイアログを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.normal,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: 「普通」が表示されていることを確認
        expect(
          find.text('普通'),
          findsOneWidget,
        ); // 【確認内容】: 普通が表示されていること 🔵
      });
    });

    // =========================================================================
    // 3. 異常系テストケース
    // =========================================================================
    group('3. 異常系テストケース', () {
      /// TC-069-013: ダイアログ外タップで閉じない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5002（誤操作防止）
      testWidgets('TC-069-013: ダイアログ外タップで閉じない', (tester) async {
        // 【テスト目的】: barrierDismissible: falseの動作を確認 🔵
        // 【テスト内容】: ダイアログ外をタップしても閉じないことを検証
        // 【期待される動作】: ダイアログが表示されたまま
        // 🔵 青信号: REQ-5002の誤操作防止に基づく

        // Given: 【テストデータ準備】: ダイアログを表示
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // When: 【ユーザー操作実行】: ダイアログ外をタップ
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: ダイアログがまだ表示されていることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        ); // 【確認内容】: ダイアログが閉じていないこと 🔵
      });

      /// TC-069-014: 連続タップで複数回コールバックが呼ばれない
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5002（誤操作防止）
      testWidgets('TC-069-014: 連続タップで複数回コールバックが呼ばれない', (tester) async {
        // 【テスト目的】: 連続タップ防止機能の動作を確認 🔵
        // 【テスト内容】: 高速な連続タップでコールバックが1回のみ呼ばれることを検証
        // 【期待される動作】: コールバックは1回のみ呼ばれる
        // 🔵 青信号: REQ-5002の誤操作防止に基づく

        // Given: 【テストデータ準備】: コールバック回数カウント用の変数を準備
        int callCount = 0;

        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) => callCount++,
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // When: 【ユーザー操作実行】: 連続タップ
        final adoptButton = find.text('採用');
        await tester.tap(adoptButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(adoptButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(adoptButton);
        await tester.pumpAndSettle();

        // Then: 【結果検証】: コールバックは1回のみ呼ばれたことを確認
        expect(
          callCount,
          equals(1),
        ); // 【確認内容】: コールバックが1回のみ呼ばれること 🔵
      });
    });

    // =========================================================================
    // 4. 境界値テストケース
    // =========================================================================
    group('4. 境界値テストケース', () {
      /// TC-069-015: 長いテキストが正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: UI設計
      testWidgets('TC-069-015: 長いテキストが正しく表示される', (tester) async {
        // 【テスト目的】: 500文字の最大長テキストが正しく表示されることを確認 🟡
        // 【テスト内容】: 長いテキストでダイアログがオーバーフローしないことを検証
        // 【期待される動作】: テキストがスクロール可能エリアで表示される
        // 🟡 黄信号: UI設計からの推測

        // Given: 【テストデータ準備】: 500文字の長いテキストを準備
        final longText = 'あ' * 500;

        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: longText,
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: オーバーフローエラーが発生しないことを確認
        expect(
          tester.takeException(),
          isNull,
        ); // 【確認内容】: オーバーフローエラーがないこと 🟡
        expect(
          find.textContaining('あ'),
          findsWidgets,
        ); // 【確認内容】: テキストが表示されていること 🟡
      });

      /// TC-069-016: 最小長テキスト（2文字）が表示される
      ///
      /// 優先度: P2（中優先度）
      /// 関連要件: EDGE-105
      testWidgets('TC-069-016: 最小長テキストが表示される', (tester) async {
        // 【テスト目的】: 最小入力文字数（2文字）でも正しく表示されることを確認 🟡
        // 【テスト内容】: 短いテキストでもダイアログが正常動作することを検証
        // 【期待される動作】: 両方のテキストが正しく表示される
        // 🟡 黄信号: EDGE-105からの推測

        // Given: 【テストデータ準備】: 2文字のテキストを準備
        await tester.pumpWidget(
          buildTestWidget(
            originalText: 'あい',
            convertedText: 'あいうえお',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: 2文字でも正しく表示されることを確認
        expect(
          find.text('あい'),
          findsOneWidget,
        ); // 【確認内容】: 最小長テキストが表示されること 🟡
      });

      /// TC-069-017: 元の文と変換結果が同じ場合の表示
      ///
      /// 優先度: P2（中優先度）
      /// 関連要件: EDGE-002
      testWidgets('TC-069-017: 同一テキストでも正常表示', (tester) async {
        // 【テスト目的】: 変換しても同じ結果になるケースで正常動作することを確認 🟡
        // 【テスト内容】: 元の文と変換結果が同じ場合でもエラーにならないことを検証
        // 【期待される動作】: 両方同じテキストが表示される
        // 🟡 黄信号: EDGE-002からの推測

        // Given: 【テストデータ準備】: 同一テキストを準備
        const sameText = 'ありがとう';

        await tester.pumpWidget(
          buildTestWidget(
            originalText: sameText,
            convertedText: sameText,
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: 同じテキストでもダイアログが正常動作することを確認
        expect(
          find.text(sameText),
          findsWidgets,
        ); // 【確認内容】: テキストが表示されていること（2箇所） 🟡
        expect(
          find.text('採用'),
          findsOneWidget,
        ); // 【確認内容】: 採用ボタンが表示されていること 🟡
      });
    });

    // =========================================================================
    // 5. アクセシビリティテストケース
    // =========================================================================
    group('5. アクセシビリティテストケース', () {
      /// TC-069-018: ボタンサイズがアクセシビリティ要件を満たす
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5001
      testWidgets('TC-069-018: ボタンサイズがアクセシビリティ要件を満たす', (tester) async {
        // 【テスト目的】: すべてのボタンが44×44px以上であることを確認 🔵
        // 【テスト内容】: 各ボタンのサイズがREQ-5001のタップターゲットサイズ要件を満たすことを検証
        // 【期待される動作】: 各ボタンのサイズが最小44×44px
        // 🔵 青信号: REQ-5001のタップターゲットサイズ要件に基づく

        // Given: 【テストデータ準備】: ダイアログを表示
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: 各ボタンのサイズを確認
        // 採用ボタン
        final adoptButton = find.widgetWithText(ElevatedButton, '採用');
        final adoptSize = tester.getSize(adoptButton);
        expect(
          adoptSize.width,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        ); // 【確認内容】: 採用ボタンの幅が44px以上 🔵
        expect(
          adoptSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        ); // 【確認内容】: 採用ボタンの高さが44px以上 🔵

        // 再生成ボタン
        final regenerateButton = find.widgetWithText(ElevatedButton, '再生成');
        final regenerateSize = tester.getSize(regenerateButton);
        expect(
          regenerateSize.width,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        ); // 【確認内容】: 再生成ボタンの幅が44px以上 🔵
        expect(
          regenerateSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        ); // 【確認内容】: 再生成ボタンの高さが44px以上 🔵

        // 元の文を使うボタン
        final useOriginalButton = find.widgetWithText(OutlinedButton, '元の文を使う');
        final useOriginalSize = tester.getSize(useOriginalButton);
        expect(
          useOriginalSize.width,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        ); // 【確認内容】: 元の文を使うボタンの幅が44px以上 🔵
        expect(
          useOriginalSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        ); // 【確認内容】: 元の文を使うボタンの高さが44px以上 🔵
      });

      /// TC-069-019: Semanticsラベルが正しく設定される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: アクセシビリティ
      testWidgets('TC-069-019: Semanticsラベルが設定される', (tester) async {
        // 【テスト目的】: スクリーンリーダー対応のラベルが設定されていることを確認 🟡
        // 【テスト内容】: ダイアログにSemanticsラベルが付与されていることを検証
        // 【期待される動作】: Semanticsウィジェットにラベルが設定されている
        // 🟡 黄信号: アクセシビリティ要件からの推測

        // Given: 【テストデータ準備】: ダイアログを表示
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: Semanticsラベルが設定されていることを確認
        final semanticsFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label != null,
        );
        expect(
          semanticsFinder,
          findsWidgets,
        ); // 【確認内容】: Semanticsラベルが設定されていること 🟡
      });
    });

    // =========================================================================
    // 6. テーマ対応テストケース
    // =========================================================================
    group('6. テーマ対応テストケース', () {
      /// TC-069-020: ライトモードで正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-803
      testWidgets('TC-069-020: ライトモードで正しく表示される', (tester) async {
        // 【テスト目的】: ライトテーマでダイアログが正しく表示されることを確認 🟡
        // 【テスト内容】: ライトテーマ適用時にダイアログがエラーなく表示されることを検証
        // 【期待される動作】: ダイアログが白背景で表示される
        // 🟡 黄信号: REQ-803のテーマ機能からの推測

        // Given: 【テストデータ準備】: ライトテーマでダイアログを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
            theme: lightTheme,
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: ダイアログが正常に表示されることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        ); // 【確認内容】: ライトモードでダイアログが表示されること 🟡
      });

      /// TC-069-021: ダークモードで正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-803
      testWidgets('TC-069-021: ダークモードで正しく表示される', (tester) async {
        // 【テスト目的】: ダークテーマでダイアログが正しく表示されることを確認 🟡
        // 【テスト内容】: ダークテーマ適用時にダイアログがエラーなく表示されることを検証
        // 【期待される動作】: ダイアログがダーク背景で表示される
        // 🟡 黄信号: REQ-803のテーマ機能からの推測

        // Given: 【テストデータ準備】: ダークテーマでダイアログを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
            theme: darkTheme,
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: ダイアログが正常に表示されることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        ); // 【確認内容】: ダークモードでダイアログが表示されること 🟡
      });

      /// TC-069-022: 高コントラストモードで正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-803, REQ-5006
      testWidgets('TC-069-022: 高コントラストモードで正しく表示される', (tester) async {
        // 【テスト目的】: 高コントラストテーマでダイアログが正しく表示されることを確認 🟡
        // 【テスト内容】: 高コントラストテーマ適用時にダイアログがエラーなく表示されることを検証
        // 【期待される動作】: WCAG 2.1 AA準拠のコントラスト比で表示される
        // 🟡 黄信号: REQ-5006のコントラスト要件からの推測

        // Given: 【テストデータ準備】: 高コントラストテーマでダイアログを構築
        await tester.pumpWidget(
          buildTestWidget(
            originalText: '水 ぬるく',
            convertedText: 'お水をぬるめでお願いします',
            politenessLevel: PolitenessLevel.polite,
            onAdopt: (_) {},
            onRegenerate: () {},
            onUseOriginal: (_) {},
            theme: highContrastTheme,
          ),
        );

        await openDialog(tester);

        // Then: 【結果検証】: ダイアログが正常に表示されることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        ); // 【確認内容】: 高コントラストモードでダイアログが表示されること 🟡
      });
    });
  });
}
