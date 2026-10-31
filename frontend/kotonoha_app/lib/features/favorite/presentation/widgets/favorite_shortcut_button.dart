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
    this.singleLine = false,
  });

  final Favorite favorite;
  final VoidCallback onPressed;
  final double height;
  final FontSize fontSize;

  /// 2 行に折らず、縮めても収まらない名前は「…」で切る。電話では文字盤の高さを
  /// 優先するため（全文は長押しのツールチップで見られる）。
  final bool singleLine;

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
  /// 大きさで 2 行にする。[singleLine] のときは [_minScaleSingleLine] まで縮め、
  /// それでも収まらなければ 1 行のまま「…」で切る。
  Widget _label(BuildContext context, TextStyle style, double maxWidth) {
    // ボタンが文字に付ける書式（字間など）も含めて、実際に描く書式で測る
    final effective = DefaultTextStyle.of(context).style.merge(style);
    double widthAt(double fontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: favorite.content,
          style: effective.copyWith(fontSize: fontSize),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final needed = widthAt(style.fontSize!);
    // 端数で折り返さないよう、わずかに余らせる
    final scale = needed <= maxWidth ? 1.0 : maxWidth / needed * 0.98;
    final shrunk = style.fontSize! * scale;
    // OS の文字の拡大は比例しないことがある（Android 14 以降）ので、縮めた大きさで
    // 測り直し、それでも収まらなければ「…」で切らずに元の大きさで 2 行にする
    if (singleLine) {
      final floor = scale < _minScaleSingleLine ? _minScaleSingleLine : scale;
      return Text(
        favorite.content,
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: floor < 1
            ? style.copyWith(fontSize: style.fontSize! * floor)
            : style,
      );
    }
    final oneLine =
        scale == 1 || (scale >= _minScale && widthAt(shrunk) <= maxWidth);
    return Text(
      favorite.content,
      maxLines: oneLine ? 1 : 2,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: oneLine && scale < 1 ? style.copyWith(fontSize: shrunk) : style,
    );
  }

  static const _minScale = 0.75;

  /// 文字「大」の電話で 5 文字の「ありがとう」が切れずに 1 行に入る下限
  static const _minScaleSingleLine = 0.65;
}
