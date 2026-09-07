/// StatusButton 定数定義
/// 状態ボタン機能で使用する定数を一元管理。
/// グリッドレイアウト設定、色定義などの設定値を定義。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';

/// 状態ボタン機能の定数
/// グリッドレイアウト、ボタン間隔などの設定値を管理。
class StatusButtonConstants {
  StatusButtonConstants._();

  /// グリッド列数（縦向き）
  /// 横4列のグリッドレイアウト
  static const int gridColumns = 4;

  /// ボタン間隔（最小4px、推奨8px）
  /// 各ボタン間に適切な間隔
  static const double buttonSpacing = 8.0;

  /// デフォルトボタンサイズ
  /// 44px以上のタップターゲット（推奨52px）
  static const double defaultButtonSize = 52.0;
}

/// 状態ボタンの色定義
/// NFR-U003: カテゴリ別の色分け
/// 身体状態（痛い、暑い、寒い、眠い）: オレンジ系
/// 要求（トイレ、水、助けて、待って）: 青系
/// 感情（ありがとう、ごめんなさい、大丈夫、もう一度）: 緑系
/// 文字色について: ここで定義するのは**背景色のみ**。
/// 文字色は固定せず、StatusButton 側で背景輝度から
/// `bestContrastingTextColor` により選ぶ。いずれの色も白文字では
/// WCAG AA(4.5:1) を満たせない（2.16〜3.12:1）ため。
class StatusButtonColors {
  StatusButtonColors._();

  /// 身体状態（痛い、暑い、寒い、眠い）: オレンジ系
  /// 黒文字で 9.74:1（白文字では 2.16:1 でAA未達）。
  static const Color physical = Color(0xFFFF9800);

  /// 要求（トイレ、水、助けて、待って）: 青系
  /// 黒文字で 6.72:1（白文字では 3.12:1 でAA未達）。
  static const Color request = Color(0xFF2196F3);

  /// 感情・コミュニケーション（もう一度、ありがとう、ごめんなさい、大丈夫）: 緑系
  /// 黒文字で 7.56:1（白文字では 2.78:1 でAA未達）。
  static const Color emotion = Color(0xFF4CAF50);

  /// タイプに応じた背景色を取得
  /// [type] に基づいてカテゴリ別の色を返す。
  /// 身体状態: オレンジ系 [physical]
  /// 要求: 青系 [request]
  /// 感情・コミュニケーション: 緑系 [emotion]
  static Color getColor(StatusButtonType type) {
    switch (type) {
      // 身体状態: オレンジ系
      case StatusButtonType.pain:
      case StatusButtonType.hot:
      case StatusButtonType.cold:
      case StatusButtonType.sleepy:
        return physical;
      // 要求: 青系
      case StatusButtonType.toilet:
      case StatusButtonType.water:
      case StatusButtonType.help:
      case StatusButtonType.wait:
        return request;
      // 感情・コミュニケーション: 緑系
      case StatusButtonType.again:
      case StatusButtonType.thanks:
      case StatusButtonType.sorry:
      case StatusButtonType.okay:
        return emotion;
    }
  }
}

/// デフォルトの必須8ボタン
/// 8-12個の固定文言として提供
/// デフォルトでは必須の8個を表示。
const List<StatusButtonType> defaultStatusTypes = [
  StatusButtonType.pain,
  StatusButtonType.toilet,
  StatusButtonType.hot,
  StatusButtonType.cold,
  StatusButtonType.water,
  StatusButtonType.sleepy,
  StatusButtonType.help,
  StatusButtonType.wait,
];

/// オプションの追加4ボタン
/// 必要に応じて追加できるオプションボタン。
const List<StatusButtonType> optionalStatusTypes = [
  StatusButtonType.again,
  StatusButtonType.thanks,
  StatusButtonType.sorry,
  StatusButtonType.okay,
];

/// 全12ボタン（必須8 + オプション4）
/// 全ての状態ボタンを表示する場合に使用。
const List<StatusButtonType> allStatusTypes = [
  ...defaultStatusTypes,
  ...optionalStatusTypes,
];
