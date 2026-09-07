/// SettingsNotifier 永続化マイグレーションテスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';

void main() {
  group('SettingsNotifier - 永続化フォーマットのマイグレーション', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    group('FontSize: 旧形式（int index）→ 新形式（String name）', () {
      for (final fontSize in FontSize.values) {
        test(
          '旧形式 fontSize=${fontSize.index}（${fontSize.name}）が正しく復元され、'
          'String形式で再保存される',
          () async {
            // Given: 旧形式（enum index int）で保存された状態を再現
            SharedPreferences.setMockInitialValues({
              'fontSize': fontSize.index,
            });

            // When: SettingsNotifier.buildで復元（アプリ起動を模擬）
            container = ProviderContainer();
            final settings =
                await container.read(settingsNotifierProvider.future);

            // Then: 旧int値から対応するenumへ正しく読み替えられている
            expect(settings.fontSize, fontSize,
                reason: '旧形式のindex値(${fontSize.index})が'
                    '${fontSize.name}として正しく復元される');

            // Then: 次回以降String形式で読み込めるよう、SharedPreferencesへ
            // マイグレーション（再保存）されている
            final prefs = await SharedPreferences.getInstance();
            expect(prefs.getString('fontSize'), fontSize.name,
                reason: '旧形式から読み込んだ値がString name形式へ再保存されている');
          },
        );
      }
    });

    group('AppTheme: 旧形式（int index）→ 新形式（String name）', () {
      for (final theme in AppTheme.values) {
        test(
          '旧形式 theme=${theme.index}（${theme.name}）が正しく復元され、'
          'String形式で再保存される',
          () async {
            // Given: 旧形式（enum index int）で保存された状態を再現
            SharedPreferences.setMockInitialValues({
              'theme': theme.index,
            });

            // When: SettingsNotifier.buildで復元（アプリ起動を模擬）
            container = ProviderContainer();
            final settings =
                await container.read(settingsNotifierProvider.future);

            // Then: 旧int値から対応するenumへ正しく読み替えられている
            expect(settings.theme, theme,
                reason: '旧形式のindex値(${theme.index})が${theme.name}として正しく復元される');

            // Then: 次回以降String形式で読み込めるよう再保存されている
            final prefs = await SharedPreferences.getInstance();
            expect(prefs.getString('theme'), theme.name,
                reason: '旧形式から読み込んだ値がString name形式へ再保存されている');
          },
        );
      }
    });

    group('新形式（String name）が既に保存されている場合', () {
      test('fontSize: String形式のままマイグレーションを起こさず正しく復元される', () async {
        // Given: 新形式（String name）で保存された状態
        SharedPreferences.setMockInitialValues({
          'fontSize': FontSize.large.name,
        });

        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        expect(settings.fontSize, FontSize.large);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.large.name);
      });

      test('theme: String形式のままマイグレーションを起こさず正しく復元される', () async {
        // Given: 新形式（String name）で保存された状態
        SharedPreferences.setMockInitialValues({
          'theme': AppTheme.highContrast.name,
        });

        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        expect(settings.theme, AppTheme.highContrast);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme'), AppTheme.highContrast.name);
      });
    });

    group('異常系・境界値', () {
      test('fontSize: 範囲外の旧形式int値はデフォルト値（medium）にフォールバックする', () async {
        SharedPreferences.setMockInitialValues({
          'fontSize': 999, // FontSize.values の範囲外
        });

        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        expect(settings.fontSize, FontSize.medium);
      });

      test('theme: 範囲外の旧形式int値はデフォルト値（light）にフォールバックする', () async {
        SharedPreferences.setMockInitialValues({
          'theme': -1, // 範囲外（負数）
        });

        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        expect(settings.theme, AppTheme.light);
      });

      test('fontSize: 不正なString値はデフォルト値（medium）にフォールバックする', () async {
        SharedPreferences.setMockInitialValues({
          'fontSize': 'not_a_valid_font_size',
        });

        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        expect(settings.fontSize, FontSize.medium);
      });

      test('未保存（null）の場合はデフォルト値（fontSize=medium, theme=light）を使用する', () async {
        SharedPreferences.setMockInitialValues({});

        container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        expect(settings.fontSize, FontSize.medium);
        expect(settings.theme, AppTheme.light);
      });
    });
  });
}
