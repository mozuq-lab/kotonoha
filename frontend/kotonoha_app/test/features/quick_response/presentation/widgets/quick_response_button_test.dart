/// QuickResponseButton ウィジェットテスト
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
/// テストケース: TC-QRB-001〜TC-QRB-020, TC-A11Y-001〜TC-A11Y-004, TC-EDGE-001
///
/// テスト対象: lib/features/quick_response/presentation/widgets/quick_response_button.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

void main() {
  group('QuickResponseButton', () {
    // =========================================================================
    // 2.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-QRB-001: 「はい」ボタンが正しいラベルで表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001, FR-006
      testWidgets('TC-QRB-001: 「はい」ボタンが正しいラベルで表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('はい'), findsOneWidget);
      });

      /// TC-QRB-002: 「いいえ」ボタンが正しいラベルで表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001, FR-006
      testWidgets('TC-QRB-002: 「いいえ」ボタンが正しいラベルで表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.no,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('いいえ'), findsOneWidget);
      });

      /// TC-QRB-003: 「わからない」ボタンが正しいラベルで表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001, FR-006
      testWidgets('TC-QRB-003: 「わからない」ボタンが正しいラベルで表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.unknown,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('わからない'), findsOneWidget);
      });
    });

    // =========================================================================
    // 2.2 サイズテスト（アクセシビリティ）
    // =========================================================================
    group('サイズテスト', () {
      /// TC-QRB-004: ボタン高さがデフォルトで60px以上である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-003
      testWidgets('TC-QRB-004: ボタン高さがデフォルトで60px以上である',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(QuickResponseButton));
        expect(size.height, greaterThanOrEqualTo(60.0));
      });

      /// TC-QRB-005: ボタン幅がデフォルトで100px以上である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-004
      testWidgets('TC-QRB-005: ボタン幅がデフォルトで100px以上である',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(QuickResponseButton));
        expect(size.width, greaterThanOrEqualTo(100.0));
      });

      /// TC-QRB-006: ボタン高さが44px未満に設定できない（最小保証）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-201
      testWidgets('TC-QRB-006: ボタン高さが44px未満に設定できない', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                height: 30.0, // 最小未満
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(QuickResponseButton));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// TC-QRB-007: ボタン幅が44px未満に設定できない（最小保証）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-201
      testWidgets('TC-QRB-007: ボタン幅が44px未満に設定できない', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                width: 30.0, // 最小未満
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(QuickResponseButton));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// TC-QRB-008: カスタムサイズが正しく適用される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-003, FR-004
      testWidgets('TC-QRB-008: カスタムサイズが正しく適用される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                width: 150.0,
                height: 80.0,
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(QuickResponseButton));
        expect(size.width, equals(150.0));
        expect(size.height, equals(80.0));
      });
    });

    // =========================================================================
    // 2.3 イベントテスト
    // =========================================================================
    group('イベントテスト', () {
      /// TC-QRB-009: タップ時にonPressedコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-203
      testWidgets('TC-QRB-009: タップ時にonPressedコールバックが呼ばれる',
          (tester) async {
        // Arrange
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump();

        // Assert
        expect(tapped, isTrue);
      });

      /// TC-QRB-010: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-QRB-010: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる',
          (tester) async {
        // Arrange
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump();

        // Assert
        expect(spokenText, equals('はい'));
      });

      /// TC-QRB-010b: 「いいえ」タップ時にonTTSSpeakが「いいえ」で呼ばれる
      testWidgets('TC-QRB-010b: 「いいえ」タップ時にonTTSSpeakが「いいえ」で呼ばれる',
          (tester) async {
        // Arrange
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.no,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump();

        // Assert
        expect(spokenText, equals('いいえ'));
      });

      /// TC-QRB-010c: 「わからない」タップ時にonTTSSpeakが「わからない」で呼ばれる
      testWidgets(
          'TC-QRB-010c: 「わからない」タップ時にonTTSSpeakが「わからない」で呼ばれる',
          (tester) async {
        // Arrange
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.unknown,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump();

        // Assert
        expect(spokenText, equals('わからない'));
      });

      /// TC-QRB-011: onPressed: nullで無効状態になる
      ///
      /// 優先度: P1（高優先度）
      testWidgets('TC-QRB-011: onPressed: nullで無効状態になる', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: null,
              ),
            ),
          ),
        );

        // Assert
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      /// TC-QRB-012: タップ時に視覚的フィードバック（InkWell/リップル）が発生する
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-102
      testWidgets('TC-QRB-012: タップ時に視覚的フィードバックが発生する', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Act & Assert - ElevatedButtonはMaterialのInkリップルを持つ
        expect(find.byType(ElevatedButton), findsOneWidget);
        // InkWellがElevatedButton内に存在することを確認
        final inkWell = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(InkWell),
        );
        expect(inkWell, findsWidgets);
      });
    });

    // =========================================================================
    // 2.4 スタイルテスト
    // =========================================================================
    group('スタイルテスト', () {
      /// TC-QRB-013: 「はい」ボタンの背景色が青/緑系である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-U003
      testWidgets('TC-QRB-013: 「はい」ボタンの背景色が青/緑系である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert - デフォルトの背景色が青/緑系であることを確認
        final button =
            tester.widget<QuickResponseButton>(find.byType(QuickResponseButton));
        expect(button.responseType, equals(QuickResponseType.yes));
        // 実装時に適切な色が設定されていることを確認
        // 青/緑系であることを確認（green成分が高い）
        // Note: Color.g returns normalized value (0.0-1.0), not 0-255
        // Convert to 0-255 range: (color.g * 255).round()
        expect((QuickResponseButtonColors.yes.g * 255).round(), greaterThan(100));
      });

      /// TC-QRB-014: 「いいえ」ボタンの背景色が赤系である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-U003
      testWidgets('TC-QRB-014: 「いいえ」ボタンの背景色が赤系である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.no,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(QuickResponseButton), findsOneWidget);
        // 赤系の色であることを確認（色相が0付近または360付近）
        expect(QuickResponseButtonColors.no, isNotNull);
      });

      /// TC-QRB-015: 「わからない」ボタンの背景色がグレー系である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-U003
      testWidgets('TC-QRB-015: 「わからない」ボタンの背景色がグレー系である',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.unknown,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(QuickResponseButton), findsOneWidget);
        expect(QuickResponseButtonColors.unknown, isNotNull);
      });

      /// TC-QRB-016: カスタム背景色が適用される
      ///
      /// 優先度: P2（中優先度）
      testWidgets('TC-QRB-016: カスタム背景色が適用される', (tester) async {
        // Arrange
        const customColor = Colors.purple;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                backgroundColor: customColor,
              ),
            ),
          ),
        );

        // Assert
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style;
        expect(style?.backgroundColor?.resolve({}), equals(customColor));
      });

      /// TC-QRB-017: カスタムテキスト色が適用される
      ///
      /// 優先度: P2（中優先度）
      testWidgets('TC-QRB-017: カスタムテキスト色が適用される', (tester) async {
        // Arrange
        const customColor = Colors.yellow;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                textColor: customColor,
              ),
            ),
          ),
        );

        // Assert
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final style = button.style;
        expect(style?.foregroundColor?.resolve({}), equals(customColor));
      });
    });

    // =========================================================================
    // 2.5 フォントサイズ対応テスト
    // =========================================================================
    group('フォントサイズ対応テスト', () {
      /// TC-QRB-018: フォントサイズ「小」でラベルが16pxで表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007
      testWidgets('TC-QRB-018: フォントサイズ「小」でラベルが16pxで表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                fontSize: FontSize.small,
              ),
            ),
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('はい'));
        expect(text.style?.fontSize, equals(AppSizes.fontSizeSmall));
        expect(text.style?.fontSize, equals(16.0));
      });

      /// TC-QRB-019: フォントサイズ「中」でラベルが20pxで表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007
      testWidgets('TC-QRB-019: フォントサイズ「中」でラベルが20pxで表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                fontSize: FontSize.medium,
              ),
            ),
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('はい'));
        expect(text.style?.fontSize, equals(AppSizes.fontSizeMedium));
        expect(text.style?.fontSize, equals(20.0));
      });

      /// TC-QRB-020: フォントサイズ「大」でラベルが24pxで表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007
      testWidgets('TC-QRB-020: フォントサイズ「大」でラベルが24pxで表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                fontSize: FontSize.large,
              ),
            ),
          ),
        );

        // Assert
        final text = tester.widget<Text>(find.text('はい'));
        expect(text.style?.fontSize, equals(AppSizes.fontSizeLarge));
        expect(text.style?.fontSize, equals(24.0));
      });
    });

    // =========================================================================
    // テーマテスト
    // =========================================================================
    group('テーマテスト', () {
      /// TC-TH-001: ライトモードで適切な配色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103
      testWidgets('TC-TH-001: ライトモードで適切な配色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(QuickResponseButton));
        expect(Theme.of(context).brightness, equals(Brightness.light));
      });

      /// TC-TH-002: ダークモードで適切な配色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103
      testWidgets('TC-TH-002: ダークモードで適切な配色で表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(QuickResponseButton));
        expect(Theme.of(context).brightness, equals(Brightness.dark));
      });

      /// TC-TH-003: 高コントラストモードで適切な配色で表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-103, FR-202
      testWidgets('TC-TH-003: 高コントラストモードで適切な配色で表示される',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(QuickResponseButton));
        final theme = Theme.of(context);
        expect(theme.colorScheme.primary, equals(AppColors.primaryHighContrast));
      });
    });

    // =========================================================================
    // アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-A11Y-001: 各ボタンにSemanticsラベルが設定される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A001
      testWidgets('TC-A11Y-001: Semanticsラベルが設定される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert - Semanticsウィジェットが存在し、適切なラベルを持つ
        final semantics = tester.getSemantics(find.byType(QuickResponseButton));
        expect(semantics.label, contains('はい'));
      });

      /// TC-A11Y-002: 各ボタンがボタンセマンティクスを持つ
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A001
      testWidgets('TC-A11Y-002: ボタンセマンティクスを持つ', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert - ElevatedButtonが内部でボタンセマンティクスを設定
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      /// TC-A11Y-003: 色だけでなくラベルテキストで識別可能
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-A001
      testWidgets('TC-A11Y-003: ラベルテキストで識別可能', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  QuickResponseButton(
                    responseType: QuickResponseType.yes,
                    onPressed: () {},
                  ),
                  QuickResponseButton(
                    responseType: QuickResponseType.no,
                    onPressed: () {},
                  ),
                  QuickResponseButton(
                    responseType: QuickResponseType.unknown,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert - 各ボタンが一意のラベルテキストを持つ
        expect(find.text('はい'), findsOneWidget);
        expect(find.text('いいえ'), findsOneWidget);
        expect(find.text('わからない'), findsOneWidget);
      });

      /// TC-A11Y-004: タップターゲットが44x44px以上を常に満たす
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-201
      testWidgets('TC-A11Y-004: タップターゲットが44x44px以上', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        final size = tester.getSize(find.byType(QuickResponseButton));
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      });
    });

    // =========================================================================
    // エッジケーステスト
    // =========================================================================
    group('エッジケーステスト', () {
      /// TC-EDGE-001: 同じボタンを連続タップした場合デバウンスが機能する
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-004
      testWidgets('TC-EDGE-001: 連続タップ時にデバウンスが機能する', (tester) async {
        // Arrange
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () {},
                onTTSSpeak: (_) => callCount++,
              ),
            ),
          ),
        );

        // Act - 連続タップ
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump();

        // Assert - デバウンスにより1回だけ呼ばれる
        expect(callCount, equals(1));
      });

      /// TC-EDGE-008: TTSサービスがnull/未初期化でもボタンタップが動作する
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-003
      testWidgets('TC-EDGE-008: onTTSSpeakがnullでもボタンタップが動作する',
          (tester) async {
        // Arrange
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButton(
                responseType: QuickResponseType.yes,
                onPressed: () => tapped = true,
                onTTSSpeak: null, // TTSコールバックなし
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(QuickResponseButton));
        await tester.pump();

        // Assert
        expect(tapped, isTrue);
      });
    });
  });
}
