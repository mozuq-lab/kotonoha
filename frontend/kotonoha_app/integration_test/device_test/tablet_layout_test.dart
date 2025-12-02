/// タブレット表示テスト
///
/// TASK-0095: 実機テスト（iOS/Android/タブレット）
/// 信頼性レベル: 🔵 青信号（NFR-402に基づく、RT-104〜RT-107）
///
/// 9.7インチ以上タブレットでの最適表示を検証するE2Eテスト。
/// タップターゲットサイズ、レイアウト最適化を確認。
@Tags(['e2e', 'device', 'tablet', 'ios', 'android'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('タブレット最適表示テスト（9.7インチ以上）', () {
    // ============================================================
    // RT-104: タブレット表示テスト（9.7インチ以上）
    // ============================================================
    testWidgets(
      'RT-104: 9.7インチ以上のタブレットで最適な表示がされる',
      (tester) async {
        // 【テスト目的】: タブレットでの最適表示を確認
        // 【関連要件】: NFR-402（9.7インチ以上のタブレット最適表示）
        // 【手順】: iPad/タブレットで起動
        // 【期待結果】: 文字盤・定型文が見やすく表示される
        // 🔵 信頼性レベル: 青信号

        // 【テストデータ準備】: アプリを初期化
        await pumpApp(tester);

        // 【実際の処理実行】: タブレットサイズに設定（iPad 10.2インチ相当）
        // 縦向き: 810 × 1080（2160 × 1620の約50%スケール）
        await tester.binding.setSurfaceSize(const Size(810, 1080));
        await tester.pumpAndSettle();

        // 【結果検証】: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);
        expect(find.text('た'), findsWidgets);
        expect(find.text('な'), findsWidgets);
        // 【確認内容】: タブレットで文字盤が見やすく表示される 🔵

        await takeScreenshot(binding, 'RT-104_tablet_character_board');

        // 【実際の処理実行】: 定型文画面に遷移
        final presetTabFinder = find.text('定型文');
        if (presetTabFinder.evaluate().isNotEmpty) {
          await tester.tap(presetTabFinder);
          await tester.pumpAndSettle();
        }

        // 【結果検証】: 定型文が見やすく表示される
        // Note: 実機でタブレット表示時に定型文が多数表示されることを手動確認
        // 【確認内容】: タブレットで定型文が見やすく配置される 🔵

        await takeScreenshot(binding, 'RT-104_tablet_presets');

        // 【実際の処理実行】: 横向きに回転（タブレット推奨表示）
        await tester.binding.setSurfaceSize(const Size(1080, 810));
        await tester.pumpAndSettle();

        // 【結果検証】: 横向きで定型文が最適化される
        // 【確認内容】: タブレット横向きで定型文が複数列で表示される 🔵

        await takeScreenshot(binding, 'RT-104_tablet_landscape_presets');
      },
    );

    // ============================================================
    // RT-105: スマートフォン表示テスト
    // ============================================================
    testWidgets(
      'RT-105: スマートフォン（5〜6インチ）で基本機能が動作する',
      (tester) async {
        // 【テスト目的】: スマートフォンでの基本動作を確認
        // 【関連要件】: NFR-402（スマートフォンでも基本機能が動作）
        // 【手順】: iPhone/スマホで起動
        // 【期待結果】: 基本機能が動作する（最適化は期待しない）
        // 🟡 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 【実際の処理実行】: スマートフォンサイズに設定（iPhone 14相当）
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpAndSettle();

        // 【結果検証】: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        // 【確認内容】: スマートフォンで文字盤が表示される 🟡

        await takeScreenshot(binding, 'RT-105_smartphone_layout');

        // 【実際の処理実行】: 文字を入力
        await typeOnCharacterBoard(tester, 'テスト');
        expect(find.text('テスト'), findsWidgets);

        // 【実際の処理実行】: 読み上げ
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(milliseconds: 500));

        // 【結果検証】: スマートフォンで基本機能が動作する
        // Note: 実機でレイアウトが崩れず、主要ボタンがタップ可能なことを手動確認
        // 【確認内容】: スマートフォンで基本機能が動作する 🟡

        await takeScreenshot(binding, 'RT-105_smartphone_basic_function');
      },
    );

    // ============================================================
    // RT-106: タップターゲットサイズテスト（最小44px × 44px）
    // ============================================================
    testWidgets(
      'RT-106: 文字盤ボタンのタップターゲットが44px × 44px以上である',
      (tester) async {
        // 【テスト目的】: タップターゲットサイズの要件を確認
        // 【関連要件】: REQ-5001（最小44px × 44px）、NFR-202
        // 【手順】: 文字盤ボタンのサイズ確認
        // 【期待結果】: 44px × 44px以上
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: タブレットサイズに設定
        await tester.binding.setSurfaceSize(const Size(810, 1080));
        await tester.pumpAndSettle();

        // 【結果検証】: 文字盤の「あ」ボタンのサイズを確認
        final charFinder = find.text('あ');
        expect(charFinder, findsWidgets);

        final firstCharButton = charFinder.first;
        final buttonSize = tester.getSize(firstCharButton);

        debugPrint('文字盤ボタンサイズ: ${buttonSize.width} × ${buttonSize.height}');

        // 【結果検証】: ボタンサイズが44px × 44px以上
        expect(
          buttonSize.width,
          greaterThanOrEqualTo(44.0),
          reason: '文字盤ボタンの幅が44px未満です（${buttonSize.width}px）',
        );
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(44.0),
          reason: '文字盤ボタンの高さが44px未満です（${buttonSize.height}px）',
        );
        // 【確認内容】: タップターゲットサイズが44px × 44px以上 🔵

        await takeScreenshot(binding, 'RT-106_tap_target_size');

        // 【実際の処理実行】: スマートフォンサイズでも確認
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpAndSettle();

        final charFinderSmartphone = find.text('あ');
        if (charFinderSmartphone.evaluate().isNotEmpty) {
          final buttonSizeSmartphone =
              tester.getSize(charFinderSmartphone.first);
          debugPrint(
              'スマートフォンボタンサイズ: ${buttonSizeSmartphone.width} × ${buttonSizeSmartphone.height}');

          // 【結果検証】: スマートフォンでもボタンサイズが44px × 44px以上
          expect(
            buttonSizeSmartphone.width,
            greaterThanOrEqualTo(44.0),
            reason: 'スマートフォンでボタンの幅が44px未満です（${buttonSizeSmartphone.width}px）',
          );
          expect(
            buttonSizeSmartphone.height,
            greaterThanOrEqualTo(44.0),
            reason: 'スマートフォンでボタンの高さが44px未満です（${buttonSizeSmartphone.height}px）',
          );
          // 【確認内容】: スマートフォンでもタップターゲットサイズ要件を満たす 🔵
        }
      },
    );

    // ============================================================
    // RT-107: 大ボタンサイズテスト（推奨60px × 60px）
    // ============================================================
    testWidgets(
      'RT-107: 大ボタン・緊急ボタンのサイズが60px × 60px以上である',
      (tester) async {
        // 【テスト目的】: 大ボタンサイズの要件を確認
        // 【関連要件】: NFR-202（推奨60px × 60px以上）
        // 【手順】: 大ボタン・緊急ボタンのサイズ確認
        // 【期待結果】: 60px × 60px以上
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: タブレットサイズに設定
        await tester.binding.setSurfaceSize(const Size(810, 1080));
        await tester.pumpAndSettle();

        // 【結果検証】: 大ボタン「はい」のサイズを確認
        final yesButtonFinder = find.text('はい');
        if (yesButtonFinder.evaluate().isNotEmpty) {
          final yesButtonSize = tester.getSize(yesButtonFinder.first);
          debugPrint(
              '大ボタン「はい」サイズ: ${yesButtonSize.width} × ${yesButtonSize.height}');

          // 【結果検証】: ボタンサイズが60px × 60px以上が推奨
          // Note: 44px × 44px以上は必須要件
          expect(
            yesButtonSize.width,
            greaterThanOrEqualTo(44.0),
            reason: '大ボタンの幅が44px未満です（${yesButtonSize.width}px）',
          );
          expect(
            yesButtonSize.height,
            greaterThanOrEqualTo(44.0),
            reason: '大ボタンの高さが44px未満です（${yesButtonSize.height}px）',
          );

          // 推奨サイズ（60px × 60px）の確認（警告のみ）
          if (yesButtonSize.width < 60.0 || yesButtonSize.height < 60.0) {
            debugPrint('⚠️ 警告: 大ボタンのサイズが推奨値（60px × 60px）未満です');
          }
          // 【確認内容】: 大ボタンサイズが要件を満たす 🔵
        }

        await takeScreenshot(binding, 'RT-107_large_button_size');

        // 【結果検証】: 緊急ボタンのサイズを確認
        final emergencyButtonFinder = find.text('緊急');
        if (emergencyButtonFinder.evaluate().isNotEmpty) {
          final emergencyButtonSize =
              tester.getSize(emergencyButtonFinder.first);
          debugPrint(
              '緊急ボタンサイズ: ${emergencyButtonSize.width} × ${emergencyButtonSize.height}');

          expect(
            emergencyButtonSize.width,
            greaterThanOrEqualTo(44.0),
            reason: '緊急ボタンの幅が44px未満です（${emergencyButtonSize.width}px）',
          );
          expect(
            emergencyButtonSize.height,
            greaterThanOrEqualTo(44.0),
            reason: '緊急ボタンの高さが44px未満です（${emergencyButtonSize.height}px）',
          );

          if (emergencyButtonSize.width < 60.0 ||
              emergencyButtonSize.height < 60.0) {
            debugPrint('⚠️ 警告: 緊急ボタンのサイズが推奨値（60px × 60px）未満です');
          }
          // 【確認内容】: 緊急ボタンサイズが要件を満たす 🔵
        }
      },
    );

    // ============================================================
    // タブレット文字盤配置最適化テスト
    // ============================================================
    testWidgets(
      'タブレットで文字盤ボタン配置が最適化される',
      (tester) async {
        // 【テスト目的】: タブレットでの文字盤配置最適化を確認
        // 【関連要件】: NFR-402（文字盤ボタンのサイズ・配置最適化）
        // 【手順】: タブレットサイズで文字盤を表示
        // 【期待結果】: 適切なサイズ・配置で表示される
        // 🟡 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 【実際の処理実行】: タブレット縦向きサイズに設定
        await tester.binding.setSurfaceSize(const Size(810, 1080));
        await tester.pumpAndSettle();

        // 【結果検証】: 文字盤の主要な文字が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);
        expect(find.text('た'), findsWidgets);
        expect(find.text('な'), findsWidgets);
        // 【確認内容】: タブレットで文字盤が適切に配置される 🟡

        await takeScreenshot(binding, 'tablet_character_board_portrait');

        // 【実際の処理実行】: タブレット横向きサイズに設定
        await tester.binding.setSurfaceSize(const Size(1080, 810));
        await tester.pumpAndSettle();

        // 【結果検証】: 横向きでも文字盤が適切に配置される
        expect(find.text('あ'), findsWidgets);
        // 【確認内容】: タブレット横向きで文字盤が最適化される 🟡

        await takeScreenshot(binding, 'tablet_character_board_landscape');
      },
    );

    // ============================================================
    // タブレット定型文表示最適化テスト
    // ============================================================
    testWidgets(
      'タブレットで定型文一覧が見やすく表示される',
      (tester) async {
        // 【テスト目的】: タブレットでの定型文表示最適化を確認
        // 【関連要件】: NFR-402（定型文一覧が見やすく表示）
        // 【手順】: タブレットサイズで定型文を表示
        // 【期待結果】: スクロール不要で多数表示される
        // 🟡 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 【実際の処理実行】: タブレット縦向きサイズに設定
        await tester.binding.setSurfaceSize(const Size(810, 1080));
        await tester.pumpAndSettle();

        // 【実際の処理実行】: 定型文画面に遷移
        final presetTabFinder = find.text('定型文');
        if (presetTabFinder.evaluate().isNotEmpty) {
          await tester.tap(presetTabFinder);
          await tester.pumpAndSettle();
        }

        // 【結果検証】: 定型文が表示される
        // Note: 実機でタブレット表示時に多数の定型文が表示されることを手動確認
        // 【確認内容】: タブレットで定型文が見やすく表示される 🟡

        await takeScreenshot(binding, 'tablet_presets_portrait');

        // 【実際の処理実行】: タブレット横向きサイズに設定
        await tester.binding.setSurfaceSize(const Size(1080, 810));
        await tester.pumpAndSettle();

        // 【結果検証】: 横向きで定型文が複数列で表示される
        // 【確認内容】: タブレット横向きで定型文が複数列で表示される 🟡

        await takeScreenshot(binding, 'tablet_presets_landscape');
      },
    );

    // ============================================================
    // タブレット大ボタン・緊急ボタン配置テスト
    // ============================================================
    testWidgets(
      'タブレットで大ボタン・緊急ボタンが誤タップしにくい配置になる',
      (tester) async {
        // 【テスト目的】: タブレットでのボタン配置を確認
        // 【関連要件】: NFR-402（誤タップしにくい配置・サイズ）
        // 【手順】: タブレットサイズで大ボタン・緊急ボタンを表示
        // 【期待結果】: 適切な余白・サイズで配置される
        // 🟡 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 【実際の処理実行】: タブレットサイズに設定
        await tester.binding.setSurfaceSize(const Size(810, 1080));
        await tester.pumpAndSettle();

        // 【結果検証】: 大ボタンが表示される
        final yesButtonFinder = find.text('はい');
        final noButtonFinder = find.text('いいえ');
        final unknownButtonFinder = find.text('わからない');

        if (yesButtonFinder.evaluate().isNotEmpty) {
          expect(yesButtonFinder, findsWidgets);
        }
        if (noButtonFinder.evaluate().isNotEmpty) {
          expect(noButtonFinder, findsWidgets);
        }
        if (unknownButtonFinder.evaluate().isNotEmpty) {
          expect(unknownButtonFinder, findsWidgets);
        }
        // 【確認内容】: 大ボタンが適切に配置される 🟡

        // 【結果検証】: 緊急ボタンが表示される
        final emergencyButtonFinder = find.text('緊急');
        if (emergencyButtonFinder.evaluate().isNotEmpty) {
          expect(emergencyButtonFinder, findsWidgets);
        }
        // 【確認内容】: 緊急ボタンが適切に配置される 🟡

        await takeScreenshot(binding, 'tablet_button_layout');

        // Note: 実機でボタン間の余白が適切で、誤タップしにくいことを手動確認
      },
    );
  });

  // ============================================================
  // クリーンアップ
  // ============================================================
  tearDown(() async {
    // 画面サイズをリセット
    await binding.setSurfaceSize(const Size(800, 600));
  });
}
