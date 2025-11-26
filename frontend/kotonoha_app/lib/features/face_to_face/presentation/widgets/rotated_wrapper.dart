/// RotatedWrapper widget
///
/// TASK-0053: 180度画面回転機能実装
/// REQ-502: 画面を180度回転できる機能
///
/// 子ウィジェットを180度回転するラッパーウィジェット
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 180度回転ラッパーウィジェット
///
/// 子ウィジェットを180度回転して表示する。
/// 回転の中心点は画面中央（Alignment.center）。
class RotatedWrapper extends StatelessWidget {
  /// 回転するかどうか
  ///
  /// true: 180度回転する
  /// false: そのまま表示する
  final bool isRotated;

  /// 子ウィジェット
  final Widget child;

  /// RotatedWrapperを作成
  ///
  /// [isRotated] 回転するかどうか
  /// [child] 子ウィジェット
  const RotatedWrapper({
    super.key,
    required this.isRotated,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 回転しない場合は子ウィジェットをそのまま返す
    if (!isRotated) {
      return child;
    }

    // 回転する場合はTransform.rotateで180度回転
    // Key付きでテスト時に識別可能にする
    return Transform(
      key: const ValueKey('rotation_transform'),
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(math.pi),
      child: child,
    );
  }
}
