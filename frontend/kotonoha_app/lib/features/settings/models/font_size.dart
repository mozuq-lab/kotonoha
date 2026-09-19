/// 機能概要: フォントサイズ設定のenum定義
/// 実装方針: interfaces.dartで定義されたFontSize enumを再利用
library;

import 'package:kotonoha_app/core/constants/app_sizes.dart';

// 実装内容: フォントサイズの3段階（小・中・大）を定義
// アクセシビリティ要件として3段階のフォントサイズ選択を提供
enum FontSize {
  // 小サイズ: 視力が良好なユーザー向け
  // 3段階選択要件に基づく
  small('小'),

  // 中サイズ: デフォルトサイズ（最も一般的）
  // interfaces.dartのデフォルト値定義に基づく
  medium('中'),

  // 大サイズ: 視力が弱い高齢者・視覚障害者向け（アクセシビリティ対応）
  // アクセシビリティ要件に基づく
  large('大');

  // 表示名: UI上に表示するための日本語名
  // interfaces.dartの定義に基づく
  final String displayName;

  // コンストラクタ: enumの各値に表示名を関連付け
  const FontSize(this.displayName);
}

/// フォントサイズ設定をテーマの倍率に写す
/// 文字盤やボタンが使う明示サイズ（[AppSizes.fontSizeSmall] 等）と同じ比にする。
extension FontSizeScale on FontSize {
  /// テーマの textTheme に掛ける倍率（中 = 1.0）
  double get scaleFactor => switch (this) {
        FontSize.small => AppSizes.fontSizeSmall / AppSizes.fontSizeMedium,
        FontSize.medium => 1.0,
        FontSize.large => AppSizes.fontSizeLarge / AppSizes.fontSizeMedium,
      };
}
