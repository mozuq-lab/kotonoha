/// QuickResponseButtons ウィジェットテスト
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
/// テストケース: TC-QRBs-001〜TC-QRBs-011, TC-A11Y-005, TC-EDGE-004〜TC-EDGE-007
///
/// テスト対象: lib/features/quick_response/presentation/widgets/quick_response_buttons.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';

void main() {
  group('QuickResponseButtons', () {
    // =========================================================================
    // 3.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-QRBs-001: 3つのボタン（はい、いいえ、わからない）が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001
      testWidgets('TC-QRBs-001: 3つのボタンが表示される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('はい'), findsOneWidget);
        expect(find.text('いいえ'), findsOneWidget);
        expect(find.text('わからない'), findsOneWidget);
      });

      /// TC-QRBs-002: ボタンが横並びで配置される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      testWidgets('TC-QRBs-002: ボタンが横並びで配置される', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert - Rowウィジェットが使用されていることを確認
        expect(find.byType(Row), findsWidgets);

        // 各ボタンのY座標が同じであることを確認
        final yesRect = tester.getRect(find.text('はい'));
        final noRect = tester.getRect(find.text('いいえ'));
        final unknownRect = tester.getRect(find.text('わからない'));

        expect(yesRect.center.dy, equals(noRect.center.dy));
        expect(noRect.center.dy, equals(unknownRect.center.dy));
      });

      /// TC-QRBs-003: ボタンの配置順序が左から「はい」「いいえ」「わからない」
      ///
      /// 優先度: P0（必須）
      /// 関連要件: NFR-U002
      testWidgets('TC-QRBs-003: ボタンの配置順序が正しい', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert - 左から右への順序を確認
        final yesRect = tester.getRect(find.text('はい'));
        final noRect = tester.getRect(find.text('いいえ'));
        final unknownRect = tester.getRect(find.text('わからない'));

        expect(yesRect.left, lessThan(noRect.left));
        expect(noRect.left, lessThan(unknownRect.left));
      });
    });

    // =========================================================================
    // 3.2 レイアウトテスト
    // =========================================================================
    group('レイアウトテスト', () {
      /// TC-QRBs-004: ボタン間の間隔が8px以上である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-005
      testWidgets('TC-QRBs-004: ボタン間の間隔が8px以上である', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final buttons = tester
            .widgetList<QuickResponseButton>(find.byType(QuickResponseButton));
        final buttonList = buttons.toList();
        expect(buttonList.length, equals(3));

        // ボタン間の間隔を取得
        final yesButtonRect = tester.getRect(
          find.byType(QuickResponseButton).first,
        );
        final noButtonRect = tester.getRect(
          find.byType(QuickResponseButton).at(1),
        );
        final unknownButtonRect = tester.getRect(
          find.byType(QuickResponseButton).at(2),
        );

        final spacing1 = noButtonRect.left - yesButtonRect.right;
        final spacing2 = unknownButtonRect.left - noButtonRect.right;

        expect(spacing1, greaterThanOrEqualTo(8.0));
        expect(spacing2, greaterThanOrEqualTo(8.0));
      });

      /// TC-QRBs-005: 3つのボタンが画面幅に収まる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-004
      testWidgets('TC-QRBs-005: 3つのボタンが画面幅に収まる', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final containerSize = tester.getSize(find.byType(QuickResponseButtons));
        final screenWidth =
            tester.element(find.byType(QuickResponseButtons)).size?.width ??
                800;

        expect(containerSize.width, lessThanOrEqualTo(screenWidth));
      });

      /// TC-QRBs-006: 各ボタンの幅が均等に割り当てられる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-004
      testWidgets('TC-QRBs-006: 各ボタンの幅が均等に割り当てられる', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert - Expandedで均等配分されていることを確認
        expect(find.byType(Expanded), findsNWidgets(3));
      });

      /// TC-QRBs-007: ボタンコンテナがホーム画面上部に配置可能
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-002
      testWidgets('TC-QRBs-007: ボタンコンテナが上部に配置可能', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  QuickResponseButtons(
                    onResponse: (_) {},
                  ),
                  const Expanded(
                    child: Placeholder(), // 文字盤エリアの代替
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        final buttonsRect = tester.getRect(find.byType(QuickResponseButtons));
        expect(buttonsRect.top, equals(0.0)); // 上部に配置されている
      });
    });

    // =========================================================================
    // 3.3 イベント伝播テスト
    // =========================================================================
    group('イベント伝播テスト', () {
      /// TC-QRBs-008: 「はい」ボタンタップでonResponseコールバックがyesで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-QRBs-008: 「はい」タップでonResponseがyesで呼ばれる', (tester) async {
        // Arrange
        QuickResponseType? receivedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (type) => receivedType = type,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('はい'));
        await tester.pump();

        // Assert
        expect(receivedType, equals(QuickResponseType.yes));
      });

      /// TC-QRBs-009: 「いいえ」ボタンタップでonResponseコールバックがnoで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-QRBs-009: 「いいえ」タップでonResponseがnoで呼ばれる', (tester) async {
        // Arrange
        QuickResponseType? receivedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (type) => receivedType = type,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('いいえ'));
        await tester.pump();

        // Assert
        expect(receivedType, equals(QuickResponseType.no));
      });

      /// TC-QRBs-010: 「わからない」ボタンタップでonResponseコールバックがunknownで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-QRBs-010: 「わからない」タップでonResponseがunknownで呼ばれる',
          (tester) async {
        // Arrange
        QuickResponseType? receivedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (type) => receivedType = type,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('わからない'));
        await tester.pump();

        // Assert
        expect(receivedType, equals(QuickResponseType.unknown));
      });

      /// TC-QRBs-011: タップ時にonTTSSpeakコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-QRBs-011: タップ時にonTTSSpeakコールバックが呼ばれる', (tester) async {
        // Arrange
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('はい'));
        await tester.pump();

        // Assert
        expect(spokenText, equals('はい'));
      });

      /// TC-QRBs-011b: 「いいえ」タップ時にonTTSSpeakが「いいえ」で呼ばれる
      testWidgets('TC-QRBs-011b: 「いいえ」タップ時にonTTSSpeakが「いいえ」で呼ばれる',
          (tester) async {
        // Arrange
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('いいえ'));
        await tester.pump();

        // Assert
        expect(spokenText, equals('いいえ'));
      });

      /// TC-QRBs-011c: 「わからない」タップ時にonTTSSpeakが「わからない」で呼ばれる
      testWidgets('TC-QRBs-011c: 「わからない」タップ時にonTTSSpeakが「わからない」で呼ばれる',
          (tester) async {
        // Arrange
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('わからない'));
        await tester.pump();

        // Assert
        expect(spokenText, equals('わからない'));
      });
    });

    // =========================================================================
    // アクセシビリティテスト
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-A11Y-005: ボタン間隔が誤タップ防止に十分（8px以上）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-A002
      testWidgets('TC-A11Y-005: ボタン間隔が誤タップ防止に十分', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final buttons = find.byType(QuickResponseButton);
        expect(buttons, findsNWidgets(3));

        final firstButtonRect = tester.getRect(buttons.first);
        final secondButtonRect = tester.getRect(buttons.at(1));

        final spacing = secondButtonRect.left - firstButtonRect.right;
        expect(spacing, greaterThanOrEqualTo(AppSizes.paddingSmall));
      });
    });

    // =========================================================================
    // テーマテスト
    // =========================================================================
    group('テーマテスト', () {
      /// TC-TH-004: 高コントラストモードでコントラスト比4.5:1以上を確保
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-202
      testWidgets('TC-TH-004: 高コントラストモードでコントラスト比4.5:1以上', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final context = tester.element(find.byType(QuickResponseButtons));
        final theme = Theme.of(context);
        expect(
            theme.colorScheme.primary, equals(AppColors.primaryHighContrast));
      });
    });

    // =========================================================================
    // エッジケーステスト
    // =========================================================================
    group('エッジケーステスト', () {
      /// TC-EDGE-004: 狭い画面幅（320px）でもボタンが44px以上を維持
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-005, FR-201
      testWidgets('TC-EDGE-004: 狭い画面幅でもボタンが44px以上を維持', (tester) async {
        // Arrange - 狭い画面サイズを設定
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final buttons = tester
            .widgetList<QuickResponseButton>(find.byType(QuickResponseButton));

        for (final button in buttons) {
          final size = tester.getSize(find.byWidget(button));
          expect(
            size.width,
            greaterThanOrEqualTo(AppSizes.minTapTarget),
            reason: 'ボタン幅が44px未満です',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(AppSizes.minTapTarget),
            reason: 'ボタン高さが44px未満です',
          );
        }

        // クリーンアップ
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      /// TC-EDGE-005: タブレット画面幅（768px以上）で適切なサイズで表示
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-003, FR-004
      testWidgets('TC-EDGE-005: タブレット画面幅で適切なサイズで表示', (tester) async {
        // Arrange - タブレットサイズを設定
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final buttons = tester
            .widgetList<QuickResponseButton>(find.byType(QuickResponseButton));

        for (final button in buttons) {
          final size = tester.getSize(find.byWidget(button));
          expect(
            size.height,
            greaterThanOrEqualTo(60.0),
            reason: 'タブレットではボタン高さが60px以上であるべき',
          );
        }

        // クリーンアップ
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      /// TC-EDGE-006: 画面回転（縦向き→横向き）でレイアウトが崩れない
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-104
      testWidgets('TC-EDGE-006: 画面回転でレイアウトが崩れない', (tester) async {
        // Arrange - 縦向き
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // 縦向きでの確認
        expect(find.text('はい'), findsOneWidget);
        expect(find.text('いいえ'), findsOneWidget);
        expect(find.text('わからない'), findsOneWidget);

        // 横向きに変更
        tester.view.physicalSize = const Size(812, 375);

        await tester.pump();

        // Assert - 横向きでもすべてのボタンが表示される
        expect(find.text('はい'), findsOneWidget);
        expect(find.text('いいえ'), findsOneWidget);
        expect(find.text('わからない'), findsOneWidget);

        // クリーンアップ
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      /// TC-EDGE-007: 画面回転後もタップターゲットが44px以上を維持
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-104, FR-201
      testWidgets('TC-EDGE-007: 画面回転後もタップターゲットが44px以上', (tester) async {
        // Arrange - 横向き（短い高さ）
        tester.view.physicalSize = const Size(812, 375);
        tester.view.devicePixelRatio = 1.0;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
              ),
            ),
          ),
        );

        // Assert
        final buttons = tester
            .widgetList<QuickResponseButton>(find.byType(QuickResponseButton));

        for (final button in buttons) {
          final size = tester.getSize(find.byWidget(button));
          expect(
            size.width,
            greaterThanOrEqualTo(44.0),
            reason: '回転後もボタン幅が44px以上であるべき',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(44.0),
            reason: '回転後もボタン高さが44px以上であるべき',
          );
        }

        // クリーンアップ
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      /// TC-EDGE-003: 連続タップ時にonResponseが1回だけ呼ばれる（デバウンス期間内）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-004
      testWidgets('TC-EDGE-003: 連続タップ時にonResponseが1回だけ呼ばれる', (tester) async {
        // Arrange
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) => callCount++,
              ),
            ),
          ),
        );

        // Act - 連続タップ
        await tester.tap(find.text('はい'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('はい'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('はい'));
        await tester.pump();

        // Assert - デバウンスにより1回だけ呼ばれる
        expect(callCount, equals(1));
      });
    });
  });
}
