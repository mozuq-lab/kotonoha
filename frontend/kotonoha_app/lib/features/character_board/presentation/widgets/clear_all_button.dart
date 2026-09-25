/// ClearAllButton ウィジェット
/// 入力バッファのすべての文字を削除するためのボタン。
/// タップ時に確認ダイアログを表示し、誤操作を防止する。
/// 正方形のタップ領域（既定60px、44px以上）を確保する。
/// 全消去ボタンで入力欄のすべての文字を削除する機能を提供
/// 全消去ボタンタップ時に確認ダイアログを表示
/// 重要な操作（全消去）に誤操作防止の仕組みを設ける
/// タップターゲットのサイズは44px x 44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_confirmation_dialog.dart';

/// 全消去ボタンのアクセシブルラベル。
/// 定数にしている理由: 破壊的操作の全消去ボタンと、同じ画面に常時並ぶ
/// 緊急ボタンも赤系なので、識別は色だけに頼らずラベル・形状でも行う。
/// ラベルが識別手段であることを明示し
/// テストから参照できるようにするために定数化している。
const String clearAllButtonSemanticsLabel = '全消去';

/// 全消去ボタンウィジェット
/// 入力バッファのすべての文字を削除するためのボタン。
/// タップ時に確認ダイアログを表示し、誤操作を防止する。
/// 正方形のタップ領域（既定60px、44px以上）を確保する。
class ClearAllButton extends StatelessWidget {
  /// 確認後のコールバック
  final VoidCallback? onConfirmed;

  /// ボタンの有効/無効状態
  final bool enabled;

  /// ボタンの一辺の長さ（正方形。[AppSizes.minTapTarget] 未満にはしない）
  final double size;

  /// ClearAllButtonを作成する
  const ClearAllButton({
    super.key,
    this.onConfirmed,
    this.enabled = true,
    this.size = AppSizes.recommendedTapTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side = size < AppSizes.minTapTarget ? AppSizes.minTapTarget : size;

    return Semantics(
      label: clearAllButtonSemanticsLabel,
      button: true,
      enabled: enabled,
      child: ElevatedButton(
        onPressed: enabled ? () => _showConfirmationDialog(context) : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size.square(side),
          fixedSize: Size.square(side),
          padding: EdgeInsets.zero,
          // 淡い警告色にし、緊急ボタンの強い赤を際立たせる。
          backgroundColor: WidgetStateColor.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.disabledColor.withValues(alpha: 0.12);
              }
              return Color.lerp(
                theme.colorScheme.surface,
                theme.colorScheme.error,
                0.14,
              )!;
            },
          ),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.disabledColor.withValues(alpha: 0.38);
              }
              return theme.colorScheme.onSurface;
            },
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
        ),
        child: const Icon(
          Icons.delete_outline,
          size: AppSizes.iconSizeMedium,
        ),
      ),
    );
  }

  /// 確認ダイアログを表示
  void _showConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ClearConfirmationDialog(
        onConfirmed: () {
          Navigator.of(dialogContext).pop();
          onConfirmed?.call();
        },
        onCancelled: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}
