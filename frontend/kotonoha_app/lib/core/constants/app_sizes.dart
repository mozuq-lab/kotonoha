/// Application size constants
///
/// Defines sizes for tap targets, fonts, spacing, etc.
/// Following accessibility guidelines (REQ-5001, REQ-801)
class AppSizes {
  // Private constructor to prevent instantiation
  AppSizes._();

  // タップターゲット最小サイズ (REQ-5001: Minimum tap target size)
  // WCAG 2.1: Minimum 44x44 pixels for touch targets
  static const double minTapTarget = 44.0;

  // 推奨タップターゲットサイズ (Recommended tap target size)
  // For better accessibility, especially for large buttons and emergency button
  static const double recommendedTapTarget = 60.0;

  // フォントサイズ (REQ-801: Font size options - small/medium/large)
  static const double fontSizeSmall = 16.0;
  static const double fontSizeMedium = 20.0;
  static const double fontSizeLarge = 24.0;

  // 余白 (Spacing/Padding)
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // マージン (Margins)
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  // アイコンサイズ (Icon sizes)
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ボーダー半径 (Border radius)
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  // 文字盤関連 (Character board specific)
  static const double characterBoardButtonSize = 60.0;
  static const double characterBoardButtonSpacing = 8.0;

  // 入力欄 (Input field)
  static const double inputFieldHeight = 60.0;
  static const int maxInputLength = 1000;
}
