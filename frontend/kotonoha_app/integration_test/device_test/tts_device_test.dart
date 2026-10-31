/// TTS実機動作テスト
/// TTS（Text-to-Speech）機能の実機動作を検証するE2Eテスト。
/// iOS AVSpeechSynthesizer、Android TextToSpeech、エッジケースを確認。
///
/// 文字盤で打てるのは基本の五十音（＋濁点・半濁点・空白）だけなので、文はひらがな。
/// 長い文や多数の文は、キーボード入力と同じ入力欄（`home_input_field`）に入れる。
/// iOS 固有（RT-201〜203）は iOS だけ、Android 固有（RT-204〜206）は Android だけで走る。
@Tags(['e2e', 'device', 'tts', 'ios', 'android'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';

import '../helpers/test_helpers.dart';

final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;
final bool _isAndroid = defaultTargetPlatform == TargetPlatform.android;

/// 入力欄に文を入れる（キーボード入力と同じ経路）
Future<void> _enterInput(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('home_input_field')), text);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TTS実機動作テスト（プラットフォーム固有）', () {
    // RT-201: iOS TTS（AVSpeechSynthesizer）テスト
    testWidgets(
      'RT-201: iOS実機でTTS（AVSpeechSynthesizer）が正常動作する',
      (tester) async {
        // （iOS AVSpeechSynthesizer）
        // 手順: iOS実機で読み上げ
        // 期待結果: 日本語音声エンジンで読み上げられる
        // Note: このテストはiOS実機でのみ実行される

        await pumpApp(tester);

        // 実際の処理実行: 日本語テキストを入力
        await typeOnCharacterBoard(tester, 'こんにちは　これはにほんごのよみあげです');

        // 実際の処理実行: 読み上げを開始
        await tapAndExpectSpeech(tester, find.text('読み上げ'));

        // 結果検証: TTS読み上げが実行される
        // Note: iOS実機で以下を手動確認
        // AVSpeechSynthesizerが使用されている
        // 日本語音声エンジンで読み上げられる
        // 音声がクリアで聞き取りやすい

        await takeScreenshot(binding, 'RT-201_ios_tts');
        await stopSpeechIfSpeaking(tester);
      },
      skip: !_isIOS,
    );

    // RT-202: iOS SafeAreaテスト
    testWidgets(
      'RT-202: iPhoneノッチ対応でレイアウトがSafeArea内に収まる',
      (tester) async {
        // （iOS SafeArea対応）
        // 手順: iPhone（ノッチあり）で起動
        // 期待結果: レイアウトがSafeArea内に収まる

        await pumpApp(tester);

        // 実際の処理実行: iPhone 14サイズに設定
        await setTestSurfaceSize(tester, const Size(390, 844));

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'RT-202_ios_safe_area');

        // Note: iOS実機（iPhone 12以降、ノッチあり）で以下を手動確認
        // レイアウトがノッチやホームインジケーターと重ならない
        // 文字盤ボタンが画面端まで適切に配置される
      },
      skip: !_isIOS,
    );

    // RT-203: iOSガイド付きアクセステスト
    testWidgets(
      'RT-203: iOSガイド付きアクセス有効時もアプリが正常動作する',
      (tester) async {
        // （iOSガイド付きアクセス）
        // 手順: ガイド付きアクセス有効化
        // 期待結果: アプリが正常動作する

        await pumpApp(tester);

        // 実際の処理実行: 基本機能を実行
        await typeOnCharacterBoard(tester, 'がいどつきあくせす');
        await tapAndExpectSpeech(tester, find.text('読み上げ'));

        // 結果検証: アプリが正常動作する
        expect(find.text('がいどつきあくせす'), findsWidgets);

        await takeScreenshot(binding, 'RT-203_ios_guided_access');
        await stopSpeechIfSpeaking(tester);

        // Note: iOS実機で以下を手動確認
        // 1. 設定 > アクセシビリティ > ガイドアクセス を有効化
        // 2. アプリ起動後、ホームボタン3回押し（または電源ボタン3回押し）
        // 3. ガイド付きアクセスを開始
        // 4. アプリの基本機能（文字盤、TTS、定型文）が正常動作することを確認
        // 5. アプリからの脱出ができないことを確認（セキュリティ）
      },
      skip: !_isIOS,
    );

    // RT-204: Android TTS（TextToSpeech）テスト
    testWidgets(
      'RT-204: Android実機でTTS（TextToSpeech）が正常動作する',
      (tester) async {
        // （Android TextToSpeech）
        // 手順: Android実機で読み上げ
        // 期待結果: 日本語音声エンジンで読み上げられる

        await pumpApp(tester);

        // 実際の処理実行: 日本語テキストを入力
        await typeOnCharacterBoard(tester, 'こんにちは　これはにほんごのよみあげです');

        // 実際の処理実行: 読み上げを開始
        await tapAndExpectSpeech(tester, find.text('読み上げ'));

        // 結果検証: TTS読み上げが実行される
        // Note: Android実機で以下を手動確認
        // TextToSpeechが使用されている
        // 日本語音声エンジン（Google TTS等）で読み上げられる
        // 音声がクリアで聞き取りやすい

        await takeScreenshot(binding, 'RT-204_android_tts');
        await stopSpeechIfSpeaking(tester);
      },
      skip: !_isAndroid,
    );

    // RT-205: Android Navigation Barテスト
    testWidgets(
      'RT-205: Android Navigation Bar対応でレイアウトが適切に調整される',
      (tester) async {
        // （Android Navigation Bar対応）
        // 手順: 3ボタン/ジェスチャーナビゲーション
        // 期待結果: レイアウトが適切に調整される

        await pumpApp(tester);

        // 実際の処理実行: Android Pixelサイズに設定
        await setTestSurfaceSize(tester, const Size(412, 915));

        // 結果検証: 文字盤が表示される
        expect(find.text('あ'), findsWidgets);

        await takeScreenshot(binding, 'RT-205_android_navigation_bar');

        // Note: Android実機で以下を手動確認
        // 3ボタンナビゲーション有効時にレイアウトが適切に調整される
        // ジェスチャーナビゲーション有効時にレイアウトが適切に調整される
        // Navigation Barと重ならない
      },
      skip: !_isAndroid,
    );

    // RT-206: Android画面ピン留めテスト
    testWidgets(
      'RT-206: Android画面ピン留め有効時もアプリが正常動作する',
      (tester) async {
        // （Android画面ピン留め）
        // 手順: 画面ピン留め有効化
        // 期待結果: アプリが正常動作する

        await pumpApp(tester);

        // 実際の処理実行: 基本機能を実行
        await typeOnCharacterBoard(tester, 'がめんのこてい');
        await tapAndExpectSpeech(tester, find.text('読み上げ'));

        // 結果検証: アプリが正常動作する
        expect(find.text('がめんのこてい'), findsWidgets);

        await takeScreenshot(binding, 'RT-206_android_screen_pinning');
        await stopSpeechIfSpeaking(tester);

        // Note: Android実機で以下を手動確認
        // 1. 設定 > セキュリティ > 画面の固定 を有効化
        // 2. アプリ起動後、最近使ったアプリボタンをタップ
        // 3. アプリカードの上部にあるピンアイコンをタップ
        // 4. 画面ピン留めを開始
        // 5. アプリの基本機能（文字盤、TTS、定型文）が正常動作することを確認
        // 6. 戻る+最近使ったアプリボタン長押しでピン留め解除できることを確認
      },
      skip: !_isAndroid,
    );
  });

  // エッジケース・エラーハンドリングテスト
  group('TTS実機エッジケーステスト', () {
    // RT-301: OS音量0での読み上げテスト
    testWidgets(
      'RT-301: OS音量0で読み上げ実行時に視覚的警告が表示される',
      (tester) async {
        // （OS音量0での読み上げ）
        // 手順: 音量0→読み上げ実行
        // 期待結果: 「音量が0です」視覚的警告表示

        await pumpApp(tester);

        // 実際の処理実行: テキストを入力
        await typeOnCharacterBoard(tester, 'おとのおおきさ');

        // 実際の処理実行: 読み上げを実行
        await tapAndExpectSpeech(tester, find.text('読み上げ'));
        await tester.pump(const Duration(milliseconds: 500));

        // 結果検証: 音量警告が表示される可能性がある（端末の音量はテストから変えない）
        // Note: 実機で以下を手動確認
        // 1. OS音量を0（ミュート）に設定
        // 2. 読み上げボタンをタップ
        // 3. 画面上部に「音量が0です」の帯が出る（閉じるボタンで消せる）
        // 4. 定型文・履歴・お気に入りの画面から読み上げても同じ帯が出る
        // 5. 音量を上げて読み上げ直すと帯が消える

        await takeScreenshot(binding, 'RT-301_volume_zero_warning');
        await stopSpeechIfSpeaking(tester);
      },
      // Note: 実機で音量0に設定して手動実行してください
    );

    // RT-303: TTS音声エンジン未インストールテスト
    testWidgets(
      'RT-303: TTS音声エンジン未インストール時にエラーメッセージが表示される',
      (tester) async {
        // （TTS音声エンジン未インストール）
        // 手順: 日本語音声エンジンを削除（可能なら）
        // 期待結果: エラーメッセージ表示、テキスト表示のみ継続

        await pumpApp(tester);

        // 実際の処理実行: テキストを入力
        await typeOnCharacterBoard(tester, 'おんせいえんじんのてすと');

        // 実際の処理実行: 読み上げを実行（音声エンジンがあれば読み上げ、無ければ失敗の帯が出る）
        await tester.tap(find.text('読み上げ'));
        await tester.pump(const Duration(seconds: 1));

        // 結果検証: エラーメッセージが表示される可能性がある
        // Note: 実機で以下を手動確認
        // 1. iOS: 設定 > アクセシビリティ > 読み上げコンテンツ > 声 で日本語音声を削除
        // 2. Android: 設定 > システム > 言語と入力 > テキスト読み上げ で音声エンジンをアンインストール
        // 3. 読み上げボタンをタップ
        // 4. 「読み上げできませんでした。もう一度押すか、端末の読み上げの設定を確かめてください」
        //    の帯が出る（起動時に準備できなかったときは「読み上げを準備できませんでした。
        //    端末の読み上げの設定で、日本語の声が使えるか確かめてください」）
        // 5. テキスト表示は継続され、アプリがクラッシュしない

        await takeScreenshot(binding, 'RT-303_tts_engine_missing');
        await stopSpeechIfSpeaking(tester);
      },
      // Note: 実機で音声エンジンをアンインストールして手動実行してください
    );

    // RT-304: バックグラウンド復帰テスト
    testWidgets(
      'RT-304: アプリをバックグラウンドから復帰しても状態が復元される',
      (tester) async {
        // （バックグラウンド復帰）
        // 手順: アプリをバックグラウンドに→復帰
        // 期待結果: 前回の画面状態・入力内容が復元される

        await pumpApp(tester);

        // 実際の処理実行: テキストを入力
        await typeOnCharacterBoard(tester, 'はいけいからもどる');

        // 結果検証: 入力内容が表示される
        expect(find.text('はいけいからもどる'), findsWidgets);

        await takeScreenshot(binding, 'RT-304_before_background');

        // Note: 実機で以下を手動確認
        // 1. 文字列を入力した状態でホームボタン（またはジェスチャー）でバックグラウンドに移行
        // 2. 他のアプリを開く（メモリプレッシャーをかける）
        // 3. アプリを再度開く
        // 4. 入力内容が保持されている
        // 5. 画面状態（選択中のタブ、スクロール位置等）が復元される

        // テストではアプリのライフサイクルをシミュレート（バックグラウンド→復帰）
        // 状態は1段ずつしか移れない（resumed→inactive→hidden→paused と逆順）。
        // 背景にある間はフレームが止まり pump が返らないので、戻すまで pump しない
        // （2026-10-17 に iPad シミュレータで pump が返らず止まった）。
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        for (final state in [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpAndSettle();

        // 結果検証: 入力内容が引き続き表示される
        expect(find.text('はいけいからもどる'), findsWidgets);

        await takeScreenshot(binding, 'RT-304_after_background');
      },
      // Note: 実機でバックグラウンド移行して手動実行してください
    );

    // RT-305: 長文読み上げテスト
    testWidgets(
      'RT-305: 500文字以上の長文を安定して読み上げられる',
      (tester) async {
        // TTS実機確認項目（500文字以上の長文）
        // 手順: 500文字以上の長文を読み上げ
        // 期待結果: 安定して読み上げられる、途中で停止しない

        await pumpApp(tester);

        // 実際の処理実行: 500文字以上の長文を入力（文字盤では打てない長さなので入力欄へ）
        final longText = List.filled(26, 'これはながいぶんのよみあげのてすとです。').join();
        expect(longText.length, greaterThanOrEqualTo(500));
        await _enterInput(tester, longText);

        // 実際の処理実行: 読み上げを開始
        await tapAndExpectSpeech(tester, find.text('読み上げ'));
        await tester.pump(const Duration(seconds: 3));

        // 結果検証: 長文が表示され、3秒後も読み上げが続いている（途中で止まらない）
        expect(find.text(longText), findsWidgets);
        expect(
          appContainer(tester).read(ttsProvider).state,
          TTSState.speaking,
          reason: '500文字の読み上げが3秒以内に止まった',
        );

        // Note: 実機で以下を手動確認
        // 1. 500文字以上の長文を入力
        // 2. 読み上げボタンをタップ
        // 3. 最後まで安定して読み上げられる
        // 4. 途中で停止しない
        // 5. メモリリークが発生しない

        await takeScreenshot(binding, 'RT-305_long_text_tts');

        // 実際の処理実行: 停止ボタンで中断できる
        await tapButton(tester, '停止');
        expect(appContainer(tester).read(ttsProvider).state,
            isNot(TTSState.speaking));
      },
    );

    // RT-306: 連続読み上げテスト
    testWidgets(
      'RT-306: 10回連続で読み上げても安定動作する',
      (tester) async {
        // TTS実機確認項目（連続読み上げ）
        // 手順: 10回連続で読み上げ実行
        // 期待結果: 安定して読み上げられる、メモリリークなし

        await pumpApp(tester);

        // 実際の処理実行: テキストを入力
        await typeOnCharacterBoard(tester, 'れんぞくよみあげ');

        // 実際の処理実行: 10回連続で読み上げ（毎回、読み上げ中を通ることを確かめる）
        for (int i = 0; i < 10; i++) {
          debugPrint('連続読み上げ: ${i + 1}回目');
          await waitUntilQuiet(tester);
          await tapAndExpectSpeech(tester, find.text('読み上げ'));
        }
        await waitUntilQuiet(tester);

        // 結果検証: 10回連続読み上げが完了する
        // Note: 実機で以下を手動確認
        // 1. 文字列を入力
        // 2. 読み上げボタンを10回連続でタップ
        // 3. すべて安定して読み上げられる
        // 4. メモリリークが発生しない
        // 5. アプリがクラッシュしない

        await takeScreenshot(binding, 'RT-306_continuous_tts');
      },
    );

    // RT-307: ストレージ容量不足テスト
    testWidgets(
      'RT-307: ストレージ容量不足時に警告表示される',
      (tester) async {
        // （ストレージ容量不足）
        // 手順: デバイスのストレージを極限まで埋める
        // 期待結果: 警告表示、古い履歴削除提案

        await pumpApp(tester);

        // 実際の処理実行: 多数の履歴を作成（50件制限を超える60件）
        for (int i = 0; i < 60; i++) {
          await _enterInput(tester, 'りれき${i + 1}');
          await tapAndExpectSpeech(tester, find.text('読み上げ'));
          await stopSpeechIfSpeaking(tester);
          // 「読み上げ」の連続タップは300ms以内だと無視されるので間を空ける
          await tester.pump(const Duration(milliseconds: 400));
        }

        // 結果検証: 履歴が50件制限で管理され、新しい方が残る
        final histories = appContainer(tester).read(historyProvider).histories;
        expect(histories, hasLength(HistoryRepository.maxHistoryCount));
        expect(histories.first.content, 'りれき60');
        expect(histories.last.content, 'りれき11');
        // Note: 実機で以下を手動確認
        // 1. デバイスのストレージを限界まで埋める
        // 2. アプリで履歴を大量に保存
        // 3. ストレージ容量不足の警告が表示される
        // 4. 「古い履歴を削除しますか?」などの提案が表示される
        // 5. 自動的に古い履歴が削除される（50件制限。これはテストでも確かめる）

        await takeScreenshot(binding, 'RT-307_storage_warning');
      },
      // Note: 実機でストレージを満杯にして手動実行してください
    );
  });
}
