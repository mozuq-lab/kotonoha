/// PhraseDeleteDialog - 削除確認ダイアログ
/// 削除時に確認ダイアログを表示
/// 確認後に削除を実行
/// キャンセルで削除を中止
/// 削除操作に確認ダイアログを設ける
/// ダイアログ外タップで閉じない（誤操作防止）
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

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
    // AA対応: 以前は Colors.red(#F44336) + Colors.white を固定しており
    // 全テーマで 3.68:1 と WCAG AA(4.5:1) 未達だった。テーマの error 色は
    // 各テーマの背景に対しAAを満たすよう定義済みなのでそれを使い
    // 文字色は背景輝度から選ぶ（ライト 9.11:1 / ダーク 12.30:1
    // 高コントラスト 5.89:1）。
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('定型文の削除'),
      // 定型文を削除してもお気に入りは残る（ADR-005、2026-09-13）ので、
      // お気に入りに関する告知は出さない。
      content: const Text('この定型文を削除しますか？'),
      actions: [
        // キャンセルボタン
        TextButton(
          onPressed: () {
            // キャンセルコールバック発火
            onCancel?.call();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
          ),
          child: const Text('キャンセル'),
        ),
        // 削除ボタン
        ElevatedButton(
          onPressed: () {
            // 削除確認コールバック発火
            onConfirm?.call();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
            backgroundColor: errorColor,
            foregroundColor: bestContrastingTextColor(errorColor),
          ),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
