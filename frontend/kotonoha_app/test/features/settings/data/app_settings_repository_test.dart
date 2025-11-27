import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/shared/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/data/app_settings_repository.dart';

void main() {
  late SharedPreferences prefs;
  late AppSettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = AppSettingsRepository(prefs: prefs);
  });

  group('AppSettingsRepository', () {
    group('正常系テスト', () {
      test('TC-056-001: フォントサイズを保存できる', () async {
        // Arrange & Act
        await repository.saveFontSize(FontSize.large);
        final settings = await repository.load();

        // Assert
        expect(settings.fontSize, FontSize.large);
      });

      test('TC-056-002: テーマを保存できる', () async {
        // Arrange & Act
        await repository.saveTheme(AppTheme.dark);
        final settings = await repository.load();

        // Assert
        expect(settings.theme, AppTheme.dark);
      });

      test('TC-056-003: TTS速度を保存できる', () async {
        // Arrange & Act
        await repository.saveTtsSpeed(TtsSpeed.slow);
        final settings = await repository.load();

        // Assert
        expect(settings.ttsSpeed, TtsSpeed.slow);
      });

      test('TC-056-004: AI丁寧さレベルを保存できる', () async {
        // Arrange & Act
        await repository.savePolitenessLevel(PolitenessLevel.polite);
        final settings = await repository.load();

        // Assert
        expect(settings.politenessLevel, PolitenessLevel.polite);
      });

      test('TC-056-005: 全設定を一括保存できる', () async {
        // Arrange
        const settings = AppSettings(
          fontSize: FontSize.large,
          theme: AppTheme.highContrast,
          ttsSpeed: TtsSpeed.fast,
          politenessLevel: PolitenessLevel.casual,
        );

        // Act
        await repository.saveAll(settings);
        final loaded = await repository.load();

        // Assert
        expect(loaded.fontSize, FontSize.large);
        expect(loaded.theme, AppTheme.highContrast);
        expect(loaded.ttsSpeed, TtsSpeed.fast);
        expect(loaded.politenessLevel, PolitenessLevel.casual);
      });

      test('TC-056-006: アプリ再起動後も設定が保持される（永続化テスト）', () async {
        // Arrange - 設定を保存
        await repository.saveFontSize(FontSize.large);
        await repository.saveTheme(AppTheme.dark);
        await repository.saveTtsSpeed(TtsSpeed.slow);
        await repository.savePolitenessLevel(PolitenessLevel.polite);

        // Act - 新しいRepositoryインスタンスで読み込み（アプリ再起動をシミュレート）
        final newPrefs = await SharedPreferences.getInstance();
        final newRepository = AppSettingsRepository(prefs: newPrefs);
        final settings = await newRepository.load();

        // Assert
        expect(settings.fontSize, FontSize.large);
        expect(settings.theme, AppTheme.dark);
        expect(settings.ttsSpeed, TtsSpeed.slow);
        expect(settings.politenessLevel, PolitenessLevel.polite);
      });
    });

    group('デフォルト値テスト', () {
      test('TC-056-007: 初回起動時はデフォルト値が返される', () async {
        // Arrange - 空のSharedPreferences（setUpで設定済み）

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.fontSize, FontSize.medium);
        expect(settings.theme, AppTheme.light);
        expect(settings.ttsSpeed, TtsSpeed.normal);
        expect(settings.politenessLevel, PolitenessLevel.normal);
      });

      test('TC-056-008: フォントサイズのデフォルト値はmedium', () async {
        // Arrange - fontSizeキーが存在しない状態

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.fontSize, FontSize.medium);
      });

      test('TC-056-009: テーマのデフォルト値はlight', () async {
        // Arrange - themeキーが存在しない状態

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.theme, AppTheme.light);
      });
    });

    group('境界値テスト', () {
      test('TC-056-010: FontSizeの全値を保存・読み込みできる', () async {
        for (final size in FontSize.values) {
          // Act
          await repository.saveFontSize(size);
          final settings = await repository.load();

          // Assert
          expect(settings.fontSize, size);
        }
      });

      test('TC-056-011: AppThemeの全値を保存・読み込みできる', () async {
        for (final theme in AppTheme.values) {
          // Act
          await repository.saveTheme(theme);
          final settings = await repository.load();

          // Assert
          expect(settings.theme, theme);
        }
      });

      test('TC-056-012: TtsSpeedの全値を保存・読み込みできる', () async {
        for (final speed in TtsSpeed.values) {
          // Act
          await repository.saveTtsSpeed(speed);
          final settings = await repository.load();

          // Assert
          expect(settings.ttsSpeed, speed);
        }
      });

      test('TC-056-013: PolitenessLevelの全値を保存・読み込みできる', () async {
        for (final level in PolitenessLevel.values) {
          // Act
          await repository.savePolitenessLevel(level);
          final settings = await repository.load();

          // Assert
          expect(settings.politenessLevel, level);
        }
      });
    });

    group('異常系テスト', () {
      test('TC-056-014: 不正なフォントサイズ値が保存されていた場合デフォルト値を返す', () async {
        // Arrange - 不正な値を直接保存
        await prefs.setString('fontSize', 'invalid_size');

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.fontSize, FontSize.medium);
      });

      test('TC-056-015: 不正なテーマ値が保存されていた場合デフォルト値を返す', () async {
        // Arrange - 不正な値を直接保存
        await prefs.setString('theme', 'invalid_theme');

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.theme, AppTheme.light);
      });

      test('TC-056-016: 不正なTTS速度値が保存されていた場合デフォルト値を返す', () async {
        // Arrange - 不正な値を直接保存
        await prefs.setString('ttsSpeed', 'invalid_speed');

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.ttsSpeed, TtsSpeed.normal);
      });

      test('TC-056-017: 不正な丁寧さレベル値が保存されていた場合デフォルト値を返す', () async {
        // Arrange - 不正な値を直接保存
        await prefs.setString('politenessLevel', 'invalid_level');

        // Act
        final settings = await repository.load();

        // Assert
        expect(settings.politenessLevel, PolitenessLevel.normal);
      });
    });

    group('上書きテスト', () {
      test('TC-056-018: 設定を上書き保存できる', () async {
        // Arrange
        await repository.saveFontSize(FontSize.small);

        // Act - 上書き
        await repository.saveFontSize(FontSize.large);
        final settings = await repository.load();

        // Assert
        expect(settings.fontSize, FontSize.large);
      });

      test('TC-056-019: 個別設定の変更が他の設定に影響しない', () async {
        // Arrange - 全設定を非デフォルト値で保存
        await repository.saveFontSize(FontSize.large);
        await repository.saveTheme(AppTheme.dark);
        await repository.saveTtsSpeed(TtsSpeed.fast);
        await repository.savePolitenessLevel(PolitenessLevel.polite);

        // Act - fontSizeのみ変更
        await repository.saveFontSize(FontSize.small);
        final settings = await repository.load();

        // Assert
        expect(settings.fontSize, FontSize.small); // 変更された
        expect(settings.theme, AppTheme.dark); // 元のまま
        expect(settings.ttsSpeed, TtsSpeed.fast); // 元のまま
        expect(settings.politenessLevel, PolitenessLevel.polite); // 元のまま
      });
    });
  });
}
