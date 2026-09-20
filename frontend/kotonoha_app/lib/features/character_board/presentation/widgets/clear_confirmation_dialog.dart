/// ClearConfirmationDialog ウィジェット
/// 全消去ボタンタップ時に表示される確認ダイアログ。
/// 誤操作防止のため、「はい」「いいえ」ボタンで確認を求める。
/// 全消去ボタンタップ時に確認ダイアログを表示
/// 重要な操作（全消去）に誤操作防止の仕組みを設ける
/// タップターゲットのサイズは44px x 44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

/// 全消去確認ダイアログウィジェット
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
    // 並び（間隔・並び順・タップ目標・スクロール）は ConfirmationDialog が持つ。
    // ここで AlertDialog を組み直さない（台帳 L-130）
    return ConfirmationDialog(
      title: '確認',
      message: '入力内容をすべて消去しますか？',
      cancelLabel: 'いいえ',
      confirmLabel: 'はい',
      onCancel: onCancelled,
      onConfirm: onConfirmed,
    );
  }

  /// ダイアログを表示するヘルパーメソッド
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
