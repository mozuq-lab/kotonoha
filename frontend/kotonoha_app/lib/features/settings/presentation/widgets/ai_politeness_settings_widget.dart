/// AI丁寧さレベル設定ウィジェット
///
/// TASK-0071: 設定画面UI実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: REQ-903
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_conversion/domain/models/politeness_level.dart';
import '../../providers/settings_provider.dart';

/// AI丁寧さレベル設定ウィジェット
///
/// AI変換の丁寧さレベルを3段階（カジュアル/普通/丁寧）から選択するUI。
///
/// REQ-903: 丁寧さレベルを3段階から選択可能
class AIPolitenessSettingsWidget extends ConsumerWidget {
  /// コンストラクタ
  const AIPolitenessSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
      data: (settings) {
        final currentLevel = settings.aiPoliteness;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('丁寧さレベル'),
            const SizedBox(height: 8),
            SegmentedButton<PolitenessLevel>(
              // 【AA対応】: デフォルト高さ約40pxを44px以上に拡張（タップターゲット要件）。
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              segments: PolitenessLevel.values.map((level) {
                return ButtonSegment<PolitenessLevel>(
                  value: level,
                  label: Text(level.displayName),
                );
              }).toList(),
              selected: {currentLevel},
              onSelectionChanged: (Set<PolitenessLevel> newSelection) {
                if (newSelection.isNotEmpty) {
                  ref.read(settingsNotifierProvider.notifier).setAIPoliteness(
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
