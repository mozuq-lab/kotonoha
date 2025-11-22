/// ClearConfirmationDialog ウィジェット
///
/// TASK-0039: 削除ボタン・全消去ボタン実装
///
/// 全消去ボタンタップ時に表示される確認ダイアログ。
/// 誤操作防止のため、「はい」「いいえ」ボタンで確認を求める。
///
/// 関連要件:
/// - REQ-2001: 全消去ボタンタップ時に確認ダイアログを表示
/// - REQ-5002: 重要な操作（全消去）に誤操作防止の仕組みを設ける
/// - REQ-5001: タップターゲットのサイズは44px x 44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 全消去確認ダイアログウィジェット
///
/// 全消去ボタンタップ時に表示される確認ダイアログ。
/// 誤操作防止のため、「はい」「いいえ」ボタンで確認を求める。
class ClearConfirmationDialog extends StatelessWidget {
  /// 確認時のコールバック
  final VoidCallback onConfirmed;

  /// キャンセル時のコールバック
  final VoidCallback onCancelled;

  /// ClearConfirmationDialogを作成する
  const ClearConfirmationDialog({
    super.key,
    required this.onConfirmed,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('確認'),
      content: const Text('入力内容をすべて消去しますか？'),
      actions: [
        // いいえボタン
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(
              AppSizes.minTapTarget,
              AppSizes.minTapTarget,
            ),
          ),
          onPressed: onCancelled,
          child: const Text('いいえ'),
        ),
        // はいボタン
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(
              AppSizes.minTapTarget,
              AppSizes.minTapTarget,
            ),
          ),
          onPressed: onConfirmed,
          child: const Text('はい'),
        ),
      ],
    );
  }

  /// ダイアログを表示するヘルパーメソッド
  ///
  /// [context] - BuildContext
  /// [onConfirmed] - 確認時のコールバック
  /// [onCancelled] - キャンセル時のコールバック
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onConfirmed,
    required VoidCallback onCancelled,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClearConfirmationDialog(
        onConfirmed: onConfirmed,
        onCancelled: onCancelled,
      ),
    );
  }
}
