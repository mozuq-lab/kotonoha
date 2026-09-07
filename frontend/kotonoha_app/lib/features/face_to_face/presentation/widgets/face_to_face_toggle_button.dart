/// 対面表示モード切り替えボタンウィジェット
/// 通常モードと対面表示モードをシンプルな操作で切り替え
/// タップターゲット44px×44px以上
library;

import 'package:flutter/material.dart';

/// 対面表示モード切り替えボタン
/// 1タップで対面表示モードの有効/無効を切り替えるボタン。
/// モードの状態に応じてアイコンが変化する。
/// シンプルな操作で切り替え
/// 最小タップターゲット44px×44px
class FaceToFaceToggleButton extends StatelessWidget {
  /// 対面表示モードが有効かどうか
  final bool isEnabled;

  /// ボタンタップ時のコールバック
  final VoidCallback onTap;

  /// FaceToFaceToggleButtonを作成
  /// [isEnabled] 現在のモード状態
  /// [onTap] タップ時のコールバック
  const FaceToFaceToggleButton({
    super.key,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isEnabled ? '対面表示モードを終了' : '対面表示モードを開始',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // 最小タップターゲット44px×44px
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            // モード状態に応じたアイコン
            isEnabled ? Icons.fullscreen_exit : Icons.zoom_out_map,
            size: 24,
            semanticLabel: isEnabled ? '対面表示モードを終了' : '対面表示モードを開始',
          ),
        ),
      ),
    );
  }
}
