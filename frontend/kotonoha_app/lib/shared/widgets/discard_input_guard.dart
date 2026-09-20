/// 入力中の内容を、戻る操作で黙って捨てさせないための包み（台帳 L-136）
///
/// 利用者は文字盤で 1 文字ずつ打つ。打ち終わった文が確認なしに消えると、
/// **打ち直すしかない**（発話で訂正できないので、他に伝える手段が無い）。
///
/// `barrierDismissible: false` が塞ぐのは**ダイアログの外をタップしたとき**
/// だけで、**Android のシステムバック**は通ってしまう。
/// **入力を持つダイアログは、これで包む。**
///
/// 効かない経路（2026-09-20 実測）:
///   - **ブラウザの戻る**は `PopScope` を通らない。web の engine は
///     `history.back()` を `popRoute` ではなく `pushRouteInformation` として
///     送るため（台帳 L-143）
///   - iOS にはシステムバックが無く、ダイアログは `PopupRoute` なので
///     エッジスワイプの対象外。実質 Android 専用の守り
///   - 「キャンセル」ボタンは通らない。**押し間違いではなく意思表示**なので、
///     そこで訊き返さない
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

/// 入力があるうちは、戻る操作で閉じる前に確認する
///
/// ```dart
/// DiscardInputGuard(
///   hasInput: controller.text.isNotEmpty,
///   onDiscard: () => Navigator.of(context).pop(),
///   child: ConfirmationDialogLayout.build(...),
/// )
/// ```
/// 入力が無ければ何もしない（余計な確認で足止めしない）。
class DiscardInputGuard extends StatelessWidget {
  /// 捨てると困る入力があるか
  final bool hasInput;

  /// 「破棄する」を選んだとき。ふつうはダイアログを閉じる
  final VoidCallback onDiscard;

  /// 包む中身
  final Widget child;

  /// DiscardInputGuardを作成する
  const DiscardInputGuard({
    super.key,
    required this.hasInput,
    required this.onDiscard,
    required this.child,
  });

  /// 確認の見出し
  static const String confirmTitle = '入力中の内容';

  /// 確認の本文。テストがこの文言を参照する
  static const String confirmMessage = '入力中の内容を破棄しますか？';

  /// 破棄せずに戻る側のラベル
  static const String keepLabel = '書き続ける';

  /// 破棄する側のラベル
  static const String discardLabel = '破棄する';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 入力があるあいだは戻る操作でそのまま閉じさせない。
      // 閉じるかどうかは、下の確認を経てから決める
      canPop: !hasInput,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ConfirmationDialog(
            title: confirmTitle,
            message: confirmMessage,
            // 取り消し側は「書き続ける」。**打った文が消えるのは破棄側**なので、
            // `destructive` の塗りは破棄側に付く
            cancelLabel: keepLabel,
            confirmLabel: discardLabel,
            // 打った文が消えるのは破棄側。既定に頼らず明示する
            kind: ConfirmKind.destructive,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        );
        // `await` の間にこの route が取り除かれていることがありうる。
        // SDK の `PopScope` の公式サンプル（`examples/api/.../pop_scope.0.dart`）も
        // `context.mounted` を確かめてから pop する
        if (!context.mounted) return;
        if (discard ?? false) onDiscard();
      },
      child: child,
    );
  }
}
