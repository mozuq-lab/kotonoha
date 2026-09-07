/// StatusButton ウィジェット
/// 状態ボタン用のウィジェット。
/// タップ時にTTS読み上げを実行し、アクセシビリティ要件を満たす。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_constants.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_constants.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';

/// 状態ボタンウィジェット
/// 「痛い」「トイレ」「暑い」等の状態を伝えるボタン。
/// アクセシビリティ要件に準拠した44px以上のタップターゲットを持つ。
/// 使用例
/// ```dart
/// StatusButton(
/// statusType: StatusButtonType.pain
/// onPressed:  => print('痛いがタップされました')
/// onTTSSpeak: (text) => ttsService.speak(text)
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
  /// AA対応: 背景はカテゴリ別の色（オレンジ／青／緑）なのに文字色を
  /// Colors.white 固定にしていたため、身体状態 2.16:1 / 要求 3.12:1
  /// 感情 2.78:1 といずれも WCAG AA(4.5:1) 未達だった。
  /// カテゴリ色は識別の手がかり（NFR-U003）なので変えず、実際の背景色の
  /// 輝度から黒・白のうちコントラスト比が高い方を選ぶ。
  Color get _textColor =>
      widget.textColor ?? bestContrastingTextColor(_backgroundColor);

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
            // AA対応: GridViewのセルがaspectRatio 1.0で子サイズを制約するため
            // largeフォント時にラベルがoverflowしないようFittedBoxで縮小し
            // それでも収まらない場合はellipsisで省略する。
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
