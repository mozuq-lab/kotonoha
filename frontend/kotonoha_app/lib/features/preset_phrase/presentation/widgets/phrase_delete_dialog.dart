/// PhraseDeleteDialog - 削除確認ダイアログ
/// 削除時に確認ダイアログを表示
/// 確認後に削除を実行
/// キャンセルで削除を中止
/// 削除操作に確認ダイアログを設ける
/// ダイアログ外タップで閉じない（誤操作防止）
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

/// 機能概要: 削除確認ダイアログ
/// 実装方針: AlertDialogベースで確認メッセージ表示、誤操作防止
/// 定型文削除前の確認ダイアログ。
/// 誤操作防止のため、ダイアログ外タップでは閉じない設計。
class PhraseDeleteDialog extends StatelessWidget {
  /// パラメータ定義: 削除対象の定型文
  final PresetPhrase phrase;

  /// パラメータ定義: 削除確認時のコールバック
  final VoidCallback? onConfirm;

  /// パラメータ定義: キャンセル時のコールバック
  final VoidCallback? onCancel;

  /// PhraseDeleteDialogを作成する
  const PhraseDeleteDialog({
    super.key,
    required this.phrase,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // 並び（間隔・並び順・タップ目標・スクロール）は ConfirmationDialog が持つ。
    // ここで AlertDialog を組み直さない（台帳 L-130）
    return ConfirmationDialog(
      title: '定型文の削除',
      // 定型文を削除してもお気に入りは残る（ADR-005、2026-09-13）ので、
      // お気に入りに関する告知は出さない。
      message: 'この定型文を削除しますか？',
      cancelLabel: 'キャンセル',
      confirmLabel: '削除',
      onCancel: () {
        onCancel?.call();
        Navigator.of(context).pop();
      },
      onConfirm: () {
        onConfirm?.call();
        Navigator.of(context).pop();
      },
    );
  }
}
