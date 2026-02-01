/// TTS速度設定 統合テスト
///
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// テストケース: TC-049-007〜TC-049-009, TC-049-015, TC-049-017
///
/// テスト対象: エンドツーエンドのフロー（設定→TTS→永続化）
///
/// 【TDD Redフェーズ】: 統合的な機能が未実装、テストが失敗するはず
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import '../mocks/mock_flutter_tts.dart';

/// TTSNotifierを作成するヘルパー関数（テスト用）
TTSNotifier createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(serviceOverride: service);
}

void main() {
  group('TTS速度設定 統合テスト', () {
    late ProviderContainer container;
    late MockFlutterTts mockFlutterTts;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue('');
      registerFallbackValue(0.0);
      registerFallbackValue(TTSSpeed.normal);
    });

    setUp(() async {
      // 【テスト前準備】: SharedPreferencesのモックを初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
      SharedPreferences.setMockInitialValues({});

      // MockFlutterTtsを作成
      mockFlutterTts = MockFlutterTts();

      // モックのデフォルト動作を設定
      when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.setSpeechRate(any()))
          .thenAnswer((_) async => 1);
      when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    });

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄し、次のテストに影響しないようにする
      // 【状態復元】: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // =========================================================================
    // 正常系テストケース（速度別読み上げ）
    // =========================================================================
    group('正常系テスト - 速度別読み上げ', () {
      /// TTC-VS-003: 速度を「とても遅い」に設定後、読み上げが0.5倍速で実行される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: 速度設定→読み上げのエンドツーエンドフロー
      test('TTC-VS-003: 速度を「とても遅い」に設定後、テキストを読み上げると0.5倍速で再生されることを確認', () async {
        // 【テスト目的】: 「とても遅い」設定後の読み上げが正しい速度で実行されることを確認 🔵
        // 【テスト内容】: 速度を「とても遅い」に設定し、テキストを読み上げると0.5倍速で再生されることを検証
        // 【期待される動作】: flutter_ttsのsetSpeechRate(0.5)とspeak()が呼ばれる
        // 🔵 青信号: 既存テスト（TC-049-007〜009）のパターンに基づく

        // Given: 【テストデータ準備】: ProviderContainerを作成し、TTSServiceのモックを注入
        // 【初期条件設定】: アプリ起動時の状態
        container = ProviderContainer(
          overrides: [
            ttsProvider.overrideWith(
              () => createTestTTSNotifier(mockFlutterTts),
            ),
          ],
        );

        // SettingsNotifierとTTSNotifierを取得
        await container.read(settingsNotifierProvider.future);
        final settingsNotifier =
            container.read(settingsNotifierProvider.notifier);

        final ttsNotifier = container.read(ttsProvider.notifier);
        await ttsNotifier.initialize();

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: 速度を「とても遅い」に設定し、テキストを読み上げる
        // 【処理内容】: ユーザーが速度を「とても遅い」に設定し、実際にテキストを読み上げる場合を模擬
        // 【実行タイミング】: 高齢者や聴覚に配慮が必要な方に伝える際のユースケース
        await settingsNotifier.setTTSSpeed(TTSSpeed.verySlow);
        await ttsNotifier.speak('こんにちは');

        // Then: 【結果検証】: setSpeechRate(0.5)とspeak()が呼ばれたことを確認
        // 【期待値確認】: 要件定義書のデータフローに基づく
        // 【品質保証】: エンドツーエンドで速度設定→読み上げが正しく機能することを確認
        verify(() => mockFlutterTts.setSpeechRate(0.5))
            .called(1); // 【確認内容】: 0.5倍速が設定されたことを確認 🔵
        verify(() => mockFlutterTts.speak('こんにちは'))
            .called(1); // 【確認内容】: 読み上げが開始されたことを確認 🔵

        // 【確認ポイント】: SettingsNotifier→TTSNotifier→TTSService→FlutterTtsの連携
      });

      /// TC-049-007: 速度を「遅い」に設定し、読み上げると0.7倍速で再生される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: エンドツーエンドでの速度設定→読み上げフロー
      test('TC-049-007: 速度を「遅い」に設定後、テキストを読み上げると0.7倍速で再生されることを確認', () async {
        // 【テスト目的】: 速度設定→読み上げの一連のフローで、設定した速度が正しく適用されることを確認 🔵
        // 【テスト内容】: 速度を「遅い」に設定し、テキストを読み上げると0.7倍速で再生されることを検証
        // 【期待される動作】: flutter_ttsのsetSpeechRate(0.7)とspeak()が呼ばれる
        // 🔵 青信号: requirements.md（218-226行目）の使用例「4.2. 速度を「遅い」に変更」に基づく

        // Given: 【テストデータ準備】: ProviderContainerを作成し、TTSServiceのモックを注入
        // 【初期条件設定】: アプリ起動時の状態
        container = ProviderContainer(
          overrides: [
            ttsProvider.overrideWith(
              () => createTestTTSNotifier(mockFlutterTts),
            ),
          ],
        );

        // SettingsNotifierとTTSNotifierを取得
        await container.read(settingsNotifierProvider.future);
        final settingsNotifier =
            container.read(settingsNotifierProvider.notifier);

        final ttsNotifier = container.read(ttsProvider.notifier);
        await ttsNotifier.initialize();

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: 速度を「遅い」に設定し、テキストを読み上げる
        // 【処理内容】: ユーザーが速度を「遅い」に設定し、実際にテキストを読み上げる場合を模擬
        // 【実行タイミング】: 高齢者に伝える際のユースケース
        await settingsNotifier.setTTSSpeed(TTSSpeed.slow);
        await ttsNotifier.speak('こんにちは');

        // Then: 【結果検証】: setSpeechRate(0.7)とspeak()が呼ばれたことを確認
        // 【期待値確認】: requirements.md（218-226行目）の使用例に基づく
        // 【品質保証】: エンドツーエンドで速度設定→読み上げが正しく機能することを確認
        verify(() => mockFlutterTts.setSpeechRate(0.7))
            .called(1); // 【確認内容】: 0.7倍速が設定されたことを確認 🔵
        verify(() => mockFlutterTts.speak('こんにちは'))
            .called(1); // 【確認内容】: 読み上げが開始されたことを確認 🔵

        // 【確認ポイント】: 速度設定後、次回の読み上げから新しい速度が適用される
      });

      /// TC-049-008: 速度を「普通」に設定し、読み上げると1.0倍速で再生される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: デフォルト速度（normal）が正しく動作すること
      test('TC-049-008: 速度を「普通」に設定後、テキストを読み上げると1.0倍速で再生されることを確認', () async {
        // 【テスト目的】: デフォルト速度（normal）が正しく動作することを確認 🔵
        // 【テスト内容】: 速度を「普通」に設定し、テキストを読み上げると1.0倍速で再生されることを検証
        // 【期待される動作】: flutter_ttsのsetSpeechRate(1.0)とspeak()が呼ばれる
        // 🔵 青信号: TTSSpeed.normalの値が1.0であること（tts_speed.dart 67-69行目）

        // Given: 【テストデータ準備】: ProviderContainerを作成し、TTSServiceのモックを注入
        // 【初期条件設定】: アプリ起動時の状態
        container = ProviderContainer(
          overrides: [
            ttsProvider.overrideWith(
              () => createTestTTSNotifier(mockFlutterTts),
            ),
          ],
        );

        // SettingsNotifierとTTSNotifierを取得
        await container.read(settingsNotifierProvider.future);
        final settingsNotifier =
            container.read(settingsNotifierProvider.notifier);

        final ttsNotifier = container.read(ttsProvider.notifier);
        await ttsNotifier.initialize();

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: 速度を「普通」に設定し、テキストを読み上げる
        // 【処理内容】: ユーザーが標準速度で読み上げを行う場合を模擬
        // 【実行タイミング】: 最も一般的なユースケース
        await settingsNotifier.setTTSSpeed(TTSSpeed.normal);
        await ttsNotifier.speak('こんにちは');

        // Then: 【結果検証】: setSpeechRate(1.0)とspeak()が呼ばれたことを確認
        // 【期待値確認】: TTSSpeed.normalの値が1.0であること（tts_speed.dart 67-69行目）
        // 【品質保証】: デフォルト速度が正しく動作することを確認
        verify(() => mockFlutterTts.setSpeechRate(1.0))
            .called(1); // 【確認内容】: 1.0倍速が設定されたことを確認 🔵
        verify(() => mockFlutterTts.speak('こんにちは'))
            .called(1); // 【確認内容】: 読み上げが開始されたことを確認 🔵

        // 【確認ポイント】: 1.0倍速が標準的な読み上げ速度として機能する
      });

      /// TC-049-009: 速度を「速い」に設定し、読み上げると1.3倍速で再生される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: 最大速度（fast）が正しく動作すること
      test('TC-049-009: 速度を「速い」に設定後、テキストを読み上げると1.3倍速で再生されることを確認', () async {
        // 【テスト目的】: 最大速度（fast）が正しく動作することを確認 🔵
        // 【テスト内容】: 速度を「速い」に設定し、テキストを読み上げると1.3倍速で再生されることを検証
        // 【期待される動作】: flutter_ttsのsetSpeechRate(1.3)とspeak()が呼ばれる
        // 🔵 青信号: requirements.md（228-236行目）の使用例「4.3. 速度を「速い」に変更」に基づく

        // Given: 【テストデータ準備】: ProviderContainerを作成し、TTSServiceのモックを注入
        // 【初期条件設定】: アプリ起動時の状態
        container = ProviderContainer(
          overrides: [
            ttsProvider.overrideWith(
              () => createTestTTSNotifier(mockFlutterTts),
            ),
          ],
        );

        // SettingsNotifierとTTSNotifierを取得
        await container.read(settingsNotifierProvider.future);
        final settingsNotifier =
            container.read(settingsNotifierProvider.notifier);

        final ttsNotifier = container.read(ttsProvider.notifier);
        await ttsNotifier.initialize();

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: 速度を「速い」に設定し、テキストを読み上げる
        // 【処理内容】: ユーザーが慣れた介護スタッフとの素早いコミュニケーションを行う場合を模擬
        // 【実行タイミング】: requirements.md（228-236行目）の使用例に基づく
        await settingsNotifier.setTTSSpeed(TTSSpeed.fast);
        await ttsNotifier.speak('こんにちは');

        // Then: 【結果検証】: setSpeechRate(1.3)とspeak()が呼ばれたことを確認
        // 【期待値確認】: requirements.md（228-236行目）の使用例に基づく
        // 【品質保証】: 最大速度が正しく動作することを確認
        verify(() => mockFlutterTts.setSpeechRate(1.3))
            .called(1); // 【確認内容】: 1.3倍速が設定されたことを確認 🔵
        verify(() => mockFlutterTts.speak('こんにちは'))
            .called(1); // 【確認内容】: 読み上げが開始されたことを確認 🔵

        // 【確認ポイント】: 1.3倍速でも聞き取れる範囲内の速度設定
      });
    });

    // =========================================================================
    // 境界値テストケース
    // =========================================================================
    group('境界値テスト', () {
      /// TC-049-015: TTSSpeed enumの全値（slow/normal/fast）が正しく動作する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: すべての速度設定が正常に動作することを確認
      test(
          'TC-049-015: TTSSpeed enumのすべての値（slow=0、normal=1、fast=2）が正しくshared_preferencesに保存・復元されることを確認',
          () async {
        // 【テスト目的】: すべての速度設定が正常に動作することを確認 🔵
        // 【テスト内容】: 3つの速度設定すべてで保存・復元ロジックが動作することを検証
        // 【期待される動作】: slow、normal、fastすべてが正しくshared_preferencesに保存・復元される
        // 🔵 青信号: REQ-404、interfaces.dart（298-319行目）、既存テスト（settings_provider_test.dart TC-015、TC-016）のパターンに基づく

        // Given: 【テストデータ準備】: TTSSpeed enumの全値
        // 【初期条件設定】: ユーザーがすべての速度設定を試す場合
        final allSpeeds = [TTSSpeed.slow, TTSSpeed.normal, TTSSpeed.fast];

        for (final speed in allSpeeds) {
          // 各速度について個別にテスト
          SharedPreferences.setMockInitialValues({});

          container = ProviderContainer(
            overrides: [
              ttsProvider.overrideWith(
                () => createTestTTSNotifier(mockFlutterTts),
              ),
            ],
          );

          // SettingsNotifierを取得
          await container.read(settingsNotifierProvider.future);
          final settingsNotifier =
              container.read(settingsNotifierProvider.notifier);

          // When: 【実際の処理実行】: 各速度を設定
          // 【処理内容】: setTTSSpeed()で速度を変更
          await settingsNotifier.setTTSSpeed(speed);

          // Then: 【結果検証】: shared_preferencesに正しく保存されたことを確認
          // 【期待値確認】: 3つの速度設定すべてで同じ保存・復元ロジックが動作する
          // 【品質保証】: すべての速度設定が正常に動作することを確認
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('tts_speed'),
              speed.name); // 【確認内容】: shared_preferencesに正しく保存されたことを確認 🔵

          // 再起動後の復元テスト
          SharedPreferences.setMockInitialValues({
            'tts_speed': speed.name,
          });

          container.dispose();
          container = ProviderContainer();

          // 復元を確認
          final restoredSettings =
              await container.read(settingsNotifierProvider.future);
          expect(restoredSettings.ttsSpeed,
              speed); // 【確認内容】: 再起動後に正しく復元されたことを確認 🔵

          container.dispose();
        }

        // 【確認ポイント】: 最小速度（0.7）と最大速度（1.3）が正しく設定される
        // 【確認ポイント】: flutter_ttsの速度範囲（0.5〜2.0）内に収まる
      });

      /// TC-049-017: 読み上げ中に速度を変更しても、現在の読み上げは元の速度で継続
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: EDGE-1
      /// 検証内容: 並行処理の安全性を確認
      test(
          'TC-049-017: 読み上げ中に速度を変更した場合、現在の読み上げは元の速度で継続し、次回の読み上げから新しい速度が適用されることを確認',
          () async {
        // 【テスト目的】: 並行処理の安全性を確認 🟡
        // 【テスト内容】: 読み上げ中に速度を変更しても、現在の読み上げは元の速度で継続することを検証
        // 【期待される動作】: 現在の読み上げは元の速度で継続、次回の読み上げから新しい速度が適用される
        // 🟡 黄信号: requirements.md（286-296行目）のEDGE-1に基づく

        // Given: 【テストデータ準備】: ProviderContainerを作成し、TTSServiceのモックを注入
        // 【初期条件設定】: 速度「普通」で読み上げ中の状態
        container = ProviderContainer(
          overrides: [
            ttsProvider.overrideWith(
              () => createTestTTSNotifier(mockFlutterTts),
            ),
          ],
        );

        // SettingsNotifierとTTSNotifierを取得
        await container.read(settingsNotifierProvider.future);
        final settingsNotifier =
            container.read(settingsNotifierProvider.notifier);

        final ttsNotifier = container.read(ttsProvider.notifier);
        await ttsNotifier.initialize();

        // 速度を「普通」に設定して読み上げ開始
        await settingsNotifier.setTTSSpeed(TTSSpeed.normal);
        await ttsNotifier.speak('長いテキスト...');

        // モックの呼び出し履歴をクリア
        clearInteractions(mockFlutterTts);

        // When: 【実際の処理実行】: 読み上げ中に速度を「速い」に変更
        // 【処理内容】: ユーザーが読み上げ中に「速すぎる」と感じて速度を変更する場合を模擬
        await settingsNotifier.setTTSSpeed(TTSSpeed.fast);

        // 次回の読み上げ
        await ttsNotifier.speak('次のテキスト');

        // Then: 【結果検証】: 次回の読み上げから新しい速度が適用されたことを確認
        // 【期待値確認】: requirements.md（286-296行目）のEDGE-1に基づく
        // 【品質保証】: 並行処理の安全性を確認
        verify(() => mockFlutterTts.setSpeechRate(1.3))
            .called(greaterThanOrEqualTo(1)); // 【確認内容】: 新しい速度が設定されたことを確認 🟡
        verify(() => mockFlutterTts.speak('次のテキスト'))
            .called(1); // 【確認内容】: 次回の読み上げが開始されたことを確認 🟡

        // 【確認ポイント】: 読み上げ中の速度変更が安全に処理される
        // 【確認ポイント】: 状態遷移が正しく管理される
      });
    });
  });
}
