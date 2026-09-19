/// 入力欄が上限に達したことを伝える告知（EDGE-101、台帳 L-73）
///
/// 上限で超過分を黙って捨てるのではなく、達したことと、これ以上入力できないことを
/// 入力欄の直下に出す。上限を下回れば消える。読み上げは liveRegion で自動通知する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

/// 上限到達の告知
class InputLimitNotice extends ConsumerWidget {
  /// 告知を作る
  const InputLimitNotice({super.key});

  /// 告知文（数字は [InputBufferNotifier.maxLength] から取る）
  static const String message =
      '${InputBufferNotifier.maxLength} 文字に達しました。これ以上は入力できません';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reached = ref.watch(inputLimitReachedProvider);
    if (!reached) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.paddingXSmall),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
