/// QuickResponseButtons ウィジェット
/// 「はい」「いいえ」「わからない」の3ボタンを横並びで表示するコンテナウィジェット。
/// ホーム画面上部に配置し、ユーザーが質問に即座に回答できるようにする。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/themes/button_tone.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_constants.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

/// クイック応答ボタンコンテナウィジェット
/// 3つのクイック応答ボタン（はい・いいえ・わからない）を横並びで表示。
/// 画面上部に常時表示
/// NFR-U002: 左から「はい」「いいえ」「わからない」の順序
/// 使用例
/// ```dart
/// QuickResponseButtons(
/// onResponse: (type) => handleResponse(type)
/// onTTSSpeak: (text) => ttsService.speak(text)
/// )
/// ```
class QuickResponseButtons extends StatefulWidget {
  /// 応答選択時のコールバック
  /// 選択されたQuickResponseTypeを引数として呼び出される
  final void Function(QuickResponseType type) onResponse;

  /// TTS読み上げコールバック（オプション）
  /// ボタンタップ時にラベルテキストを渡して呼び出される
  final void Function(String text)? onTTSSpeak;

  /// フォントサイズ設定（オプション）
  /// フォントサイズ設定への追従
  final FontSize? fontSize;

  /// ボタン間のスペース（オプション）
  /// 8px以上、デフォルト12px
  final double? spacing;

  /// ボタンの高さ（オプション）
  /// 指定しない場合は各QuickResponseButtonのデフォルト値（60px）を使用。
  /// 可視高さの乏しいレイアウト（スマホ縦持ち・横持ち）でのコンパクト化に使用。
  /// 44px未満に丸められることはない（QuickResponseButton側で保証）。
  final double? buttonHeight;
  final bool illustrated;

  /// QuickResponseButtonsを作成する
  const QuickResponseButtons({
    super.key,
    required this.onResponse,
    this.onTTSSpeak,
    this.fontSize,
    this.spacing,
    this.buttonHeight,
    this.illustrated = false,
  });

  @override
  State<QuickResponseButtons> createState() => _QuickResponseButtonsState();
}

class _QuickResponseButtonsState extends State<QuickResponseButtons>
    with DebounceMixin {
  /// ボタン間の間隔を取得（最小8px、デフォルト12px）
  double get _spacing {
    final requestedSpacing =
        widget.spacing ?? QuickResponseConstants.defaultButtonSpacing;
    return requestedSpacing < QuickResponseConstants.minButtonSpacing
        ? QuickResponseConstants.minButtonSpacing
        : requestedSpacing;
  }

  /// ボタン配置順序（左から: はい、いいえ、わからない）
  static const List<QuickResponseType> _buttonOrder = [
    QuickResponseType.yes,
    QuickResponseType.no,
    QuickResponseType.unknown,
  ];

  /// タップハンドラ（デバウンス付き）
  void _handleTap(QuickResponseType type) {
    // デバウンスチェック（DebounceMixinを使用）
    if (!checkDebounce()) return;

    // TTS読み上げコールバックを呼び出し
    widget.onTTSSpeak?.call(type.label);

    // onResponseコールバックを呼び出し
    widget.onResponse(type);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buttonOrder.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;

        final tone = widget.illustrated ? _tone(context, type) : null;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : _spacing / 2,
              right: index == _buttonOrder.length - 1 ? 0 : _spacing / 2,
            ),
            child: QuickResponseButton(
              responseType: type,
              onPressed: () => _handleTap(type),
              onTTSSpeak: null, // デバウンスはこのウィジェットで管理
              fontSize: widget.fontSize,
              height: widget.buttonHeight,
              showIcon: widget.illustrated,
              // 高コントラストは従来どおり（淡い面とテーマの縁・文字色の自動選択）
              backgroundColor: tone?.fill ??
                  (widget.illustrated
                      ? Color.lerp(Theme.of(context).colorScheme.surface,
                          QuickResponseButtonColors.getColor(type), 0.22)
                      : null),
              textColor: tone?.text,
              borderColor: tone?.border,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// はい・いいえは塗りで強く、わからないは落ち着いた面にする。
  /// 高コントラストは null（呼び出し側で従来どおりの色にする）。
  ButtonTone? _tone(BuildContext context, QuickResponseType type) {
    final scheme = Theme.of(context).colorScheme;
    final base = QuickResponseButtonColors.getColor(type);
    if (scheme.primary == Colors.black) return null;
    if (type == QuickResponseType.unknown) {
      return ButtonTone(
        fill: scheme.surfaceContainerLow,
        border: scheme.outline,
        text: scheme.onSurface,
      );
    }
    return ButtonTone.solid(base, scheme.brightness);
  }
}
