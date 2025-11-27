/// PhraseListWidget ウィジェット
///
/// TASK-0040: 定型文一覧UI実装
///
/// 定型文一覧を表示するメインウィジェット。
/// お気に入り優先表示、カテゴリ別分類、空状態表示を担当する。
/// ListView.builderを使用して大量データにも対応。
///
/// 関連要件:
/// - REQ-101: 定型文を一覧表示
/// - REQ-105: お気に入り定型文を一覧上部に優先表示
/// - REQ-106: 定型文を2-3種類のシンプルなカテゴリで分類
/// - NFR-004: 100件の定型文を1秒以内に表示
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_category_section.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_empty_state.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【機能概要】: 定型文一覧ウィジェット
/// 【実装方針】: お気に入り→カテゴリ別の順序でListView.builderを使用
/// 【テスト対応】: TC-040-001〜TC-040-010, TC-040-024〜TC-040-032
/// 🔵 信頼性レベル: 青信号 - REQ-101、REQ-105、REQ-106、NFR-004に基づく
///
/// 定型文をお気に入り優先・カテゴリ別に表示するリストウィジェット。
/// ListView.builderを使用して大量データにも対応する。
class PhraseListWidget extends StatelessWidget {
  /// 【パラメータ定義】: 表示する定型文リスト
  /// 🔵 信頼性レベル: 青信号 - 要件定義に基づく
  final List<PresetPhrase> phrases;

  /// 【パラメータ定義】: 定型文タップ時のコールバック
  /// 🔵 信頼性レベル: 青信号 - AC-004に基づく
  final void Function(PresetPhrase) onPhraseSelected;

  /// 【パラメータ定義】: お気に入り切り替え時のコールバック（任意）
  /// 🟡 信頼性レベル: 黄信号 - REQ-105から推測
  final void Function(PresetPhrase)? onFavoriteToggle;

  /// PhraseListWidgetを作成する
  const PhraseListWidget({
    super.key,
    required this.phrases,
    required this.onPhraseSelected,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 【空状態チェック】: 定型文が0件の場合は空状態を表示
    // 🔵 信頼性レベル: 青信号 - AC-005、EDGE-104に基づく
    if (phrases.isEmpty) {
      return const PhraseEmptyState();
    }

    // 【データ分類】: お気に入りとカテゴリ別に分類
    // 🔵 信頼性レベル: 青信号 - REQ-105、REQ-106に基づく
    final favorites = phrases.where((p) => p.isFavorite).toList();
    final dailyPhrases =
        phrases.where((p) => !p.isFavorite && p.category == 'daily').toList();
    final healthPhrases =
        phrases.where((p) => !p.isFavorite && p.category == 'health').toList();
    final otherPhrases =
        phrases.where((p) => !p.isFavorite && p.category == 'other').toList();

    // 【セクション構築】: 表示するセクションのリストを作成
    // 🔵 信頼性レベル: 青信号 - REQ-105（お気に入り優先）、REQ-106（カテゴリ分類）
    final sections = <Widget>[];

    // 【お気に入りセクション】: お気に入りが存在する場合のみ表示
    // 🔵 信頼性レベル: 青信号 - REQ-105に基づく
    if (favorites.isNotEmpty) {
      sections.add(_buildFavoriteSection(context, favorites));
    }

    // 【日常カテゴリセクション】: 空でない場合のみ表示
    // 🔵 信頼性レベル: 青信号 - REQ-106、EDGE-204に基づく
    if (dailyPhrases.isNotEmpty) {
      sections.add(
        PhraseCategorySection(
          category: 'daily',
          phrases: dailyPhrases,
          onPhraseSelected: onPhraseSelected,
          onFavoriteToggle: onFavoriteToggle,
        ),
      );
    }

    // 【体調カテゴリセクション】: 空でない場合のみ表示
    // 🔵 信頼性レベル: 青信号 - REQ-106、EDGE-204に基づく
    if (healthPhrases.isNotEmpty) {
      sections.add(
        PhraseCategorySection(
          category: 'health',
          phrases: healthPhrases,
          onPhraseSelected: onPhraseSelected,
          onFavoriteToggle: onFavoriteToggle,
        ),
      );
    }

    // 【その他カテゴリセクション】: 空でない場合のみ表示
    // 🔵 信頼性レベル: 青信号 - REQ-106、EDGE-204に基づく
    if (otherPhrases.isNotEmpty) {
      sections.add(
        PhraseCategorySection(
          category: 'other',
          phrases: otherPhrases,
          onPhraseSelected: onPhraseSelected,
          onFavoriteToggle: onFavoriteToggle,
        ),
      );
    }

    // 【リスト表示】: ListView.builderで効率的に描画
    // 🟡 信頼性レベル: 黄信号 - NFR-004（パフォーマンス）のための最適化
    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) => sections[index],
    );
  }

  /// 【機能概要】: お気に入りセクションを構築
  /// 【実装方針】: ヘッダー + アイテムリストをColumnで構築
  /// 【テスト対応】: TC-040-002、TC-040-008
  /// 🔵 信頼性レベル: 青信号 - REQ-105に基づく
  Widget _buildFavoriteSection(
    BuildContext context,
    List<PresetPhrase> favorites,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 【お気に入りヘッダー】: 「お気に入り」ラベル
        // 🔵 信頼性レベル: 青信号 - REQ-105に基づく
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
            vertical: AppSizes.paddingSmall,
          ),
          child: Text(
            'お気に入り',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        // 【お気に入りアイテムリスト】: お気に入り定型文を表示
        // 🔵 信頼性レベル: 青信号 - REQ-105に基づく
        ...favorites.map(
          (phrase) => PhraseListItem(
            phrase: phrase,
            onTap: () => onPhraseSelected(phrase),
            onFavoriteToggle: onFavoriteToggle != null
                ? () => onFavoriteToggle!(phrase)
                : null,
          ),
        ),
      ],
    );
  }
}
