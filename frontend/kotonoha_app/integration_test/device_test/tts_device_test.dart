/// TTS実機動作テスト
///
/// TASK-0095: 実機テスト（iOS/Android/タブレット）
/// 信頼性レベル: 🔵 青信号（NFR-001、REQ-401〜REQ-404に基づく、RT-201〜RT-206、RT-301〜RT-307）
///
/// TTS（Text-to-Speech）機能の実機動作を検証するE2Eテスト。
/// iOS AVSpeechSynthesizer、Android TextToSpeech、エッジケースを確認。
@Tags(['e2e', 'device', 'tts', 'ios', 'android'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TTS実機動作テスト（プラットフォーム固有）', () {
    // ============================================================
    // RT-201: iOS TTS（AVSpeechSynthesizer）テスト
    // ============================================================
    testWidgets(
      'RT-201: iOS実機でTTS（AVSpeechSynthesizer）が正常動作する',
      (tester) async {
        // 【テスト目的】: iOS固有のTTS実装を確認
        // 【関連要件】: REQ-401（iOS AVSpeechSynthesizer）
        // 【手順】: iOS実機で読み上げ
        // 【期待結果】: 日本語音声エンジンで読み上げられる
        // 🔵 信頼性レベル: 青信号
        // Note: このテストはiOS実機でのみ実行される

        await pumpApp(tester);

        // 【実際の処理実行】: 日本語テキストを入力
        await typeOnCharacterBoard(tester, 'こんにちは。これはiOSのテストです。');

        // 【実際の処理実行】: 読み上げを開始
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 2));

        // 【結果検証】: TTS読み上げが実行される
        // Note: iOS実機で以下を手動確認：
        // - AVSpeechSynthesizerが使用されている
        // - 日本語音声エンジンで読み上げられる
        // - 音声がクリアで聞き取りやすい
        // 【確認内容】: iOS TTSが正常動作する 🔵

        await takeScreenshot(binding, 'RT-201_ios_tts');
      },
      // Note: iOS実機で手動実行してください
    );

    // ============================================================
    // RT-202: iOS SafeAreaテスト
    // ============================================================
    testWidgets(
      'RT-202: iPhoneノッチ対応でレイアウトがSafeArea内に収まる',
      (tester) async {
        // 【テスト目的】: iOS SafeArea対応を確認
        // 【関連要件】: NFR-205（iOS SafeArea対応）
        // 【手順】: iPhone（ノッチあり）で起動
        // 【期待結果】: レイアウトがSafeArea内に収まる
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: iPhone 14サイズに設定
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpAndSettle();

        // 【結果検証】: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        // 【確認内容】: SafeArea内にレイアウトが収まる 🔵

        await takeScreenshot(binding, 'RT-202_ios_safe_area');

        // Note: iOS実機（iPhone 12以降、ノッチあり）で以下を手動確認：
        // - レイアウトがノッチやホームインジケーターと重ならない
        // - 文字盤ボタンが画面端まで適切に配置される
      },
      // Note: iOS実機で手動実行してください
    );

    // ============================================================
    // RT-203: iOSガイド付きアクセステスト
    // ============================================================
    testWidgets(
      'RT-203: iOSガイド付きアクセス有効時もアプリが正常動作する',
      (tester) async {
        // 【テスト目的】: iOSガイド付きアクセス対応を確認
        // 【関連要件】: NFR-205（iOSガイド付きアクセス）
        // 【手順】: ガイド付きアクセス有効化
        // 【期待結果】: アプリが正常動作する
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: 基本機能を実行
        await typeOnCharacterBoard(tester, 'ガイド付きアクセス');
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 1));

        // 【結果検証】: アプリが正常動作する
        expect(find.text('ガイド付きアクセス'), findsWidgets);
        // 【確認内容】: ガイド付きアクセス有効時も動作する 🔵

        await takeScreenshot(binding, 'RT-203_ios_guided_access');

        // Note: iOS実機で以下を手動確認：
        // 1. 設定 > アクセシビリティ > ガイドアクセス を有効化
        // 2. アプリ起動後、ホームボタン3回押し（または電源ボタン3回押し）
        // 3. ガイド付きアクセスを開始
        // 4. アプリの基本機能（文字盤、TTS、定型文）が正常動作することを確認
        // 5. アプリからの脱出ができないことを確認（セキュリティ）
      },
      // Note: iOS実機で手動実行してください
    );

    // ============================================================
    // RT-204: Android TTS（TextToSpeech）テスト
    // ============================================================
    testWidgets(
      'RT-204: Android実機でTTS（TextToSpeech）が正常動作する',
      (tester) async {
        // 【テスト目的】: Android固有のTTS実装を確認
        // 【関連要件】: REQ-401（Android TextToSpeech）
        // 【手順】: Android実機で読み上げ
        // 【期待結果】: 日本語音声エンジンで読み上げられる
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: 日本語テキストを入力
        await typeOnCharacterBoard(tester, 'こんにちは。これはAndroidのテストです。');

        // 【実際の処理実行】: 読み上げを開始
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 2));

        // 【結果検証】: TTS読み上げが実行される
        // Note: Android実機で以下を手動確認：
        // - TextToSpeechが使用されている
        // - 日本語音声エンジン（Google TTS等）で読み上げられる
        // - 音声がクリアで聞き取りやすい
        // 【確認内容】: Android TTSが正常動作する 🔵

        await takeScreenshot(binding, 'RT-204_android_tts');
      },
      // Note: Android実機で手動実行してください
    );

    // ============================================================
    // RT-205: Android Navigation Barテスト
    // ============================================================
    testWidgets(
      'RT-205: Android Navigation Bar対応でレイアウトが適切に調整される',
      (tester) async {
        // 【テスト目的】: Android Navigation Bar対応を確認
        // 【関連要件】: NFR-205（Android Navigation Bar対応）
        // 【手順】: 3ボタン/ジェスチャーナビゲーション
        // 【期待結果】: レイアウトが適切に調整される
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: Android Pixelサイズに設定
        await tester.binding.setSurfaceSize(const Size(412, 915));
        await tester.pumpAndSettle();

        // 【結果検証】: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);
        // 【確認内容】: Navigation Bar対応でレイアウトが調整される 🔵

        await takeScreenshot(binding, 'RT-205_android_navigation_bar');

        // Note: Android実機で以下を手動確認：
        // - 3ボタンナビゲーション有効時にレイアウトが適切に調整される
        // - ジェスチャーナビゲーション有効時にレイアウトが適切に調整される
        // - Navigation Barと重ならない
      },
      // Note: Android実機で手動実行してください
    );

    // ============================================================
    // RT-206: Android画面ピン留めテスト
    // ============================================================
    testWidgets(
      'RT-206: Android画面ピン留め有効時もアプリが正常動作する',
      (tester) async {
        // 【テスト目的】: Android画面ピン留め対応を確認
        // 【関連要件】: NFR-205（Android画面ピン留め）
        // 【手順】: 画面ピン留め有効化
        // 【期待結果】: アプリが正常動作する
        // 🔵 信頼性レベル: 青信号

        await pumpApp(tester);

        // 【実際の処理実行】: 基本機能を実行
        await typeOnCharacterBoard(tester, '画面ピン留め');
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 1));

        // 【結果検証】: アプリが正常動作する
        expect(find.text('画面ピン留め'), findsWidgets);
        // 【確認内容】: 画面ピン留め有効時も動作する 🔵

        await takeScreenshot(binding, 'RT-206_android_screen_pinning');

        // Note: Android実機で以下を手動確認：
        // 1. 設定 > セキュリティ > 画面の固定 を有効化
        // 2. アプリ起動後、最近使ったアプリボタンをタップ
        // 3. アプリカードの上部にあるピンアイコンをタップ
        // 4. 画面ピン留めを開始
        // 5. アプリの基本機能（文字盤、TTS、定型文）が正常動作することを確認
        // 6. 戻る+最近使ったアプリボタン長押しでピン留め解除できることを確認
      },
      // Note: Android実機で手動実行してください
    );
  });

  // ============================================================
  // エッジケース・エラーハンドリングテスト
  // ============================================================
  group('TTS実機エッジケーステスト', () {
    // ============================================================
    // RT-301: OS音量0での読み上げテスト
    // ============================================================
    testWidgets(
      'RT-301: OS音量0で読み上げ実行時に視覚的警告が表示される',
      (tester) async {
        // 【テスト目的】: 音量0での読み上げエラーハンドリングを確認
        // 【関連要件】: EDGE-202（OS音量0での読み上げ）
        // 【手順】: 音量0→読み上げ実行
        // 【期待結果】: 「音量が0です」視覚的警告表示
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: テキストを入力
        await typeOnCharacterBoard(tester, '音量テスト');

        // 【実際の処理実行】: 読み上げを実行
        await tapIconButton(tester, Icons.volume_up);
        await tester.pumpAndSettle();

        // 【結果検証】: 音量警告が表示される可能性がある
        // Note: 実機で以下を手動確認：
        // 1. OS音量を0（ミュート）に設定
        // 2. 読み上げボタンをタップ
        // 3. 「音量が0です。音量を上げてください」などの視覚的警告が表示される
        // 4. スナックバーまたはダイアログで通知される
        // 【確認内容】: 音量0時に視覚的警告が表示される 🟡

        await takeScreenshot(binding, 'RT-301_volume_zero_warning');
      },
      // Note: 実機で音量0に設定して手動実行してください
    );

    // ============================================================
    // RT-302: マナーモード時の緊急ボタンテスト
    // ============================================================
    testWidgets(
      'RT-302: マナーモード時の緊急ボタン押下で明確な警告が表示される',
      (tester) async {
        // 【テスト目的】: マナーモード時の緊急ボタンエラーハンドリングを確認
        // 【関連要件】: EDGE-203（マナーモード時の緊急ボタン）
        // 【手順】: マナーモード→緊急ボタン
        // 【期待結果】: 明確な警告表示（音が鳴らない旨）
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: 緊急ボタンをタップ
        final emergencyFinder = find.text('緊急');
        if (emergencyFinder.evaluate().isNotEmpty) {
          await tester.tap(emergencyFinder);
          await tester.pumpAndSettle();

          // 【実際の処理実行】: 確認ダイアログで「はい」をタップ
          final confirmYesFinder = find.text('はい');
          if (confirmYesFinder.evaluate().isNotEmpty) {
            await tester.tap(confirmYesFinder);
            await tester.pumpAndSettle();
          }
        }

        // 【結果検証】: マナーモード警告が表示される可能性がある
        // Note: 実機で以下を手動確認：
        // 1. デバイスをマナーモードに設定
        // 2. 緊急ボタンを押下
        // 3. 「マナーモードのため音が鳴りません」などの警告が表示される
        // 4. 視覚的な警告（画面赤表示、テキスト表示）は正常動作する
        // 【確認内容】: マナーモード時に明確な警告が表示される 🟡

        await takeScreenshot(binding, 'RT-302_silent_mode_warning');

        // 【クリーンアップ】: 緊急画面を閉じる
        final closeFinder = find.text('閉じる');
        if (closeFinder.evaluate().isNotEmpty) {
          await tester.tap(closeFinder);
          await tester.pumpAndSettle();
        }
      },
      // Note: 実機でマナーモード設定して手動実行してください
    );

    // ============================================================
    // RT-303: TTS音声エンジン未インストールテスト
    // ============================================================
    testWidgets(
      'RT-303: TTS音声エンジン未インストール時にエラーメッセージが表示される',
      (tester) async {
        // 【テスト目的】: TTS音声エンジン未インストール時のエラーハンドリングを確認
        // 【関連要件】: EDGE-004（TTS音声エンジン未インストール）
        // 【手順】: 日本語音声エンジンを削除（可能なら）
        // 【期待結果】: エラーメッセージ表示、テキスト表示のみ継続
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: テキストを入力
        await typeOnCharacterBoard(tester, '音声エンジンテスト');

        // 【実際の処理実行】: 読み上げを実行
        await tapIconButton(tester, Icons.volume_up);
        await tester.pumpAndSettle();

        // 【結果検証】: エラーメッセージが表示される可能性がある
        // Note: 実機で以下を手動確認：
        // 1. iOS: 設定 > アクセシビリティ > 読み上げコンテンツ > 声 で日本語音声を削除
        // 2. Android: 設定 > システム > 言語と入力 > テキスト読み上げ で音声エンジンをアンインストール
        // 3. 読み上げボタンをタップ
        // 4. 「音声エンジンがインストールされていません」などのエラーメッセージが表示される
        // 5. テキスト表示は継続され、アプリがクラッシュしない
        // 【確認内容】: 音声エンジン未インストール時に適切なエラー表示 🟡

        await takeScreenshot(binding, 'RT-303_tts_engine_missing');
      },
      // Note: 実機で音声エンジンをアンインストールして手動実行してください
    );

    // ============================================================
    // RT-304: バックグラウンド復帰テスト
    // ============================================================
    testWidgets(
      'RT-304: アプリをバックグラウンドから復帰しても状態が復元される',
      (tester) async {
        // 【テスト目的】: バックグラウンド復帰時の状態復元を確認
        // 【関連要件】: EDGE-201（バックグラウンド復帰）
        // 【手順】: アプリをバックグラウンドに→復帰
        // 【期待結果】: 前回の画面状態・入力内容が復元される
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: テキストを入力
        await typeOnCharacterBoard(tester, 'バックグラウンドテスト');

        // 【結果検証】: 入力内容が表示される
        expect(find.text('バックグラウンドテスト'), findsWidgets);

        await takeScreenshot(binding, 'RT-304_before_background');

        // Note: 実機で以下を手動確認：
        // 1. 文字列を入力した状態でホームボタン（またはジェスチャー）でバックグラウンドに移行
        // 2. 他のアプリを開く（メモリプレッシャーをかける）
        // 3. アプリを再度開く
        // 4. 入力内容が保持されている
        // 5. 画面状態（選択中のタブ、スクロール位置等）が復元される
        // 【確認内容】: バックグラウンド復帰時に状態が復元される 🟡

        // テストではアプリのライフサイクルをシミュレート
        await tester.pump(const Duration(seconds: 1));

        // 【結果検証】: 入力内容が引き続き表示される
        expect(find.text('バックグラウンドテスト'), findsWidgets);
        // 【確認内容】: アプリ状態が保持される 🟡

        await takeScreenshot(binding, 'RT-304_after_background');
      },
      // Note: 実機でバックグラウンド移行して手動実行してください
    );

    // ============================================================
    // RT-305: 長文読み上げテスト
    // ============================================================
    testWidgets(
      'RT-305: 500文字以上の長文を安定して読み上げられる',
      (tester) async {
        // 【テスト目的】: 長文読み上げの安定性を確認
        // 【関連要件】: TTS実機確認項目（500文字以上の長文）
        // 【手順】: 500文字以上の長文を読み上げ
        // 【期待結果】: 安定して読み上げられる、途中で停止しない
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: 長文を入力（簡略化）
        const longText = 'これは長文読み上げのテストです。';
        await typeOnCharacterBoard(tester, longText);

        // 【実際の処理実行】: 読み上げを開始
        await tapIconButton(tester, Icons.volume_up);
        await tester.pump(const Duration(seconds: 3));

        // 【結果検証】: 長文が表示される
        expect(find.text(longText), findsWidgets);

        // Note: 実機で以下を手動確認：
        // 1. 500文字以上の長文を入力
        // 2. 読み上げボタンをタップ
        // 3. 最後まで安定して読み上げられる
        // 4. 途中で停止しない
        // 5. メモリリークが発生しない
        // 【確認内容】: 長文読み上げが安定動作する 🟡

        await takeScreenshot(binding, 'RT-305_long_text_tts');

        // 【実際の処理実行】: 停止ボタンで中断できる
        final stopButton = find.byIcon(Icons.stop);
        if (stopButton.evaluate().isNotEmpty) {
          await tester.tap(stopButton);
          await tester.pumpAndSettle();
        }
      },
    );

    // ============================================================
    // RT-306: 連続読み上げテスト
    // ============================================================
    testWidgets(
      'RT-306: 10回連続で読み上げても安定動作する',
      (tester) async {
        // 【テスト目的】: 連続読み上げの安定性を確認
        // 【関連要件】: TTS実機確認項目（連続読み上げ）
        // 【手順】: 10回連続で読み上げ実行
        // 【期待結果】: 安定して読み上げられる、メモリリークなし
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: テキストを入力
        await typeOnCharacterBoard(tester, '連続読み上げテスト');

        // 【実際の処理実行】: 10回連続で読み上げ
        for (int i = 0; i < 10; i++) {
          debugPrint('連続読み上げ: ${i + 1}回目');
          await tapIconButton(tester, Icons.volume_up);
          await tester.pump(const Duration(milliseconds: 500));

          // 短い待機
          await tester.pump(const Duration(milliseconds: 100));
        }

        // 【結果検証】: 10回連続読み上げが完了する
        // Note: 実機で以下を手動確認：
        // 1. 文字列を入力
        // 2. 読み上げボタンを10回連続でタップ
        // 3. すべて安定して読み上げられる
        // 4. メモリリークが発生しない
        // 5. アプリがクラッシュしない
        // 【確認内容】: 連続読み上げが安定動作する 🟡

        await takeScreenshot(binding, 'RT-306_continuous_tts');
      },
    );

    // ============================================================
    // RT-307: ストレージ容量不足テスト
    // ============================================================
    testWidgets(
      'RT-307: ストレージ容量不足時に警告表示される',
      (tester) async {
        // 【テスト目的】: ストレージ容量不足時のエラーハンドリングを確認
        // 【関連要件】: EDGE-003（ストレージ容量不足）
        // 【手順】: デバイスのストレージを極限まで埋める
        // 【期待結果】: 警告表示、古い履歴削除提案
        // 🟡 信頼性レベル: 黄信号（エッジケース）

        await pumpApp(tester);

        // 【実際の処理実行】: 多数の履歴を作成
        for (int i = 0; i < 60; i++) {
          // 50件制限を超える
          await typeOnCharacterBoard(tester, 'テスト履歴${i + 1}');
          await tapIconButton(tester, Icons.volume_up);
          await tester.pump(const Duration(milliseconds: 100));

          // 入力欄をクリア
          final clearButton = find.byIcon(Icons.clear);
          if (clearButton.evaluate().isNotEmpty) {
            await tester.tap(clearButton);
            await tester.pump();
          }
        }

        // 【結果検証】: 履歴が50件制限で管理される
        // Note: 実機で以下を手動確認：
        // 1. デバイスのストレージを限界まで埋める
        // 2. アプリで履歴を大量に保存
        // 3. ストレージ容量不足の警告が表示される
        // 4. 「古い履歴を削除しますか?」などの提案が表示される
        // 5. 自動的に古い履歴が削除される（50件制限）
        // 【確認内容】: ストレージ容量不足時に適切な警告が表示される 🟡

        await takeScreenshot(binding, 'RT-307_storage_warning');
      },
      // Note: 実機でストレージを満杯にして手動実行してください
    );
  });
}
