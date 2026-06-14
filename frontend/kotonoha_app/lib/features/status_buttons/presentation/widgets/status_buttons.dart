/// StatusButtons ウィジェット
///
/// TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装
/// 要件: FR-002（ボタン数）、FR-007（グリッドレイアウト）、FR-008（ボタン間隔）
/// 信頼性レベル: 青信号（要件定義書ベース）
///
/// 状態ボタン8-12個をグリッド形式で表示するコンテナウィジェット。
/// 横4列のグリッドレイアウトで配置し、各ボタン間に適切な間隔を設ける。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_constants.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';
import 'package:kotonoha_app/features/status_buttons/presentation/widgets/status_button.dart';

/// 状態ボタンコンテナウィジェット
///
/// 「痛い」「トイレ」「暑い」等の状態ボタンを8-12個、
/// グリッド形式（横4列）で表示するコンテナ。
///
/// 使用例:
/// ```dart
/// StatusButtons(
///   onStatus: (type) => print('${type.label}がタップされました'),
///   onTTSSpeak: (text) => ttsService.speak(text),
/// )
/// ```
class StatusButtons extends StatelessWidget {
  /// 状態ボタンタップ時のコールバック
  final void Function(StatusButtonType type)? onStatus;

  /// TTS読み上げコールバック
  final void Function(String text)? onTTSSpeak;

  /// 表示するボタンのリスト（オプション）
  /// 指定しない場合は必須の8個を表示
  final List<StatusButtonType>? statusTypes;

  /// フォントサイズ設定（オプション）
  final FontSize? fontSize;

  /// StatusButtonsを作成する
  const StatusButtons({
    super.key,
    this.onStatus,
    this.onTTSSpeak,
    this.statusTypes,
    this.fontSize,
  });

  /// 表示するボタンリストを取得（デフォルトは必須の8個）
  List<StatusButtonType> get _displayTypes {
    return statusTypes ?? defaultStatusTypes;
  }

  @override
  Widget build(BuildContext context) {
    // 【AA対応】: GridView.countのchildAspectRatioが子のサイズを制約するため、
    // 各セルの高さが最小タップターゲット(44px)を下回らないようにaspectRatioを動的計算する。
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = StatusButtonConstants.gridColumns;
        const spacing = StatusButtonConstants.buttonSpacing;
        final cellWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        // セル高さ = max(セル幅, 44px)。幅が十分なら正方形(aspectRatio=1.0)、
        // 幅が狭い場合は高さを44pxに固定して横長セルにし、タップターゲットを確保する。
        const minHeight = AppSizes.minTapTarget;
        final cellHeight = cellWidth < minHeight ? minHeight : cellWidth;
        final aspectRatio = cellWidth > 0 ? cellWidth / cellHeight : 1.0;

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _displayTypes.map((type) {
            return StatusButton(
              statusType: type,
              onPressed: onStatus != null ? () => onStatus!(type) : null,
              onTTSSpeak: onTTSSpeak,
              fontSize: fontSize,
            );
          }).toList(),
        );
      },
    );
  }
}
