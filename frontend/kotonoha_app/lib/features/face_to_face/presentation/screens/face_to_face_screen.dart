/// 対面表示モード画面
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// REQ-501: テキストを画面中央に大きく表示する拡大表示モード
/// REQ-503: 通常モードと対面表示モードをシンプルな操作で切り替え
/// NFR-202: ボタン・タップ領域を視認性が高く押しやすいサイズ
library;

import 'package:flutter/material.dart';
import '../widgets/face_to_face_text_display.dart';

/// 対面表示モード画面
///
/// テキストを画面中央に大きく表示し、対面の相手が
/// メッセージを読み取りやすいようにする全画面ウィジェット。
///
/// REQ-501: 画面中央に大きく表示
/// REQ-503: シンプルな操作で切り替え
/// NFR-202: 視認性が高く押しやすいボタン
class FaceToFaceScreen extends StatelessWidget {
  /// 表示するテキスト
  final String displayText;

  /// 戻るボタン押下時のコールバック
  ///
  /// 指定しない場合はNavigator.popを使用
  final VoidCallback? onBack;

  /// FaceToFaceScreenを作成
  ///
  /// [displayText] 表示するテキスト
  /// [onBack] 戻るボタン押下時のコールバック（オプション）
  const FaceToFaceScreen({
    super.key,
    required this.displayText,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // シンプルな背景（REQ-501から推測）
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // テキスト表示（画面中央）
            Center(
              child: FaceToFaceTextDisplay(
                text: displayText,
              ),
            ),
            // 戻るボタン（右上に配置）
            Positioned(
              top: 16,
              right: 16,
              child: _buildBackButton(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 戻るボタンを構築
  ///
  /// REQ-5001: 最小タップターゲット44px×44px
  /// NFR-202: 視認性が高く押しやすいサイズ
  Widget _buildBackButton(BuildContext context) {
    return Semantics(
      button: true,
      label: '対面表示モードを終了',
      child: InkWell(
        onTap: onBack ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // REQ-5001: 最小タップターゲット44px×44px
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.close,
            size: 24,
            semanticLabel: '閉じる',
          ),
        ),
      ),
    );
  }
}
