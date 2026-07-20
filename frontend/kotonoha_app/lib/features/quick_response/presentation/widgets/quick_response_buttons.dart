/// QuickResponseButtons ウィジェット
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
/// 要件: FR-001（3ボタン表示）、FR-002（上部常時配置）、FR-005（間隔）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 「はい」「いいえ」「わからない」の3ボタンを横並びで表示するコンテナウィジェット。
/// ホーム画面上部に配置し、ユーザーが質問に即座に回答できるようにする。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_constants.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

/// クイック応答ボタンコンテナウィジェット
///
/// 3つのクイック応答ボタン（はい・いいえ・わからない）を横並びで表示。
/// REQ-201: 画面上部に常時表示
/// NFR-U002: 左から「はい」「いいえ」「わからない」の順序
///
/// 使用例:
/// ```dart
/// QuickResponseButtons(
///   onResponse: (type) => handleResponse(type),
///   onTTSSpeak: (text) => ttsService.speak(text),
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
  /// FR-007: フォントサイズ設定への追従
  final FontSize? fontSize;

  /// ボタン間のスペース（オプション）
  /// FR-005: 8px以上、デフォルト12px
  final double? spacing;

  /// ボタンの高さ（オプション）
  /// 指定しない場合は各QuickResponseButtonのデフォルト値（60px）を使用。
  /// 可視高さの乏しいレイアウト（スマホ縦持ち・横持ち）でのコンパクト化に使用。
  /// 44px未満に丸められることはない（QuickResponseButton側で保証）。
  final double? buttonHeight;

  /// QuickResponseButtonsを作成する
  const QuickResponseButtons({
    super.key,
    required this.onResponse,
    this.onTTSSpeak,
    this.fontSize,
    this.spacing,
    this.buttonHeight,
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
            ),
          ),
        );
      }).toList(),
    );
  }
}
