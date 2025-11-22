/// DeleteButton ウィジェット
///
/// TASK-0039: 削除ボタン・全消去ボタン実装
///
/// 入力バッファの最後の1文字を削除するためのボタン。
/// アクセシビリティ要件（REQ-5001: 44px以上、NFR-202: 60px推奨）に準拠。
///
/// 関連要件:
/// - REQ-003: 削除ボタンで最後の1文字を削除する機能を提供
/// - REQ-5001: タップターゲットのサイズは44px x 44px以上
/// - NFR-202: タップ領域は60px x 60px以上推奨
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 削除ボタンウィジェット
///
/// 入力バッファの最後の1文字を削除するためのボタン。
/// アクセシビリティ要件（REQ-5001: 44px以上、NFR-202: 60px推奨）に準拠。
class DeleteButton extends StatelessWidget {
  /// ボタンタップ時のコールバック
  final VoidCallback? onPressed;

  /// ボタンの有効/無効状態
  final bool enabled;

  /// DeleteButtonを作成する
  const DeleteButton({
    super.key,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '削除',
      button: true,
      enabled: enabled,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.recommendedTapTarget,
            AppSizes.recommendedTapTarget,
          ),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          disabledBackgroundColor: theme.disabledColor.withValues(alpha: 0.12),
          disabledForegroundColor: theme.disabledColor.withValues(alpha: 0.38),
        ),
        child: const Icon(
          Icons.backspace_outlined,
          size: AppSizes.iconSizeMedium,
        ),
      ),
    );
  }
}
