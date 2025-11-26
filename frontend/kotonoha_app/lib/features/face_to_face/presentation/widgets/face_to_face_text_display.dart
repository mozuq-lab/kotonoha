/// 対面表示テキスト表示ウィジェット
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// REQ-501: テキストを画面中央に大きく表示する拡大表示モード
library;

import 'package:flutter/material.dart';

/// 対面表示用のテキスト表示ウィジェット
///
/// テキストを画面中央に大きく表示する。
/// 対面の相手がメッセージを読み取りやすいよう、
/// 大きなフォントサイズでシンプルに表示する。
///
/// REQ-501: テキストを画面中央に大きく表示
class FaceToFaceTextDisplay extends StatelessWidget {
  /// 表示するテキスト
  final String text;

  /// フォントサイズ（オプション）
  ///
  /// 指定しない場合はデフォルトの大きなフォントサイズ（32px以上）を使用
  final double? fontSize;

  /// FaceToFaceTextDisplayを作成
  ///
  /// [text] 表示するテキスト
  /// [fontSize] フォントサイズ（オプション、デフォルト: 36px）
  const FaceToFaceTextDisplay({
    super.key,
    required this.text,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveFontSize = fontSize ?? 36.0;

    return Semantics(
      label: '対面表示テキスト: $text',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            text,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
