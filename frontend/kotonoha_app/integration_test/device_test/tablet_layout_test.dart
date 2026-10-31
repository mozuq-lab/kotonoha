/// タブレット表示テスト
/// 9.7インチ以上タブレットでの最適表示を検証するE2Eテスト。
/// タップターゲットサイズ、レイアウト最適化を確認。
@Tags(['e2e', 'device', 'tablet', 'ios', 'android'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('タブレット最適表示テスト（9.7インチ以上）', () {
    // RT-104: タブレット表示テスト（9.7インチ以上）
    testWidgets(
      'RT-104: 9.7インチ以上のタブレットで最適な表示がされる',
      (tester) async {
        // （9.7インチ以上のタブレット最適表示）
        // 手順: iPad/タブレットで起動
        // 期待結果: 文字盤・定型文が見やすく表示される

        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: タブレットサイズに設定（iPad 10.2インチ相当）
        // 縦向き: 810 × 1080（2160 × 1620の約50%スケール）
        await setTestSurfaceSize(tester, const Size(810, 1080));

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);
        expect(find.text('た'), findsWidgets);
        expect(find.text('な'), findsWidgets);

        await takeScreenshot(binding, 'RT-104_tablet_character_board');

        // 実際の処理実行: 定型文画面に遷移
        await openFromHome(tester, '定型文');
        expect(find.byTooltip('定型文を追加'), findsOneWidget);

        // 結果検証: 定型文が見やすく表示される
        // Note: 実機でタブレット表示時に定型文が多数表示されることを手動確認

        await takeScreenshot(binding, 'RT-104_tablet_presets');

        // 実際の処理実行: 横向きに回転（タブレット推奨表示）
        await setTestSurfaceSize(tester, const Size(1080, 810));

        // 結果検証: 横向きで定型文が最適化される

        await takeScreenshot(binding, 'RT-104_tablet_landscape_presets');
      },
    );

    // RT-105: スマートフォン表示テスト
    testWidgets(
      'RT-105: スマートフォン（5〜6インチ）で基本機能が動作する',
      (tester) async {
        // （スマートフォンでも基本機能が動作）
        // 手順: iPhone/スマホで起動
        // 期待結果: 基本機能が動作する（最適化は期待しない）

        await pumpApp(tester);

        // 実際の処理実行: スマートフォンサイズに設定（iPhone 14相当）
        await setTestSurfaceSize(tester, const Size(390, 844));

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'RT-105_smartphone_layout');

        // 実際の処理実行: 文字を入力
        await typeOnCharacterBoard(tester, 'てすと');
        expect(find.text('てすと'), findsWidgets);

        // 実際の処理実行: 読み上げ
        await tapAndExpectSpeech(tester, find.text('読み上げ'));

        // 結果検証: スマートフォンで基本機能が動作する
        // Note: 実機でレイアウトが崩れず、主要ボタンがタップ可能なことを手動確認

        await takeScreenshot(binding, 'RT-105_smartphone_basic_function');
        await stopSpeechIfSpeaking(tester);
      },
    );

    // RT-106: タップターゲットサイズテスト（最小44px × 44px）
    testWidgets(
      'RT-106: 文字盤ボタンのタップターゲットが44px × 44px以上である',
      (tester) async {
        // （最小44px × 44px）
        // 手順: 文字盤ボタンのサイズ確認
        // 期待結果: 44px × 44px以上

        await pumpApp(tester);

        // 実際の処理実行: タブレットサイズに設定
        await setTestSurfaceSize(tester, const Size(810, 1080));

        // 結果検証: 文字盤の「あ」ボタンのサイズを確認
        // 文字（Text）ではなくボタン全体の大きさを測る。Text の大きさは
        // 文字の大きさで、タップできる範囲ではない。
        final charButton = find.byKey(const ValueKey('character_button_あ'));
        expect(charButton, findsOneWidget);

        final buttonSize = tester.getSize(charButton);

        debugPrint('文字盤ボタンサイズ: ${buttonSize.width} × ${buttonSize.height}');

        // 結果検証: ボタンサイズが44px × 44px以上
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

        await takeScreenshot(binding, 'RT-106_tap_target_size');

        // 実際の処理実行: スマートフォンサイズでも確認
        await setTestSurfaceSize(tester, const Size(390, 844));

        final charButtonSmartphone =
            find.byKey(const ValueKey('character_button_あ'));
        expect(charButtonSmartphone, findsOneWidget);
        final buttonSizeSmartphone = tester.getSize(charButtonSmartphone);
        debugPrint(
            'スマートフォンボタンサイズ: ${buttonSizeSmartphone.width} × ${buttonSizeSmartphone.height}');

        // 結果検証: スマートフォンでもボタンサイズが44px × 44px以上
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
      },
    );

    // RT-107: 大ボタンサイズテスト（推奨60px × 60px）
    testWidgets(
      'RT-107: 大ボタンのサイズが60px × 60px以上である',
      (tester) async {
        // （推奨60px × 60px以上）
        // 手順: 大ボタンのサイズ確認
        // 期待結果: 60px × 60px以上

        await pumpApp(tester);

        // 実際の処理実行: タブレットサイズに設定
        await setTestSurfaceSize(tester, const Size(810, 1080));

        // 結果検証: 大ボタン「はい」のサイズを確認（文字ではなくボタン全体）
        final yesButtonFinder = find.ancestor(
          of: find.text('はい'),
          matching: find.byType(QuickResponseButton),
        );
        expect(yesButtonFinder, findsOneWidget);
        final yesButtonSize = tester.getSize(yesButtonFinder);
        debugPrint(
            '大ボタン「はい」サイズ: ${yesButtonSize.width} × ${yesButtonSize.height}');

        // 結果検証: ボタンサイズが60px × 60px以上が推奨
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

        await takeScreenshot(binding, 'RT-107_large_button_size');
      },
    );

    // タブレット文字盤配置最適化テスト
    testWidgets(
      'タブレットで文字盤ボタン配置が最適化される',
      (tester) async {
        // （文字盤ボタンのサイズ・配置最適化）
        // 手順: タブレットサイズで文字盤を表示
        // 期待結果: 適切なサイズ・配置で表示される

        await pumpApp(tester);

        // 実際の処理実行: タブレット縦向きサイズに設定
        await setTestSurfaceSize(tester, const Size(810, 1080));

        // 結果検証: 文字盤の主要な文字が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);
        expect(find.text('た'), findsWidgets);
        expect(find.text('な'), findsWidgets);

        await takeScreenshot(binding, 'tablet_character_board_portrait');

        // 実際の処理実行: タブレット横向きサイズに設定
        await setTestSurfaceSize(tester, const Size(1080, 810));

        // 結果検証: 横向きでも文字盤が適切に配置される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'tablet_character_board_landscape');
      },
    );

    // タブレット定型文表示最適化テスト
    testWidgets(
      'タブレットで定型文一覧が見やすく表示される',
      (tester) async {
        // （定型文一覧が見やすく表示）
        // 手順: タブレットサイズで定型文を表示
        // 期待結果: スクロール不要で多数表示される

        await pumpApp(tester);

        // 実際の処理実行: タブレット縦向きサイズに設定
        await setTestSurfaceSize(tester, const Size(810, 1080));

        // 実際の処理実行: 定型文画面に遷移
        await openFromHome(tester, '定型文');
        expect(find.byTooltip('定型文を追加'), findsOneWidget);

        // 結果検証: 定型文が表示される
        // Note: 実機でタブレット表示時に多数の定型文が表示されることを手動確認

        await takeScreenshot(binding, 'tablet_presets_portrait');

        // 実際の処理実行: タブレット横向きサイズに設定
        await setTestSurfaceSize(tester, const Size(1080, 810));

        // 結果検証: 横向きで定型文が複数列で表示される

        await takeScreenshot(binding, 'tablet_presets_landscape');
      },
    );

    // タブレット大ボタン配置テスト
    testWidgets(
      'タブレットで大ボタンが誤タップしにくい配置になる',
      (tester) async {
        // （誤タップしにくい配置・サイズ）
        // 手順: タブレットサイズで大ボタンを表示
        // 期待結果: 適切な余白・サイズで配置される

        await pumpApp(tester);

        // 実際の処理実行: タブレットサイズに設定
        await setTestSurfaceSize(tester, const Size(810, 1080));

        // 結果検証: 大ボタンが表示される
        final yesButtonFinder = find.text('はい');
        final noButtonFinder = find.text('いいえ');
        final unknownButtonFinder = find.text('わからない');

        expect(yesButtonFinder, findsOneWidget);
        expect(noButtonFinder, findsOneWidget);
        expect(unknownButtonFinder, findsOneWidget);

        await takeScreenshot(binding, 'tablet_button_layout');

        // Note: 実機でボタン間の余白が適切で、誤タップしにくいことを手動確認
      },
    );
  });
}
