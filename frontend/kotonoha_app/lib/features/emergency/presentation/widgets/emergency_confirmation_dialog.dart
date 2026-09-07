/// EmergencyConfirmationDialog ウィジェット
/// 緊急呼び出し確認ダイアログ。
/// 緊急ボタンタップ後に表示され、2段階確認を実現する。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/constants/app_text_styles.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';

/// 緊急呼び出し確認ダイアログ
/// 緊急ボタンタップ後に表示される確認ダイアログ。
/// 2段階確認（ボタンタップ→確認ダイアログ→確認タップ）を実現する。
/// デザイン仕様
/// タイトル: 「緊急呼び出し」
/// メッセージ: 「緊急呼び出しを実行しますか?」
/// 「はい」ボタン: 赤色背景、緊急処理実行
/// 「いいえ」ボタン: グレー背景、キャンセル
/// ダイアログ外タップでは閉じない（barrierDismissible: false）
/// 連続タップ防止機能により、ボタンは1回のみ反応する
/// 使用例
/// ```dart
/// showDialog(
/// context: context
/// barrierDismissible: false
/// builder: (_) => EmergencyConfirmationDialog(
/// onConfirm:  {
/// Navigator.of(context).pop;
/// executeEmergency;
/// }
/// onCancel:  => Navigator.of(context).pop
/// )
/// );
/// ```
class EmergencyConfirmationDialog extends StatefulWidget {
  /// 確認メッセージ
  /// 定数として公開する理由: テストがこの文言をハードコードすると
  /// 疑問符の全角・半角のような1文字の差で照合が外れ、しかも
  /// 「ダイアログが出ていない」という誤った症状に見える。実際にそれが起き
  /// E2E の緊急ボタン7件が失敗していた（Issue #84）。
  /// テストはこの定数を参照すること。
  static const String confirmationMessage = '緊急呼び出しを実行しますか?';

  /// タイトル
  static const String dialogTitle = '緊急呼び出し';

  /// 実行ボタンのラベル
  static const String confirmLabel = 'はい';

  /// キャンセルボタンのラベル
  static const String cancelLabel = 'いいえ';

  /// 「はい」ボタンタップ時のコールバック
  final VoidCallback onConfirm;

  /// 「いいえ」ボタンタップ時のコールバック
  final VoidCallback onCancel;

  /// EmergencyConfirmationDialogを作成する
  /// [onConfirm] - 「はい」タップ時のコールバック（必須）
  /// [onCancel] - 「いいえ」タップ時のコールバック（必須）
  const EmergencyConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  /// テーマに応じた緊急ボタンの色を取得
  /// ライトモード: 標準の赤色（AppColors.emergency）
  /// ダークモード: 明るい赤色（AppColors.emergencyDark）
  /// 高コントラストモード: 純粋な赤色（AppColors.emergencyHighContrast）
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
    // AA対応: ボタン背景はテーマごとに変わるため、文字色を固定せず
    // 実際の背景色の輝度から黒・白のうちコントラスト比が高い方を選ぶ。
    final cancelButtonTextColor = bestContrastingTextColor(cancelButtonColor);

    return Semantics(
      label: '緊急呼び出し確認ダイアログ',
      child: AlertDialog(
        title: Text(
          EmergencyConfirmationDialog.dialogTitle,
          style: AppTextStyles.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              EmergencyConfirmationDialog.confirmationMessage,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            // AA対応: 補足文の色に Colors.grey(#9E9E9E) を固定していたため
            // ダイアログ背景との組み合わせでライト 2.46:1 / 高コントラスト 2.68:1 と
            // WCAG AA(4.5:1)未達だった。テーマの onSurfaceVariant は各テーマの
            // サーフェス色に対しAAを満たすよう定義済みのため、これを使う。
            Text(
              '周囲に緊急音が鳴り、画面が赤くなります。',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
        label: EmergencyConfirmationDialog.cancelLabel,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onTap: widget.onCancel,
      );

  /// 「はい」ボタンを構築
  /// AA対応: 背景は緊急色（テーマごとに変わる）なのに文字色を
  /// Colors.white 固定にしていたため、ダーク(#EF5350) 3.49:1
  /// 高コントラスト(#FF0000) 4.00:1 で WCAG AA(4.5:1) 未達だった。
  /// 緊急色は「目立たせる」ための色なので暗くはせず
  /// 背景輝度から最良の文字色を選ぶことで赤を保ったまま基準を満たす。
  Widget _buildConfirmButton(Color backgroundColor) => _buildDialogButton(
        label: EmergencyConfirmationDialog.confirmLabel,
        backgroundColor: backgroundColor,
        textColor: bestContrastingTextColor(backgroundColor),
        onTap: widget.onConfirm,
      );
}
