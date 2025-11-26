/// RotationToggleButton widget
///
/// TASK-0053: 180度画面回転機能実装
/// REQ-502: 画面を180度回転できる機能
/// REQ-503: シンプルな操作で切り替え
/// REQ-5001: タップターゲット44px×44px以上
///
/// 180度回転を切り替えるボタンウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/face_to_face_provider.dart';

/// 180度回転切り替えボタン
///
/// REQ-502: 画面を180度回転できる機能
/// REQ-5001: タップターゲット44px×44px以上
class RotationToggleButton extends ConsumerWidget {
  /// RotationToggleButtonを作成
  const RotationToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faceToFaceProvider);
    final notifier = ref.read(faceToFaceProvider.notifier);

    return Semantics(
      label: '画面を180度回転',
      button: true,
      child: Material(
        color: state.isRotated180
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            notifier.toggleRotation();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            child: Icon(
              Icons.screen_rotation,
              size: 32,
              color: state.isRotated180
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
