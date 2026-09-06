/// テーマ依存の配色セレクタ
///
/// 要件: REQ-803（テーマ設定）、REQ-5006（WCAG 2.1 AA準拠）
/// 信頼性レベル: 青信号 - 要件定義書ベース
///
/// 「自前の背景を持たず、テーマの surface に直接載る」要素の色を
/// テーマの明暗に応じて選ぶためのヘルパー群。
/// 固定色を使うとライト・ダークの一方で必ずコントラストが不足するため、
/// この層で切り替える。
///
/// 置き場所について: 以前は core/widgets/error_dialog.dart に同居していたが、
/// 色を1つ使うためだけに feature 側からダイアログ実装を import する形に
/// なっていたため、テーマ層に移した。
library;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// テーマの明暗に応じた警告アイコン色を返す
///
/// テーマの surface に直接載るアイコン（オフライン・AI変換不可・音量ゼロなど）
/// に使う。非テキスト基準 3:1 に対し、
/// ライト 5.44:1 / ダーク 9.63:1 / 高コントラスト 5.93:1。
Color warningIconColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppColors.warningIconDark
        : AppColors.warningIcon;
