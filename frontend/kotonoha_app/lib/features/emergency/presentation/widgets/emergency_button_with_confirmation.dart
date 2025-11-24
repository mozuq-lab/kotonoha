/// EmergencyButtonWithConfirmation ウィジェット
///
/// TASK-0045: 緊急ボタンUI実装
/// 要件: REQ-301（緊急ボタン常時表示）、REQ-302（2段階確認）、REQ-5002（誤操作防止）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 確認ダイアログ付き緊急ボタンウィジェット。
/// 既存のEmergencyButton（TASK-0017）を拡張し、確認ダイアログ連携、
/// テーマ対応、アクセシビリティ対応を追加。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

/// 確認ダイアログ付き緊急ボタンウィジェット
///
/// 緊急時に介護者を呼び出すための目立つ赤い円形ボタン。
/// タップ時に確認ダイアログを表示し、2段階確認を実現する。
///
/// デザイン仕様:
/// - 背景色: 赤（テーマに応じて調整）
/// - 形状: 円形（CircleBorder）
/// - サイズ: デフォルト60px、最小44px保証
/// - アイコン: notifications_active（白色）
/// - エレベーション: 4（影あり）
///
/// REQ-301: 全画面で常時表示
/// REQ-302: 2段階確認（ボタンタップ→確認ダイアログ→確認タップ）
/// REQ-5002: 誤操作防止
///
/// 使用例:
/// ```dart
/// EmergencyButtonWithConfirmation(
///   onEmergencyConfirmed: () {
///     // 緊急処理を実行
///     playEmergencySound();
///     showEmergencyScreen();
///   },
/// )
/// ```
class EmergencyButtonWithConfirmation extends StatelessWidget {
  /// 緊急呼び出し確認後のコールバック
  final VoidCallback onEmergencyConfirmed;

  /// ボタンサイズ（幅・高さ共通、デフォルト: 60px）
  /// 最小44px保証（REQ-5001）
  final double size;

  /// 確認ダイアログをカスタマイズするためのビルダー（オプション）
  /// 指定しない場合はEmergencyConfirmationDialogを使用
  final Widget Function(
    BuildContext context,
    VoidCallback onConfirm,
    VoidCallback onCancel,
  )? dialogBuilder;

  /// EmergencyButtonWithConfirmationを作成する
  ///
  /// [onEmergencyConfirmed] - 確認後のコールバック（必須）
  /// [size] - ボタンサイズ（デフォルト: 60px、最小: 44px）
  /// [dialogBuilder] - カスタムダイアログビルダー（オプション）
  const EmergencyButtonWithConfirmation({
    super.key,
    required this.onEmergencyConfirmed,
    this.size = AppSizes.recommendedTapTarget,
    this.dialogBuilder,
  });

  /// 実際に使用するサイズを計算（最小44px保証）
  double get _effectiveSize {
    return size < AppSizes.minTapTarget ? AppSizes.minTapTarget : size;
  }

  /// 確認ダイアログを表示
  Future<void> _showConfirmationDialog(BuildContext context) async {
    void onConfirm() {
      Navigator.of(context).pop();
      onEmergencyConfirmed();
    }

    void onCancel() {
      Navigator.of(context).pop();
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // REQ-5002: 誤操作防止
      builder: (dialogContext) {
        if (dialogBuilder != null) {
          return dialogBuilder!(dialogContext, onConfirm, onCancel);
        }
        return EmergencyConfirmationDialog(
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // EmergencyConfirmationDialogの静的メソッドを使用して色を取得
    final backgroundColor = EmergencyConfirmationDialog.getEmergencyColor(
      context,
    );
    final effectiveSize = _effectiveSize;

    return Semantics(
      label: '緊急呼び出しボタン',
      button: true,
      child: SizedBox(
        width: effectiveSize,
        height: effectiveSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showConfirmationDialog(context),
            customBorder: const CircleBorder(),
            child: Ink(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: AppSizes.elevationMedium,
                    offset: Offset(0, AppSizes.elevationSmall),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_active,
                  size: AppSizes.iconSizeLarge,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
