import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/themes/app_visual_theme.dart';

/// ホームを単独で描画する場合も、全画面と同じテーマを適用する。
ThemeData homeTheme(ThemeData base, {required bool highContrast}) {
  return appVisualTheme(base, highContrast: highContrast);
}
