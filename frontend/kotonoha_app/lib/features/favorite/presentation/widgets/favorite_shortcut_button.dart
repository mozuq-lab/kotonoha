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
          child: Text(
            favorite.content,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
