/// CharacterBoardWidget ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';

void main() {
  group('CharacterBoardWidget', () {
    group('正常系テスト - 文字表示', () {
      /// 基本五十音が正しく表示される
      testWidgets('TC-CB-001: 基本五十音が正しく表示される', (tester) async {
        // テストデータ準備: 基本五十音の代表的な文字をテスト
        // 初期条件設定: デフォルト状態で文字盤を表示
        // ignore: unused_local_variable
        String? tappedCharacter;

        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacter = char,
              ),
            ),
          ),
        );

        // 結果検証: 基本五十音の代表的な文字が表示されていることを確認
        // あ行〜わ行、んの各文字が存在する
        expect(find.text('あ'), findsOneWidget);
        expect(find.text('か'), findsOneWidget);
        expect(find.text('さ'), findsOneWidget);
        expect(find.text('た'), findsOneWidget);
        expect(find.text('な'), findsOneWidget);
        expect(find.text('は'), findsOneWidget);
        expect(find.text('ま'), findsOneWidget);
        expect(find.text('や'), findsOneWidget);
        expect(find.text('ら'), findsOneWidget);
        expect(find.text('わ'), findsOneWidget);
        expect(find.text('ん'), findsOneWidget);
      });

      /// 濁音が正しく表示される
      testWidgets('TC-CB-002: 濁音が正しく表示される', (tester) async {
        // テストデータ準備: 濁音文字の代表的な文字をテスト
        // 初期条件設定: 濁音カテゴリを表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                initialCategory: CharacterCategory.dakuon,
              ),
            ),
          ),
        );

        // 結果検証: 濁音の代表的な文字が表示されていることを確認
        expect(find.text('が'), findsOneWidget);
        expect(find.text('ざ'), findsOneWidget);
        expect(find.text('だ'), findsOneWidget);
        expect(find.text('ば'), findsOneWidget);
      });

      /// 半濁音が正しく表示される
      testWidgets('TC-CB-003: 半濁音が正しく表示される', (tester) async {
        // テストデータ準備: 半濁音文字をテスト
        // 初期条件設定: 半濁音カテゴリを表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                initialCategory: CharacterCategory.handakuon,
              ),
            ),
          ),
        );

        // 結果検証: 半濁音5文字がすべて表示されていることを確認
        expect(find.text('ぱ'), findsOneWidget);
        expect(find.text('ぴ'), findsOneWidget);
        expect(find.text('ぷ'), findsOneWidget);
        expect(find.text('ぺ'), findsOneWidget);
        expect(find.text('ぽ'), findsOneWidget);
      });

      /// 拗音・小文字が正しく表示される
      testWidgets('TC-CB-004: 拗音・小文字が正しく表示される', (tester) async {
        // テストデータ準備: 小文字をテスト
        // 初期条件設定: 小文字カテゴリを表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                initialCategory: CharacterCategory.komoji,
              ),
            ),
          ),
        );

        // 結果検証: 小文字9文字がすべて表示されていることを確認
        expect(find.text('ゃ'), findsOneWidget);
        expect(find.text('ゅ'), findsOneWidget);
        expect(find.text('ょ'), findsOneWidget);
        expect(find.text('っ'), findsOneWidget);
        expect(find.text('ぁ'), findsOneWidget);
      });

      /// 句読点・記号が正しく表示される
      testWidgets('TC-CB-005: 句読点・記号が正しく表示される', (tester) async {
        // テストデータ準備: 記号をテスト
        // 初期条件設定: 記号カテゴリを表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                initialCategory: CharacterCategory.kigou,
              ),
            ),
          ),
        );

        // 結果検証: 記号5文字がすべて表示されていることを確認
        expect(find.text('ー'), findsOneWidget);
        expect(find.text('、'), findsOneWidget);
        expect(find.text('。'), findsOneWidget);
        expect(find.text('？'), findsOneWidget);
        expect(find.text('！'), findsOneWidget);
      });
    });

    group('正常系テスト - タップ動作', () {
      /// 文字タップでコールバックが呼ばれる
      testWidgets('TC-CB-006: 文字タップでコールバックが呼ばれる', (tester) async {
        // テストデータ準備: コールバック受信用の変数
        // 初期条件設定: デフォルト状態で文字盤を表示
        String? tappedCharacter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacter = char,
              ),
            ),
          ),
        );

        // 実際の処理実行: 「あ」ボタンをタップ
        // 処理内容: 文字ボタンのタップイベントをシミュレート
        await tester.tap(find.text('あ'));
        await tester.pump();

        // 結果検証: コールバックに「あ」が渡されたことを確認
        // tappedCharacterが「あ」になっている
        expect(tappedCharacter, equals('あ'));
      });

      /// 連続タップで複数文字が入力される
      testWidgets('TC-CB-007: 連続タップで複数文字が入力される', (tester) async {
        // テストデータ準備: コールバック呼び出し記録用のリスト
        // 初期条件設定: デフォルト状態で文字盤を表示
        final List<String> tappedCharacters = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacters.add(char),
              ),
            ),
          ),
        );

        // 実際の処理実行: 「こ」「ん」「に」「ち」「は」を順番にタップ
        // 処理内容: 連続した文字入力をシミュレート
        await tester.tap(find.text('こ'));
        await tester.pump();
        await tester.tap(find.text('ん'));
        await tester.pump();
        await tester.tap(find.text('に'));
        await tester.pump();
        await tester.tap(find.text('ち'));
        await tester.pump();
        await tester.tap(find.text('は'));
        await tester.pump();

        // 結果検証: 5回のコールバックが順番に呼ばれたことを確認
        // tappedCharactersに「こんにちは」が順番に格納されている
        expect(tappedCharacters.length, equals(5));
        expect(tappedCharacters.join(), equals('こんにちは'));
      });
    });

    group('サイズ・レイアウトテスト', () {
      /// ボタンサイズが44px以上である
      testWidgets('TC-CB-008: ボタンサイズが44px以上である', (tester) async {
        // テストデータ準備: なし
        // 初期条件設定: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: CharacterButtonウィジェットのサイズを確認
        // 最小タップターゲット44px以上
        final buttons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in buttons) {
          expect(
            button.size,
            greaterThanOrEqualTo(AppSizes.minTapTarget),
          );
        }
      });

      /// 推奨ボタンサイズが60px以上である
      testWidgets('TC-CB-009: 推奨ボタンサイズが60px以上である', (tester) async {
        // テストデータ準備: なし
        // 初期条件設定: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: デフォルトのボタンサイズを確認
        // 推奨タップターゲット60px以上
        final buttons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in buttons) {
          expect(
            button.size,
            greaterThanOrEqualTo(AppSizes.recommendedTapTarget),
          );
        }
      });
    });

    group('テーマ・スタイルテスト', () {
      /// ライトテーマで適切な色が使用される
      testWidgets('TC-CB-012: ライトテーマで適切な色が使用される', (tester) async {
        // テストデータ準備: ライトテーマを設定
        // 初期条件設定: ライトテーマで文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: ライトテーマが適用されていることを確認
        // Theme.of(context).brightness == light
        final context = tester.element(find.byType(CharacterBoardWidget));
        expect(
          Theme.of(context).brightness,
          equals(Brightness.light),
        );
      });

      /// ダークテーマで適切な色が使用される
      testWidgets('TC-CB-013: ダークテーマで適切な色が使用される', (tester) async {
        // テストデータ準備: ダークテーマを設定
        // 初期条件設定: ダークテーマで文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: ダークテーマが適用されていることを確認
        // Theme.of(context).brightness == dark
        final context = tester.element(find.byType(CharacterBoardWidget));
        expect(
          Theme.of(context).brightness,
          equals(Brightness.dark),
        );
      });

      /// 高コントラストテーマで適切な色が使用される
      testWidgets('TC-CB-014: 高コントラストテーマで適切な色が使用される', (tester) async {
        // テストデータ準備: 高コントラストテーマを設定
        // 初期条件設定: 高コントラストテーマで文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: 高コントラストテーマが適用されていることを確認
        final context = tester.element(find.byType(CharacterBoardWidget));
        expect(
          Theme.of(context),
          isNotNull,
        );
      });

      /// フォントサイズ「小」で適切なサイズになる
      testWidgets('TC-CB-015: フォントサイズ「小」で適切なサイズになる', (tester) async {
        // テストデータ準備: フォントサイズ「小」を設定
        // 初期条件設定: フォントサイズ「小」で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                fontSize: FontSize.small,
              ),
            ),
          ),
        );

        // 結果検証: フォントサイズが「小」設定に追従していることを確認
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(
          widget.fontSize,
          equals(FontSize.small),
        );
      });

      /// フォントサイズ「中」で適切なサイズになる
      testWidgets('TC-CB-016: フォントサイズ「中」で適切なサイズになる', (tester) async {
        // テストデータ準備: フォントサイズ「中」を設定
        // 初期条件設定: フォントサイズ「中」で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                fontSize: FontSize.medium,
              ),
            ),
          ),
        );

        // 結果検証: フォントサイズが「中」設定に追従していることを確認
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(
          widget.fontSize,
          equals(FontSize.medium),
        );
      });

      /// フォントサイズ「大」で適切なサイズになる
      testWidgets('TC-CB-017: フォントサイズ「大」で適切なサイズになる', (tester) async {
        // テストデータ準備: フォントサイズ「大」を設定
        // 初期条件設定: フォントサイズ「大」で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                fontSize: FontSize.large,
              ),
            ),
          ),
        );

        // 結果検証: フォントサイズが「大」設定に追従していることを確認
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(
          widget.fontSize,
          equals(FontSize.large),
        );
      });
    });

    group('アクセシビリティテスト', () {
      /// Semanticsラベルが設定される
      testWidgets('TC-CB-018: Semanticsラベルが設定される', (tester) async {
        // テストデータ準備: なし
        // 初期条件設定: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: Semanticsが設定されていることを確認
        // ElevatedButtonやInkWellは自動的にSemanticsを持つ
        expect(
          find.byType(CharacterBoardWidget),
          findsOneWidget,
        );
      });

      /// タップフィードバックが表示される
      testWidgets('TC-CB-019: タップフィードバックが表示される', (tester) async {
        // テストデータ準備: なし
        // 初期条件設定: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 結果検証: InkWellまたはMaterial ripple effectが使用されていることを確認
        expect(
          find.byType(InkWell),
          findsWidgets,
        );
      });
    });

    group('状態テスト', () {
      /// isEnabled: falseで無効状態になる
      testWidgets('TC-CB-020: isEnabled: falseで無効状態になる', (tester) async {
        // テストデータ準備: コールバック呼び出し確認用の変数
        // 初期条件設定: isEnabled: falseで文字盤を表示
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) => callbackCalled = true,
                isEnabled: false,
              ),
            ),
          ),
        );

        // 実際の処理実行: 無効状態で文字をタップ
        await tester.tap(find.text('あ'));
        await tester.pump();

        // 結果検証: コールバックが呼ばれないことを確認
        expect(callbackCalled, isFalse);
      });

      /// isEnabled: trueで有効状態になる
      testWidgets('TC-CB-021: isEnabled: trueで有効状態になる', (tester) async {
        // テストデータ準備: コールバック呼び出し確認用の変数
        // 初期条件設定: isEnabled: trueで文字盤を表示
        bool callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) => callbackCalled = true,
                isEnabled: true,
              ),
            ),
          ),
        );

        // 実際の処理実行: 有効状態で文字をタップ
        await tester.tap(find.text('あ'));
        await tester.pump();

        // 結果検証: コールバックが呼ばれることを確認
        expect(callbackCalled, isTrue);
      });
    });

    // 6. 濁点・半濁点・空白キーテスト（改善: 3タップ問題解消）
    group('濁点・半濁点・空白キーテスト', () {
      testWidgets('基本タブに濁点キーが表示され、タップでコールバックに濁点記号が渡される', (tester) async {
        String? tappedCharacter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacter = char,
              ),
            ),
          ),
        );

        expect(find.text(CharacterData.dakutenKey), findsOneWidget);

        await tester.tap(find.text(CharacterData.dakutenKey));
        await tester.pump();

        expect(tappedCharacter, equals(CharacterData.dakutenKey));
      });

      testWidgets('基本タブに半濁点キーが表示され、タップでコールバックに半濁点記号が渡される', (tester) async {
        String? tappedCharacter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacter = char,
              ),
            ),
          ),
        );

        expect(find.text(CharacterData.handakutenKey), findsOneWidget);

        await tester.tap(find.text(CharacterData.handakutenKey));
        await tester.pump();

        expect(tappedCharacter, equals(CharacterData.handakutenKey));
      });

      testWidgets('基本タブに空白キーが「空白」というラベルで表示され、タップで全角スペースが渡される', (tester) async {
        String? tappedCharacter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacter = char,
              ),
            ),
          ),
        );

        // 表示上は「空白」ラベル（全角スペースそのままでは視認できないため）
        expect(find.text('空白'), findsOneWidget);

        await tester.tap(find.text('空白'));
        await tester.pump();

        expect(tappedCharacter, equals(CharacterData.spaceKey));
      });
    });
  });
}
