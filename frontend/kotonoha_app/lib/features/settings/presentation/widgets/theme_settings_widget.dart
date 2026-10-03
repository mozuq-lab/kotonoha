/// テーマ設定ウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_theme.dart';
import '../../providers/settings_provider.dart';
import 'settings_choice_group.dart';

/// テーマ設定ウィジェット
/// テーマを3種類（ライト/ダーク/高コントラスト）から選択するUI。
/// 3つのテーマを提供
/// テーマ変更時に即座に反映
class ThemeSettingsWidget extends ConsumerWidget {
  /// コンストラクタ
  const ThemeSettingsWidget({super.key});

  /// テーマの短い表示名を取得
  String _getShortDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'ライト';
      case AppTheme.dark:
        return 'ダーク';
      case AppTheme.highContrast:
        return '高コントラスト';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
      data: (settings) {
        return SettingsChoiceGroup<AppTheme>(
          title: 'テーマ',
          values: AppTheme.values,
          labelOf: _getShortDisplayName,
          selected: settings.theme,
          onSelected: ref.read(settingsNotifierProvider.notifier).setTheme,
        );
      },
    );
  }
}
