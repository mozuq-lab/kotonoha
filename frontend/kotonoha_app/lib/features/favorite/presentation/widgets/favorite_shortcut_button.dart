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
    return Semantics(
      button: true,
      label: favorite.content,
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          key: Key('home_favorite_${favorite.id}'),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: favoriteBackground(favorite, scheme),
            foregroundColor: favoriteForeground(favorite, scheme),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              favorite.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
