/// 対面表示テキスト表示ウィジェット
/// テキストを画面中央に大きく表示する拡大表示モード
library;

import 'package:flutter/material.dart';

/// 対面表示用のテキスト表示ウィジェット
/// テキストを画面中央に大きく表示する。
/// 対面の相手がメッセージを読み取りやすいよう
/// 大きなフォントサイズでシンプルに表示する。
/// テキストを画面中央に大きく表示
class FaceToFaceTextDisplay extends StatelessWidget {
  /// 表示するテキスト
  final String text;

  /// フォントサイズ（オプション）
  /// 指定しない場合は、表示できる範囲に収まる最大の大きさ（36px 以上）にする
  final double? fontSize;

  /// FaceToFaceTextDisplayを作成
  /// [text] 表示するテキスト
  /// [fontSize] フォントサイズ（オプション、省略時は画面に合わせて自動）
  const FaceToFaceTextDisplay({
    super.key,
    required this.text,
    this.fontSize,
  });

  /// 自動で決めるときの最小・最大の文字の大きさ
  static const double minAutoFontSize = 36.0;
  static const double maxAutoFontSize = 240.0;

  /// 上下は左上・右上のボタン（上端から 16 + 56）と重ならないだけ空ける。
  /// 180 度回転しても同じになるよう上下を揃える。
  static const EdgeInsets _padding =
      EdgeInsets.symmetric(horizontal: 24.0, vertical: 88.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(fontWeight: FontWeight.w500);

    return Semantics(
      label: '対面表示テキスト: $text',
      child: Center(
        child: Padding(
          padding: _padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 指定が無ければ、画面に収まる最大の大きさにする（相手が離れていても読める）
              final effectiveFontSize = fontSize ??
                  _fitFontSize(
                    context,
                    baseStyle,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
              // 最小の大きさでも収まらないとき（長い文・大きな文字倍率）は
              // 切らずにスクロールで全文を見せる。収まるときは中央に置かれる
              return SingleChildScrollView(
                child: Text(
                  text,
                  style: baseStyle.copyWith(fontSize: effectiveFontSize),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// [maxWidth] × [maxHeight] に折り返して収まる最大の文字の大きさ
  double _fitFontSize(
    BuildContext context,
    TextStyle style,
    double maxWidth,
    double maxHeight,
  ) {
    if (!maxWidth.isFinite || !maxHeight.isFinite || text.isEmpty) {
      return minAutoFontSize;
    }
    final scaler = MediaQuery.textScalerOf(context);
    bool fits(double size, {bool singleLine = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      final ok = painter.height <= maxHeight &&
          (!singleLine || painter.computeLineMetrics().length == 1);
      painter.dispose();
      return ok;
    }

    // 1 行に 4 文字は入る大きさまでにする（2 文字ずつの折り返しは読みにくい）
    // （文字倍率で大きくなる分も含めて数える）
    final perChar = maxWidth / 4 / scaler.scale(1);
    final upper = perChar < maxAutoFontSize ? perChar : maxAutoFontSize;
    if (upper <= minAutoFontSize) return minAutoFontSize;

    double largest({bool singleLine = false}) {
      var low = minAutoFontSize;
      var high = upper;
      for (var i = 0; i < 12; i++) {
        final mid = (low + high) / 2;
        if (fits(mid, singleLine: singleLine)) {
          low = mid;
        } else {
          high = mid;
        }
      }
      return low.floorToDouble();
    }

    if (!fits(minAutoFontSize)) return minAutoFontSize;
    final any = largest();
    // 1 行に収まる大きさがそれほど小さくなければ、語の途中で折り返さない 1 行を選ぶ
    if (fits(minAutoFontSize, singleLine: true)) {
      final oneLine = largest(singleLine: true);
      if (oneLine >= any * 0.75) return oneLine;
    }
    return any;
  }
}
