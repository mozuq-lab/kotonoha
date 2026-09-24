/// 読み上げに失敗したことを告げる帯
///
/// 読み上げの失敗（エンジンが応答しない・エラーを返した）は、以前は状態に
/// 持つだけで画面に出なかった。利用者は読み上げたつもりで、相手に伝わって
/// いないことに気づけない（守る約束 ④）。`AppShell` に置き、どの画面でも出す。
/// 次に読み上げが始まれば、状態がエラーでなくなるので消える。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';

/// 読み上げに失敗したときだけ出る帯
class TtsFailureBanner extends ConsumerWidget {
  /// 帯を作る
  const TtsFailureBanner({super.key});

  /// 帯の文言
  static const message = '読み上げできませんでした。もう一度押すか、端末の読み上げの設定を確かめてください';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed =
        ref.watch(ttsProvider.select((s) => s.state)) == TTSState.error;
    if (!failed) return const SizedBox.shrink();

    // 配色は保存の一部失敗の帯と同じ（コントラスト比は検証済み）
    final colors = recoverableBannerColors();
    // liveRegion: 出た時点で支援技術に読み上げさせる。
    // Material で包む理由は OfflineBanner と同じ（Scaffold の外に置くため）。
    return Semantics(
      label: message,
      liveRegion: true,
      container: true,
      excludeSemantics: true,
      child: Material(
        color: colors.background,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volume_off, size: 18, color: colors.foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.foreground, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
