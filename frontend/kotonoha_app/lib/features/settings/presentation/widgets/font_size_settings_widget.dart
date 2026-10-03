/// フォントサイズ設定ウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/font_size.dart';
import '../../providers/settings_provider.dart';
import 'settings_choice_group.dart';

/// フォントサイズ設定ウィジェット
/// フォントサイズを3段階（小/中/大）から選択するUI。
/// フォントサイズを3段階から選択可能
/// 設定変更時に即座に反映
class FontSizeSettingsWidget extends ConsumerWidget {
  /// コンストラクタ
  const FontSizeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
      data: (settings) {
        final currentFontSize = settings.fontSize;

        return SettingsChoiceGroup<FontSize>(
          title: 'フォントサイズ',
          values: FontSize.values,
          labelOf: (size) => size.displayName,
          selected: currentFontSize,
          onSelected: ref.read(settingsNotifierProvider.notifier).setFontSize,
        );
      },
    );
  }
}
