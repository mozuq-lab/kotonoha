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
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.shade700,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 音量オフアイコン
            Icon(
              Icons.volume_off,
              color: Colors.orange.shade800,
              size: 28,
            ),
            const SizedBox(width: 12),
            // 警告メッセージ
            Expanded(
              child: Text(
                '音量が0です',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
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
                child: Icon(
                  Icons.close,
                  color: Colors.orange.shade800,
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
