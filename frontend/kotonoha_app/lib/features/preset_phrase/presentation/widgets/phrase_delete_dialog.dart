/// PhraseDeleteDialog - 削除確認ダイアログ
///
/// TASK-0041: 定型文CRUD機能実装
/// TDD Refactorフェーズ: ドキュメント改善
///
/// 関連要件:
/// - CRUD-101: 削除時に確認ダイアログを表示
/// - CRUD-102: 確認後に削除を実行
/// - CRUD-103: キャンセルで削除を中止
/// - CRUD-204: 削除操作に確認ダイアログを設ける
/// - EDGE-013: ダイアログ外タップで閉じない（誤操作防止）
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【機能概要】: 削除確認ダイアログ
/// 【実装方針】: AlertDialogベースで確認メッセージ表示、誤操作防止
/// 【テスト対応】: TC-041-028〜TC-041-031
/// 🔵 信頼性レベル: 青信号 - CRUD-101, CRUD-204, REQ-5002に基づく
///
/// 定型文削除前の確認ダイアログ。
/// 誤操作防止のため、ダイアログ外タップでは閉じない設計。
class PhraseDeleteDialog extends StatelessWidget {
  /// 【パラメータ定義】: 削除対象の定型文
  /// 🔵 信頼性レベル: 青信号 - UC-003に基づく
  final PresetPhrase phrase;

  /// 【パラメータ定義】: 削除確認時のコールバック
  /// 🔵 信頼性レベル: 青信号 - CRUD-102に基づく
  final VoidCallback? onConfirm;

  /// 【パラメータ定義】: キャンセル時のコールバック
  /// 🔵 信頼性レベル: 青信号 - CRUD-103に基づく
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
    return AlertDialog(
      title: const Text('定型文の削除'),
      content: const Text('この定型文を削除しますか？'),
      actions: [
        // キャンセルボタン (TC-041-030)
        TextButton(
          onPressed: () {
            // キャンセルコールバック発火 (CRUD-103)
            onCancel?.call();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
          ),
          child: const Text('キャンセル'),
        ),
        // 削除ボタン (TC-041-029)
        ElevatedButton(
          onPressed: () {
            // 削除確認コールバック発火 (CRUD-102)
            onConfirm?.call();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
