import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/presentation/constants/favorite_colors.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

/// ホーム上部に並ぶお気に入りの即時読み上げボタン。
class FavoriteShortcutButton extends StatelessWidget {
  const FavoriteShortcutButton({
    super.key,
    required this.favorite,
    required this.onPressed,
    required this.height,
    required this.fontSize,
  });

  final Favorite favorite;
  final VoidCallback onPressed;
  final double height;
  final FontSize fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textSize = switch (fontSize) {
      FontSize.small => AppSizes.fontSizeSmall,
      FontSize.medium => AppSizes.fontSizeMedium,
      FontSize.large => AppSizes.fontSizeLarge,
    };
    final background = favoriteBackground(favorite, scheme);
    // 読み上げの名前は中の文字から付く。外に Semantics やツールチップの読み上げを
    // 重ねると、同じ文が 2 回読まれる（ツールチップは長押しで全文を見せるためだけ）
    return Tooltip(
      message: favorite.content,
      excludeFromSemantics: true,
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          key: Key('home_favorite_${favorite.id}'),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: favoriteForeground(favorite, scheme),
            side: favoriteBorder(favorite, scheme),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => _label(
              context,
              TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
              constraints.maxWidth,
            ),
          ),
        ),
      ),
    );
  }

  /// 電話の幅では 5 文字の「ありがとう」が「ありが／とう」と語の途中で折り返して
  /// いた（iPhone 17 Pro、2026-10-18）。1 行に収まらないときは文字を縮めて 1 行に
  /// する。縮めすぎると読めないので、[_minScale] でも収まらない長い名前は元の
  /// 大きさで 2 行にする。
  Widget _label(BuildContext context, TextStyle style, double maxWidth) {
    // ボタンが文字に付ける書式（字間など）も含めて、実際に描く書式で測る
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final painter = TextPainter(
      text: TextSpan(text: favorite.content, style: effective),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final needed = painter.width;
    painter.dispose();
    // 端数で折り返さないよう、わずかに余らせる
    final scale = needed <= maxWidth ? 1.0 : maxWidth / needed * 0.98;
    final oneLine = scale >= _minScale;
    return Text(
      favorite.content,
      maxLines: oneLine ? 1 : 2,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: oneLine && scale < 1
          ? style.copyWith(fontSize: style.fontSize! * scale)
          : style,
    );
  }

  static const _minScale = 0.75;
}
