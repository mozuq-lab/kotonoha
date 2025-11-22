/// StatusButtons ウィジェットテスト
///
/// TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装
/// テストケース: TC-SBs-001〜TC-SBs-020, TC-EDGE-001〜TC-EDGE-014
///
/// テスト対象: lib/features/status_buttons/presentation/widgets/status_buttons.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';
import 'package:kotonoha_app/features/status_buttons/presentation/widgets/status_button.dart';
import 'package:kotonoha_app/features/status_buttons/presentation/widgets/status_buttons.dart';

void main() {
  group('StatusButtons', () {
    // =========================================================================
    // 3.1 レンダリングテスト
    // =========================================================================
    group('レンダリングテスト', () {
      /// TC-SBs-001: 8個以上の状態ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      testWidgets('TC-SBs-001: 8個以上の状態ボタンが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons = tester.widgetList(find.byType(StatusButton));
        expect(buttons.length, greaterThanOrEqualTo(8));
      });

      /// TC-SBs-002: 12個以下の状態ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      testWidgets('TC-SBs-002: 12個以下の状態ボタンが表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons = tester.widgetList(find.byType(StatusButton));
        expect(buttons.length, lessThanOrEqualTo(12));
      });

      /// TC-SBs-003: 必須の8個のボタンが全て表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001, FR-002
      testWidgets('TC-SBs-003: 必須の8個のボタンが全て表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        // 必須の8個のボタンが全て表示されていることを確認
        expect(find.text('痛い'), findsOneWidget);
        expect(find.text('トイレ'), findsOneWidget);
        expect(find.text('暑い'), findsOneWidget);
        expect(find.text('寒い'), findsOneWidget);
        expect(find.text('水'), findsOneWidget);
        expect(find.text('眠い'), findsOneWidget);
        expect(find.text('助けて'), findsOneWidget);
        expect(find.text('待って'), findsOneWidget);
      });

      /// TC-SBs-004: デフォルトで必須ボタンのみ表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-001
      testWidgets('TC-SBs-004: デフォルトで必須ボタンのみ表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        // 必須の8個のボタンが表示される
        final buttons = tester.widgetList(find.byType(StatusButton));
        expect(buttons.length, equals(8));
      });

      /// TC-SBs-005: オプションボタン追加時に最大12個まで表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-002
      testWidgets('TC-SBs-005: オプションボタン追加時に最大12個まで表示される',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
                statusTypes: StatusButtonType.values, // 全12個
              ),
            ),
          ),
        );

        final buttons = tester.widgetList(find.byType(StatusButton));
        expect(buttons.length, equals(12));
      });
    });

    // =========================================================================
    // 3.2 レイアウトテスト（グリッド配置）
    // =========================================================================
    group('レイアウトテスト', () {
      /// TC-SBs-006: ボタンがグリッド形式（横4列）で配置される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007
      testWidgets('TC-SBs-006: ボタンがグリッド形式（横4列）で配置される',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        // 最初の4つのボタンが同じY座標にあることを確認
        final buttons =
            tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

        if (buttons.length >= 4) {
          final firstRowY = tester.getRect(find.byWidget(buttons[0])).top;
          for (int i = 0; i < 4 && i < buttons.length; i++) {
            final buttonY = tester.getRect(find.byWidget(buttons[i])).top;
            expect(buttonY, equals(firstRowY));
          }
        }
      });

      /// TC-SBs-007: ボタン間の間隔が4px以上である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-008, NFR-A002
      testWidgets('TC-SBs-007: ボタン間の間隔が4px以上である', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons =
            tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

        if (buttons.length >= 2) {
          final firstButton = tester.getRect(find.byWidget(buttons[0]));
          final secondButton = tester.getRect(find.byWidget(buttons[1]));

          final spacing = secondButton.left - firstButton.right;
          expect(spacing, greaterThanOrEqualTo(4.0));
        }
      });

      /// TC-SBs-008: 8個のボタンが2行4列で配置される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007
      testWidgets('TC-SBs-008: 8個のボタンが2行4列で配置される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons =
            tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

        expect(buttons.length, equals(8));

        // 最初の4つは1行目、次の4つは2行目
        if (buttons.length >= 8) {
          final row1Y = tester.getRect(find.byWidget(buttons[0])).top;
          final row2Y = tester.getRect(find.byWidget(buttons[4])).top;

          // 1行目のボタンは同じY座標
          for (int i = 0; i < 4; i++) {
            final buttonY = tester.getRect(find.byWidget(buttons[i])).top;
            expect(buttonY, equals(row1Y));
          }

          // 2行目のボタンは同じY座標（1行目とは異なる）
          for (int i = 4; i < 8; i++) {
            final buttonY = tester.getRect(find.byWidget(buttons[i])).top;
            expect(buttonY, equals(row2Y));
          }

          // 行間に差があることを確認
          expect(row2Y, greaterThan(row1Y));
        }
      });

      /// TC-SBs-009: 12個のボタンが3行4列で配置される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-007
      testWidgets('TC-SBs-009: 12個のボタンが3行4列で配置される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
                statusTypes: StatusButtonType.values, // 全12個
              ),
            ),
          ),
        );

        final buttons =
            tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

        expect(buttons.length, equals(12));

        if (buttons.length >= 12) {
          final row1Y = tester.getRect(find.byWidget(buttons[0])).top;
          final row2Y = tester.getRect(find.byWidget(buttons[4])).top;
          final row3Y = tester.getRect(find.byWidget(buttons[8])).top;

          // 各行が異なるY座標にあることを確認
          expect(row2Y, greaterThan(row1Y));
          expect(row3Y, greaterThan(row2Y));
        }
      });

      /// TC-SBs-010: 各ボタンの幅が均等に割り当てられる
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-007
      testWidgets('TC-SBs-010: 各ボタンの幅が均等に割り当てられる', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons =
            tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

        if (buttons.length >= 4) {
          final widths = <double>[];
          for (int i = 0; i < 4; i++) {
            final size = tester.getSize(find.byWidget(buttons[i]));
            widths.add(size.width);
          }

          // 最初の4つのボタンは同じ幅（許容誤差1px）
          for (final width in widths) {
            expect((width - widths[0]).abs(), lessThanOrEqualTo(1.0));
          }
        }
      });
    });

    // =========================================================================
    // 3.3 イベント伝播テスト
    // =========================================================================
    group('イベント伝播テスト', () {
      /// TC-SBs-012: 「痛い」ボタンタップでonStatusコールバックがpainで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-SBs-012: 「痛い」ボタンタップでonStatusコールバックがpainで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('痛い'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.pain));
      });

      /// TC-SBs-013: 「トイレ」ボタンタップでonStatusコールバックがtoiletで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets(
          'TC-SBs-013: 「トイレ」ボタンタップでonStatusコールバックがtoiletで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('トイレ'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.toilet));
      });

      /// TC-SBs-014: 「暑い」ボタンタップでonStatusコールバックがhotで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-SBs-014: 「暑い」ボタンタップでonStatusコールバックがhotで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('暑い'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.hot));
      });

      /// TC-SBs-015: 「寒い」ボタンタップでonStatusコールバックがcoldで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-SBs-015: 「寒い」ボタンタップでonStatusコールバックがcoldで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('寒い'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.cold));
      });

      /// TC-SBs-016: 「水」ボタンタップでonStatusコールバックがwaterで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-SBs-016: 「水」ボタンタップでonStatusコールバックがwaterで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('水'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.water));
      });

      /// TC-SBs-017: 「眠い」ボタンタップでonStatusコールバックがsleepyで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets(
          'TC-SBs-017: 「眠い」ボタンタップでonStatusコールバックがsleepyで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('眠い'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.sleepy));
      });

      /// TC-SBs-018: 「助けて」ボタンタップでonStatusコールバックがhelpで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets(
          'TC-SBs-018: 「助けて」ボタンタップでonStatusコールバックがhelpで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('助けて'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.help));
      });

      /// TC-SBs-019: 「待って」ボタンタップでonStatusコールバックがwaitで呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets(
          'TC-SBs-019: 「待って」ボタンタップでonStatusコールバックがwaitで呼ばれる',
          (tester) async {
        StatusButtonType? tappedType;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (type) => tappedType = type,
              ),
            ),
          ),
        );

        await tester.tap(find.text('待って'));
        await tester.pump();

        expect(tappedType, equals(StatusButtonType.wait));
      });

      /// TC-SBs-020: タップ時にonTTSSpeakコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-101
      testWidgets('TC-SBs-020: タップ時にonTTSSpeakコールバックが呼ばれる',
          (tester) async {
        String? spokenText;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
                onTTSSpeak: (text) => spokenText = text,
              ),
            ),
          ),
        );

        await tester.tap(find.text('痛い'));
        await tester.pump();

        expect(spokenText, equals('痛い'));
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
      testWidgets('TC-EDGE-001: 同じボタンを連続タップした場合デバウンスが機能する',
          (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
                onTTSSpeak: (_) => callCount++,
              ),
            ),
          ),
        );

        // 連続タップ
        await tester.tap(find.text('痛い'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('痛い'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('痛い'));
        await tester.pump();

        // デバウンスにより1回だけ呼ばれる
        expect(callCount, equals(1));
      });

      /// TC-EDGE-003: 連続タップ時にonStatusが1回だけ呼ばれる（デバウンス期間内）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-004
      testWidgets('TC-EDGE-003: 連続タップ時にonStatusが1回だけ呼ばれる',
          (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) => callCount++,
              ),
            ),
          ),
        );

        // 連続タップ
        await tester.tap(find.text('痛い'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('痛い'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('痛い'));
        await tester.pump();

        // デバウンスにより1回だけ呼ばれる
        expect(callCount, equals(1));
      });

      /// TC-EDGE-004: 狭い画面幅（320px）でもボタンが44px以上を維持
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-005, FR-201
      testWidgets('TC-EDGE-004: 狭い画面幅（320px）でもボタンが44px以上を維持',
          (tester) async {
        // 狭い画面サイズを設定
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons = tester.widgetList<StatusButton>(
          find.byType(StatusButton),
        );

        for (final button in buttons) {
          final size = tester.getSize(find.byWidget(button));
          expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
          expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
        }

        // クリーンアップ
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      /// TC-EDGE-012: ボタン数が8個の場合に正しく表示される（最小値）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      testWidgets('TC-EDGE-012: ボタン数が8個の場合に正しく表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons = tester.widgetList(find.byType(StatusButton));
        expect(buttons.length, equals(8));
      });

      /// TC-EDGE-013: ボタン数が12個の場合に正しく表示される（最大値）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      testWidgets('TC-EDGE-013: ボタン数が12個の場合に正しく表示される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
                statusTypes: StatusButtonType.values, // 全12個
              ),
            ),
          ),
        );

        final buttons = tester.widgetList(find.byType(StatusButton));
        expect(buttons.length, equals(12));
      });

      /// TC-EDGE-014: ボタン間隔が4px（最小値）で正しく配置される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: FR-008
      testWidgets('TC-EDGE-014: ボタン間隔が4px以上で正しく配置される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusButtons(
                onStatus: (_) {},
              ),
            ),
          ),
        );

        final buttons =
            tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

        if (buttons.length >= 2) {
          final firstButton = tester.getRect(find.byWidget(buttons[0]));
          final secondButton = tester.getRect(find.byWidget(buttons[1]));

          final spacing = secondButton.left - firstButton.right;
          expect(spacing, greaterThanOrEqualTo(4.0));
        }
      });
    });
  });
}
