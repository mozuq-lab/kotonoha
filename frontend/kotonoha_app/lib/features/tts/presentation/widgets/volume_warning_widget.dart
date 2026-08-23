/// 音量警告ウィジェット
///
/// TASK-0051: OS音量0の警告表示
/// OS音量0時の視覚的警告を表示するウィジェット
///
/// 【機能概要】: OSの音量が0（ミュート）の場合に視覚的警告を表示する
/// 【設計方針】:
/// - アクセシビリティ重視: タップターゲット44px以上、高コントラスト
/// - 視認性: 目立つ色（オレンジ/黄色系）で表示
/// 【保守性】: 警告表示のUIをこのウィジェットに集約
library;

import 'package:flutter/material.dart';

// =============================================================================
// 定数定義
// =============================================================================

/// 【設定定数】: 警告表示の背景色
const Color _warningBackground = Color(0xFFFFE0B2); // Colors.orange.shade100 相当

/// 【設定定数】: 警告表示の前景色（テキスト・アイコン）
/// 背景 #FFE0B2 に対しコントラスト比 8.2:1 で WCAG 2.1 AA (4.5:1) を満たす。
/// 従来の orange.shade800/900 は約2.5〜3.0:1 で AA 未達だったため使用しない。
/// 🔵 信頼性レベル: 青信号 - 高コントラスト要件（4.5:1以上）
const Color _warningForeground = Color(0xFF6D2C00);

/// 【設定定数】: 警告表示の枠線色
/// 非テキストUI要素の要件（3:1以上）を満たす。前景と同系色で統一する。
/// 🔵 信頼性レベル: 青信号 - WCAG 2.1 AA 非テキストコントラスト
const Color _warningBorder = Color(0xFF8C3A00);

/// 音量警告ウィジェット
///
/// OSの音量が0（ミュート）の場合に「音量が0です」という
/// 視覚的警告を表示するウィジェット。
///
/// 【主要機能】:
/// - 「音量が0です」メッセージと音量オフアイコンの表示
/// - 閉じるボタンによる警告の非表示化
///
/// 【要件対応】:
/// - EDGE-202: OSの音量が0の状態で読み上げを実行した場合の視覚的警告
/// - REQ-5001: タップターゲット44px×44px以上
///
/// 【パラメータ】:
/// - [isVisible]: 警告を表示するかどうか
/// - [onDismiss]: 閉じるボタンのコールバック
/// - [onOpenSettings]: 音量設定を開くコールバック（オプション）
///
/// 🔵 信頼性レベル: 高（要件定義書ベース）
class VolumeWarningWidget extends StatelessWidget {
  const VolumeWarningWidget({
    super.key,
    required this.isVisible,
    required this.onDismiss,
    this.onOpenSettings,
  });

  /// 警告を表示するかどうか
  final bool isVisible;

  /// 閉じるボタンのコールバック
  final VoidCallback onDismiss;

  /// 音量設定を開くコールバック（オプション）
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      // 非表示時は空のSizedBoxを返す
      return const SizedBox.shrink();
    }

    return Semantics(
      label: '警告: 音量が0です',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _warningBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _warningBorder,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 音量オフアイコン
            const Icon(
              Icons.volume_off,
              color: _warningForeground,
              size: 28,
            ),
            const SizedBox(width: 12),
            // 警告メッセージ
            const Expanded(
              child: Text(
                '音量が0です',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _warningForeground,
                ),
              ),
            ),
            // 閉じるボタン（44x44以上のタップターゲット）
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  color: _warningForeground,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
