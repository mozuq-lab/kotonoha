/// AI変換結果表示・選択ダイアログ ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';

import '../../../../support/contrast_helpers.dart';

void main() {
  group('TASK-0069: AI変換結果表示・選択UIテスト', () {
    // テスト用ヘルパーメソッド

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

    group('1. 正常系テストケース（表示テスト）', () {
      /// ダイアログが正しく表示される
      testWidgets('TC-069-001: ダイアログが正しく表示される', (tester) async {
        // Given: テストデータ準備: 標準的なAI変換データでダイアログを構築
        // 初期条件設定: 典型的なAI変換の入出力パターン
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: ダイアログが表示されていることを確認
        // に基づく
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        );
      });

      /// タイトル「AI変換結果」が表示される
      testWidgets('TC-069-002: タイトル「AI変換結果」が表示される', (tester) async {
        // Given: テストデータ準備: ダイアログ表示用のウィジェットを構築
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: タイトルが表示されていることを確認
        expect(
          find.text('AI変換結果'),
          findsOneWidget,
        );
      });

      /// 元の文が表示される
      testWidgets('TC-069-003: 元の文が表示される', (tester) async {
        // Given: テストデータ準備: 元のテキストを設定
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: ラベルとテキストが表示されていることを確認
        expect(
          find.text('元の文'),
          findsOneWidget,
        );
        expect(
          find.text(testOriginalText),
          findsOneWidget,
        );
      });

      /// 変換結果が表示される
      testWidgets('TC-069-004: 変換結果が表示される', (tester) async {
        // Given: テストデータ準備: 変換結果テキストを設定
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: 変換結果が表示されていることを確認
        expect(
          find.text('変換結果'),
          findsOneWidget,
        );
        expect(
          find.text(testConvertedText),
          findsOneWidget,
        );
      });

      /// 丁寧さレベルが表示される
      testWidgets('TC-069-005: 丁寧さレベルが表示される', (tester) async {
        // Given: テストデータ準備: 丁寧レベルでダイアログを構築
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: 丁寧さレベルが表示されていることを確認
        expect(
          find.text('丁寧'),
          findsOneWidget,
        );
      });

      /// 「採用」ボタンが表示される
      testWidgets('TC-069-006: 「採用」ボタンが表示される', (tester) async {
        // Given: テストデータ準備: ダイアログ表示用のウィジェットを構築
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: 「採用」ボタンが表示されていることを確認
        expect(
          find.text('採用'),
          findsOneWidget,
        );
      });

      /// 「再生成」ボタンが表示される
      testWidgets('TC-069-007: 「再生成」ボタンが表示される', (tester) async {
        // Given: テストデータ準備: ダイアログ表示用のウィジェットを構築
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: 「再生成」ボタンが表示されていることを確認
        expect(
          find.text('再生成'),
          findsOneWidget,
        );
      });

      /// 「元の文を使う」ボタンが表示される
      testWidgets('TC-069-008: 「元の文を使う」ボタンが表示される', (tester) async {
        // Given: テストデータ準備: ダイアログ表示用のウィジェットを構築
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

        // When: ユーザー操作実行: ダイアログを開く
        await openDialog(tester);

        // Then: 結果検証: 「元の文を使う」ボタンが表示されていることを確認
        expect(
          find.text('元の文を使う'),
          findsOneWidget,
        );
      });
    });

    group('2. 正常系テストケース（インタラクションテスト）', () {
      /// 「採用」ボタンタップでコールバックが呼ばれる
      testWidgets('TC-069-009: 「採用」ボタンタップでコールバックが呼ばれる', (tester) async {
        // Given: テストデータ準備: コールバック確認用の変数を準備
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

        // When: ユーザー操作実行: 「採用」ボタンをタップ
        await tester.tap(find.text('採用'));
        await tester.pumpAndSettle();

        // Then: 結果検証: コールバックが正しいテキストで呼ばれたことを確認
        expect(
          adoptedText,
          equals(testConvertedText),
        );
      });

      /// 「再生成」ボタンタップでコールバックが呼ばれる
      testWidgets('TC-069-010: 「再生成」ボタンタップでコールバックが呼ばれる', (tester) async {
        // Given: テストデータ準備: コールバック確認用の変数を準備
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

        // When: ユーザー操作実行: 「再生成」ボタンをタップ
        await tester.tap(find.text('再生成'));
        await tester.pumpAndSettle();

        // Then: 結果検証: コールバックが呼ばれたことを確認
        expect(
          regenerateCalled,
          isTrue,
        );
      });

      /// 「元の文を使う」ボタンタップでコールバックが呼ばれる
      testWidgets('TC-069-011: 「元の文を使う」ボタンタップでコールバックが呼ばれる', (tester) async {
        // Given: テストデータ準備: コールバック確認用の変数を準備
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

        // When: ユーザー操作実行: 「元の文を使う」ボタンをタップ
        await tester.tap(find.text('元の文を使う'));
        await tester.pumpAndSettle();

        // Then: 結果検証: コールバックが正しいテキストで呼ばれたことを確認
        expect(
          usedOriginalText,
          equals(testOriginalText),
        );
      });

      /// casualレベルが正しく表示される
      testWidgets('TC-069-012a: casualレベルが正しく表示される', (tester) async {
        // Given: テストデータ準備: カジュアルレベルでダイアログを構築
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

        // Then: 結果検証: 「カジュアル」が表示されていることを確認
        expect(
          find.text('カジュアル'),
          findsOneWidget,
        );
      });

      /// normalレベルが正しく表示される
      testWidgets('TC-069-012b: normalレベルが正しく表示される', (tester) async {
        // Given: テストデータ準備: 普通レベルでダイアログを構築
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

        // Then: 結果検証: 「普通」が表示されていることを確認
        expect(
          find.text('普通'),
          findsOneWidget,
        );
      });
    });

    group('3. 異常系テストケース', () {
      /// ダイアログ外タップで閉じない
      testWidgets('TC-069-013: ダイアログ外タップで閉じない', (tester) async {
        // Given: テストデータ準備: ダイアログを表示
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

        // When: ユーザー操作実行: ダイアログ外をタップ
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Then: 結果検証: ダイアログがまだ表示されていることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        );
      });

      /// 連続タップで複数回コールバックが呼ばれない
      testWidgets('TC-069-014: 連続タップで複数回コールバックが呼ばれない', (tester) async {
        // Given: テストデータ準備: コールバック回数カウント用の変数を準備
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: AIConversionResultDialog(
                originalText: '水 ぬるく',
                convertedText: 'お水をぬるめでお願いします',
                politenessLevel: PolitenessLevel.polite,
                onAdopt: (_) => callCount++,
                onRegenerate: () {},
                onUseOriginal: (_) {},
              ),
            ),
          ),
        );

        // 前提ダイアログが表示され、ボタンが操作可能であること
        final adoptButton = find.text('採用');
        expect(adoptButton, findsOneWidget);

        // When: ユーザー操作実行: 連続タップ（ダイアログはpopされない）
        await tester.tap(adoptButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(adoptButton);
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(adoptButton);
        await tester.pumpAndSettle();

        // Then: 結果検証: コールバックは1回のみ呼ばれたことを確認
        expect(
          callCount,
          equals(1),
          reason: '連続タップ防止（_handleTap の早期リターンと '
              'onPressed の disabled 化）により2回目以降のタップは無視される必要がある',
        );
      });
    });

    group('4. 境界値テストケース', () {
      /// 長いテキストが正しく表示される
      testWidgets('TC-069-015: 長いテキストが正しく表示される', (tester) async {
        // Given: テストデータ準備: 500文字の長いテキストを準備
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

        // Then: 結果検証: オーバーフローエラーが発生しないことを確認
        expect(
          tester.takeException(),
          isNull,
        );
        expect(
          find.textContaining('あ'),
          findsWidgets,
        );
      });

      /// 最小長テキスト（2文字）が表示される
      testWidgets('TC-069-016: 最小長テキストが表示される', (tester) async {
        // Given: テストデータ準備: 2文字のテキストを準備
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

        // Then: 結果検証: 2文字でも正しく表示されることを確認
        expect(
          find.text('あい'),
          findsOneWidget,
        );
      });

      /// 元の文と変換結果が同じ場合の表示
      testWidgets('TC-069-017: 同一テキストでも正常表示', (tester) async {
        // Given: テストデータ準備: 同一テキストを準備
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

        // Then: 結果検証: 同じテキストでもダイアログが正常動作することを確認
        expect(
          find.text(sameText),
          findsWidgets,
        );
        expect(
          find.text('採用'),
          findsOneWidget,
        );
      });
    });

    group('5. アクセシビリティテストケース', () {
      /// ボタンサイズがアクセシビリティ要件を満たす
      testWidgets('TC-069-018: ボタンサイズがアクセシビリティ要件を満たす', (tester) async {
        // Given: テストデータ準備: ダイアログを表示
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

        // Then: 結果検証: 各ボタンのサイズを確認
        // 採用ボタン
        final adoptButton = find.widgetWithText(ElevatedButton, '採用');
        final adoptSize = tester.getSize(adoptButton);
        expect(
          adoptSize.width,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );
        expect(
          adoptSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );

        // 再生成ボタン
        final regenerateButton = find.widgetWithText(ElevatedButton, '再生成');
        final regenerateSize = tester.getSize(regenerateButton);
        expect(
          regenerateSize.width,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );
        expect(
          regenerateSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );

        // 元の文を使うボタン
        final useOriginalButton = find.widgetWithText(OutlinedButton, '元の文を使う');
        final useOriginalSize = tester.getSize(useOriginalButton);
        expect(
          useOriginalSize.width,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );
        expect(
          useOriginalSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );
      });

      /// Semanticsラベルが正しく設定される
      testWidgets('TC-069-019: Semanticsラベルが設定される', (tester) async {
        // Given: テストデータ準備: ダイアログを表示
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

        // Then: 結果検証: Semanticsラベルが設定されていることを確認
        final semanticsFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label != null,
        );
        expect(
          semanticsFinder,
          findsWidgets,
        );
      });
    });

    group('6. テーマ対応テストケース', () {
      /// ライトモードで正しく表示される
      testWidgets('TC-069-020: ライトモードで正しく表示される', (tester) async {
        // Given: テストデータ準備: ライトテーマでダイアログを構築
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

        // Then: 結果検証: ダイアログが正常に表示されることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        );
      });

      /// ダークモードで正しく表示される
      testWidgets('TC-069-021: ダークモードで正しく表示される', (tester) async {
        // Given: テストデータ準備: ダークテーマでダイアログを構築
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

        // Then: 結果検証: ダイアログが正常に表示されることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        );
      });

      /// 高コントラストモードで正しく表示される
      testWidgets('TC-069-022: 高コントラストモードで正しく表示される', (tester) async {
        // Given: テストデータ準備: 高コントラストテーマでダイアログを構築
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

        // Then: 結果検証: ダイアログが正常に表示されることを確認
        expect(
          find.byType(AIConversionResultDialog),
          findsOneWidget,
        );
      });
    });

    // 7. AA対応（コントラスト比）テスト
    // AA対応: 従来は「採用」ボタンの文字色にColors.white固定
    // （ライトテーマのprimaryLight(#2196F3)背景では約3.1:1）
    // 「元の文」「変換結果」ラベルにColors.grey(#9E9E9E)固定
    // （約2.8:1）を使用しており、いずれもWCAG AA（4.5:1）未達だった。
    // ここでは実際にレンダリングされたウィジェットの色を取得し
    // Color.computeLuminanceを用いたWCAG 2.1のコントラスト比計算式で
    // ライト/ダーク/高コントラストの3テーマすべてがAA基準を満たすことを検証する。
    group('7. AA対応（コントラスト比）テスト', () {
      final themes = <String, ThemeData>{
        'light': lightTheme,
        'dark': darkTheme,
        'highContrast': highContrastTheme,
      };

      for (final entry in themes.entries) {
        final themeName = entry.key;
        final theme = entry.value;

        testWidgets('$themeNameテーマ: 「採用」ボタンの文字色がWCAG AAを満たす', (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              originalText: '水 ぬるく',
              convertedText: 'お水をぬるめでお願いします',
              politenessLevel: PolitenessLevel.polite,
              onAdopt: (_) {},
              onRegenerate: () {},
              onUseOriginal: (_) {},
              theme: theme,
            ),
          );
          await openDialog(tester);

          final adoptButton = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '採用'),
          );
          final style = adoptButton.style!;
          final background = style.backgroundColor!.resolve(<WidgetState>{})!;
          final foreground = style.foregroundColor!.resolve(<WidgetState>{})!;
          final ratio = contrastRatio(foreground, background);

          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$themeName: 背景=$background 文字=$foreground '
                'のコントラスト比は$ratioでWCAG AA(4.5:1)未達',
          );
        });

        testWidgets('$themeNameテーマ: 「元の文」「変換結果」ラベルの文字色がWCAG AAを満たす',
            (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              originalText: '水 ぬるく',
              convertedText: 'お水をぬるめでお願いします',
              politenessLevel: PolitenessLevel.polite,
              onAdopt: (_) {},
              onRegenerate: () {},
              onUseOriginal: (_) {},
              theme: theme,
            ),
          );
          await openDialog(tester);

          // ラベルはダイアログのcontent領域（surface系の背景）上に表示される
          final background = theme.colorScheme.surface;

          for (final label in ['元の文', '変換結果']) {
            final textWidget = tester.widget<Text>(find.text(label));
            final foreground = textWidget.style!.color!;
            final ratio = contrastRatio(foreground, background);

            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: '$themeName: ラベル"$label" 背景=$background '
                  '文字=$foreground のコントラスト比は$ratioでWCAG AA(4.5:1)未達',
            );
          }
        });
      }
    });
  });
}
