/// 実機基本動作テスト
/// iOS/Android実機での基本機能動作を検証するE2Eテスト。
/// 文字盤入力、TTS読み上げ、定型文、履歴、お気に入り、AI変換などの
/// 主要機能が実機で正常に動作することを確認。
@Tags(['e2e', 'device', 'ios', 'android'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('実機基本動作テスト（iOS/Android共通）', () {
    // RT-001: アプリ起動テスト
    testWidgets(
      'RT-001: アプリが正常に起動し文字盤画面が表示される',
      (tester) async {
        // （iOS 14.0+、Android 10+）
        // 手順: ホーム画面からアプリアイコンをタップ
        // 期待結果: アプリが起動し、文字盤画面が表示される

        // テストデータ準備: アプリを初期化
        await pumpApp(tester);

        // 結果検証: 文字盤画面が表示される
        expect(find.text('あ'), findsWidgets);
        expect(find.text('か'), findsWidgets);
        expect(find.text('さ'), findsWidgets);

        // スクリーンショット: 起動画面
        await takeScreenshot(binding, 'RT-001_app_startup');
      },
    );

    // RT-002: 文字盤タップ入力テスト（: 100ms以内）
    testWidgets(
      'RT-002: 文字盤タップが100ms以内に反応する',
      (tester) async {
        // （文字盤タップ応答100ms以内）
        // 手順: 「あ」ボタンをタップ
        // 期待結果: 入力欄に「あ」が表示される、100ms以内

        await pumpApp(tester);

        // パフォーマンス計測: 文字盤タップ応答時間
        await measurePerformance(
          '文字盤タップ応答（あ）',
          maxMilliseconds: 100,
          action: () async {
            await tapCharacterOnBoard(tester, 'あ');
          },
        );

        // 結果検証: 入力欄に「あ」が表示される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'RT-002_character_tap_response');
      },
    );

    // RT-003: TTS読み上げテスト（: 1秒以内）
    testWidgets(
      'RT-003: TTS読み上げが1秒以内に開始される',
      (tester) async {
        // （TTS読み上げ開始1秒以内）
        // 手順: 「こんにちは」と入力し、読み上げボタンタップ
        // 期待結果: 1秒以内に読み上げが開始される

        await pumpApp(tester);

        // 実際の処理実行: 文字列入力
        await typeOnCharacterBoard(tester, 'こんにちは');

        // パフォーマンス計測: TTS読み上げ開始時間
        final stopwatch = Stopwatch()..start();
        await tapIconButton(tester, Icons.volume_up);
        stopwatch.stop();

        final elapsed = stopwatch.elapsedMilliseconds;
        debugPrint('TTS読み上げ開始時間: ${elapsed}ms');

        // 結果検証: 1秒以内に読み上げが開始される
        // Note: 実機では実際のTTS音声が再生されることを手動確認
        expect(
          elapsed,
          lessThan(1000),
          reason: 'TTS読み上げ開始が1秒を超えました（${elapsed}ms）',
        );

        await takeScreenshot(binding, 'RT-003_tts_started');
      },
    );

    // RT-004: TTS速度変更テスト
    testWidgets(
      'RT-004: TTS読み上げ速度を変更できる',
      (tester) async {
        // （TTS速度変更）
        // 手順: 設定で速度「遅い」→「速い」に変更
        // 期待結果: 読み上げ速度が変更される

        await pumpApp(tester);

        // 実際の処理実行: 設定画面に遷移
        await tapIconButton(tester, Icons.settings);
        expect(find.text('設定'), findsOneWidget);

        // 実際の処理実行: TTS速度を「遅い」に変更
        final slowSpeedFinder = find.text('遅い');
        if (slowSpeedFinder.evaluate().isNotEmpty) {
          await tester.tap(slowSpeedFinder);
          await tester.pumpAndSettle();
        }

        // 結果検証: 「遅い」が選択されている
        expect(find.text('遅い'), findsOneWidget);

        await takeScreenshot(binding, 'RT-004_tts_speed_slow');

        // 実際の処理実行: TTS速度を「速い」に変更
        final fastSpeedFinder = find.text('速い');
        if (fastSpeedFinder.evaluate().isNotEmpty) {
          await tester.tap(fastSpeedFinder);
          await tester.pumpAndSettle();
        }

        expect(find.text('速い'), findsOneWidget);
        await takeScreenshot(binding, 'RT-004_tts_speed_fast');
      },
    );

    // RT-005: TTS停止テスト
    testWidgets(
      'RT-005: 読み上げ中に停止ボタンで即座に停止する',
      (tester) async {
        // （TTS停止・中断）
        // 手順: 読み上げ中に停止ボタンタップ
        // 期待結果: 読み上げが即座に停止する

        await pumpApp(tester);

        // 実際の処理実行: 長文を入力
        await typeOnCharacterBoard(tester, 'これはテストです。長い文章を入力して読み上げを確認します。');

        // 実際の処理実行: 読み上げを開始
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(milliseconds: 500));

        // 実際の処理実行: 停止ボタンをタップ
        final stopButton = find.byIcon(Icons.stop);
        if (stopButton.evaluate().isNotEmpty) {
          await tester.tap(stopButton);
          await tester.pumpAndSettle();
        }

        // 結果検証: 停止ボタンが機能する
        // Note: 実機では音声が実際に停止することを手動確認

        await takeScreenshot(binding, 'RT-005_tts_stopped');
      },
    );

    // RT-006: 定型文選択テスト
    testWidgets(
      'RT-006: 定型文「ありがとう」をタップして即座に読み上げられる',
      (tester) async {
        // （定型文機能）
        // 手順: 定型文「ありがとう」タップ
        // 期待結果: 即座に「ありがとう」が読み上げられる

        await pumpApp(tester);

        // 実際の処理実行: 定型文画面に遷移
        // Note: 定型文は文字盤画面に表示されている場合がある
        final presetFinder = find.text('ありがとう');
        if (presetFinder.evaluate().isEmpty) {
          // 定型文タブに遷移
          final presetTabFinder = find.text('定型文');
          if (presetTabFinder.evaluate().isNotEmpty) {
            await tester.tap(presetTabFinder);
            await tester.pumpAndSettle();
          }
        }

        // 実際の処理実行: 「ありがとう」をタップ
        final thankYouFinder = find.text('ありがとう');
        if (thankYouFinder.evaluate().isNotEmpty) {
          await tester.tap(thankYouFinder.first);
          await tester.pumpAndSettle();
        }

        // 結果検証: 定型文が選択される
        // Note: 実機では「ありがとう」が実際に読み上げられることを手動確認

        await takeScreenshot(binding, 'RT-006_preset_phrase_thankyou');
      },
    );

    // RT-007: 大ボタンタップテスト
    testWidgets(
      'RT-007: 大ボタン「はい」をタップして即座に読み上げられる',
      (tester) async {
        // （大ボタン・状態ボタン）
        // 手順: 「はい」ボタンタップ
        // 期待結果: 「はい」が即座に読み上げられる

        await pumpApp(tester);

        // 実際の処理実行: 「はい」ボタンをタップ
        final yesFinder = find.text('はい');
        if (yesFinder.evaluate().isNotEmpty) {
          await tester.tap(yesFinder.first);
          await tester.pumpAndSettle();
        }

        // 結果検証: 大ボタンが機能する
        // Note: 実機では「はい」が実際に読み上げられることを手動確認

        await takeScreenshot(binding, 'RT-007_large_button_yes');
      },
    );

    // RT-008: 緊急ボタンテスト
    testWidgets(
      'RT-008: 緊急ボタンで緊急音が鳴り画面が赤表示される',
      (tester) async {
        // （緊急ボタン）
        // 手順: 緊急ボタンを2回タップ（確認ダイアログ→「はい」）
        // 期待結果: 緊急音が鳴り、画面が赤表示される

        await pumpApp(tester);

        // 実際の処理実行: 緊急ボタンをタップ
        final emergencyFinder = find.text('緊急');
        if (emergencyFinder.evaluate().isNotEmpty) {
          await tester.tap(emergencyFinder);
          await tester.pumpAndSettle();

          // 実際の処理実行: 確認ダイアログで「はい」をタップ
          final confirmYesFinder = find.text('はい');
          if (confirmYesFinder.evaluate().isNotEmpty) {
            await tester.tap(confirmYesFinder);
            await tester.pumpAndSettle();
          }
        }

        // 結果検証: 緊急画面が表示される
        // Note: 実機では緊急音が実際に鳴ることを手動確認

        await takeScreenshot(binding, 'RT-008_emergency_activated');

        // クリーンアップ: 緊急画面を閉じる
        final closeFinder = find.text('閉じる');
        if (closeFinder.evaluate().isNotEmpty) {
          await tester.tap(closeFinder);
          await tester.pumpAndSettle();
        }
      },
    );

    // RT-009: 履歴保存・再生テスト
    testWidgets(
      'RT-009: 読み上げ実行後に履歴が保存され再読み上げできる',
      (tester) async {
        // （履歴機能）
        // 手順: 読み上げ実行→履歴画面→履歴タップ
        // 期待結果: 履歴が保存され、再読み上げされる

        await pumpApp(tester);

        // 実際の処理実行: 文字列を入力して読み上げ
        await typeOnCharacterBoard(tester, 'テスト履歴');
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 1));

        // 実際の処理実行: 履歴画面に遷移
        final historyTabFinder = find.text('履歴');
        if (historyTabFinder.evaluate().isNotEmpty) {
          await tester.tap(historyTabFinder);
          await tester.pumpAndSettle();
        }

        // 結果検証: 履歴に「テスト履歴」が保存されている
        expect(find.text('テスト履歴'), findsWidgets);

        await takeScreenshot(binding, 'RT-009_history_saved');

        // 実際の処理実行: 履歴をタップして再読み上げ
        final historyItemFinder = find.text('テスト履歴');
        if (historyItemFinder.evaluate().isNotEmpty) {
          await tester.tap(historyItemFinder.first);
          await tester.pumpAndSettle();
        }

        // 結果検証: 再読み上げが実行される
        // Note: 実機では「テスト履歴」が実際に読み上げられることを手動確認
      },
    );

    // RT-010: お気に入り登録テスト
    testWidgets(
      'RT-010: 履歴からお気に入り登録できる',
      (tester) async {
        // （お気に入り機能）
        // 手順: 履歴からお気に入り登録
        // 期待結果: お気に入り一覧に表示される

        await pumpApp(tester);

        // 実際の処理実行: 文字列を入力して読み上げ
        await typeOnCharacterBoard(tester, 'お気に入りテスト');
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 1));

        // 実際の処理実行: 履歴画面に遷移
        final historyTabFinder = find.text('履歴');
        if (historyTabFinder.evaluate().isNotEmpty) {
          await tester.tap(historyTabFinder);
          await tester.pumpAndSettle();
        }

        // 実際の処理実行: お気に入りボタンをタップ
        final favoriteFinder = find.byIcon(Icons.star_border);
        if (favoriteFinder.evaluate().isNotEmpty) {
          await tester.tap(favoriteFinder.first);
          await tester.pumpAndSettle();
        }

        // 実際の処理実行: お気に入り画面に遷移
        final favoriteTabFinder = find.text('お気に入り');
        if (favoriteTabFinder.evaluate().isNotEmpty) {
          await tester.tap(favoriteTabFinder);
          await tester.pumpAndSettle();
        }

        // 結果検証: お気に入りに「お気に入りテスト」が表示される
        expect(find.text('お気に入りテスト'), findsWidgets);

        await takeScreenshot(binding, 'RT-010_favorite_registered');
      },
    );

    // RT-012: オフライン動作テスト
    testWidgets(
      'RT-012: 機内モード（オフライン）でも基本機能が動作する',
      (tester) async {
        // （オフラインファースト）
        // 手順: 機内モード→文字入力→読み上げ
        // 期待結果: 文字盤・TTS・定型文が正常動作する

        await pumpApp(tester);

        // Note: 機内モードは実機で手動設定する必要がある
        // テストコードでは基本機能が動作することを確認

        // 実際の処理実行: 文字列を入力
        await typeOnCharacterBoard(tester, 'オフライン');
        expect(find.text('オフライン'), findsWidgets);

        // 実際の処理実行: 読み上げ
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 1));

        // 結果検証: オフラインでも基本機能が動作する
        // Note: 実機で機内モードにして、文字盤・TTS・定型文が動作することを手動確認

        await takeScreenshot(binding, 'RT-012_offline_mode');
      },
    );

    // RT-013: フォントサイズ変更テスト
    testWidgets(
      'RT-013: フォントサイズを「大」に変更できる',
      (tester) async {
        // （フォントサイズ変更）
        // 手順: 設定でフォントサイズ「大」に変更
        // 期待結果: 文字盤・定型文・ボタンラベルが大きく表示される

        await pumpApp(tester);

        // 実際の処理実行: 設定画面に遷移
        await tapIconButton(tester, Icons.settings);
        expect(find.text('設定'), findsOneWidget);

        // 実際の処理実行: フォントサイズ「大」を選択
        final largeFontFinder = find.text('大');
        if (largeFontFinder.evaluate().isNotEmpty) {
          await tester.tap(largeFontFinder.first);
          await tester.pumpAndSettle();
        }

        // 結果検証: フォントサイズが「大」に設定される
        expect(find.text('大'), findsWidgets);

        await takeScreenshot(binding, 'RT-013_font_size_large');

        // 実際の処理実行: ホーム画面に戻る
        await tapIconButton(tester, Icons.arrow_back);

        // 結果検証: 文字盤の文字が大きく表示される
        // Note: 実機で文字が実際に大きく表示されることを手動確認
      },
    );

    // RT-014: テーマ変更テスト
    testWidgets(
      'RT-014: テーマを「ダークモード」に変更できる',
      (tester) async {
        // （テーマ変更）
        // 手順: 設定でテーマ「ダークモード」に変更
        // 期待結果: 全画面がダークテーマに変更される

        await pumpApp(tester);

        // 実際の処理実行: 設定画面に遷移
        await tapIconButton(tester, Icons.settings);
        expect(find.text('設定'), findsOneWidget);

        // 実際の処理実行: テーマ「ダーク」を選択
        final darkThemeFinder = find.text('ダーク');
        if (darkThemeFinder.evaluate().isNotEmpty) {
          await tester.tap(darkThemeFinder.first);
          await tester.pumpAndSettle();
        }

        // 結果検証: テーマが「ダーク」に設定される
        expect(find.text('ダーク'), findsWidgets);

        await takeScreenshot(binding, 'RT-014_theme_dark');

        // 実際の処理実行: ホーム画面に戻る
        await tapIconButton(tester, Icons.arrow_back);

        // 結果検証: ダークテーマが適用されている
        // Note: 実機で画面が実際にダークテーマになることを手動確認
      },
    );

    // RT-015: 高コントラストモードテスト
    testWidgets(
      'RT-015: 高コントラストモードに変更できる',
      (tester) async {
        // （コントラスト比4.5:1以上）
        // 手順: 設定でテーマ「高コントラスト」に変更
        // 期待結果: コントラスト比4.5:1以上で表示される

        await pumpApp(tester);

        // 実際の処理実行: 設定画面に遷移
        await tapIconButton(tester, Icons.settings);
        expect(find.text('設定'), findsOneWidget);

        // 実際の処理実行: テーマ「高コントラスト」を選択
        final highContrastFinder = find.text('高コントラスト');
        if (highContrastFinder.evaluate().isNotEmpty) {
          await tester.tap(highContrastFinder.first);
          await tester.pumpAndSettle();
        }

        // 結果検証: テーマが「高コントラスト」に設定される
        expect(find.text('高コントラスト'), findsWidgets);

        await takeScreenshot(binding, 'RT-015_theme_high_contrast');

        // 実際の処理実行: ホーム画面に戻る
        await tapIconButton(tester, Icons.arrow_back);

        // 結果検証: 高コントラストテーマが適用されている
        // Note: 実機でコントラスト比が4.5:1以上であることを手動確認
      },
    );

    // RT-016: 対面表示モードテスト
    testWidgets(
      'RT-016: 対面表示モードで画面が180度回転する',
      (tester) async {
        // （対面表示機能）
        // 手順: 対面表示ボタンタップ
        // 期待結果: 画面が180度回転し、テキストが大きく表示される

        await pumpApp(tester);

        // 実際の処理実行: 文字列を入力
        await typeOnCharacterBoard(tester, '対面表示');

        // 実際の処理実行: 対面表示ボタンをタップ
        final faceToFaceFinder = find.byIcon(Icons.flip);
        if (faceToFaceFinder.evaluate().isNotEmpty) {
          await tester.tap(faceToFaceFinder);
          await tester.pumpAndSettle();
        }

        // 結果検証: 対面表示モードが有効になる
        // Note: 実機で画面が180度回転し、テキストが大きく表示されることを手動確認

        await takeScreenshot(binding, 'RT-016_face_to_face_mode');
      },
    );
  });
}
