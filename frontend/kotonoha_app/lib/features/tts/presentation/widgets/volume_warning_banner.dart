/// 音量 0 のまま読み上げたことを告げる帯（EDGE-202）
///
/// 以前はホームの本文にだけ置いていたので、履歴・お気に入り・定型文の画面から
/// 読み上げても出なかった（隠れたホームが状態だけを立て、戻ったときに出た）。
/// 読み上げ失敗の帯と同じく `AppShell` に置き、どの画面でも出す。
///
/// 出す: どの画面からでも、読み上げが始まったとき（speaking に変わったとき）に
/// 音量を確かめ、0 なら出す。
/// 消す: 閉じるボタン、または音量が 0 でない状態で次に読み上げが始まったとき。
/// 画面を移っただけでは消さない（音量は端末全体のもので、0 のままかもしれない）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';

/// 音量 0 の警告の帯。警告が要らないときは高さ 0
///
/// ほかの帯と同じく `AppShell` の帯の列に置く。ステータスバーの分の余白は
/// シェル（`_StatusBarArea`）が引き受けるので、この帯では持たない。
class VolumeWarningBanner extends ConsumerWidget {
  /// 帯を作る
  const VolumeWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // どのボタン・どの画面から読み上げが始まっても確かめるため、
    // 全画面共通のここで読み上げの状態遷移（非 speaking → speaking）を見張る。
    ref.listen<TTSServiceState>(ttsProvider, (previous, next) {
      final wasSpeaking = previous?.state == TTSState.speaking;
      final isSpeaking = next.state == TTSState.speaking;
      if (!wasSpeaking && isSpeaking) {
        ref.read(volumeWarningProvider.notifier).checkVolumeBeforeSpeak();
      }
    });
    final showWarning = ref.watch(volumeWarningProvider).showWarning;
    if (!showWarning) return const SizedBox.shrink();

    // Material で包む理由は OfflineBanner と同じ（各画面の Scaffold より外に
    // 置くので、無いと Text が既定の下線付きの書式になり、InkWell も描けない）。
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        child: VolumeWarningWidget(
          isVisible: true,
          onDismiss: () =>
              ref.read(volumeWarningProvider.notifier).dismissWarning(),
        ),
      ),
    );
  }
}
