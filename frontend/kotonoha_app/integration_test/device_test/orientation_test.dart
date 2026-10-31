/// 画面方向対応テスト
/// 縦向き・横向き両対応を検証するE2Eテスト。
/// 画面回転時のレイアウト調整、状態保持を確認。
@Tags(['e2e', 'device', 'orientation', 'ios', 'android'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('画面方向対応テスト（iOS/Android共通）', () {
    // RT-101: 縦向き表示テスト
    testWidgets(
      'RT-101: 縦向き（Portrait）でレイアウトが最適化される',
      (tester) async {
        // （縦向き・横向き両対応）
        // 手順: デバイスを縦向きにする
        // 期待結果: レイアウトが縦向きに最適化される

        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 画面サイズを縦向き（Portrait）に設定
        // Note: 実機では物理的にデバイスを回転させる
        // テストでは画面サイズを変更してシミュレート
        await setTestSurfaceSize(tester, const Size(390, 844)); // iPhone 14相当

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);

        await takeScreenshot(binding, 'RT-101_portrait_layout');

        // 結果検証: 文字盤ボタンが適切なサイズで表示される
        // Note: 実機でボタンサイズが44px × 44px以上であることを手動確認
      },
    );

    // RT-102: 横向き表示テスト
    testWidgets(
      'RT-102: 横向き（Landscape）でレイアウトが最適化される',
      (tester) async {
        // （縦向き・横向き両対応）
        // 手順: デバイスを横向きにする
        // 期待結果: レイアウトが横向きに最適化される

        await pumpApp(tester);

        // 実際の処理実行: 画面サイズを横向き（Landscape）に設定
        // Note: 実機では物理的にデバイスを回転させる
        await setTestSurfaceSize(tester, const Size(844, 390)); // iPhone 14横向き

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);

        await takeScreenshot(binding, 'RT-102_landscape_layout');

        // 結果検証: 横向きで文字盤・定型文が見やすく配置される
        // Note: 実機で横向き時にボタン配置が最適化されることを手動確認
      },
    );

    // RT-103: 画面回転時の状態保持テスト
    testWidgets(
      'RT-103: 画面回転時に入力内容が保持される',
      (tester) async {
        // （画面回転時にユーザー入力状態が保持される）
        // 手順: 入力中にデバイスを回転
        // 期待結果: 入力内容が保持される

        await pumpApp(tester);

        // 実際の処理実行: 縦向きで文字列を入力
        await setTestSurfaceSize(tester, const Size(390, 844)); // 縦向き

        await typeOnCharacterBoard(tester, 'がめんかいてん');

        // 結果検証: 入力内容が表示される
        expect(find.text('がめんかいてん'), findsWidgets);

        await takeScreenshot(binding, 'RT-103_before_rotation');

        // 実際の処理実行: 横向きに回転
        await setTestSurfaceSize(tester, const Size(844, 390)); // 横向き

        // 結果検証: 入力内容が保持されている
        expect(find.text('がめんかいてん'), findsWidgets);

        await takeScreenshot(binding, 'RT-103_after_rotation');

        // 実際の処理実行: 縦向きに戻す
        await setTestSurfaceSize(tester, const Size(390, 844)); // 縦向き

        // 結果検証: 入力内容が引き続き保持されている
        expect(find.text('がめんかいてん'), findsWidgets);

        await takeScreenshot(binding, 'RT-103_rotation_back');
      },
    );

    // 画面回転時のレイアウト調整テスト
    testWidgets(
      '画面回転時にレイアウトが自動調整される',
      (tester) async {
        // （レイアウト自動調整）
        // 手順: 縦向き→横向き→縦向きと回転
        // 期待結果: 各向きでレイアウトが最適化される

        await pumpApp(tester);

        // 実際の処理実行: 縦向きで開始
        await setTestSurfaceSize(tester, const Size(390, 844));

        // 結果検証: 文字盤が縦向きレイアウトで表示される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'rotation_portrait_initial');

        // 実際の処理実行: 横向きに回転
        await setTestSurfaceSize(tester, const Size(844, 390));

        // 結果検証: レイアウトが横向きに調整される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'rotation_landscape');

        // 実際の処理実行: 設定画面に遷移して回転
        await openFromHome(tester, '設定');
        expect(find.text('設定'), findsOneWidget);

        await takeScreenshot(binding, 'rotation_settings_landscape');

        // 実際の処理実行: 横向きのまま設定を変更（既定の「中」から「大」へ）
        await scrollAndTap(tester, find.text('大'));

        // 実際の処理実行: 縦向きに戻す
        await setTestSurfaceSize(tester, const Size(390, 844));

        // 結果検証: 設定画面のまま縦向きレイアウトに調整され、変えた設定が残る
        expect(find.text('設定'), findsOneWidget);
        final settings =
            await appContainer(tester).read(settingsNotifierProvider.future);
        expect(settings.fontSize, FontSize.large, reason: '回転で設定が戻る');

        await takeScreenshot(binding, 'rotation_settings_portrait');
      },
    );

    // タブレット横向き推奨表示テスト
    testWidgets(
      'タブレット横向きで最適な表示がされる',
      (tester) async {
        // （タブレット横向き推奨）
        // 手順: タブレットサイズの横向き画面で表示
        // 期待結果: 文字盤・定型文が見やすく配置される

        await pumpApp(tester);

        // 実際の処理実行: タブレット横向きサイズに設定（iPad 10.2インチ相当）
        await setTestSurfaceSize(tester, const Size(1080, 810));

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);

        await takeScreenshot(binding, 'tablet_landscape_layout');

        // 実際の処理実行: 定型文画面に遷移
        await openFromHome(tester, '定型文');
        expect(find.byTooltip('定型文を追加'), findsOneWidget);

        // 結果検証: 定型文が横向きで見やすく配置される
        // Note: 実機でタブレット横向き時に定型文が2-3列で表示されることを手動確認

        await takeScreenshot(binding, 'tablet_landscape_presets');
      },
    );

    // 横向き定型文カラム数調整テスト
    testWidgets(
      '横向き時に定型文カラム数が調整される',
      (tester) async {
        // （レイアウト自動調整）
        // 手順: 縦向き→横向きで定型文画面を表示
        // 期待結果: 縦1列、横2-3列に調整される

        await pumpApp(tester);

        // 実際の処理実行: 縦向きで定型文画面を表示
        await setTestSurfaceSize(tester, const Size(390, 844));

        await openFromHome(tester, '定型文');
        expect(find.byTooltip('定型文を追加'), findsOneWidget);

        // 結果検証: 定型文が縦向きで表示される
        await takeScreenshot(binding, 'preset_portrait_columns');

        // 実際の処理実行: 横向きに回転
        await setTestSurfaceSize(tester, const Size(844, 390));

        // 結果検証: 定型文が横向きで表示される
        // Note: 実機で横向き時にカラム数が増えることを手動確認

        await takeScreenshot(binding, 'preset_landscape_columns');
      },
    );
  });
}
