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

  // 入力表示エリア (Input display area)
  // 標準レイアウトでの入力エリア最小高さ
  static const double inputAreaMinHeightStandard = 80.0;
  // コンパクトレイアウト（スマホ幅・低可視高さ）での入力エリア最小高さ
  static const double inputAreaMinHeightCompact = 60.0;
  // 入力エリアの最大高さ（可視画面高さに対する比率）。
  // 長文（最大1000文字）入力時に文字盤エリアを圧迫しないための上限。
  static const double inputAreaMaxHeightRatio = 0.2;

  // レスポンシブブレークポイント (Responsive breakpoints)
  // この幅未満はスマホ幅とみなし、コンパクトなレイアウトに切り替える
  static const double phoneMaxWidth = 600.0;
  // 可視高さ（Scaffold body）がこの値未満の場合、
  // 主に横持ちスマホを想定した2ペイン・コンパクトレイアウトに切り替える
  static const double compactHeightThreshold = 500.0;

  // クイック応答ボタン (Quick response button)
  // コンパクトレイアウトでのクイック応答ボタン高さ（44px以上を維持）
  static const double quickResponseButtonHeightCompact = 48.0;

  // 状態ボタン (Status buttons)
  // ホーム画面での横スクロールストリップの高さ。縦スペースを圧迫しないよう
  // 1行分（44px以上のタップターゲット + 余白）に収める。
  static const double statusButtonStripHeight = 56.0;
  // 状態ボタンストリップ内の各ボタンの幅
  static const double statusButtonStripItemWidth = 84.0;

  // 入力候補チップ行 (Input candidate chips)
  // 候補がない/入力が空のときは高さ0（行ごと非表示）になる。
  // 候補がある場合のみ、この高さの横スクロール1行を表示する。
  static const double inputCandidateRowHeight = 48.0;
  // 候補チップ1件あたりの最大幅の絶対上限。
  // 長文候補（履歴文など）でチップが際限なく伸び、後続候補が実質
  // 表示されなくなることを防ぐための上限（画面幅の約60%と比較し、
  // 小さい方が採用される）。
  static const double candidateChipMaxWidth = 280.0;

  // ダイアログボタン (Dialog buttons)
  static const double dialogButtonWidth = 120.0;
  static const double dialogButtonMinWidth = 100.0;

  // エレベーション (Elevation)
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
}
