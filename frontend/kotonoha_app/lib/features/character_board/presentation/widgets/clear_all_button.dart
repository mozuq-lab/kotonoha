/// ClearAllButton ウィジェット
///
/// TASK-0039: 削除ボタン・全消去ボタン実装
///
/// 入力バッファのすべての文字を削除するためのボタン。
/// タップ時に確認ダイアログを表示し、誤操作を防止する。
/// アクセシビリティ要件（REQ-5001: 44px以上、NFR-202: 60px推奨）に準拠。
///
/// 関連要件:
/// - REQ-004: 全消去ボタンで入力欄のすべての文字を削除する機能を提供
/// - REQ-2001: 全消去ボタンタップ時に確認ダイアログを表示
/// - REQ-5002: 重要な操作（全消去）に誤操作防止の仕組みを設ける
/// - REQ-5001: タップターゲットのサイズは44px x 44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_confirmation_dialog.dart';

/// 全消去ボタンのアクセシブルラベル。
///
/// 定数にしている理由: 破壊的操作の全消去ボタンと、同じ画面に常時並ぶ
/// 緊急ボタンは、どちらも赤系の塗りボタンになる。両者を輝度比で十分に離すことは
/// WCAG AA の要件と数学的に両立しないため（test/accessibility/
/// theme_error_color_contrast_test.dart の考察を参照）、実際の識別は
/// 色ではなくラベル・形状が担う。ラベルが識別手段であることを明示し、
/// テストから参照できるようにするために定数化している。
const String clearAllButtonSemanticsLabel = '全消去';

/// 全消去ボタンウィジェット
///
/// 入力バッファのすべての文字を削除するためのボタン。
/// タップ時に確認ダイアログを表示し、誤操作を防止する。
/// アクセシビリティ要件（REQ-5001: 44px以上、NFR-202: 60px推奨）に準拠。
class ClearAllButton extends StatelessWidget {
  /// 確認後のコールバック
  final VoidCallback? onConfirmed;

  /// ボタンの有効/無効状態
  final bool enabled;

  /// ClearAllButtonを作成する
  const ClearAllButton({
    super.key,
    this.onConfirmed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: clearAllButtonSemanticsLabel,
      button: true,
      enabled: enabled,
      child: ElevatedButton(
        onPressed: enabled ? () => _showConfirmationDialog(context) : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.recommendedTapTarget,
            AppSizes.recommendedTapTarget,
          ),
          // 警告色（赤系）で表示（AC-010）
          backgroundColor: WidgetStateColor.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.disabledColor.withValues(alpha: 0.12);
              }
              return theme.colorScheme.error;
            },
          ),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.disabledColor.withValues(alpha: 0.38);
              }
              return theme.colorScheme.onError;
            },
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
