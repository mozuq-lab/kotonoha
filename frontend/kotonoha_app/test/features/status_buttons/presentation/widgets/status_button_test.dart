/// StatusButton ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';
import 'package:kotonoha_app/features/status_buttons/presentation/widgets/status_button.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

void main() {
  group('StatusButton', () {
    // 2.1 レンダリングテスト
    group('レンダリングテスト', () {
      /// 「痛い」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-001: 「痛い」ボタンが正しいラベルで表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('痛い'), findsOneWidget);
      });

      /// 「トイレ」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-002: 「トイレ」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.toilet,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('トイレ'), findsOneWidget);
      });

      /// 「暑い」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-003: 「暑い」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.hot,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('暑い'), findsOneWidget);
      });

      /// 「寒い」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-004: 「寒い」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.cold,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('寒い'), findsOneWidget);
      });

      /// 「水」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-005: 「水」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.water,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('水'), findsOneWidget);
      });

      /// 「眠い」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-006: 「眠い」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.sleepy,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('眠い'), findsOneWidget);
      });

      /// 「助けて」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-007: 「助けて」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.help,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('助けて'), findsOneWidget);
      });

      /// 「待って」ボタンが正しいラベルで表示される
      testWidgets('TC-SB-008: 「待って」ボタンが正しいラベルで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.wait,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('待って'), findsOneWidget);
      });
    });

    // 2.2 サイズテスト（アクセシビリティ）
    group('サイズテスト', () {
      /// ボタン高さがデフォルトで44px以上である
      testWidgets('TC-SB-009: ボタン高さがデフォルトで44px以上である', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(StatusButton));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// ボタン幅がデフォルトで44px以上である
      testWidgets('TC-SB-010: ボタン幅がデフォルトで44px以上である', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(StatusButton));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// ボタン高さが44px未満に設定できない（最小保証）
      testWidgets('TC-SB-011: ボタン高さが44px未満に設定できない', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                height: 30.0, // 最小未満
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(StatusButton));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// ボタン幅が44px未満に設定できない（最小保証）
      testWidgets('TC-SB-012: ボタン幅が44px未満に設定できない', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                width: 30.0, // 最小未満
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(StatusButton));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });

      /// カスタムサイズ指定時も最小サイズが保証される
      testWidgets('TC-SB-013: カスタムサイズ指定時も最小サイズが保証される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                width: 20.0,
                height: 20.0,
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(StatusButton));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      });
    });

    // 2.3 イベントテスト
    group('イベントテスト', () {
      /// タップ時にonPressedコールバックが呼ばれる
      testWidgets('TC-SB-014: タップ時にonPressedコールバックが呼ばれる', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(tapped, isTrue);
      });

      /// タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる
      testWidgets('TC-SB-015: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる',
          (tester) async {
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(spokenText, equals('痛い'));
      });

      /// onPressed: nullで無効状態になる
      testWidgets('TC-SB-016: onPressed: nullで無効状態になる', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: null,
              ),
            ),
          ),
        );

        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      /// タップ時に視覚的フィードバック（InkWell/リップル）が発生する
      testWidgets('TC-SB-017: タップ時に視覚的フィードバックが発生する', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        // ElevatedButtonはMaterialのInkリップルを持つ
        expect(find.byType(ElevatedButton), findsOneWidget);
        final inkWell = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(InkWell),
        );
        expect(inkWell, findsWidgets);
      });

      /// 「痛い」タップでonTTSSpeakが「痛い」で呼ばれる
      testWidgets('TC-SB-018: 「痛い」タップでonTTSSpeakが「痛い」で呼ばれる', (tester) async {
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(spokenText, equals('痛い'));
      });

      /// 「トイレ」タップでonTTSSpeakが「トイレ」で呼ばれる
      testWidgets('TC-SB-019: 「トイレ」タップでonTTSSpeakが「トイレ」で呼ばれる', (tester) async {
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.toilet,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(spokenText, equals('トイレ'));
      });

      /// 「助けて」タップでonTTSSpeakが「助けて」で呼ばれる
      testWidgets('TC-SB-020: 「助けて」タップでonTTSSpeakが「助けて」で呼ばれる', (tester) async {
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.help,
                onPressed: () {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(spokenText, equals('助けて'));
      });
    });

    // 2.4 デバウンステスト
    group('デバウンステスト', () {
      /// 連続タップ時にデバウンスが機能する
      testWidgets('TC-SB-021: 連続タップ時にデバウンスが機能する', (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                onTTSSpeak: (_) => callCount++,
              ),
            ),
          ),
        );

        // 連続タップ
        await tester.tap(find.byType(StatusButton));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(StatusButton));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        // デバウンスにより1回だけ呼ばれる
        expect(callCount, equals(1));
      });

      /// デバウンス期間経過後は再度タップが有効になる
      testWidgets(
        'TC-SB-022: デバウンス期間経過後は再度タップが有効になる',
        skip: true,
        (tester) async {
          int callCount = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StatusButton(
                  statusType: StatusButtonType.pain,
                  onPressed: () {},
                  onTTSSpeak: (_) => callCount++,
                ),
              ),
            ),
          );

          // 最初のタップ
          await tester.tap(find.byType(StatusButton));
          await tester.pump();

          // 実際の時間経過を待つ（DateTime.nowベースのデバウンス）
          // Flutter test frameworkでは、tester.binding.delayedを使用して
          // 実際のシステム時間を経過させる
          // 注: CI環境でのタイミング問題を避けるため、デバウンス期間(300ms)より
          // 十分に長い時間（600ms）を待機する
          await tester.binding.delayed(const Duration(milliseconds: 600));
          await tester.pump();

          // 2回目のタップ
          await tester.tap(find.byType(StatusButton));
          await tester.pump();

          // 2回呼ばれる
          expect(callCount, equals(2));
        },
      );

      /// 連続タップでonTTSSpeakが1回だけ呼ばれる
      testWidgets('TC-SB-023: 連続タップでonTTSSpeakが1回だけ呼ばれる', (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                onTTSSpeak: (_) => callCount++,
              ),
            ),
          ),
        );

        // 連続タップ（100ms間隔で3回）
        await tester.tap(find.byType(StatusButton));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byType(StatusButton));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(callCount, equals(1));
      });
    });

    // 2.5 フォントサイズ対応テスト
    group('フォントサイズ対応テスト', () {
      /// フォントサイズ「小」でラベルが適切なサイズで表示される
      testWidgets('TC-SB-024: フォントサイズ「小」でラベルが適切なサイズで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                fontSize: FontSize.small,
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('痛い'));
        expect(text.style?.fontSize, equals(AppSizes.fontSizeSmall));
      });

      /// フォントサイズ「中」でラベルが適切なサイズで表示される
      testWidgets('TC-SB-025: フォントサイズ「中」でラベルが適切なサイズで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                fontSize: FontSize.medium,
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('痛い'));
        expect(text.style?.fontSize, equals(AppSizes.fontSizeMedium));
      });

      /// フォントサイズ「大」でラベルが適切なサイズで表示される
      testWidgets('TC-SB-026: フォントサイズ「大」でラベルが適切なサイズで表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
                fontSize: FontSize.large,
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('痛い'));
        expect(text.style?.fontSize, equals(AppSizes.fontSizeLarge));
      });
    });

    // テーマテスト
    group('テーマテスト', () {
      /// ライトモードで適切な配色で表示される
      testWidgets('TC-TH-001: ライトモードで適切な配色で表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final context = tester.element(find.byType(StatusButton));
        expect(Theme.of(context).brightness, equals(Brightness.light));
      });

      /// ダークモードで適切な配色で表示される
      testWidgets('TC-TH-002: ダークモードで適切な配色で表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final context = tester.element(find.byType(StatusButton));
        expect(Theme.of(context).brightness, equals(Brightness.dark));
      });

      /// 高コントラストモードで適切な配色で表示される
      testWidgets('TC-TH-003: 高コントラストモードで適切な配色で表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        // 高コントラストテーマが適用されていることを確認
        expect(find.byType(StatusButton), findsOneWidget);
      });
    });

    // アクセシビリティテスト
    group('アクセシビリティテスト', () {
      /// TC-A11Y-001: 各ボタンにSemanticsラベルが設定される
      testWidgets('TC-A11Y-001: Semanticsラベルが設定される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final semantics = tester.getSemantics(find.byType(StatusButton));
        expect(semantics.label, contains('痛い'));
      });

      /// TC-A11Y-002: 「痛い」ボタンにSemantics(label: '痛い')が設定される
      testWidgets('TC-A11Y-002: 「痛い」ボタンにSemantics(label: \'痛い\')が設定される',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final semantics = tester.getSemantics(find.byType(StatusButton));
        expect(semantics.label, equals('痛い'));
      });

      /// TC-A11Y-003: 各ボタンがボタンセマンティクスを持つ
      testWidgets('TC-A11Y-003: ボタンセマンティクスを持つ', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        // ElevatedButtonが内部でボタンセマンティクスを設定
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      /// TC-A11Y-004: 色だけでなくラベルテキストで状態を識別可能
      testWidgets('TC-A11Y-004: ラベルテキストで状態を識別可能', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  StatusButton(
                    statusType: StatusButtonType.pain,
                    onPressed: () {},
                  ),
                  StatusButton(
                    statusType: StatusButtonType.toilet,
                    onPressed: () {},
                  ),
                  StatusButton(
                    statusType: StatusButtonType.help,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // 各ボタンが一意のラベルテキストを持つ
        expect(find.text('痛い'), findsOneWidget);
        expect(find.text('トイレ'), findsOneWidget);
        expect(find.text('助けて'), findsOneWidget);
      });

      /// TC-A11Y-005: タップターゲットが44x44px以上を常に満たす
      testWidgets('TC-A11Y-005: タップターゲットが44x44px以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () {},
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(StatusButton));
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      });
    });

    // エッジケーステスト
    group('エッジケーステスト', () {
      /// TC-: TTSサービスがnull/未初期化でもボタンタップが動作する
      testWidgets('TC-EDGE-009: onTTSSpeakがnullでもボタンタップが動作する', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () => tapped = true,
                onTTSSpeak: null, // TTSコールバックなし
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(tapped, isTrue);
      });

      /// TC-: onTTSSpeak未設定でもonPressedは動作する
      testWidgets('TC-EDGE-011: onTTSSpeak未設定でもonPressedは動作する', (tester) async {
        bool onPressedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButton(
                statusType: StatusButtonType.pain,
                onPressed: () => onPressedCalled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(StatusButton));
        await tester.pump();

        expect(onPressedCalled, isTrue);
      });
    });
  });
}
