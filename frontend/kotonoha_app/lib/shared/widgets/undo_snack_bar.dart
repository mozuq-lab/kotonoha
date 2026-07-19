/// Undo対応SnackBar表示ヘルパー
///
/// 改善: 履歴・お気に入りの削除は従来「確認ダイアログ→削除」のみで、
/// 誤タップで「はい」を選んでしまうと復元手段がなかった。
/// 個別削除は確認ダイアログを廃止して即削除に変更し、代わりに
/// 「元に戻す」操作付きSnackBar（8秒間表示）を表示することで、
/// 誤操作からの回復を可能にする。
///
/// スクリーンリーダー利用者にも削除完了・復元手段が伝わるよう、
/// SnackBarの内容にliveRegionを設定する。
library;

import 'package:flutter/material.dart';

/// 「元に戻す」アクション付きのSnackBarを表示する。
///
/// [message] - 表示するメッセージ（例: 「削除しました」）
/// [onUndo] - 「元に戻す」タップ時のコールバック
/// [duration] - 表示時間（デフォルト8秒）
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 8),
}) {
  final messenger = ScaffoldMessenger.of(context);
  // 連続削除時に前のSnackBarが残ったままにならないようにする
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Semantics(
        liveRegion: true,
        child: Text(message),
      ),
      duration: duration,
      action: SnackBarAction(
        label: '元に戻す',
        onPressed: onUndo,
      ),
    ),
  );
}
