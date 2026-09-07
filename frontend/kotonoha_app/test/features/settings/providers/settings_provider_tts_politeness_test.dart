/// TTS速度・AI丁寧さレベル設定 Providerテスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';

void main() {
  group('TASK-0074: TTS速度・AI丁寧さレベル設定 Providerテスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    group('正常系テストケース', () {
      /// TTS速度「遅い」の選択と保存
      test('TC-074-003: TTS速度「遅い」の選択と保存', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: TTS速度を「遅い」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 結果検証: TTS速度がslowに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow);

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), TTSSpeed.slow.name);

        container.dispose();
      });

      /// TTS速度「普通」の選択と保存（デフォルト）
      test('TC-074-004: TTS速度「普通」の選択と保存（デフォルト）', () async {
        // Given: テストデータ準備: 空のSharedPreferences
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // When: 実際の処理実行: 初期状態を取得
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: デフォルトがnormalであること
        expect(settings.ttsSpeed, TTSSpeed.normal);

        container.dispose();
      });

      /// TTS速度「速い」の選択と保存
      test('TC-074-005: TTS速度「速い」の選択と保存', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: TTS速度を「速い」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 結果検証: TTS速度がfastに更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.fast);

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), TTSSpeed.fast.name);

        container.dispose();
      });

      /// AI丁寧さレベル「カジュアル」の選択と保存
      test('TC-074-006: AI丁寧さレベル「カジュアル」の選択と保存', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: AI丁寧さレベルを「カジュアル」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setAIPoliteness(PolitenessLevel.casual);

        // Then: 結果検証: AI丁寧さレベルがcasualに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.casual);

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_politeness'), PolitenessLevel.casual.name);

        container.dispose();
      });

      /// AI丁寧さレベル「普通」の選択と保存（デフォルト）
      test('TC-074-007: AI丁寧さレベル「普通」の選択と保存（デフォルト）', () async {
        // Given: テストデータ準備: 空のSharedPreferences
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // When: 実際の処理実行: 初期状態を取得
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: デフォルトがnormalであること
        expect(settings.aiPoliteness, PolitenessLevel.normal);

        container.dispose();
      });

      /// AI丁寧さレベル「丁寧」の選択と保存
      test('TC-074-008: AI丁寧さレベル「丁寧」の選択と保存', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: AI丁寧さレベルを「丁寧」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setAIPoliteness(PolitenessLevel.polite);

        // Then: 結果検証: AI丁寧さレベルがpoliteに更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.polite);

        // SharedPreferencesに保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_politeness'), PolitenessLevel.polite.name);

        container.dispose();
      });

      /// TTS速度変更が即座に反映される
      test('TC-074-009: TTS速度変更が即座に反映される', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: TTS速度を「遅い」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: 結果検証: 即座にstateが更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow);

        container.dispose();
      });

      /// AI丁寧さレベル変更が即座に反映される
      test('TC-074-010: AI丁寧さレベル変更が即座に反映される', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: AI丁寧さレベルを「丁寧」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setAIPoliteness(PolitenessLevel.polite);

        // Then: 結果検証: 即座にstateが更新されていること
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.polite);

        container.dispose();
      });

      /// アプリ再起動後のTTS速度設定復元
      test('TC-074-011: アプリ再起動後のTTS速度設定復元', () async {
        // Given: テストデータ準備: SharedPreferencesにtts_speed: "fast"を保存
        SharedPreferences.setMockInitialValues({
          'tts_speed': TTSSpeed.fast.name,
        });

        // When: 実際の処理実行: 新しいProviderContainerを作成（再起動を模擬）
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: TTS速度「fast」が正しく復元されたことを確認
        expect(settings.ttsSpeed, TTSSpeed.fast);

        container.dispose();
      });

      /// アプリ再起動後のAI丁寧さレベル設定復元
      test('TC-074-012: アプリ再起動後のAI丁寧さレベル設定復元', () async {
        // Given: テストデータ準備: SharedPreferencesにai_politeness: "polite"を保存
        SharedPreferences.setMockInitialValues({
          'ai_politeness': PolitenessLevel.polite.name,
        });

        // When: 実際の処理実行: 新しいProviderContainerを作成（再起動を模擬）
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: AI丁寧さレベル「polite」が正しく復元されたことを確認
        expect(settings.aiPoliteness, PolitenessLevel.polite);

        container.dispose();
      });

      /// 複数設定の同時保存・復元
      test('TC-074-013: 複数設定の同時保存・復元', () async {
        // Given: テストデータ準備: 初期コンテナを作成
        SharedPreferences.setMockInitialValues({});
        final container1 = ProviderContainer();

        await container1.read(settingsNotifierProvider.future);
        final notifier1 = container1.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: TTS速度とAI丁寧さレベルを変更
        await notifier1.setTTSSpeed(TTSSpeed.slow);
        await notifier1.setAIPoliteness(PolitenessLevel.casual);

        // コンテナを破棄
        container1.dispose();

        // 新しいProviderContainerを作成（再起動を模擬）
        final container2 = ProviderContainer();
        final settings = await container2.read(settingsNotifierProvider.future);

        // Then: 結果検証: すべての設定が正しく復元されること
        expect(settings.ttsSpeed, TTSSpeed.slow);
        expect(settings.aiPoliteness, PolitenessLevel.casual);

        // 他の設定（fontSize, theme）も影響を受けないこと
        expect(settings.fontSize, FontSize.medium);
        expect(settings.theme, AppTheme.light);

        container2.dispose();
      });
    });

    group('異常系テストケース', () {
      /// TTS速度の不正値フォールバック
      test('TC-074-014: TTS速度の不正値フォールバック', () async {
        // Given: テストデータ準備: SharedPreferencesに不正な値を保存
        SharedPreferences.setMockInitialValues({
          'tts_speed': 'invalid_value',
        });

        // When: 実際の処理実行: Provider初期化
        final container = ProviderContainer();

        // Then: 結果検証: エラーにならず、デフォルト値（normal）が使用される
        try {
          final settings =
              await container.read(settingsNotifierProvider.future);
          // 不正値の場合はデフォルト値が使用されるべき
          expect(settings.ttsSpeed, TTSSpeed.normal);
        } catch (e) {
          // エラーが発生した場合はテスト失敗
          fail('不正値でアプリがクラッシュしました: $e');
        }

        container.dispose();
      });

      /// AI丁寧さレベルの不正値フォールバック
      test('TC-074-015: AI丁寧さレベルの不正値フォールバック', () async {
        // Given: テストデータ準備: SharedPreferencesに不正な値を保存
        SharedPreferences.setMockInitialValues({
          'ai_politeness': 'invalid_value',
        });

        // When: 実際の処理実行: Provider初期化
        final container = ProviderContainer();

        // Then: 結果検証: エラーにならず、デフォルト値（normal）が使用される
        try {
          final settings =
              await container.read(settingsNotifierProvider.future);
          // 不正値の場合はデフォルト値が使用されるべき
          expect(settings.aiPoliteness, PolitenessLevel.normal);
        } catch (e) {
          // エラーが発生した場合はテスト失敗
          fail('不正値でアプリがクラッシュしました: $e');
        }

        container.dispose();
      });
    });

    group('境界値テストケース', () {
      /// TTSSpeed enumの全値テスト
      test('TC-074-017: TTSSpeed enumの全値テスト', () async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When/Then: 実際の処理実行と結果検証: 各値について保存・復元を確認
        for (final speed in TTSSpeed.values) {
          // 各速度を設定
          await notifier.setTTSSpeed(speed);

          // stateが更新されていることを確認
          final state = container.read(settingsNotifierProvider);
          expect(state.requireValue.ttsSpeed, speed);

          // SharedPreferencesに保存されていることを確認
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('tts_speed'), speed.name);
        }

        container.dispose();
      });

      /// PolitenessLevel enumの全値テスト
      test('TC-074-018: PolitenessLevel enumの全値テスト', () async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When/Then: 実際の処理実行と結果検証: 各値について保存・復元を確認
        for (final level in PolitenessLevel.values) {
          // 各丁寧さレベルを設定
          await notifier.setAIPoliteness(level);

          // stateが更新されていることを確認
          final state = container.read(settingsNotifierProvider);
          expect(state.requireValue.aiPoliteness, level);

          // SharedPreferencesに保存されていることを確認
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('ai_politeness'), level.name);
        }

        container.dispose();
      });

      /// TTS速度の連続変更テスト
      test('TC-074-019: TTS速度の連続変更テスト', () async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: slow → normal → fast → slow の順に変更
        await notifier.setTTSSpeed(TTSSpeed.slow);
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow);

        await notifier.setTTSSpeed(TTSSpeed.normal);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.normal);

        await notifier.setTTSSpeed(TTSSpeed.fast);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.fast);

        await notifier.setTTSSpeed(TTSSpeed.slow);
        state = container.read(settingsNotifierProvider);

        // Then: 結果検証: 最終的に slow が正しく設定される
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow);

        // SharedPreferencesにも最終値が保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('tts_speed'), TTSSpeed.slow.name);

        container.dispose();
      });

      /// AI丁寧さレベルの連続変更テスト
      test('TC-074-020: AI丁寧さレベルの連続変更テスト', () async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: casual → normal → polite → casual の順に変更
        await notifier.setAIPoliteness(PolitenessLevel.casual);
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.casual);

        await notifier.setAIPoliteness(PolitenessLevel.normal);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.normal);

        await notifier.setAIPoliteness(PolitenessLevel.polite);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.aiPoliteness, PolitenessLevel.polite);

        await notifier.setAIPoliteness(PolitenessLevel.casual);
        state = container.read(settingsNotifierProvider);

        // Then: 結果検証: 最終的に casual が正しく設定される
        expect(state.requireValue.aiPoliteness, PolitenessLevel.casual);

        // SharedPreferencesにも最終値が保存されていること
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('ai_politeness'), PolitenessLevel.casual.name);

        container.dispose();
      });
    });

    // 4. 統合テストケース
    group('統合テストケース', () {
      /// SettingsProviderの全機能統合テスト
      test('TC-074-021: SettingsProviderの全機能統合テスト', () async {
        // Given: テストデータ準備: 初期コンテナを作成
        SharedPreferences.setMockInitialValues({});
        final container1 = ProviderContainer();

        await container1.read(settingsNotifierProvider.future);
        final notifier1 = container1.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: すべての設定を変更
        await notifier1.setFontSize(FontSize.large);
        await notifier1.setTheme(AppTheme.dark);
        await notifier1.setTTSSpeed(TTSSpeed.fast);
        await notifier1.setAIPoliteness(PolitenessLevel.polite);

        // コンテナを破棄
        container1.dispose();

        // 新しいProviderContainerを作成（再起動を模擬）
        final container2 = ProviderContainer();
        final settings = await container2.read(settingsNotifierProvider.future);

        // Then: 結果検証: すべての設定が正しく復元されること
        expect(settings.fontSize, FontSize.large);
        expect(settings.theme, AppTheme.dark);
        expect(settings.ttsSpeed, TTSSpeed.fast);
        expect(settings.aiPoliteness, PolitenessLevel.polite);

        container2.dispose();
      });
    });
  });
}
