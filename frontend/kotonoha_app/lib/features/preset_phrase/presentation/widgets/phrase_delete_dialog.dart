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
import 'package:kotonoha_app/core/utils/contrast.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 機能概要: 削除確認ダイアログ
/// 実装方針: AlertDialogベースで確認メッセージ表示、誤操作防止
/// テスト対応: TC-041-028〜TC-041-031
/// 信頼性レベル: 青信号 - CRUD-101, CRUD-204, REQ-5002に基づく
///
/// 定型文削除前の確認ダイアログ。
/// 誤操作防止のため、ダイアログ外タップでは閉じない設計。
class PhraseDeleteDialog extends StatelessWidget {
  /// パラメータ定義: 削除対象の定型文
  /// 信頼性レベル: 青信号 - UC-003に基づく
  final PresetPhrase phrase;

  /// パラメータ定義: この定型文がお気に入り登録済みかどうか
  ///
  /// Phase 3 / WP-2: 定型文の削除はお気に入りも連動削除する
  /// （deletePhrase → deleteFavoriteBySourceId）。お気に入りの正は
  /// favoriteProvider（ADR-005）で PresetPhrase 自体からは分からないため、
  /// 呼び出し側（PresetPhraseScreen）が favoriteProvider から判定して渡す。
  /// true のときだけ、お気に入りも消えることを確認文に足す。
  final bool isFavorite;

  /// パラメータ定義: 削除確認時のコールバック
  /// 信頼性レベル: 青信号 - CRUD-102に基づく
  final VoidCallback? onConfirm;

  /// パラメータ定義: キャンセル時のコールバック
  /// 信頼性レベル: 青信号 - CRUD-103に基づく
  final VoidCallback? onCancel;

  /// PhraseDeleteDialogを作成する
  const PhraseDeleteDialog({
    super.key,
    required this.phrase,
    this.isFavorite = false,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // AA対応: 以前は Colors.red(#F44336) + Colors.white を固定しており
    // 全テーマで 3.68:1 と WCAG AA(4.5:1) 未達だった。テーマの error 色は
    // 各テーマの背景に対しAAを満たすよう定義済みなのでそれを使い、
    // 文字色は背景輝度から選ぶ（ライト 9.11:1 / ダーク 12.30:1 /
    // 高コントラスト 5.89:1）。
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('定型文の削除'),
      content: isFavorite
          // 告知: お気に入り登録済みのときだけ、連動削除を確認文で伝える
          // （利用者は発話で訂正できず、端末内にしかデータが無いため）。
          // 未登録の定型文では出さない（無用な不安を与えないため）。
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('この定型文を削除しますか？'),
                SizedBox(height: 8),
                Text('お気に入りからも削除されます'),
              ],
            )
          : const Text('この定型文を削除しますか？'),
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
            backgroundColor: errorColor,
            foregroundColor: bestContrastingTextColor(errorColor),
          ),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
