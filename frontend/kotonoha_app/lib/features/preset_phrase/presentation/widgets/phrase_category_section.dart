/// PhraseCategorySection ウィジェット
///
/// TASK-0040: 定型文一覧UI実装
///
/// カテゴリセクションを表示するウィジェット。
/// カテゴリヘッダーと、そのカテゴリに属する定型文を表示する。
///
/// 関連要件:
/// - REQ-106: 定型文を2-3種類のシンプルなカテゴリで分類
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【機能概要】: カテゴリセクションウィジェット
/// 【実装方針】: ヘッダー + アイテムリストの縦並びレイアウト
/// 【テスト対応】: TC-040-017〜TC-040-021
/// 🔵 信頼性レベル: 青信号 - REQ-106に基づく
///
/// カテゴリヘッダーと、そのカテゴリに属する定型文リストを表示する。
class PhraseCategorySection extends StatelessWidget {
  /// 【パラメータ定義】: カテゴリ識別子（'daily', 'health', 'other'）
  /// 🔵 信頼性レベル: 青信号 - REQ-106に基づく
  final String category;

  /// 【パラメータ定義】: このカテゴリに属する定型文リスト
  /// 🔵 信頼性レベル: 青信号 - 要件定義に基づく
  final List<PresetPhrase> phrases;

  /// 【パラメータ定義】: 定型文タップ時のコールバック
  /// 🔵 信頼性レベル: 青信号 - AC-004に基づく
  final void Function(PresetPhrase)? onPhraseSelected;

  /// 【パラメータ定義】: お気に入り切り替え時のコールバック
  /// 🟡 信頼性レベル: 黄信号 - REQ-105から推測
  final void Function(PresetPhrase)? onFavoriteToggle;

  /// PhraseCategorySectionを作成する
  const PhraseCategorySection({
    super.key,
    required this.category,
    required this.phrases,
    this.onPhraseSelected,
    this.onFavoriteToggle,
  });

  /// 【機能概要】: カテゴリ識別子を日本語表示名に変換
  /// 【実装方針】: switchで3カテゴリをマッピング
  /// 【テスト対応】: TC-040-018, TC-040-019, TC-040-020
  /// 🔵 信頼性レベル: 青信号 - REQ-106「日常」「体調」「その他」
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'daily':
        return '日常';
      case 'health':
        return '体調';
      case 'other':
        return 'その他';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = getCategoryDisplayName(category);

    // 【レイアウト実装】: ヘッダー + アイテムリストの縦並び
    // 🔵 信頼性レベル: 青信号 - REQ-106に基づく
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 【カテゴリヘッダー】: カテゴリ名を表示
        // 🔵 信頼性レベル: 青信号 - TC-040-017の要件
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
            vertical: AppSizes.paddingSmall,
          ),
          child: Text(
            displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        // 【定型文リスト】: カテゴリ内の定型文を表示
        // 🔵 信頼性レベル: 青信号 - TC-040-021の要件
        ...phrases.map(
          (phrase) => PhraseListItem(
            phrase: phrase,
            onTap: () => onPhraseSelected?.call(phrase),
            onFavoriteToggle: () => onFavoriteToggle?.call(phrase),
          ),
        ),
      ],
    );
  }
}
