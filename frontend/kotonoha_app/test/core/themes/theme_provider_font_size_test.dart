/// フォントサイズ設定がテーマの textTheme に反映される（REQ-802・REQ-2007、台帳 L-74）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

/// 設定を固定して返す Notifier（SharedPreferences を読まない）
class _FixedSettings extends SettingsNotifier {
  _FixedSettings(this._settings);
  final AppSettings _settings;

  @override
  Future<AppSettings> build() async => _settings;
}

void main() {
  Future<double> bodyLargeSizeFor(FontSize size) async {
    final container = ProviderContainer(
      overrides: [
        settingsNotifierProvider.overrideWith(
          () => _FixedSettings(AppSettings(fontSize: size)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsNotifierProvider.future);
    return container.read(currentThemeProvider).textTheme.bodyLarge!.fontSize!;
  }

  final base = lightTheme.textTheme.bodyLarge!.fontSize!;

  test('中（既定）ではテーマの文字サイズは変わらない', () async {
    expect(await bodyLargeSizeFor(FontSize.medium), closeTo(base, 0.01));
  });

  test('大では 1.2 倍になる（AppSizes.fontSizeLarge / fontSizeMedium）', () async {
    expect(await bodyLargeSizeFor(FontSize.large), closeTo(base * 1.2, 0.01));
  });

  test('小では 0.8 倍になる', () async {
    expect(await bodyLargeSizeFor(FontSize.small), closeTo(base * 0.8, 0.01));
  });
}
