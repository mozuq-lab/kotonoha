/// DeleteButton ウィジェット
/// 入力バッファの最後の1文字を削除するためのボタン。
/// アクセシビリティ要件（: 44px以上、: 60px推奨）に準拠。
/// 削除ボタンで最後の1文字を削除する機能を提供
/// タップターゲットのサイズは44px x 44px以上
/// タップ領域は60px x 60px以上推奨
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 削除ボタンウィジェット
/// 入力バッファの最後の1文字を削除するためのボタン。
/// アクセシビリティ要件（: 44px以上、: 60px推奨）に準拠。
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
