/// 誤操作防止の二択ダイアログ（台帳 L-130・L-131）
///
/// REQ-5002 は緊急呼び出し・全消去などを「誤操作防止の対象」として並べている。
/// この形のダイアログは **取り消し** と **取り消せない実行** を並べるので、
/// 2 つが接していたり、説明文が画面から消えていたりすると、そのまま誤操作になる。
/// 利用者は発話で訂正できず、消した入力は打ち直せない。
///
/// この形のダイアログは、**個別に `AlertDialog` を組まず、このウィジェットを使う**。
/// `AlertDialog` の既定は横 8px・縦 0px なので、何も指定しないとボタンが近すぎる
/// （幅が足りないと actions は `OverflowBar` で縦積みに切り替わり、縦の既定 0 が
/// そのまま隙間になる。細いボタンでも文字設定「大」と OS の文字拡大が重なれば
/// 縦積みに入り、**0px で接する**。2026-09-20 実測）。
/// 呼び出し側はラベルだけを渡し、ボタンそのものは作らない。そうすることで
/// 間隔・並び順・タップ目標・スクロールを取り違えられなくする。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';

/// 誤操作防止ダイアログの並び
///
/// **間隔を決めているのはここだけ。** 緊急確認ダイアログのように、色や
/// 連続タップ防止のために自前で `AlertDialog` を組む必要があるものも、
/// 並びはここから取る（ADR-005 の 1 概念 1 真実）。
abstract final class ConfirmationDialogLayout {
  /// 縦積みになったときのボタンとボタンの隙間。
  /// `AlertDialog` の `actionsOverflowButtonSpacing` に渡す（既定は 0）
  static const double overflowButtonSpacing = AppSizes.paddingMedium;

  /// 横並びのときの隙間を決める値。
  /// `OverflowBar` の `spacing` は `buttonPadding.horizontal / 2` なので、
  /// 左右 24（`.horizontal` は和で 48）で隙間 24 になる
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge);

  /// actions の外周。`buttonPadding` が外周にも足されるのは、これを
  /// **渡していないときだけ**なので、必ず明示して渡す
  static const EdgeInsets actionsPadding =
      EdgeInsets.all(AppSizes.paddingMedium);

  /// 文字が大きくなっても内容が画面からあふれないようにする。
  /// `scrollable: true` でも actions は `SingleChildScrollView` の外に残るので、
  /// ボタンは常に見えていて、説明文だけがスクロールする
  static const bool scrollable = true;

  // タップ目標 44px 以上（REQ-3001）は、ここでは指定しない。ボタンごとに
  // `minimumSize` を重ねても効かないため（2026-09-20 実測。1 文字ラベルで
  // `minimumSize` を 0 にしても 48×48）。効かない指定は重ねない
  // （ADR-008 の「発火ゼロの仕組みを作らない」）。実寸を決めているのは
  //   1. アプリのテーマの `minimumSize`（`light_theme.dart` の
  //      textButtonTheme 44×44・elevatedButtonTheme `recommendedTapTarget`）
  //   2. テーマの `materialTapTargetSize` と `visualDensity`
  // で、**2 はプラットフォームで変わる**。`defaultTargetPlatform` が
  // macOS / Windows / Linux（＝デスクトップのブラウザ）だと `ThemeData` は
  // `shrinkWrap` ＋ `VisualDensity(-2,-2)` を選び、1 の 44 から 8 引かれて
  // **「いいえ」は 36px になる**（2026-09-20 実測。main でも同じで、
  // アプリ全体の `TextButton` に及ぶ既存の穴。台帳 L-134）。
  // 契約テストはテストの既定プラットフォーム（Android 相当）で回るので、
  // この 1 本はそこまでしか見張れない。
}

/// 実行ボタンの重さ
enum ConfirmKind {
  /// 取り消せない操作（削除・全消去・下書きの置き換え）。
  /// 実行だけを塗りつぶして、取り消しと見分けられるようにする
  destructive,

  /// 取り消せるが確認が要る操作（外部送信への同意など）
  normal,
}

/// 誤操作防止の二択ダイアログ
///
/// ```dart
/// showDialog<void>(
///   context: context,
///   barrierDismissible: false,
///   builder: (dialogContext) => ConfirmationDialog(
///     title: '確認',
///     message: '入力内容をすべて消去しますか？',
///     cancelLabel: 'いいえ',
///     confirmLabel: 'はい',
///     onCancel: () => Navigator.of(dialogContext).pop(),
///     onConfirm: () { Navigator.of(dialogContext).pop(); doIt(); },
///   ),
/// );
/// ```
/// ダイアログを閉じるのは呼び出し側（このウィジェットは `Navigator` に触らない）。
class ConfirmationDialog extends StatelessWidget {
  /// 見出し
  final String title;

  /// 本文。何が起きるかを書く
  final String message;

  /// 取り消し側のラベル。**必ず先（横並びなら左、縦積みなら上）に置かれる**
  final String cancelLabel;

  /// 実行側のラベル
  final String confirmLabel;

  /// 取り消しを選んだとき
  final VoidCallback onCancel;

  /// 実行を選んだとき
  final VoidCallback onConfirm;

  /// 実行ボタンの重さ
  final ConfirmKind kind;

  /// ConfirmationDialogを作成する
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.kind = ConfirmKind.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 取り消せない操作は error 色で塗る。文字色は背景輝度から選ぶ
    // （テーマ 3 種で背景が変わるので、白や黒に固定すると AA を割る）
    final confirmBackground = switch (kind) {
      ConfirmKind.destructive => colorScheme.error,
      ConfirmKind.normal => colorScheme.primary,
    };

    return AlertDialog(
      scrollable: ConfirmationDialogLayout.scrollable,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmBackground,
            foregroundColor: bestContrastingTextColor(confirmBackground),
          ),
          child: Text(confirmLabel),
        ),
      ],
      actionsOverflowButtonSpacing:
          ConfirmationDialogLayout.overflowButtonSpacing,
      buttonPadding: ConfirmationDialogLayout.buttonPadding,
      actionsPadding: ConfirmationDialogLayout.actionsPadding,
    );
  }
}
