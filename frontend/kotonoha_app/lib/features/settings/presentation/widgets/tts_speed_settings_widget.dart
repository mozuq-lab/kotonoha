/// TTS速度設定ウィジェット
/// 読み上げ速度を4段階から選択できるUIウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tts/domain/models/tts_speed.dart';
import '../../providers/settings_provider.dart';
import 'settings_choice_group.dart';

/// TTS速度設定ウィジェット
/// 読み上げ速度を「とても遅い」「遅い」「普通」「速い」の4段階から選択できる。
/// 選択するとSettingsNotifier経由で保存され、読み上げにも即座に反映される。
class TTSSpeedSettingsWidget extends ConsumerWidget {
  /// TTS速度設定ウィジェットを作成する。
  const TTSSpeedSettingsWidget({super.key});

  /// 選択肢の表示名。ヘルプ画面の説明もこれから作る（段階を増やしてもずれない）。
  static String label(TTSSpeed speed) => switch (speed) {
        TTSSpeed.verySlow => 'とても遅い',
        TTSSpeed.slow => '遅い',
        TTSSpeed.normal => '普通',
        TTSSpeed.fast => '速い',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsyncValue = ref.watch(settingsNotifierProvider);

    return settingsAsyncValue.when(
      data: (settings) => SettingsChoiceGroup<TTSSpeed>(
        title: '読み上げ速度',
        values: TTSSpeed.values,
        labelOf: label,
        selected: settings.ttsSpeed,
        // SettingsNotifier内でTTSNotifierのsetSpeedも呼び出される
        onSelected: ref.read(settingsNotifierProvider.notifier).setTTSSpeed,
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('設定の読み込みに失敗しました: $error'),
      ),
    );
  }
}
