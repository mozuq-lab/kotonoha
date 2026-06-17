/// テーマ設定ウィジェット
///
/// TASK-0071: 設定画面UI実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-803, REQ-2008
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_theme.dart';
import '../../providers/settings_provider.dart';

/// テーマ設定ウィジェット
///
/// テーマを3種類（ライト/ダーク/高コントラスト）から選択するUI。
///
/// REQ-803: 3つのテーマを提供
/// REQ-2008: テーマ変更時に即座に反映
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('テーマ'),
            const SizedBox(height: 8),
            SegmentedButton<AppTheme>(
              // 【AA対応】: デフォルト高さ約40pxを44px以上に拡張（タップターゲット要件）。
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              segments: AppTheme.values.map((theme) {
                return ButtonSegment<AppTheme>(
                  value: theme,
                  label: Text(_getShortDisplayName(theme)),
                );
              }).toList(),
              selected: {currentTheme},
              onSelectionChanged: (Set<AppTheme> newSelection) {
                if (newSelection.isNotEmpty) {
                  ref.read(settingsNotifierProvider.notifier).setTheme(
                        newSelection.first,
                      );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
