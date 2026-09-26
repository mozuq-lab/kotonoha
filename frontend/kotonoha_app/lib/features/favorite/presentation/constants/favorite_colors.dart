import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';

/// 利用者が選べる、文字のコントラストを確保したボタン色。
const favoriteColorChoices = <(String, int)>[
  ('オレンジ', 0xFFFF9800),
  ('青', 0xFF2196F3),
  ('緑', 0xFF4CAF50),
  ('黄', 0xFFFFD54F),
  ('紫', 0xFFB39DDB),
  ('灰', 0xFFB0BEC5),
];

/// 保存済みの色を変えず、ホームと一覧で同じ落ち着いた面色にする。
Color favoriteBackground(Favorite favorite, ColorScheme scheme) => Color.lerp(
      scheme.surface,
      favorite.colorValue == null
          ? scheme.primaryContainer
          : Color(favorite.colorValue!),
      0.22,
    )!;

Color favoriteForeground(Favorite favorite, ColorScheme scheme) =>
    bestContrastingTextColor(favoriteBackground(favorite, scheme));
