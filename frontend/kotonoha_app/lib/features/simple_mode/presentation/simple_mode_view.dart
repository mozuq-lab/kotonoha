/// シンプルモード画面ウィジェット
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
/// 疲労時・症状進行時に、文字盤を使わずワンタップで意思を伝えられる
/// 大ボタンのみの簡易画面。
/// 表示内容
/// 「通常モードに戻る」明示ボタン（常にスクロールなしで到達できる位置に固定配置。
/// 誤タップで抜けられなくなることを防ぐため）
/// クイック応答（はい/いいえ/わからない）
/// お気に入り上位数件
/// 既存の [QuickResponseButtons] / [Favorite] を再利用し
/// 新規の重複実装を避ける。TTS読み上げ・履歴保存は呼び出し元
/// （HomeScreen）のコールバック経由で行うため、このウィジェット自体は
/// Riverpodに依存しないStatelessWidgetとして実装する（テスト容易性向上）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/simple_mode/domain/simple_mode_constants.dart';
import 'package:kotonoha_app/features/favorite/presentation/constants/favorite_colors.dart';

/// シンプルモード画面
class SimpleModeView extends StatelessWidget {
  /// フォントサイズ設定（設定画面の値に追従）
  final FontSize fontSize;

  /// お気に入り一覧（表示順は本ウィジェット内でdisplayOrder昇順に整列する）
  final List<Favorite> favorites;

  /// クイック応答タップ時のコールバック（履歴保存等に使用、TTSは含まない）
  final void Function(QuickResponseType type) onQuickResponse;

  /// お気に入りタップ時のコールバック（読み上げは呼び出し側の責務）
  final void Function(Favorite favorite) onFavoriteTap;

  /// TTS読み上げコールバック（クイック応答から呼ばれる）
  final void Function(String text) onTTSSpeak;

  /// 「通常モードに戻る」タップ時のコールバック
  final VoidCallback onExitSimpleMode;

  /// コンストラクタ
  const SimpleModeView({
    super.key,
    required this.fontSize,
    required this.favorites,
    required this.onQuickResponse,
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
          // 誤操作防止: スクロールしなくても常に到達できる位置に固定配置する。
          _buildExitButton(),
          const SizedBox(height: AppSizes.paddingMedium),
          // 空いた高さをボタンに配る（タブレットで下半分が空かないように）。
          // 足りない画面（電話の横持ち等）では下限の高さで組み、スクロールさせる。
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sizes = _SimpleModeSizes.of(constraints.maxHeight);
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle(context, 'クイック応答'),
                      const SizedBox(height: AppSizes.paddingSmall),
                      QuickResponseButtons(
                        onResponse: onQuickResponse,
                        onTTSSpeak: onTTSSpeak,
                        fontSize: fontSize,
                        buttonHeight: sizes.quickResponseHeight,
                        illustrated: true,
                      ),
                      if (topFavorites.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingLarge),
                        _buildSectionTitle(context, 'お気に入り'),
                        const SizedBox(height: AppSizes.paddingSmall),
                        _buildFavoritesGrid(topFavorites, sizes.favoriteHeight),
                      ],
                    ],
                  ),
                );
              },
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
          icon: const Icon(CupertinoIcons.keyboard),
          label: const Text(
            '通常モードに戻る',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid(List<Favorite> topFavorites, double cellHeight) {
    return GridView.builder(
      shrinkWrap: true,
      // 外側のSingleChildScrollViewが全体をスクロールするため
      // グリッド自体はスクロールを持たない。
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topFavorites.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: SimpleModeConstants.favoritesGridColumns,
        mainAxisExtent: cellHeight,
        crossAxisSpacing: SimpleModeConstants.favoritesGridSpacing,
        mainAxisSpacing: SimpleModeConstants.favoritesGridSpacing,
      ),
      itemBuilder: (context, index) {
        final favorite = topFavorites[index];
        return _FavoriteGridButton(
          key: Key('simple_mode_favorite_${favorite.id}'),
          favorite: favorite,
          fontSize: fontSize,
          height: cellHeight,
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
  final double height;
  final VoidCallback onTap;

  const _FavoriteGridButton({
    super.key,
    required this.favorite,
    required this.fontSize,
    required this.height,
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
          backgroundColor:
              favoriteBackground(favorite, Theme.of(context).colorScheme),
          foregroundColor:
              favoriteForeground(favorite, Theme.of(context).colorScheme),
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
            // 文字はボタンの高さに合わせて大きくする（設定の大きさが下限）
            style: TextStyle(
              fontSize: height * 0.26 > _fontSizeValue
                  ? height * 0.26
                  : _fontSizeValue,
            ),
          ),
        ),
      ),
    );
  }
}

/// シンプルモードのボタンの高さ。お気に入りが上限の件数まであっても
/// 1 画面に収まるように、空いた高さから決める。
class _SimpleModeSizes {
  const _SimpleModeSizes(this.quickResponseHeight, this.favoriteHeight);

  /// 見出し 2 つと間の余白の分（見出しの高さは文字の大きさで変わるので多めに取る）
  static const double _reserved = 120;

  factory _SimpleModeSizes.of(double availableHeight) {
    const rows = (SimpleModeConstants.maxFavoritesDisplayCount +
            SimpleModeConstants.favoritesGridColumns -
            1) ~/
        SimpleModeConstants.favoritesGridColumns;
    if (!availableHeight.isFinite) {
      return const _SimpleModeSizes(
        AppSizes.recommendedTapTarget,
        SimpleModeConstants.favoritesGridCellHeight,
      );
    }
    final quick = (availableHeight * 0.18)
        .clamp(AppSizes.recommendedTapTarget, 200.0)
        .toDouble();
    final favorite = ((availableHeight -
                _reserved -
                quick -
                SimpleModeConstants.favoritesGridSpacing * (rows - 1)) /
            rows)
        .clamp(SimpleModeConstants.favoritesGridCellHeight, 240.0)
        .toDouble();
    return _SimpleModeSizes(quick, favorite);
  }

  /// クイック応答ボタンの高さ
  final double quickResponseHeight;

  /// お気に入りボタン 1 つの高さ
  final double favoriteHeight;
}
