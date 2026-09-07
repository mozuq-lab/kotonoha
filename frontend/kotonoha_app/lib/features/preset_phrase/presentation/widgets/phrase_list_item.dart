/// PhraseListItem ウィジェット
/// 個別の定型文アイテムを表示するウィジェット。
/// タップ時にコールバックを発火し、お気に入りアイコンを表示する。
/// アクセシビリティ要件（: 44px以上、: 60px推奨）に準拠。
/// 定型文を一覧表示
/// お気に入り定型文を一覧上部に優先表示
/// タップターゲット44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/widgets/send_to_input_button.dart';

/// 機能概要: 定型文アイテムウィジェット
/// 実装方針: ListTileベースで44px以上のタップターゲットを確保
/// 個別の定型文をリストアイテムとして表示する。
/// タップ時にonTapコールバックを発火する。
class PhraseListItem extends StatelessWidget {
  /// パラメータ定義: 表示する定型文
  final PresetPhrase phrase;

  /// パラメータ定義: お気に入り状態（表示用）
  /// 設計変更: Phase 3 / WP-2 / Stage 3a - お気に入りの正はfavoriteProvider
  /// （ADR-005）。このウィジェットは単一のphraseしか扱わないため
  /// 集合ではなく判定済みのbool値を上位から受け取る。
  /// 上位は favoritePresetIds.contains(phrase.id) を渡すこと。
  /// （Stage 3b で PresetPhrase.isFavorite は削除済み。定型文はお気に入りかを
  /// 自分では知らない。）
  final bool isFavorite;

  /// パラメータ定義: タップ時のコールバック
  final VoidCallback? onTap;

  /// パラメータ定義: お気に入り切り替え時のコールバック
  final VoidCallback? onFavoriteToggle;

  /// パラメータ定義: 編集時のコールバック
  final VoidCallback? onEdit;

  /// パラメータ定義: 削除時のコールバック
  final VoidCallback? onDelete;

  /// PhraseListItemを作成する
  const PhraseListItem({
    super.key,
    required this.phrase,
    required this.isFavorite,
    this.onTap,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Semantics設定: スクリーンリーダー対応
    return Semantics(
      label: phrase.content,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            // サイズ制約: 最小44px、推奨60pxのタップターゲット
            constraints: const BoxConstraints(
              minHeight: AppSizes.recommendedTapTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            child: Row(
              children: [
                // メインコンテンツ: 定型文テキスト
                Expanded(
                  child: Text(
                    phrase.content,
                    style: theme.textTheme.bodyLarge,
                    // テキストオーバーフロー: 長いテキストは省略
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                // お気に入りアイコン: お気に入り状態を表示・切り替え
                // 設計変更: Phase 3 / WP-2 / Stage 3a - 上位から渡された
                // isFavorite（favoriteProviderが正）で判定する
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                ),
                // 入力欄へボタン: 対応。タップ=即時読み上げのみだった
                // 定型文を、入力欄に入れて編集・AI変換する動線として追加する。
                SendToInputButton(text: phrase.content),
                // 編集アイコン: 定型文を編集
                if (onEdit != null)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onEdit,
                    tooltip: '編集',
                  ),
                // 削除アイコン: 定型文を削除
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onDelete,
                    tooltip: '削除',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
