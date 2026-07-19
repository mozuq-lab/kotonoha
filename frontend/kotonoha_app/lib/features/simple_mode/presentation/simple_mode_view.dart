/// シンプルモード画面ウィジェット
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
///
/// 疲労時・症状進行時に、文字盤を使わずワンタップで意思を伝えられる
/// 大ボタンのみの簡易画面。
///
/// 表示内容:
/// - 「通常モードに戻る」明示ボタン（常にスクロールなしで到達できる位置に固定配置。
///   誤タップで抜けられなくなることを防ぐため）
/// - クイック応答（はい/いいえ/わからない）
/// - 状態ボタン12個（全ボタン: [allStatusTypes]）
/// - お気に入り上位数件
///
/// 既存の [QuickResponseButtons] / [StatusButtons] / [Favorite] を再利用し、
/// 新規の重複実装を避ける。TTS読み上げ・履歴保存は呼び出し元
/// （HomeScreen）のコールバック経由で行うため、このウィジェット自体は
/// Riverpodに依存しないStatelessWidgetとして実装する（テスト容易性向上）。
///
/// 🟡 信頼性レベル: 黄信号 - 要件定義書にない新規機能のため妥当な推測
library;

import 'package:flutter/material.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/simple_mode/domain/simple_mode_constants.dart';
import 'package:kotonoha_app/features/status_buttons/status_buttons.dart';

/// シンプルモード画面
class SimpleModeView extends StatelessWidget {
  /// フォントサイズ設定（設定画面の値に追従）
  final FontSize fontSize;

  /// お気に入り一覧（表示順は本ウィジェット内でdisplayOrder昇順に整列する）
  final List<Favorite> favorites;

  /// クイック応答タップ時のコールバック（履歴保存等に使用、TTSは含まない）
  final void Function(QuickResponseType type) onQuickResponse;

  /// 状態ボタンタップ時のコールバック（履歴保存等に使用、TTSは含まない）
  final void Function(StatusButtonType type) onStatusButton;

  /// お気に入りタップ時のコールバック（読み上げは呼び出し側の責務）
  final void Function(Favorite favorite) onFavoriteTap;

  /// TTS読み上げコールバック（クイック応答・状態ボタンから呼ばれる）
  final void Function(String text) onTTSSpeak;

  /// 「通常モードに戻る」タップ時のコールバック
  final VoidCallback onExitSimpleMode;

  /// コンストラクタ
  const SimpleModeView({
    super.key,
    required this.fontSize,
    required this.favorites,
    required this.onQuickResponse,
    required this.onStatusButton,
    required this.onFavoriteTap,
    required this.onTTSSpeak,
    required this.onExitSimpleMode,
  });

  @override
  Widget build(BuildContext context) {
    final sortedFavorites = List<Favorite>.from(favorites)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final topFavorites = sortedFavorites
        .take(SimpleModeConstants.maxFavoritesDisplayCount)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 【誤操作防止】: スクロールしなくても常に到達できる位置に固定配置する。
          _buildExitButton(),
          const SizedBox(height: AppSizes.paddingMedium),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(context, 'クイック応答'),
                  const SizedBox(height: AppSizes.paddingSmall),
                  QuickResponseButtons(
                    onResponse: onQuickResponse,
                    onTTSSpeak: onTTSSpeak,
                    fontSize: fontSize,
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  _buildSectionTitle(context, '状態'),
                  const SizedBox(height: AppSizes.paddingSmall),
                  StatusButtons(
                    statusTypes: allStatusTypes,
                    onStatus: onStatusButton,
                    onTTSSpeak: onTTSSpeak,
                    fontSize: fontSize,
                  ),
                  if (topFavorites.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.paddingLarge),
                    _buildSectionTitle(context, 'お気に入り'),
                    const SizedBox(height: AppSizes.paddingSmall),
                    _buildFavoritesGrid(topFavorites),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildExitButton() {
    return Semantics(
      button: true,
      label: '通常モードに戻る',
      child: SizedBox(
        height: AppSizes.recommendedTapTarget,
        child: ElevatedButton.icon(
          key: const Key('exit_simple_mode_button'),
          onPressed: onExitSimpleMode,
          icon: const Icon(Icons.keyboard_alt_outlined),
          label: const Text(
            '通常モードに戻る',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid(List<Favorite> topFavorites) {
    return GridView.builder(
      shrinkWrap: true,
      // 外側のSingleChildScrollViewが全体をスクロールするため、
      // グリッド自体はスクロールを持たない。
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topFavorites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: SimpleModeConstants.favoritesGridColumns,
        mainAxisExtent: SimpleModeConstants.favoritesGridCellHeight,
        crossAxisSpacing: SimpleModeConstants.favoritesGridSpacing,
        mainAxisSpacing: SimpleModeConstants.favoritesGridSpacing,
      ),
      itemBuilder: (context, index) {
        final favorite = topFavorites[index];
        return _FavoriteGridButton(
          key: Key('simple_mode_favorite_${favorite.id}'),
          favorite: favorite,
          fontSize: fontSize,
          onTap: () => onFavoriteTap(favorite),
        );
      },
    );
  }
}

/// お気に入り用の大きなグリッドボタン（シンプルモード専用）
class _FavoriteGridButton extends StatelessWidget {
  final Favorite favorite;
  final FontSize fontSize;
  final VoidCallback onTap;

  const _FavoriteGridButton({
    super.key,
    required this.favorite,
    required this.fontSize,
    required this.onTap,
  });

  double get _fontSizeValue {
    switch (fontSize) {
      case FontSize.small:
        return AppSizes.fontSizeSmall;
      case FontSize.medium:
        return AppSizes.fontSizeMedium;
      case FontSize.large:
        return AppSizes.fontSizeLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: favorite.content,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            favorite.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: _fontSizeValue),
          ),
        ),
      ),
    );
  }
}
