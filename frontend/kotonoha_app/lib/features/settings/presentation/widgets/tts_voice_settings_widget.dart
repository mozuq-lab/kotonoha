/// 読み上げの声の設定ウィジェット
/// 端末に入っている日本語の声から選ぶ。選ぶとその声で試しに読み上げる。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tts/domain/models/tts_voice.dart';
import '../../../tts/providers/tts_provider.dart';
import '../../providers/settings_provider.dart';
import 'settings_choice_group.dart';

/// 読み上げの声の設定ウィジェット
/// 「標準」（日本語の標準の声）と、端末の声を品質の高い順に並べる。
/// Web は声を選ばせない（[TTSVoice] の説明を参照）ので何も出さない。
class TTSVoiceSettingsWidget extends ConsumerStatefulWidget {
  /// 読み上げの声の設定ウィジェットを作成する。
  const TTSVoiceSettingsWidget({super.key});

  /// 声を選んだときに試しに読み上げる文
  static const sampleText = 'こんにちは。この声で読み上げます。';

  @override
  ConsumerState<TTSVoiceSettingsWidget> createState() =>
      _TTSVoiceSettingsWidgetState();
}

class _TTSVoiceSettingsWidgetState
    extends ConsumerState<TTSVoiceSettingsWidget> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 端末の設定で声を足して戻ってきたら、一覧を聞き直す
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(ttsVoicesProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _select(String? voiceId) async {
    await ref.read(settingsNotifierProvider.notifier).setTTSVoice(voiceId);
    if (!mounted) return;
    await ref
        .read(ttsProvider.notifier)
        .speak(TTSVoiceSettingsWidget.sampleText);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final settings = ref.watch(settingsNotifierProvider).asData?.value;
    if (settings == null) return const SizedBox.shrink();
    final voices = ref.watch(ttsVoicesProvider).asData?.value ?? const [];

    final byId = {for (final voice in voices) voice.id: voice};
    final unnamed = voices.where((v) => !v.hasReadableName).toList();
    String label(String? id) {
      final voice = byId[id];
      if (voice == null) return '標準';
      final base = voice.hasReadableName
          ? voice.name
          : '声 ${unnamed.indexOf(voice) + 1}';
      final notes = [
        if (voice.gender == 'female') '女性',
        if (voice.gender == 'male') '男性',
        if (voice.quality == TTSVoiceQuality.premium) 'プレミアム',
        if (voice.quality == TTSVoiceQuality.enhanced) '拡張',
      ];
      return notes.isEmpty ? base : '$base（${notes.join('・')}）';
    }

    final howToAdd = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ほかの声は、端末の「設定」→「アクセシビリティ」→「読み上げコンテンツ」'
            '→「声」→「日本語」から追加できます。「拡張」「プレミアム」の声は、'
            'より自然に聞こえます。'
        : 'ほかの声は、端末の「設定」の「テキスト読み上げ」から追加できます'
            '（機種によって場所が違います）。';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsChoiceGroup<String?>(
          title: '読み上げの声',
          values: [null, ...voices.map((v) => v.id)],
          labelOf: label,
          // 保存した声が端末から消えていたら、実際に読む「標準」を選んだ状態で見せる
          selected: byId.containsKey(settings.ttsVoiceId)
              ? settings.ttsVoiceId
              : null,
          onSelected: _select,
        ),
        const SizedBox(height: 8),
        Text(
          '選ぶと、その声で試しに読み上げます。$howToAdd',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
