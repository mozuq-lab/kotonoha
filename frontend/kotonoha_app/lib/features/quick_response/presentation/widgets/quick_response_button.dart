/// QuickResponseButton ウィジェット
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
/// 要件: FR-001（大ボタン表示）、FR-003（サイズ保証）、FR-101（TTS読み上げ）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// クイック応答用の大ボタンウィジェット。
/// タップ時にTTS読み上げを実行し、アクセシビリティ要件を満たす。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_constants.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

/// クイック応答ボタンの色定義
///
/// NFR-U003: 各ボタンの色分けは意味を反映
/// - はい: 青/緑系（肯定的）
/// - いいえ: 赤系（否定的）
/// - わからない: グレー系（中立）
class QuickResponseButtonColors {
  QuickResponseButtonColors._();

  /// 「はい」ボタンの背景色（緑系・濃いシェード）
  ///
  /// 白文字とのコントラスト比 約5.0:1（WCAG AA適合）。
  /// 旧 #4CAF50 は白文字で約2.8:1とAA不足だったため #2E7D32 に変更。
  static const Color yes = Color(0xFF2E7D32);

  /// 「いいえ」ボタンの背景色（赤系・濃いシェード）
  ///
  /// 白文字とのコントラスト比 約5.5:1（WCAG AA適合）。
  /// 旧 #E53935 は白文字で約3.9:1とAA不足だったため #C62828 に変更。
  static const Color no = Color(0xFFC62828);

  /// 「わからない」ボタンの背景色（グレー系・濃いシェード）
  ///
  /// 白文字とのコントラスト比 約6.4:1（WCAG AA適合）。
  /// 旧 #9E9E9E は白文字で約2.6:1とAA不足だったため #616161 に変更。
  static const Color unknown = Color(0xFF616161);

  /// タイプに応じた背景色を取得
  static Color getColor(QuickResponseType type) {
    switch (type) {
      case QuickResponseType.yes:
        return yes;
      case QuickResponseType.no:
        return no;
      case QuickResponseType.unknown:
        return unknown;
    }
  }
}

/// クイック応答ボタンウィジェット
///
/// 「はい」「いいえ」「わからない」のクイック応答用大ボタン。
/// アクセシビリティ要件（REQ-5001）に準拠した大きなタップターゲットを持つ。
///
/// 使用例:
/// ```dart
/// QuickResponseButton(
///   responseType: QuickResponseType.yes,
///   onPressed: () => print('はいがタップされました'),
///   onTTSSpeak: (text) => ttsService.speak(text),
/// )
/// ```
class QuickResponseButton extends StatefulWidget {
  /// 応答タイプ（yes/no/unknown）
  final QuickResponseType responseType;

  /// ボタンタップ時のコールバック
  /// nullの場合、ボタンは無効状態になる
  final VoidCallback? onPressed;

  /// TTS読み上げコールバック
  /// タップ時にラベルテキストを渡して呼び出される
  final void Function(String text)? onTTSSpeak;

  /// カスタム背景色（オプション）
  /// 指定しない場合はQuickResponseButtonColorsのデフォルト色を使用
  final Color? backgroundColor;

  /// カスタムテキスト色（オプション）
  /// 指定しない場合は白色を使用
  final Color? textColor;

  /// ボタンの幅（オプション）
  /// 指定しない場合はデフォルト値、最小44px保証
  final double? width;

  /// ボタンの高さ（オプション）
  /// 指定しない場合はデフォルト60px、最小44px保証
  final double? height;

  /// フォントサイズ設定（オプション）
  /// FR-007: フォントサイズ設定への追従
  final FontSize? fontSize;

  /// QuickResponseButtonを作成する
  const QuickResponseButton({
    super.key,
    required this.responseType,
    this.onPressed,
    this.onTTSSpeak,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  State<QuickResponseButton> createState() => _QuickResponseButtonState();
}

class _QuickResponseButtonState extends State<QuickResponseButton>
    with DebounceMixin {
  /// 実際に使用する高さを計算（最小44px保証）
  double get _effectiveHeight {
    final requestedHeight = widget.height ?? AppSizes.recommendedTapTarget;
    return requestedHeight < AppSizes.minTapTarget
        ? AppSizes.minTapTarget
        : requestedHeight;
  }

  /// 実際に使用する幅を計算（最小44px保証、デフォルト100px）
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
  String get _label => widget.responseType.label;

  /// 背景色を取得
  Color get _backgroundColor =>
      widget.backgroundColor ??
      QuickResponseButtonColors.getColor(widget.responseType);

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
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
            ),
            // 【スマホ幅対応】: 「わからない」等ラベルが長い場合、狭い幅
            // （スマホ幅でExpanded/Padding経由で圧縮される）で折り返し・
            // クリップが発生しないよう、FittedBox(scaleDown)+maxLines:1で
            // 縮小表示する。status_button.dartの対策と同方式。
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
