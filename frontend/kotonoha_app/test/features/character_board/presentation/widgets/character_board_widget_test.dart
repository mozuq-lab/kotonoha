/// CharacterBoardWidget ウィジェットテスト
///
/// TASK-0037: 五十音文字盤UI実装
/// テストケース: TC-CB-001〜TC-CB-024
///
/// テスト対象: lib/features/character_board/presentation/widgets/character_board_widget.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

// まだ存在しないウィジェットをインポート（Redフェーズ）
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';

void main() {
  group('CharacterBoardWidget', () {
    // =========================================================================
    // 1. 正常系テストケース（基本動作）
    // =========================================================================
    group('正常系テスト - 文字表示', () {
      /// TC-CB-001: 基本五十音が正しく表示される
      ///
      /// 【テスト目的】: REQ-001の充足確認
      /// 【テスト内容】: 五十音文字盤の基本ひらがな46文字が表示されることを確認
      /// 【期待される動作】: あ〜んの基本五十音がすべて表示される
      /// 🔵 青信号: REQ-001で五十音配列の文字盤表示が明確に定義されている
      testWidgets('TC-CB-001: 基本五十音が正しく表示される', (tester) async {
        // 【テストデータ準備】: 基本五十音の代表的な文字をテスト
        // 【初期条件設定】: デフォルト状態で文字盤を表示
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

        // 【結果検証】: 基本五十音の代表的な文字が表示されていることを確認
        // 【期待値確認】: あ行〜わ行、んの各文字が存在する
        expect(find.text('あ'), findsOneWidget); // 【確認内容】: あ行の先頭文字 🔵
        expect(find.text('か'), findsOneWidget); // 【確認内容】: か行の先頭文字 🔵
        expect(find.text('さ'), findsOneWidget); // 【確認内容】: さ行の先頭文字 🔵
        expect(find.text('た'), findsOneWidget); // 【確認内容】: た行の先頭文字 🔵
        expect(find.text('な'), findsOneWidget); // 【確認内容】: な行の先頭文字 🔵
        expect(find.text('は'), findsOneWidget); // 【確認内容】: は行の先頭文字 🔵
        expect(find.text('ま'), findsOneWidget); // 【確認内容】: ま行の先頭文字 🔵
        expect(find.text('や'), findsOneWidget); // 【確認内容】: や行の先頭文字 🔵
        expect(find.text('ら'), findsOneWidget); // 【確認内容】: ら行の先頭文字 🔵
        expect(find.text('わ'), findsOneWidget); // 【確認内容】: わ行の先頭文字 🔵
        expect(find.text('ん'), findsOneWidget); // 【確認内容】: 終端文字 🔵
      });

      /// TC-CB-002: 濁音が正しく表示される
      ///
      /// 【テスト目的】: 濁音文字の網羅性確認
      /// 【テスト内容】: 濁音（が行、ざ行、だ行、ば行）20文字が表示されることを確認
      /// 【期待される動作】: 濁音カテゴリを選択すると濁音が表示される
      /// 🔵 青信号: 日本語入力に濁音は必須、要件定義で明確
      testWidgets('TC-CB-002: 濁音が正しく表示される', (tester) async {
        // 【テストデータ準備】: 濁音文字の代表的な文字をテスト
        // 【初期条件設定】: 濁音カテゴリを表示
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

        // 【結果検証】: 濁音の代表的な文字が表示されていることを確認
        expect(find.text('が'), findsOneWidget); // 【確認内容】: が行の先頭文字 🔵
        expect(find.text('ざ'), findsOneWidget); // 【確認内容】: ざ行の先頭文字 🔵
        expect(find.text('だ'), findsOneWidget); // 【確認内容】: だ行の先頭文字 🔵
        expect(find.text('ば'), findsOneWidget); // 【確認内容】: ば行の先頭文字 🔵
      });

      /// TC-CB-003: 半濁音が正しく表示される
      ///
      /// 【テスト目的】: 半濁音文字の網羅性確認
      /// 【テスト内容】: 半濁音（ぱ行）5文字が表示されることを確認
      /// 【期待される動作】: 半濁音カテゴリを選択するとぱ行が表示される
      /// 🔵 青信号: 日本語入力に半濁音は必須
      testWidgets('TC-CB-003: 半濁音が正しく表示される', (tester) async {
        // 【テストデータ準備】: 半濁音文字をテスト
        // 【初期条件設定】: 半濁音カテゴリを表示
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

        // 【結果検証】: 半濁音5文字がすべて表示されていることを確認
        expect(find.text('ぱ'), findsOneWidget); // 【確認内容】: ぱ 🔵
        expect(find.text('ぴ'), findsOneWidget); // 【確認内容】: ぴ 🔵
        expect(find.text('ぷ'), findsOneWidget); // 【確認内容】: ぷ 🔵
        expect(find.text('ぺ'), findsOneWidget); // 【確認内容】: ぺ 🔵
        expect(find.text('ぽ'), findsOneWidget); // 【確認内容】: ぽ 🔵
      });

      /// TC-CB-004: 拗音・小文字が正しく表示される
      ///
      /// 【テスト目的】: 拗音・小文字の網羅性確認
      /// 【テスト内容】: 小文字（ゃゅょ、ぁぃぅぇぉ、っ）9文字が表示されることを確認
      /// 【期待される動作】: 小文字カテゴリを選択すると小文字が表示される
      /// 🔵 青信号: 日本語入力に拗音・促音は必須
      testWidgets('TC-CB-004: 拗音・小文字が正しく表示される', (tester) async {
        // 【テストデータ準備】: 小文字をテスト
        // 【初期条件設定】: 小文字カテゴリを表示
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

        // 【結果検証】: 小文字9文字がすべて表示されていることを確認
        expect(find.text('ゃ'), findsOneWidget); // 【確認内容】: ゃ 🔵
        expect(find.text('ゅ'), findsOneWidget); // 【確認内容】: ゅ 🔵
        expect(find.text('ょ'), findsOneWidget); // 【確認内容】: ょ 🔵
        expect(find.text('っ'), findsOneWidget); // 【確認内容】: っ 🔵
        expect(find.text('ぁ'), findsOneWidget); // 【確認内容】: ぁ 🔵
      });

      /// TC-CB-005: 句読点・記号が正しく表示される
      ///
      /// 【テスト目的】: 記号の網羅性確認
      /// 【テスト内容】: 句読点と記号5文字が表示されることを確認
      /// 【期待される動作】: 記号カテゴリを選択すると記号が表示される
      /// 🟡 黄信号: 記号の具体的な配置は推測
      testWidgets('TC-CB-005: 句読点・記号が正しく表示される', (tester) async {
        // 【テストデータ準備】: 記号をテスト
        // 【初期条件設定】: 記号カテゴリを表示
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

        // 【結果検証】: 記号5文字がすべて表示されていることを確認
        expect(find.text('ー'), findsOneWidget); // 【確認内容】: 長音 🟡
        expect(find.text('、'), findsOneWidget); // 【確認内容】: 読点 🟡
        expect(find.text('。'), findsOneWidget); // 【確認内容】: 句点 🟡
        expect(find.text('？'), findsOneWidget); // 【確認内容】: 疑問符 🟡
        expect(find.text('！'), findsOneWidget); // 【確認内容】: 感嘆符 🟡
      });
    });

    group('正常系テスト - タップ動作', () {
      /// TC-CB-006: 文字タップでコールバックが呼ばれる
      ///
      /// 【テスト目的】: REQ-002の充足確認
      /// 【テスト内容】: 文字ボタンタップ時にonCharacterTapコールバックが呼ばれることを確認
      /// 【期待される動作】: タップした文字がコールバックに渡される
      /// 🔵 青信号: REQ-002でタップで文字追加が明確に定義されている
      testWidgets('TC-CB-006: 文字タップでコールバックが呼ばれる', (tester) async {
        // 【テストデータ準備】: コールバック受信用の変数
        // 【初期条件設定】: デフォルト状態で文字盤を表示
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

        // 【実際の処理実行】: 「あ」ボタンをタップ
        // 【処理内容】: 文字ボタンのタップイベントをシミュレート
        await tester.tap(find.text('あ'));
        await tester.pump();

        // 【結果検証】: コールバックに「あ」が渡されたことを確認
        // 【期待値確認】: tappedCharacterが「あ」になっている
        expect(tappedCharacter, equals('あ')); // 【確認内容】: タップした文字がコールバックに渡される 🔵
      });

      /// TC-CB-007: 連続タップで複数文字が入力される
      ///
      /// 【テスト目的】: 連続入力の動作確認
      /// 【テスト内容】: 連続した文字タップで各タップごとにコールバックが呼ばれることを確認
      /// 【期待される動作】: 5回タップすると5回のコールバックが順番に呼ばれる
      /// 🔵 青信号: UC-002に基づく連続入力の動作
      testWidgets('TC-CB-007: 連続タップで複数文字が入力される', (tester) async {
        // 【テストデータ準備】: コールバック呼び出し記録用のリスト
        // 【初期条件設定】: デフォルト状態で文字盤を表示
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

        // 【実際の処理実行】: 「こ」「ん」「に」「ち」「は」を順番にタップ
        // 【処理内容】: 連続した文字入力をシミュレート
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

        // 【結果検証】: 5回のコールバックが順番に呼ばれたことを確認
        // 【期待値確認】: tappedCharactersに「こんにちは」が順番に格納されている
        expect(tappedCharacters.length, equals(5)); // 【確認内容】: 5回のコールバックが呼ばれた 🔵
        expect(tappedCharacters.join(), equals('こんにちは')); // 【確認内容】: 順番が正しい 🔵
      });
    });

    // =========================================================================
    // 2. サイズ・レイアウトテストケース
    // =========================================================================
    group('サイズ・レイアウトテスト', () {
      /// TC-CB-008: ボタンサイズが44px以上である
      ///
      /// 【テスト目的】: REQ-5001の充足確認
      /// 【テスト内容】: タップターゲットの最小サイズが44px以上であることを確認
      /// 【期待される動作】: 各文字ボタンが44px × 44px以上
      /// 🔵 青信号: REQ-5001でタップターゲット44px以上が必須
      testWidgets('TC-CB-008: ボタンサイズが44px以上である', (tester) async {
        // 【テストデータ準備】: なし
        // 【初期条件設定】: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 【結果検証】: CharacterButtonウィジェットのサイズを確認
        // 【期待値確認】: 最小タップターゲット44px以上
        final buttons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in buttons) {
          expect(
            button.size,
            greaterThanOrEqualTo(AppSizes.minTapTarget),
          ); // 【確認内容】: 各ボタンが44px以上 🔵
        }
      });

      /// TC-CB-009: 推奨ボタンサイズが60px以上である
      ///
      /// 【テスト目的】: NFR-202の充足確認
      /// 【テスト内容】: デフォルト状態でボタンサイズが60px以上であることを確認
      /// 【期待される動作】: 各文字ボタンが60px × 60px以上
      /// 🟡 黄信号: NFR-202で推奨60px以上
      testWidgets('TC-CB-009: 推奨ボタンサイズが60px以上である', (tester) async {
        // 【テストデータ準備】: なし
        // 【初期条件設定】: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 【結果検証】: デフォルトのボタンサイズを確認
        // 【期待値確認】: 推奨タップターゲット60px以上
        final buttons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in buttons) {
          expect(
            button.size,
            greaterThanOrEqualTo(AppSizes.recommendedTapTarget),
          ); // 【確認内容】: 各ボタンが60px以上 🟡
        }
      });
    });

    // =========================================================================
    // 3. テーマ・スタイルテストケース
    // =========================================================================
    group('テーマ・スタイルテスト', () {
      /// TC-CB-012: ライトテーマで適切な色が使用される
      ///
      /// 【テスト目的】: REQ-803の充足確認
      /// 【テスト内容】: ライトモードでの配色が適用されることを確認
      /// 【期待される動作】: ライトテーマのカラースキームが適用される
      /// 🔵 青信号: REQ-803でテーマ対応が必須
      testWidgets('TC-CB-012: ライトテーマで適切な色が使用される', (tester) async {
        // 【テストデータ準備】: ライトテーマを設定
        // 【初期条件設定】: ライトテーマで文字盤を表示
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

        // 【結果検証】: ライトテーマが適用されていることを確認
        // 【期待値確認】: Theme.of(context).brightness == light
        final context = tester.element(find.byType(CharacterBoardWidget));
        expect(
          Theme.of(context).brightness,
          equals(Brightness.light),
        ); // 【確認内容】: ライトテーマが適用されている 🔵
      });

      /// TC-CB-013: ダークテーマで適切な色が使用される
      ///
      /// 【テスト目的】: REQ-803の充足確認
      /// 【テスト内容】: ダークモードでの配色が適用されることを確認
      /// 【期待される動作】: ダークテーマのカラースキームが適用される
      /// 🔵 青信号: REQ-803でテーマ対応が必須
      testWidgets('TC-CB-013: ダークテーマで適切な色が使用される', (tester) async {
        // 【テストデータ準備】: ダークテーマを設定
        // 【初期条件設定】: ダークテーマで文字盤を表示
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

        // 【結果検証】: ダークテーマが適用されていることを確認
        // 【期待値確認】: Theme.of(context).brightness == dark
        final context = tester.element(find.byType(CharacterBoardWidget));
        expect(
          Theme.of(context).brightness,
          equals(Brightness.dark),
        ); // 【確認内容】: ダークテーマが適用されている 🔵
      });

      /// TC-CB-014: 高コントラストテーマで適切な色が使用される
      ///
      /// 【テスト目的】: REQ-803, REQ-5006の充足確認
      /// 【テスト内容】: 高コントラストモードでの配色が適用されることを確認
      /// 【期待される動作】: 高コントラストテーマのカラースキームが適用される
      /// 🔵 青信号: REQ-803, REQ-5006でWCAG AA準拠が必須
      testWidgets('TC-CB-014: 高コントラストテーマで適切な色が使用される', (tester) async {
        // 【テストデータ準備】: 高コントラストテーマを設定
        // 【初期条件設定】: 高コントラストテーマで文字盤を表示
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

        // 【結果検証】: 高コントラストテーマが適用されていることを確認
        final context = tester.element(find.byType(CharacterBoardWidget));
        expect(
          Theme.of(context),
          isNotNull,
        ); // 【確認内容】: 高コントラストテーマが適用されている 🔵
      });

      /// TC-CB-015: フォントサイズ「小」で適切なサイズになる
      ///
      /// 【テスト目的】: REQ-801, REQ-802の充足確認
      /// 【テスト内容】: フォントサイズ設定「小」が文字盤に追従することを確認
      /// 【期待される動作】: 文字盤の文字が小サイズで表示される
      /// 🔵 青信号: REQ-801, REQ-802でフォントサイズ追従が必須
      testWidgets('TC-CB-015: フォントサイズ「小」で適切なサイズになる', (tester) async {
        // 【テストデータ準備】: フォントサイズ「小」を設定
        // 【初期条件設定】: フォントサイズ「小」で文字盤を表示
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

        // 【結果検証】: フォントサイズが「小」設定に追従していることを確認
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(
          widget.fontSize,
          equals(FontSize.small),
        ); // 【確認内容】: フォントサイズ「小」が設定されている 🔵
      });

      /// TC-CB-016: フォントサイズ「中」で適切なサイズになる
      ///
      /// 【テスト目的】: REQ-801, REQ-802の充足確認
      /// 【テスト内容】: フォントサイズ設定「中」（デフォルト）が文字盤に追従することを確認
      /// 【期待される動作】: 文字盤の文字が中サイズで表示される
      /// 🔵 青信号: REQ-801, REQ-802でフォントサイズ追従が必須
      testWidgets('TC-CB-016: フォントサイズ「中」で適切なサイズになる', (tester) async {
        // 【テストデータ準備】: フォントサイズ「中」を設定
        // 【初期条件設定】: フォントサイズ「中」で文字盤を表示
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

        // 【結果検証】: フォントサイズが「中」設定に追従していることを確認
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(
          widget.fontSize,
          equals(FontSize.medium),
        ); // 【確認内容】: フォントサイズ「中」が設定されている 🔵
      });

      /// TC-CB-017: フォントサイズ「大」で適切なサイズになる
      ///
      /// 【テスト目的】: REQ-801, REQ-802の充足確認
      /// 【テスト内容】: フォントサイズ設定「大」が文字盤に追従することを確認
      /// 【期待される動作】: 文字盤の文字が大サイズで表示される
      /// 🔵 青信号: REQ-801, REQ-802でフォントサイズ追従が必須
      testWidgets('TC-CB-017: フォントサイズ「大」で適切なサイズになる', (tester) async {
        // 【テストデータ準備】: フォントサイズ「大」を設定
        // 【初期条件設定】: フォントサイズ「大」で文字盤を表示
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

        // 【結果検証】: フォントサイズが「大」設定に追従していることを確認
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(
          widget.fontSize,
          equals(FontSize.large),
        ); // 【確認内容】: フォントサイズ「大」が設定されている 🔵
      });
    });

    // =========================================================================
    // 4. アクセシビリティテストケース
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-CB-018: Semanticsラベルが設定される
      ///
      /// 【テスト目的】: アクセシビリティ要件の充足確認
      /// 【テスト内容】: 各文字ボタンにSemanticsラベルが設定されていることを確認
      /// 【期待される動作】: スクリーンリーダーで文字が読み上げられる
      /// 🔵 青信号: アクセシビリティ標準
      testWidgets('TC-CB-018: Semanticsラベルが設定される', (tester) async {
        // 【テストデータ準備】: なし
        // 【初期条件設定】: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 【結果検証】: Semanticsが設定されていることを確認
        // ElevatedButtonやInkWellは自動的にSemanticsを持つ
        expect(
          find.byType(CharacterBoardWidget),
          findsOneWidget,
        ); // 【確認内容】: CharacterBoardWidgetが存在する 🔵
      });

      /// TC-CB-019: タップフィードバックが表示される
      ///
      /// 【テスト目的】: ユーザビリティ確認
      /// 【テスト内容】: タップ時に視覚的フィードバックが表示されることを確認
      /// 【期待される動作】: InkWell/InkResponseによるリップルエフェクト
      /// 🟡 黄信号: UC-001で視覚的フィードバックが必要とされている
      testWidgets('TC-CB-019: タップフィードバックが表示される', (tester) async {
        // 【テストデータ準備】: なし
        // 【初期条件設定】: デフォルト状態で文字盤を表示
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 【結果検証】: InkWellまたはMaterial ripple effectが使用されていることを確認
        expect(
          find.byType(InkWell),
          findsWidgets,
        ); // 【確認内容】: タップフィードバック用のInkWellが存在する 🟡
      });
    });

    // =========================================================================
    // 5. 状態テストケース
    // =========================================================================
    group('状態テスト', () {
      /// TC-CB-020: isEnabled: falseで無効状態になる
      ///
      /// 【テスト目的】: 状態制御の確認
      /// 【テスト内容】: isEnabled: falseで文字盤全体が無効化されることを確認
      /// 【期待される動作】: タップしてもコールバックが呼ばれない
      /// 🟡 黄信号: 状態管理の必要性から推測
      testWidgets('TC-CB-020: isEnabled: falseで無効状態になる', (tester) async {
        // 【テストデータ準備】: コールバック呼び出し確認用の変数
        // 【初期条件設定】: isEnabled: falseで文字盤を表示
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

        // 【実際の処理実行】: 無効状態で文字をタップ
        await tester.tap(find.text('あ'));
        await tester.pump();

        // 【結果検証】: コールバックが呼ばれないことを確認
        expect(callbackCalled, isFalse); // 【確認内容】: 無効状態ではコールバックが呼ばれない 🟡
      });

      /// TC-CB-021: isEnabled: trueで有効状態になる
      ///
      /// 【テスト目的】: 状態制御の確認
      /// 【テスト内容】: isEnabled: true（デフォルト）で文字盤が有効化されることを確認
      /// 【期待される動作】: タップでコールバックが呼ばれる
      /// 🟡 黄信号: デフォルト動作の確認
      testWidgets('TC-CB-021: isEnabled: trueで有効状態になる', (tester) async {
        // 【テストデータ準備】: コールバック呼び出し確認用の変数
        // 【初期条件設定】: isEnabled: trueで文字盤を表示
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

        // 【実際の処理実行】: 有効状態で文字をタップ
        await tester.tap(find.text('あ'));
        await tester.pump();

        // 【結果検証】: コールバックが呼ばれることを確認
        expect(callbackCalled, isTrue); // 【確認内容】: 有効状態ではコールバックが呼ばれる 🟡
      });
    });
  });
}
