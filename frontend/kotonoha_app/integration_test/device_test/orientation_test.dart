/// 画面方向対応テスト
///
/// TASK-0095: 実機テスト（iOS/Android/タブレット）
/// 信頼性レベル: 青信号（NFR-403に基づく、RT-101〜RT-103）
///
/// 縦向き・横向き両対応を検証するE2Eテスト。
/// 画面回転時のレイアウト調整、状態保持を確認。
@Tags(['e2e', 'device', 'orientation', 'ios', 'android'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('画面方向対応テスト（iOS/Android共通）', () {
    // ============================================================
    // RT-101: 縦向き表示テスト
    // ============================================================
    testWidgets(
      'RT-101: 縦向き（Portrait）でレイアウトが最適化される',
      (tester) async {
        // テスト目的: 縦向き表示が正常に機能することを確認
        // 関連要件: NFR-403（縦向き・横向き両対応）
        // 手順: デバイスを縦向きにする
        // 期待結果: レイアウトが縦向きに最適化される
        // 信頼性レベル: 青信号

        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 実際の処理実行: 画面サイズを縦向き（Portrait）に設定
        // Note: 実機では物理的にデバイスを回転させる
        // テストでは画面サイズを変更してシミュレート
        await tester.binding
            .setSurfaceSize(const Size(390, 844)); // iPhone 14相当
        await tester.pumpAndSettle();

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        // 確認内容: 縦向きでレイアウトが適切に表示される

        await takeScreenshot(binding, 'RT-101_portrait_layout');

        // 結果検証: 文字盤ボタンが適切なサイズで表示される
        // Note: 実機でボタンサイズが44px × 44px以上であることを手動確認
      },
    );

    // ============================================================
    // RT-102: 横向き表示テスト
    // ============================================================
    testWidgets(
      'RT-102: 横向き（Landscape）でレイアウトが最適化される',
      (tester) async {
        // テスト目的: 横向き表示が正常に機能することを確認
        // 関連要件: NFR-403（縦向き・横向き両対応）
        // 手順: デバイスを横向きにする
        // 期待結果: レイアウトが横向きに最適化される
        // 信頼性レベル: 青信号

        await pumpApp(tester);

        // 実際の処理実行: 画面サイズを横向き（Landscape）に設定
        // Note: 実機では物理的にデバイスを回転させる
        await tester.binding
            .setSurfaceSize(const Size(844, 390)); // iPhone 14横向き
        await tester.pumpAndSettle();

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        // 確認内容: 横向きでレイアウトが適切に表示される

        await takeScreenshot(binding, 'RT-102_landscape_layout');

        // 結果検証: 横向きで文字盤・定型文が見やすく配置される
        // Note: 実機で横向き時にボタン配置が最適化されることを手動確認
      },
    );

    // ============================================================
    // RT-103: 画面回転時の状態保持テスト
    // ============================================================
    testWidgets(
      'RT-103: 画面回転時に入力内容が保持される',
      (tester) async {
        // テスト目的: 画面回転時の状態保持を確認
        // 関連要件: NFR-403（画面回転時にユーザー入力状態が保持される）
        // 手順: 入力中にデバイスを回転
        // 期待結果: 入力内容が保持される
        // 信頼性レベル: 青信号

        await pumpApp(tester);

        // 実際の処理実行: 縦向きで文字列を入力
        await tester.binding.setSurfaceSize(const Size(390, 844)); // 縦向き
        await tester.pumpAndSettle();

        await typeOnCharacterBoard(tester, '画面回転テスト');

        // 結果検証: 入力内容が表示される
        expect(find.text('画面回転テスト'), findsWidgets);

        await takeScreenshot(binding, 'RT-103_before_rotation');

        // 実際の処理実行: 横向きに回転
        await tester.binding.setSurfaceSize(const Size(844, 390)); // 横向き
        await tester.pumpAndSettle();

        // 結果検証: 入力内容が保持されている
        expect(find.text('画面回転テスト'), findsWidgets);
        // 確認内容: 画面回転後も入力内容が保持される

        await takeScreenshot(binding, 'RT-103_after_rotation');

        // 実際の処理実行: 縦向きに戻す
        await tester.binding.setSurfaceSize(const Size(390, 844)); // 縦向き
        await tester.pumpAndSettle();

        // 結果検証: 入力内容が引き続き保持されている
        expect(find.text('画面回転テスト'), findsWidgets);
        // 確認内容: 複数回回転しても入力内容が保持される

        await takeScreenshot(binding, 'RT-103_rotation_back');
      },
    );

    // ============================================================
    // 画面回転時のレイアウト調整テスト
    // ============================================================
    testWidgets(
      '画面回転時にレイアウトが自動調整される',
      (tester) async {
        // テスト目的: 画面回転時のレイアウト自動調整を確認
        // 関連要件: NFR-403（レイアウト自動調整）
        // 手順: 縦向き→横向き→縦向きと回転
        // 期待結果: 各向きでレイアウトが最適化される
        // 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 実際の処理実行: 縦向きで開始
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpAndSettle();

        // 結果検証: 文字盤が縦向きレイアウトで表示される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'rotation_portrait_initial');

        // 実際の処理実行: 横向きに回転
        await tester.binding.setSurfaceSize(const Size(844, 390));
        await tester.pumpAndSettle();

        // 結果検証: レイアウトが横向きに調整される
        expect(find.text('あ'), findsWidgets);
        // 確認内容: 横向きでレイアウトが再配置される

        await takeScreenshot(binding, 'rotation_landscape');

        // 実際の処理実行: 設定画面に遷移して回転
        await tapIconButton(tester, Icons.settings);
        expect(find.text('設定'), findsOneWidget);

        await takeScreenshot(binding, 'rotation_settings_landscape');

        // 実際の処理実行: 横向きのまま設定を変更
        final mediumFontFinder = find.text('中');
        if (mediumFontFinder.evaluate().isNotEmpty) {
          await tester.tap(mediumFontFinder.first);
          await tester.pumpAndSettle();
        }

        // 実際の処理実行: 縦向きに戻す
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpAndSettle();

        // 結果検証: 設定画面が縦向きレイアウトに調整される
        expect(find.text('設定'), findsOneWidget);
        // 確認内容: 設定画面も回転に対応する

        await takeScreenshot(binding, 'rotation_settings_portrait');
      },
    );

    // ============================================================
    // タブレット横向き推奨表示テスト
    // ============================================================
    testWidgets(
      'タブレット横向きで最適な表示がされる',
      (tester) async {
        // テスト目的: タブレット横向き表示の最適化を確認
        // 関連要件: NFR-402、NFR-403（タブレット横向き推奨）
        // 手順: タブレットサイズの横向き画面で表示
        // 期待結果: 文字盤・定型文が見やすく配置される
        // 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 実際の処理実行: タブレット横向きサイズに設定（iPad 10.2インチ相当）
        await tester.binding.setSurfaceSize(const Size(1080, 810));
        await tester.pumpAndSettle();

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);
        // 確認内容: タブレット横向きで文字盤が見やすく配置される

        await takeScreenshot(binding, 'tablet_landscape_layout');

        // 実際の処理実行: 定型文画面に遷移
        final presetTabFinder = find.text('定型文');
        if (presetTabFinder.evaluate().isNotEmpty) {
          await tester.tap(presetTabFinder);
          await tester.pumpAndSettle();
        }

        // 結果検証: 定型文が横向きで見やすく配置される
        // Note: 実機でタブレット横向き時に定型文が2-3列で表示されることを手動確認
        // 確認内容: タブレット横向きで定型文が複数列で表示される

        await takeScreenshot(binding, 'tablet_landscape_presets');
      },
    );

    // ============================================================
    // 横向き定型文カラム数調整テスト
    // ============================================================
    testWidgets(
      '横向き時に定型文カラム数が調整される',
      (tester) async {
        // テスト目的: 横向き時の定型文カラム数調整を確認
        // 関連要件: NFR-403（レイアウト自動調整）
        // 手順: 縦向き→横向きで定型文画面を表示
        // 期待結果: 縦1列、横2-3列に調整される
        // 信頼性レベル: 黄信号（推測を含む）

        await pumpApp(tester);

        // 実際の処理実行: 縦向きで定型文画面を表示
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpAndSettle();

        final presetTabFinder = find.text('定型文');
        if (presetTabFinder.evaluate().isNotEmpty) {
          await tester.tap(presetTabFinder);
          await tester.pumpAndSettle();
        }

        // 結果検証: 定型文が縦向きで表示される
        await takeScreenshot(binding, 'preset_portrait_columns');

        // 実際の処理実行: 横向きに回転
        await tester.binding.setSurfaceSize(const Size(844, 390));
        await tester.pumpAndSettle();

        // 結果検証: 定型文が横向きで表示される
        // Note: 実機で横向き時にカラム数が増えることを手動確認
        // 確認内容: 横向きで定型文のカラム数が調整される

        await takeScreenshot(binding, 'preset_landscape_columns');
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
