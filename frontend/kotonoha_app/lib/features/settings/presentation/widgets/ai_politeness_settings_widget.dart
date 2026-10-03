/// AI丁寧さレベル設定ウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_conversion/domain/models/politeness_level.dart';
import '../../providers/settings_provider.dart';
import 'settings_choice_group.dart';

/// AI丁寧さレベル設定ウィジェット
/// AI変換の丁寧さレベルを3段階（カジュアル/普通/丁寧）から選択するUI。
/// 丁寧さレベルを3段階から選択可能
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

        return SettingsChoiceGroup<PolitenessLevel>(
          title: '丁寧さレベル',
          values: PolitenessLevel.values,
          labelOf: (level) => level.displayName,
          selected: currentLevel,
          onSelected:
              ref.read(settingsNotifierProvider.notifier).setAIPoliteness,
        );
      },
    );
  }
}
