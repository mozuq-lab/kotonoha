/// 読み上げに失敗したことを告げる帯
///
/// 読み上げの失敗（エンジンが応答しない・エラーを返した）は、以前は状態に
/// 持つだけで画面に出なかった。利用者は読み上げたつもりで、相手に伝わって
/// いないことに気づけない（守る約束 ③）。`AppShell` に置き、どの画面でも出す。
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

  /// 帯の文言（押して読み上げられなかったとき）
  static const message = '読み上げできませんでした。もう一度押すか、端末の読み上げの設定を確かめてください';

  /// 帯の文言（起動時に読み上げを準備できなかったとき。まだ押していない）
  /// 続きの案内は `docs/user-guide/troubleshooting.md` の「TTS（音声合成）が
  /// 正しく設定されていない」に合わせる。押せば準備をやり直すので、押す案内は書かない。
  static const startupMessage =
      '読み上げを準備できませんでした。端末の読み上げの設定で、日本語の声が使えるか確かめてください';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (failed, atStartup) = ref.watch(ttsProvider
        .select((s) => (s.state == TTSState.error, s.failedAtStartup)));
    if (!failed) return const SizedBox.shrink();
    final text = atStartup ? startupMessage : message;

    // 配色は保存の一部失敗の帯と同じ（コントラスト比は検証済み）
    final colors = recoverableBannerColors();
    // liveRegion: 出た時点で支援技術に読み上げさせる。
    // Material で包む理由は OfflineBanner と同じ（Scaffold の外に置くため）。
    return Semantics(
      label: text,
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
                  text,
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
