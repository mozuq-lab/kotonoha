/// EmergencyButton ウィジェット
/// 緊急時に介護者を呼ぶための目立つ赤い円形ボタン。
/// 常時表示され、1タップで緊急メッセージを読み上げる。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 緊急ボタンウィジェット
/// 緊急時に介護者を呼び出すための目立つ赤い円形ボタン。
/// 全画面で常時表示され、1タップで緊急メッセージを読み上げる。
/// デザイン仕様
/// 背景色: 赤（#D32F2F / AppColors.emergency）
/// 形状: 円形（CircleBorder）
/// サイズ: 60x60px（推奨）
/// アイコン: notifications_active（白色）
/// 使用例
/// ```dart
/// EmergencyButton(
/// onPressed:  => speakEmergencyMessage
/// )
/// ```
class EmergencyButton extends StatelessWidget {
  /// ボタンタップ時のコールバック
  final VoidCallback onPressed;

  /// ボタンサイズ（幅・高さ共通、デフォルト: 60px）
  final double size;

  /// EmergencyButtonを作成する
  /// [onPressed] - タップ時のコールバック（必須）
  /// [size] - ボタンサイズ（デフォルト: 60px）
  const EmergencyButton({
    super.key,
    required this.onPressed,
    this.size = AppSizes.recommendedTapTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '緊急呼び出しボタン',
      button: true,
      child: SizedBox(
        width: size,
        height: size,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emergency,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(0),
            elevation: 4,
          ),
          child: const Icon(
            Icons.notifications_active,
            size: AppSizes.iconSizeLarge,
          ),
        ),
      ),
    );
  }
}
