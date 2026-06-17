/// フォントサイズ設定ウィジェット
///
/// TASK-0071: 設定画面UI実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-801, REQ-2007
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/font_size.dart';
import '../../providers/settings_provider.dart';

/// フォントサイズ設定ウィジェット
///
/// フォントサイズを3段階（小/中/大）から選択するUI。
///
/// REQ-801: フォントサイズを3段階から選択可能
/// REQ-2007: 設定変更時に即座に反映
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('フォントサイズ'),
            const SizedBox(height: 8),
            SegmentedButton<FontSize>(
              // 【AA対応】: デフォルト高さ約40pxを44px以上に拡張（タップターゲット要件）。
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              segments: FontSize.values.map((size) {
                return ButtonSegment<FontSize>(
                  value: size,
                  label: Text(size.displayName),
                );
              }).toList(),
              selected: {currentFontSize},
              onSelectionChanged: (Set<FontSize> newSelection) {
                if (newSelection.isNotEmpty) {
                  ref.read(settingsNotifierProvider.notifier).setFontSize(
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
