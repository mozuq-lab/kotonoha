/// DeleteButton ウィジェット
/// 入力バッファの最後の1文字を削除するためのボタン。
/// 正方形のタップ領域（既定60px、44px以上）を確保する。
/// 削除ボタンで最後の1文字を削除する機能を提供
/// タップターゲットのサイズは44px x 44px以上
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 削除ボタンウィジェット
/// 入力バッファの最後の1文字を削除するためのボタン。
/// 正方形のタップ領域（既定60px、44px以上）を確保する。
class DeleteButton extends StatelessWidget {
  /// ボタンタップ時のコールバック
  final VoidCallback? onPressed;

  /// ボタンの有効/無効状態
  final bool enabled;

  /// ボタンの一辺の長さ（正方形。[AppSizes.minTapTarget] 未満にはしない）
  final double size;
  final bool showLabel;

  /// DeleteButtonを作成する
  const DeleteButton({
    super.key,
    this.onPressed,
    this.enabled = true,
    this.size = AppSizes.recommendedTapTarget,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side = size < AppSizes.minTapTarget ? AppSizes.minTapTarget : size;

    return Semantics(
      label: '削除',
      button: true,
      enabled: enabled,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size.square(side),
          fixedSize: showLabel ? Size.fromHeight(side) : Size.square(side),
          padding: showLabel
              ? const EdgeInsets.symmetric(horizontal: 4)
              : EdgeInsets.zero,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
          disabledBackgroundColor: theme.disabledColor.withValues(alpha: 0.12),
          disabledForegroundColor: theme.disabledColor.withValues(alpha: 0.38),
        ),
        child: showLabel
            ? const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.delete_left, size: AppSizes.iconSizeMedium),
                SizedBox(width: 6),
                Flexible(child: Text('削除', maxLines: 2)),
              ])
            : const Icon(CupertinoIcons.delete_left,
                size: AppSizes.iconSizeMedium),
      ),
    );
  }
}
