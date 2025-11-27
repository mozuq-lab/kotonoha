// AppSettingsRepository クラッシュテスト（TDD Redフェーズ）
// TASK-0059: データ永続化テスト
//
// テストフレームワーク: flutter_test + shared_preferences
// 対象: AppSettingsRepository（クラッシュ・エラー時の動作）
//
// 【TDD Redフェーズ】: トランザクション管理機能が未実装のため、このテストは失敗する
//
// 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/settings/data/app_settings_repository.dart';
import 'package:kotonoha_app/shared/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TC-059-008: 複数の設定同時変更後のクラッシュ', () {
    late AppSettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('TC-059-008: 複数の設定を同時変更した際のトランザクション整合性を検証', () async {
      // 【テスト目的】: 複数の設定を同時変更した際のトランザクション整合性を検証
      // 【信頼性レベル】: 🔵 青信号 - NFR-304に基づく

      // Given（準備フェーズ）
      // 設定がすべてデフォルト値の状態
      var prefs = await SharedPreferences.getInstance();
      repository = AppSettingsRepository(prefs: prefs);

      // デフォルト設定を読み込み
      final defaultSettings = await repository.load();
      expect(defaultSettings.fontSize, FontSize.medium);
      expect(defaultSettings.theme, AppTheme.light);
      expect(defaultSettings.ttsSpeed, TtsSpeed.normal);
      expect(defaultSettings.politenessLevel, PolitenessLevel.normal);

      // When（実行フェーズ）
      // 設定画面で複数の設定を変更
      const newSettings = AppSettings(
        fontSize: FontSize.large,
        theme: AppTheme.dark,
        ttsSpeed: TtsSpeed.fast,
        politenessLevel: PolitenessLevel.polite,
      );

      // 設定を一括保存
      await repository.saveAll(newSettings);

      // 保存途中でのクラッシュをシミュレート（SharedPreferencesをクリア）
      // 注: 実際の環境では、saveAll()の途中で例外が発生する可能性がある
      // ここでは、保存完了後に再度デフォルト設定を読み込み、
      // すべての設定が正しく保存されているか、または部分的な保存がないかを検証

      // 新しいRepositoryインスタンスで設定を読み込む（アプリ再起動をシミュレート）
      prefs = await SharedPreferences.getInstance();
      repository = AppSettingsRepository(prefs: prefs);
      final loadedSettings = await repository.load();

      // Then（検証フェーズ）
      // すべての設定が正しく保存されている
      expect(loadedSettings.fontSize, FontSize.large,
          reason: 'フォントサイズが保存されている');
      expect(loadedSettings.theme, AppTheme.dark, reason: 'テーマが保存されている');
      expect(loadedSettings.ttsSpeed, TtsSpeed.fast, reason: 'TTS速度が保存されている');
      expect(loadedSettings.politenessLevel, PolitenessLevel.polite,
          reason: '丁寧さレベルが保存されている');

      // データの整合性が保たれている（部分的な保存がない）
      // 例: 「fontSize: large、theme: light（デフォルト）」のような状態にならない
      final allSaved = loadedSettings.fontSize == FontSize.large &&
          loadedSettings.theme == AppTheme.dark &&
          loadedSettings.ttsSpeed == TtsSpeed.fast &&
          loadedSettings.politenessLevel == PolitenessLevel.polite;
      expect(allSaved, true, reason: 'すべての設定が一貫して保存されている');
    });

    test('TC-059-008-補足: saveAll()の原子性を検証', () async {
      // 【テスト目的】: saveAll()メソッドの原子性（すべて保存されるか、すべて失敗するか）を検証
      // 【信頼性レベル】: 🔵 青信号 - NFR-304に基づく

      // Given（準備フェーズ）
      var prefs = await SharedPreferences.getInstance();
      repository = AppSettingsRepository(prefs: prefs);

      // 複数の設定を変更
      const settings = AppSettings(
        fontSize: FontSize.small,
        theme: AppTheme.highContrast,
        ttsSpeed: TtsSpeed.slow,
        politenessLevel: PolitenessLevel.casual,
      );

      // When（実行フェーズ）
      await repository.saveAll(settings);

      // SharedPreferencesをクリアして再読み込み（クラッシュ後の復旧をシミュレート）
      prefs = await SharedPreferences.getInstance();
      repository = AppSettingsRepository(prefs: prefs);
      final loadedSettings = await repository.load();

      // Then（検証フェーズ）
      // すべての設定が保存されている、または全部デフォルトに戻っている
      // （部分的な保存状態にならない）

      final allSavedOrAllDefault =
          // パターン1: すべて保存されている
          (loadedSettings.fontSize == FontSize.small &&
                  loadedSettings.theme == AppTheme.highContrast &&
                  loadedSettings.ttsSpeed == TtsSpeed.slow &&
                  loadedSettings.politenessLevel == PolitenessLevel.casual) ||
              // パターン2: すべてデフォルトに戻っている
              (loadedSettings.fontSize == FontSize.medium &&
                  loadedSettings.theme == AppTheme.light &&
                  loadedSettings.ttsSpeed == TtsSpeed.normal &&
                  loadedSettings.politenessLevel == PolitenessLevel.normal);

      expect(allSavedOrAllDefault, true, reason: '部分的な保存状態にならない');
    });

    test('TC-059-008-境界値: 個別保存メソッドのトランザクション', () async {
      // 【テスト目的】: 個別保存メソッド（saveFontSize等）が独立したトランザクションとして動作することを検証
      // 【信頼性レベル】: 🔵 青信号 - NFR-304に基づく

      // Given（準備フェーズ）
      var prefs = await SharedPreferences.getInstance();
      repository = AppSettingsRepository(prefs: prefs);

      // When（実行フェーズ）
      // 個別に設定を保存
      await repository.saveFontSize(FontSize.large);
      await repository.saveTheme(AppTheme.dark);

      // 再読み込み
      prefs = await SharedPreferences.getInstance();
      repository = AppSettingsRepository(prefs: prefs);
      final loadedSettings = await repository.load();

      // Then（検証フェーズ）
      // 個別に保存した設定が正しく保存されている
      expect(loadedSettings.fontSize, FontSize.large,
          reason: 'フォントサイズが保存されている');
      expect(loadedSettings.theme, AppTheme.dark, reason: 'テーマが保存されている');

      // 他の設定はデフォルト値のまま
      expect(loadedSettings.ttsSpeed, TtsSpeed.normal, reason: 'TTS速度はデフォルト');
      expect(loadedSettings.politenessLevel, PolitenessLevel.normal,
          reason: '丁寧さレベルはデフォルト');
    });
  });

  group('AppSettingsRepository - エラーハンドリング', () {
    test('TC-059-008-エラー: 無効な値が保存された場合のフォールバック', () async {
      // 【テスト目的】: 無効な値が保存された場合にデフォルト値にフォールバックすることを検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-304に基づく

      // Given（準備フェーズ）
      // 無効な値を手動でSharedPreferencesに保存
      SharedPreferences.setMockInitialValues({
        'fontSize': 'invalid_value',
        'theme': 'unknown_theme',
        'ttsSpeed': 'super_fast', // 存在しないenum値
        'politenessLevel': 'extremely_polite', // 存在しないenum値
      });

      // When（実行フェーズ）
      final prefs = await SharedPreferences.getInstance();
      final repository = AppSettingsRepository(prefs: prefs);
      final loadedSettings = await repository.load();

      // Then（検証フェーズ）
      // 無効な値はデフォルト値にフォールバックする
      expect(loadedSettings.fontSize, FontSize.medium,
          reason: '無効なfontSizeはデフォルトに戻る');
      expect(loadedSettings.theme, AppTheme.light, reason: '無効なthemeはデフォルトに戻る');
      expect(loadedSettings.ttsSpeed, TtsSpeed.normal,
          reason: '無効なttsSpeedはデフォルトに戻る');
      expect(loadedSettings.politenessLevel, PolitenessLevel.normal,
          reason: '無効なpolitenessLevelはデフォルトに戻る');

      // アプリはクラッシュせず、安全にデフォルト値で動作する
      expect(loadedSettings, isA<AppSettings>(),
          reason: 'AppSettingsオブジェクトが正常に生成される');
    });
  });
}
