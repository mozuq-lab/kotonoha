/// StatusButton ウィジェット
///
/// TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装
/// 要件: FR-001（状態ボタン表示）、FR-004（サイズ保証）、FR-101（TTS読み上げ）
/// 信頼性レベル: 青信号（要件定義書ベース）
///
/// 状態ボタン用のウィジェット。
/// タップ時にTTS読み上げを実行し、アクセシビリティ要件を満たす。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_constants.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_constants.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';

/// 状態ボタンウィジェット
///
/// 「痛い」「トイレ」「暑い」等の状態を伝えるボタン。
/// アクセシビリティ要件（REQ-5001）に準拠した44px以上のタップターゲットを持つ。
///
/// 使用例:
/// ```dart
/// StatusButton(
///   statusType: StatusButtonType.pain,
///   onPressed: () => print('痛いがタップされました'),
///   onTTSSpeak: (text) => ttsService.speak(text),
/// )
/// ```
class StatusButton extends StatefulWidget {
  /// 状態タイプ
  final StatusButtonType statusType;

  /// ボタンタップ時のコールバック
  /// nullの場合、ボタンは無効状態になる
  final VoidCallback? onPressed;

  /// TTS読み上げコールバック
  /// タップ時にラベルテキストを渡して呼び出される
  final void Function(String text)? onTTSSpeak;

  /// カスタム背景色（オプション）
  final Color? backgroundColor;

  /// カスタムテキスト色（オプション）
  final Color? textColor;

  /// ボタンの幅（オプション）
  final double? width;

  /// ボタンの高さ（オプション）
  final double? height;

  /// フォントサイズ設定（オプション）
  final FontSize? fontSize;

  /// StatusButtonを作成する
  const StatusButton({
    super.key,
    required this.statusType,
    this.onPressed,
    this.onTTSSpeak,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  State<StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<StatusButton> with DebounceMixin {
  /// 実際に使用する高さを計算（最小44px保証）
  double get _effectiveHeight {
    final requestedHeight =
        widget.height ?? StatusButtonConstants.defaultButtonSize;
    return requestedHeight < AppSizes.minTapTarget
        ? AppSizes.minTapTarget
        : requestedHeight;
  }

  /// 実際に使用する幅を計算（最小44px保証）
  double get _effectiveWidth {
    final requestedWidth =
        widget.width ?? QuickResponseConstants.defaultButtonWidth;
    return requestedWidth < AppSizes.minTapTarget
        ? AppSizes.minTapTarget
        : requestedWidth;
  }

  /// フォントサイズを取得
  double get _fontSize {
    switch (widget.fontSize ?? FontSize.medium) {
      case FontSize.small:
        return AppSizes.fontSizeSmall;
      case FontSize.medium:
        return AppSizes.fontSizeMedium;
      case FontSize.large:
        return AppSizes.fontSizeLarge;
    }
  }

  /// ボタンラベルを取得
  String get _label => widget.statusType.label;

  /// 背景色を取得
  Color get _backgroundColor =>
      widget.backgroundColor ?? StatusButtonColors.getColor(widget.statusType);

  /// テキスト色を取得
  Color get _textColor => widget.textColor ?? Colors.white;

  /// タップハンドラ（デバウンス付き）
  void _handleTap() {
    // デバウンスチェック（DebounceMixinを使用）
    if (!checkDebounce()) return;

    // TTS読み上げコールバックを呼び出し
    widget.onTTSSpeak?.call(_label);

    // onPressedコールバックを呼び出し
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      button: true,
      child: SizedBox(
        width: widget.width != null ? _effectiveWidth : null,
        height: _effectiveHeight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: _effectiveWidth,
            minHeight: _effectiveHeight,
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed != null ? _handleTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _backgroundColor,
              foregroundColor: _textColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
                vertical: AppSizes.paddingXSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            child: Text(
              _label,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
