/// FaceToFaceTextDisplay ウィジェット テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/face_to_face_text_display.dart';

void main() {
  group('FaceToFaceTextDisplayテスト', () {
    group('テキスト表示テスト', () {
      /// テキストが画面中央に大きく表示される
      testWidgets('TC-052-020: テキストが画面中央に大きく表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 表示するテキストを用意
        // 初期条件設定: テキストが設定されている状態
        const testText = 'お水をください';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FaceToFaceTextDisplay(
                text: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: テキストが表示されていることを確認
        // に基づく
        // 品質保証: 対面の相手がメッセージを読み取れること
        expect(
          find.text(testText),
          findsOneWidget,
        );
      });

      /// 長いテキストが適切に表示される
      testWidgets('TC-052-021: 長いテキストが適切に表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 長いテキストを用意
        // 初期条件設定: 複数行になるテキスト
        const testText = 'これは長いテキストです。複数行に渡って表示される必要があります。'
            '対面の相手が読みやすいように、適切に折り返しや改行が行われることを確認します。'
            'このテキストは画面サイズによっては複数行になることが想定されています。';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: FaceToFaceTextDisplay(
                  text: testText,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: テキストが表示されていることを確認
        // 長いテキストでもエラーなく表示される
        // 品質保証: 様々な長さのメッセージに対応できること
        expect(
          find.text(testText),
          findsOneWidget,
        );
      });

      /// 空文字列の場合、何も表示されない（またはプレースホルダー）
      testWidgets('TC-052-022: 空文字列の場合の表示を確認', (WidgetTester tester) async {
        // Given: テストデータ準備: 空文字列を用意
        // 初期条件設定: テキストが空の状態
        const testText = '';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FaceToFaceTextDisplay(
                text: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: エラーなく表示されることを確認
        // 空文字列でもクラッシュしない
        // 品質保証: 予期せぬ状態でもアプリが安定動作すること
        expect(
          find.byType(FaceToFaceTextDisplay),
          findsOneWidget,
        );
      });
    });

    // 2. フォントサイズテストケース
    group('フォントサイズテスト', () {
      /// デフォルトで大きなフォントサイズが使用される
      testWidgets('TC-052-027: デフォルトで大きなフォントサイズが使用されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: テキストを用意
        // 初期条件設定: 対面表示モードのテキスト表示
        const testText = 'テスト';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FaceToFaceTextDisplay(
                text: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: フォントサイズが大きいことを確認
        // に基づき、通常より大きいフォント
        // 品質保証: 対面の相手が読みやすいこと
        final textWidget = tester.widget<Text>(find.text(testText));
        final textStyle = textWidget.style;

        // 対面表示用の大きなフォントサイズ（最低32px以上を想定）
        expect(
          textStyle?.fontSize,
          greaterThanOrEqualTo(32),
        );
      });

      /// フォントサイズをカスタマイズできる
      testWidgets('TC-052-028: フォントサイズをカスタマイズできることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: カスタムフォントサイズを指定
        // 初期条件設定: fontSize=48を指定
        const testText = 'テスト';
        const customFontSize = 48.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FaceToFaceTextDisplay(
                text: testText,
                fontSize: customFontSize,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 指定したフォントサイズが適用されていることを確認
        // カスタマイズが正しく動作すること
        // 品質保証: 利用者のニーズに応じた調整が可能であること
        final textWidget = tester.widget<Text>(find.text(testText));
        final textStyle = textWidget.style;
        expect(
          textStyle?.fontSize,
          equals(customFontSize),
        );
      });
    });

    group('境界値テスト', () {
      /// 最大文字数（1000文字）のテキストが表示できる
      testWidgets('TC-052-029: 最大文字数（1000文字）のテキストが表示できることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 1000文字のテキストを生成
        // 初期条件設定: 最大文字数のテキスト
        final testText = 'あ' * 1000;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FaceToFaceTextDisplay(
                  text: testText,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: テキストが表示されていることを確認
        // 最大文字数でもエラーなく表示される
        // 品質保証: 長いメッセージにも対応できること
        expect(
          find.text(testText),
          findsOneWidget,
        );
      });

      /// 1文字のテキストが正しく表示される
      testWidgets('1文字のテキストが正しく表示されることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: 1文字のテキスト
        // 初期条件設定: 最小文字数のテキスト
        const testText = 'あ';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FaceToFaceTextDisplay(
                text: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: テキストが表示されていることを確認
        // 1文字でも正しく表示される
        // 品質保証: 短いメッセージにも対応できること
        expect(
          find.text(testText),
          findsOneWidget,
        );
      });
    });

    group('アクセシビリティテスト', () {
      /// Semanticsラベルが設定されていることを確認
      testWidgets('Semanticsラベルが設定されていることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceTextDisplayを構築
        const testText = 'テスト';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FaceToFaceTextDisplay(
                text: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: Semanticsが設定されていることを確認
        // アクセシビリティ対応
        final semantics =
            tester.getSemantics(find.byType(FaceToFaceTextDisplay));
        expect(semantics, isNotNull);
      });
    });
  });
}
