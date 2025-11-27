/// TextInputField ウィジェットテスト
///
/// TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）
/// テストケース: TC-TIF-001〜TC-TIF-013
///
/// テスト対象: lib/shared/widgets/text_input_field.dart (未実装)
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

// まだ存在しないウィジェットをインポート（Redフェーズ）
import 'package:kotonoha_app/shared/widgets/text_input_field.dart';

void main() {
  group('TextInputField', () {
    // =========================================================================
    // 2.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-TIF-001: TextFieldが正しく表示される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - controller指定
      ///
      /// 期待結果:
      /// - TextFieldがレンダリングされる
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-001: TextFieldが正しく表示される', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(TextField), findsOneWidget);
      });

      /// TC-TIF-002: hintTextが表示される
      ///
      /// 前提条件:
      /// - controllerが空
      ///
      /// 入力:
      /// - hintText: 'ここに入力してください'
      ///
      /// 期待結果:
      /// - ヒントテキストが表示される
      ///
      /// 優先度: 高
      testWidgets('TC-TIF-002: hintTextが表示される', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
                hintText: 'ここに入力してください',
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('ここに入力してください'), findsOneWidget);
      });
    });

    // =========================================================================
    // 2.2 入力テスト
    // =========================================================================
    group('入力テスト', () {
      /// TC-TIF-003: テキスト入力ができる
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - 'こんにちは'
      ///
      /// 期待結果:
      /// - controllerにテキストが反映される
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-003: テキスト入力ができる', (tester) async {
        // Arrange
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), 'こんにちは');

        // Assert
        expect(controller.text, equals('こんにちは'));
      });

      /// TC-TIF-004: 1000文字まで入力できる
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - 1000文字のテキスト
      ///
      /// 期待結果:
      /// - 1000文字が入力される
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-004: 1000文字まで入力できる', (tester) async {
        // Arrange
        final controller = TextEditingController();
        final text = 'あ' * 1000;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), text);

        // Assert
        expect(controller.text.length, equals(1000));
      });

      /// TC-TIF-005: 1001文字以上は入力できない
      ///
      /// 前提条件:
      /// - maxLength: 1000（デフォルト）
      ///
      /// 入力:
      /// - 1001文字のテキスト
      ///
      /// 期待結果:
      /// - 1000文字で制限される
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-005: 1001文字以上は入力できない', (tester) async {
        // Arrange
        final controller = TextEditingController();
        final text = 'あ' * 1001;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), text);

        // Assert
        expect(
            controller.text.length, lessThanOrEqualTo(AppSizes.maxInputLength));
        expect(controller.text.length, lessThanOrEqualTo(1000));
      });
    });

    // =========================================================================
    // 2.3 クリアボタンテスト
    // =========================================================================
    group('クリアボタンテスト', () {
      /// TC-TIF-006: onClear指定時にクリアボタンが表示される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - onClear指定
      ///
      /// 期待結果:
      /// - クリアアイコンが表示される
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-006: onClear指定時にクリアボタンが表示される', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
                onClear: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      /// TC-TIF-007: クリアボタンタップでonClearが呼ばれる
      ///
      /// 前提条件:
      /// - テキスト入力済み
      ///
      /// 入力:
      /// - クリアボタンタップ
      ///
      /// 期待結果:
      /// - onClearコールバックが実行される
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-007: クリアボタンタップでonClearが呼ばれる', (tester) async {
        // Arrange
        final controller = TextEditingController(text: 'テスト');
        bool cleared = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
                onClear: () => cleared = true,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.clear));

        // Assert
        expect(cleared, isTrue);
      });

      /// TC-TIF-008: onClear未指定時はクリアボタンが非表示
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - onClear未指定
      ///
      /// 期待結果:
      /// - クリアボタンが表示されない
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-008: onClear未指定時はクリアボタンが非表示', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.clear), findsNothing);
      });
    });

    // =========================================================================
    // 2.4 スタイルテスト
    // =========================================================================
    group('スタイルテスト', () {
      /// TC-TIF-009: フォントサイズが24pxである
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - fontSize = 24.0
      ///
      /// 優先度: 必須
      testWidgets('TC-TIF-009: フォントサイズが24pxである', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.style?.fontSize, equals(AppSizes.fontSizeLarge));
        expect(textField.style?.fontSize, equals(24.0));
      });

      /// TC-TIF-010: 複数行入力が可能である
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - maxLines = null（無制限）
      ///
      /// 優先度: 高
      testWidgets('TC-TIF-010: 複数行入力が可能である', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLines, isNull);
      });
    });

    // =========================================================================
    // 2.5 状態テスト
    // =========================================================================
    group('状態テスト', () {
      /// TC-TIF-011: enabled: falseで無効化される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - enabled: false
      ///
      /// 期待結果:
      /// - TextFieldが無効化される
      ///
      /// 優先度: 高
      testWidgets('TC-TIF-011: enabled: falseで無効化される', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
                enabled: false,
              ),
            ),
          ),
        );

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);
      });

      /// TC-TIF-012: readOnly: trueで読み取り専用になる
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - readOnly: true
      ///
      /// 期待結果:
      /// - 読み取り専用になる
      ///
      /// 優先度: 高
      testWidgets('TC-TIF-012: readOnly: trueで読み取り専用になる', (tester) async {
        // Arrange
        final controller = TextEditingController(text: 'テスト');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
                readOnly: true,
              ),
            ),
          ),
        );

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.readOnly, isTrue);
      });

      /// TC-TIF-013: 文字数カウンターが表示される
      ///
      /// 前提条件:
      /// - なし
      ///
      /// 入力:
      /// - なし
      ///
      /// 期待結果:
      /// - 文字数カウンターが表示される（maxLengthが設定されている）
      ///
      /// 優先度: 高
      testWidgets('TC-TIF-013: 文字数カウンターが表示される', (tester) async {
        // Arrange
        final controller = TextEditingController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextInputField(
                controller: controller,
              ),
            ),
          ),
        );

        // Assert
        // maxLengthが設定されているとカウンターが自動表示される
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLength, equals(AppSizes.maxInputLength));
        expect(textField.maxLength, equals(1000));
      });
    });
  });
}
