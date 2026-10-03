import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/themes/button_tone.dart';
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

bool _isHighContrast(ColorScheme scheme) => scheme.primary == Colors.black;

/// 保存済みの色を変えず、色相から面・縁・文字を作る。高コントラストは従来どおり。
ButtonTone? favoriteTone(Favorite favorite, ColorScheme scheme) {
  if (_isHighContrast(scheme)) return null;
  final base = favorite.colorValue == null
      ? scheme.primary
      : Color(favorite.colorValue!);
  return ButtonTone.soft(base, scheme.brightness);
}

Color favoriteBackground(Favorite favorite, ColorScheme scheme) =>
    favoriteTone(favorite, scheme)?.fill ??
    Color.lerp(
      scheme.surface,
      favorite.colorValue == null
          ? scheme.primaryContainer
          : Color(favorite.colorValue!),
      0.22,
    )!;

Color favoriteForeground(Favorite favorite, ColorScheme scheme) =>
    favoriteTone(favorite, scheme)?.text ??
    bestContrastingTextColor(favoriteBackground(favorite, scheme));

/// 縁。null ならテーマの縁（高コントラスト）
BorderSide? favoriteBorder(Favorite favorite, ColorScheme scheme) {
  final tone = favoriteTone(favorite, scheme);
  return tone == null ? null : BorderSide(color: tone.border);
}
