/// EmergencyConfirmationDialog ウィジェット
///
/// TASK-0045: 緊急ボタンUI実装
/// TASK-0046: 緊急ボタン2段階確認実装（連続タップ防止機能追加）
/// 要件: REQ-2004（確認ダイアログ表示）、REQ-2005（確認後の動作）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 緊急呼び出し確認ダイアログ。
/// 緊急ボタンタップ後に表示され、2段階確認を実現する。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/constants/app_text_styles.dart';

/// 緊急呼び出し確認ダイアログ
///
/// 緊急ボタンタップ後に表示される確認ダイアログ。
/// REQ-302: 2段階確認（ボタンタップ→確認ダイアログ→確認タップ）を実現する。
///
/// デザイン仕様:
/// - タイトル: 「緊急呼び出し」
/// - メッセージ: 「緊急呼び出しを実行しますか?」
/// - 「はい」ボタン: 赤色背景、緊急処理実行
/// - 「いいえ」ボタン: グレー背景、キャンセル
/// - ダイアログ外タップでは閉じない（barrierDismissible: false）
/// - 連続タップ防止機能により、ボタンは1回のみ反応する
///
/// 使用例:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => EmergencyConfirmationDialog(
///     onConfirm: () {
///       Navigator.of(context).pop();
///       executeEmergency();
///     },
///     onCancel: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
class EmergencyConfirmationDialog extends StatefulWidget {
  /// 「はい」ボタンタップ時のコールバック
  final VoidCallback onConfirm;

  /// 「いいえ」ボタンタップ時のコールバック
  final VoidCallback onCancel;

  /// EmergencyConfirmationDialogを作成する
  ///
  /// [onConfirm] - 「はい」タップ時のコールバック（必須）
  /// [onCancel] - 「いいえ」タップ時のコールバック（必須）
  const EmergencyConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  /// テーマに応じた緊急ボタンの色を取得
  ///
  /// - ライトモード: 標準の赤色（AppColors.emergency）
  /// - ダークモード: 明るい赤色（AppColors.emergencyDark）
  /// - 高コントラストモード: 純粋な赤色（AppColors.emergencyHighContrast）
  static Color getEmergencyColor(BuildContext context) {
    final theme = Theme.of(context);

    // 高コントラストモードの判定（primaryが黒の場合）
    if (theme.colorScheme.primary == AppColors.primaryHighContrast) {
      return AppColors.emergencyHighContrast;
    }

    // ダークモード
    if (theme.brightness == Brightness.dark) {
      return AppColors.emergencyDark;
    }

    // ライトモード
    return AppColors.emergency;
  }

  @override
  State<EmergencyConfirmationDialog> createState() =>
      _EmergencyConfirmationDialogState();
}

/// EmergencyConfirmationDialogの状態管理クラス
class _EmergencyConfirmationDialogState
    extends State<EmergencyConfirmationDialog> {
  /// 処理中フラグ（連続タップ防止用）
  bool _isProcessing = false;

  /// 高コントラストモードかどうか判定
  bool _isHighContrastMode(ThemeData theme) =>
      theme.colorScheme.primary == AppColors.primaryHighContrast;

  /// ダークモードかどうか判定
  bool _isDarkMode(ThemeData theme) => theme.brightness == Brightness.dark;

  /// テーマに応じたキャンセルボタンの背景色を取得
  Color _getCancelButtonColor(ThemeData theme) {
    if (_isHighContrastMode(theme)) return AppColors.cancelButtonHighContrast;
    if (_isDarkMode(theme)) return AppColors.cancelButtonDark;
    return AppColors.cancelButtonLight;
  }

  /// テーマに応じたキャンセルボタンのテキスト色を取得
  Color _getCancelButtonTextColor(ThemeData theme) {
    // ダークモードのみ黒文字（明るいグレー背景に対して）
    if (_isDarkMode(theme) && !_isHighContrastMode(theme)) return Colors.black;
    return Colors.white;
  }

  /// ボタンタップ処理（連続タップ防止付き）
  void _handleTap(VoidCallback callback) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmButtonColor =
        EmergencyConfirmationDialog.getEmergencyColor(context);
    final cancelButtonColor = _getCancelButtonColor(theme);
    final cancelButtonTextColor = _getCancelButtonTextColor(theme);

    return Semantics(
      label: '緊急呼び出し確認ダイアログ',
      child: AlertDialog(
        title: Text(
          '緊急呼び出し',
          style: AppTextStyles.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '緊急呼び出しを実行しますか?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              '周囲に緊急音が鳴り、画面が赤くなります。',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          _buildCancelButton(cancelButtonColor, cancelButtonTextColor),
          const SizedBox(width: AppSizes.paddingSmall),
          _buildConfirmButton(confirmButtonColor),
        ],
        actionsPadding: const EdgeInsets.all(AppSizes.paddingMedium),
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  /// ダイアログボタンを構築する共通メソッド
  Widget _buildDialogButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: AppSizes.dialogButtonWidth,
      height: AppSizes.minTapTarget,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _handleTap(onTap),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          minimumSize: const Size(
            AppSizes.dialogButtonMinWidth,
            AppSizes.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
          ),
        ),
        child: Text(label, style: AppTextStyles.button),
      ),
    );
  }

  /// 「いいえ」ボタンを構築
  Widget _buildCancelButton(Color backgroundColor, Color textColor) =>
      _buildDialogButton(
        label: 'いいえ',
        backgroundColor: backgroundColor,
        textColor: textColor,
        onTap: widget.onCancel,
      );

  /// 「はい」ボタンを構築
  Widget _buildConfirmButton(Color backgroundColor) => _buildDialogButton(
        label: 'はい',
        backgroundColor: backgroundColor,
        textColor: Colors.white,
        onTap: widget.onConfirm,
      );
}
