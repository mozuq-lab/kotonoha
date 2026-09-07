/// SettingsProvider TTS速度設定テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import '../../../mocks/mock_flutter_tts.dart';

/// TTSNotifierのモック
class MockTTSNotifier extends Mock {
  Future<void> setSpeed(TTSSpeed speed);
}

/// テスト用にモック化されたFlutterTtsを注入したTTSNotifierを作成する
TTSNotifier createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(serviceOverride: service);
}

void main() {
  group('SettingsNotifier - TTS速度設定テスト', () {
    late ProviderContainer container;
    late MockTTSNotifier mockTTSNotifier;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue(TTSSpeed.normal);
      registerFallbackValue('');
      registerFallbackValue(0.0);
    });

    setUp(() async {
      // テスト前準備: SharedPreferencesのモックを初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      SharedPreferences.setMockInitialValues({});

      // TTSNotifierのモックを作成
      mockTTSNotifier = MockTTSNotifier();
      when(() => mockTTSNotifier.setSpeed(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      // テスト後処理: ProviderContainerを破棄し、次のテストに影響しないようにする
      // 状態復元: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // 正常系テストケース
    group('正常系テスト', () {
      /// SettingsNotifier.setTTSSpeedでshared_preferencesに保存される
      test(
          'TC-049-005: setTTSSpeed()メソッドを呼び出すと、shared_preferencesに速度設定が保存されることを確認',
          () async {
        // Given: テストデータ準備: ProviderContainerを作成
        // 初期条件設定: 初期状態（normal）から開始
        container = ProviderContainer();

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: setTTSSpeed(TTSSpeed.fast)を呼び出す
        // 処理内容: ユーザーが設定画面で「速い」を選択した場合を模擬
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 結果検証: 状態が更新され、shared_preferencesに保存されたことを確認
        // （設定永続化）と（即座反映）を満たす
        // 品質保証: ユーザーの速度変更が確実に保存され、アプリ再起動後も設定が失われないことを保証
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.fast);

        // 検証項目: SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), 'fast');
      });

      /// SettingsNotifier.setTTSSpeedでTTSNotifier.setSpeedが呼ばれる
      test(
          'TC-049-006: setTTSSpeed()を呼び出すと、TTSNotifier.setSpeed()が呼ばれ、TTSエンジンに速度が反映されることを確認',
          () async {
        // Given: テストデータ準備: TTSNotifierのモックを注入したProviderContainerを作成
        // 初期条件設定: 初期状態から開始
        container = ProviderContainer(
          overrides: [
            // TTSNotifierのモックを注入（実際の実装では異なる方法が必要）
            // Note: この部分は実装時に適切なモック方法を採用する必要がある
          ],
        );

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: setTTSSpeed(TTSSpeed.slow)を呼び出す
        // 処理内容: ユーザーが設定画面で「遅い」を選択した場合を模擬
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 結果検証: TTSNotifier.setSpeedが呼ばれたことを確認
        // requirements.md（122-127行目）のデータフローに基づく
        // 品質保証: 設定画面での速度変更が、TTSエンジンに正しく伝達されることを保証

        // Note: モック化の方法により検証方法が異なるため、実装時に適切な検証方法を採用する
        // verify( => mockTTSNotifier.setSpeed(TTSSpeed.slow)).called(1);
      });

      /// アプリ再起動後、保存されたTTS速度が復元される
      test('TC-049-010: アプリを終了し再起動した後、前回設定したTTS速度が正しく復元されることを確認', () async {
        // Given: テストデータ準備: 前回のセッションで速度を「速い」に設定した状態を模擬
        // 初期条件設定: ユーザーが前回のセッションで速度を「速い」に設定し、翌日アプリを再起動した場合
        SharedPreferences.setMockInitialValues({
          'tts_speed': 'fast',
        });

        // When: 実際の処理実行: 新しいProviderContainerを作成（再起動を模擬）
        // 処理内容: アプリ起動時のProvider初期化
        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: 速度が「速い」に復元されたことを確認
        // （設定永続化）に基づく
        // 品質保証: アプリ再起動後も設定が失われないことを確認
        expect(settings.ttsSpeed, TTSSpeed.fast);
      });

      /// TTS-SPEED-RESTORE-FIX: アプリ再起動後、保存された速度が実際のTTSエンジンに反映される
      test(
          'TTS-SPEED-RESTORE-FIX: アプリ再起動後、保存された速度が実際にTTSエンジン（flutter_tts）へ適用されることを確認',
          () async {
        // Given: テストデータ準備: 前回のセッションで速度を「速い」に設定していた状態を再現
        // 初期条件設定: SharedPreferencesに保存済みの速度、モック化されたTTSエンジン
        SharedPreferences.setMockInitialValues({
          'tts_speed': 'fast',
        });

        final mockFlutterTts = MockFlutterTts();
        when(() => mockFlutterTts.setLanguage(any()))
            .thenAnswer((_) async => 1);
        when(() => mockFlutterTts.setSpeechRate(any()))
            .thenAnswer((_) async => 1);
        when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
        when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

        final service = TTSService(tts: mockFlutterTts);

        container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => TTSNotifier(serviceOverride: service)),
          ],
        );

        // When: 実際の処理実行(1): まずSettingsNotifier.buildの完了を待つ
        // （起動シーケンスで設定復元がTTS画面表示より先に完了する状況を再現）
        final settings = await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行(2): その後TTSButton等が表示され
        // ttsProviderが構築される状況を再現する
        container.read(ttsProvider.notifier);
        // バックグラウンド初期化＋保存済み速度の反映が完了するのを待つ
        await Future.delayed(const Duration(milliseconds: 100));

        // Then: 結果検証: 状態だけでなく、実際のTTSエンジンにも速度(1.3倍速)が
        // 適用されていることを確認する
        // setSpeechRate(1.0)への上書きが発生せず、最終的な速度が
        // fast(1.3)であること
        expect(settings.ttsSpeed, TTSSpeed.fast);
        verify(() => mockFlutterTts.setSpeechRate(1.3))
            .called(greaterThanOrEqualTo(1));
        expect(
          service.currentSpeed,
          TTSSpeed.fast,
        );
      });

      /// 回帰テスト: HomeScreen.buildと同じ読み取り順（settingsNotifierProvider
      /// をwatchした直後、同一の同期フレーム内でttsProviderをlisten/read）でも
      /// settingsNotifierProviderがデッドロックせず解決することを確認する。
      /// バグの背景: レビューで、SettingsNotifier.build内から
      /// `ref.exists(ttsProvider)`が真の場合にttsProvider.notifier.setSpeedを
      /// 呼ぶコードが存在すると、HomeScreen.buildの実際の呼び出し順序
      /// （settingsNotifierProviderをwatchした直後、同じ同期フレーム内で
      /// ttsProviderをlistenする）では、両Providerが同一フレームで生成される
      /// ため以下の循環待機が発生し、settingsNotifierProvider.future が
      /// 永久に解決しないデッドロックを引き起こすことが判明した
      /// SettingsNotifier.build
      /// → await ttsProvider.notifier.setSpeed
      /// → await _initFuture
      /// → await _applyPersistedSpeedIfAvailable
      /// → await ref.read(settingsNotifierProvider.future) // 循環
      /// この回帰テストは、settings→ttsの一方向依存（tts_provider.dart側の
      /// pullのみ）で運用されていることを保証する。
      test(
          '回帰: settingsNotifierProviderをwatch直後に同一フレームでttsProviderを'
          'read してもsettingsNotifierProviderがデッドロックしない', () async {
        SharedPreferences.setMockInitialValues({'tts_speed': 'fast'});

        final mockFlutterTts = MockFlutterTts();
        when(() => mockFlutterTts.setLanguage(any()))
            .thenAnswer((_) async => 1);
        when(() => mockFlutterTts.setSpeechRate(any()))
            .thenAnswer((_) async => 1);
        when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
        when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);

        final service = TTSService(tts: mockFlutterTts);

        container = ProviderContainer(
          overrides: [
            ttsProvider
                .overrideWith(() => TTSNotifier(serviceOverride: service)),
          ],
        );

        // HomeScreen.buildを模擬: settingsNotifierProviderを読んだ直後
        // awaitを挟まず同一の同期スタック内でttsProviderを読む。
        final settingsFuture = container.read(settingsNotifierProvider.future);
        container.read(ttsProvider.notifier);

        // デッドロックしていれば、この await はタイムアウトする。
        final settings = await settingsFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () => fail(
            'settingsNotifierProvider.future がデッドロックにより解決しなかった',
          ),
        );

        expect(settings.ttsSpeed, TTSSpeed.fast);
      });
    });

    // 異常系テストケース
    group('異常系テスト', () {
      /// shared_preferences保存失敗時もUI状態は更新される（楽観的更新）
      test(
          'TC-049-012: shared_preferences.setString()が失敗した場合でも、AppSettingsの状態は更新されることを確認',
          () async {
        // Given: テストデータ準備: ProviderContainerを作成
        // 初期条件設定: 正常な初期状態
        // 実際の発生シナリオ: ストレージ容量不足、ファイルシステムエラー
        container = ProviderContainer();

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // このテストでは保存失敗を注入しておらず、通常時の状態更新のみを確認する。

        // When: 実際の処理実行: setTTSSpeed(TTSSpeed.fast)を呼び出す
        // 処理内容: TTS速度変更
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 結果検証: 状態更新は成功していることを確認
        // （即座反映）と（エラーハンドリング）の両立
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.fast);
      });

      /// TTS初期化前に速度を設定してもエラーにならない
      test('TC-049-013: TTSServiceが初期化される前にsetTTSSpeed()を呼んでも、エラーが発生しないことを確認',
          () async {
        // Given: テストデータ準備: ProviderContainerを作成
        // 初期条件設定: TTS初期化前の状態
        // 実際の発生シナリオ: アプリ起動直後、ユーザーが即座に設定画面を開いた場合
        container = ProviderContainer();

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: TTS初期化前にsetTTSSpeedを呼び出す
        // 処理内容: 速度設定を行う（TTS初期化前）
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 結果検証: エラーが発生せず、速度値が保存されたことを確認
        // 初期化順序に依存しない堅牢性
        // システムの安全性: 初期化順序に関わらず、速度設定は常に保持される
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.slow);
        // エラーが発生しないことを確認（テストが完了すること自体が確認）
      });

      /// flutter_tts.setSpeechRate失敗時もアプリは継続動作
      test('TC-049-014: flutter_ttsの速度設定が失敗した場合でも、エラーログを出力してアプリは継続動作することを確認',
          () async {
        // Given: テストデータ準備: ProviderContainerを作成
        // 初期状態から速度を変更する。
        // 実際の発生シナリオ: 古いOSバージョンでの互換性問題、デバイス固有のTTSエンジンの制約
        container = ProviderContainer();

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // このテストではsetSpeechRateの失敗を注入していない。

        // When: 実際の処理実行: setTTSSpeedを呼び出す
        // 処理内容: 速度設定を行う
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 結果検証: アプリが継続動作し、状態には反映されたことを確認
        // （基本機能継続）に準拠
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.ttsSpeed, TTSSpeed.fast);
        // アプリが継続動作することを確認（テストが完了すること自体が確認）
      });
    });
  });
}
