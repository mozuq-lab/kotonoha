/// LargeButton ウィジェット
///
/// TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）
/// 要件: REQ-5001（タップターゲット44px以上）、NFR-202（視認性・押しやすさ）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 大きなタップターゲットを持つ汎用ボタンウィジェット。
/// アクセシビリティ要件に準拠し、最小44px、推奨60pxのサイズを保証。
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 大ボタンウィジェット
///
/// アクセシビリティ要件（REQ-5001）に準拠した大きなタップターゲットを持つボタン。
/// デフォルトサイズは60x60px（推奨）、最小サイズは44x44px（WCAG準拠）。
///
/// 使用例:
/// ```dart
/// LargeButton(
///   label: '送信',
///   onPressed: () => print('送信ボタンがタップされました'),
/// )
/// ```
class LargeButton extends StatelessWidget {
  /// ボタンに表示するラベルテキスト
  final String label;

  /// ボタンタップ時のコールバック
  /// nullの場合、ボタンは無効状態になる
  final VoidCallback? onPressed;

  /// ボタンの背景色（オプション）
  /// 指定しない場合はテーマのプライマリカラーを使用
  final Color? backgroundColor;

  /// ボタンのテキスト色（オプション）
  /// 指定しない場合はテーマのforegroundColorを使用
  final Color? textColor;

  /// ボタンの幅（オプション）
  /// 指定しない場合はAppSizes.recommendedTapTarget（60px）
  /// 44px未満を指定した場合は44pxに補正される
  final double? width;

  /// ボタンの高さ（オプション）
  /// 指定しない場合はAppSizes.recommendedTapTarget（60px）
  /// 44px未満を指定した場合は44pxに補正される
  final double? height;

  /// LargeButtonを作成する
  ///
  /// [label] - ボタンに表示するテキスト（必須）
  /// [onPressed] - タップ時のコールバック（nullで無効化）
  /// [backgroundColor] - 背景色（オプション）
  /// [textColor] - テキスト色（オプション）
  /// [width] - 幅（オプション、最小44px）
  /// [height] - 高さ（オプション、最小44px）
  const LargeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 最小サイズを保証（REQ-5001: 44px以上）
    final effectiveWidth = math.max(
      width ?? AppSizes.recommendedTapTarget,
      AppSizes.minTapTarget,
    );
    final effectiveHeight = math.max(
      height ?? AppSizes.recommendedTapTarget,
      AppSizes.minTapTarget,
    );

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
          padding: const EdgeInsets.all(0),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
