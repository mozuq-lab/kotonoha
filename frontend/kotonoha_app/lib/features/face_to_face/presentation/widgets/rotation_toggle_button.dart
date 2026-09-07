/// RotationToggleButton widget
/// 画面を180度回転できる機能
/// シンプルな操作で切り替え
/// タップターゲット44px×44px以上
/// 180度回転を切り替えるボタンウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/face_to_face_provider.dart';

/// 180度回転切り替えボタン
/// 画面を180度回転できる機能
/// タップターゲット44px×44px以上
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
