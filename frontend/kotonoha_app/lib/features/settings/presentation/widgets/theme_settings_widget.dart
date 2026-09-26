/// テーマ設定ウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_theme.dart';
import '../../providers/settings_provider.dart';

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
        final currentTheme = settings.theme;
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('テーマ'),
            const SizedBox(height: 8),
            // SegmentedButton は幅を等分するので、電話の幅では「高コントラスト」が
            // 語の途中で折り返す。チップは名前の幅で並び、収まらなければ次の行へ送る。
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.values.map((theme) {
                final selected = theme == currentTheme;
                // 上の「フォントサイズ」（SegmentedButton）と同じ配色にする。
                // アプリのチップのテーマは枠も選択色も無く、選択中が ✓ だけになるため
                return ChoiceChip(
                  label: Text(_getShortDisplayName(theme)),
                  selected: selected,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: scheme.outline),
                  backgroundColor: scheme.surface,
                  selectedColor: scheme.secondaryContainer,
                  checkmarkColor: scheme.onSecondaryContainer,
                  labelStyle: TextStyle(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                  ),
                  // タップ領域は 48px 四方（padded）。見た目の高さより広く取る
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) {
                    ref.read(settingsNotifierProvider.notifier).setTheme(theme);
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
