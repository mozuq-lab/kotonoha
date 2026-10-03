/// 色付きボタンの「面・縁・文字」の 3 色を、元の色の色相から作る。
///
/// 元の色を背景に薄く混ぜると、どの色も同じ明るさの灰色寄りになり、
/// 縁も一律の灰色になる。ここでは色相ごとに知覚的に揃った明るさと鮮やかさ
/// （OKLCH）で 3 色を作り、縁と文字も同じ色相の濃い色にする。
///
/// 境界の基準（台帳 L-141 の決定）: 塗りが背景に 3:1 以上、または
/// 縁が背景と塗りの両方に 3:1 以上。文字は塗りに 4.5:1 以上。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ボタン 1 つ分の色
@immutable
class ButtonTone {
  /// 3 色を指定して作る。
  const ButtonTone({
    required this.fill,
    required this.border,
    required this.text,
  });

  /// 面
  final Color fill;

  /// 縁
  final Color border;

  /// 文字・アイコン
  final Color text;

  /// 淡い面に、同じ色相の縁と濃い文字（お気に入りなど、たくさん並ぶもの）。
  /// 灰色の元の色は無彩色のまま扱う。面の明るさは元の色の明るさに少し
  /// 寄せる（黄は明るく、青は濃く）。揃えすぎると淡い色同士が見分けにくい。
  factory ButtonTone.soft(Color base, Brightness brightness) {
    final (lightness, chroma, hue) = _toOklch(base);
    final neutral = chroma < 0.03;
    if (brightness == Brightness.dark) {
      return ButtonTone(
        fill: _fromOklch(0.22 + 0.18 * lightness, neutral ? 0.012 : 0.05, hue),
        border: _fromOklch(0.72, neutral ? 0.012 : 0.13, hue),
        text: _fromOklch(0.94, neutral ? 0.012 : 0.03, hue),
      );
    }
    return ButtonTone(
      fill: _fromOklch(0.80 + 0.15 * lightness, neutral ? 0.012 : 0.09, hue),
      border: _fromOklch(0.55, neutral ? 0.02 : 0.10, hue),
      text: _fromOklch(0.36, neutral ? 0.015 : 0.08, hue),
    );
  }

  /// 中間の濃さの塗りに白文字（縁は塗りと同じで、塗り自体が背景に 3:1 以上）。
  factory ButtonTone.solid(Color base, Brightness brightness) {
    final (_, chroma, hue) = _toOklch(base);
    final neutral = chroma < 0.03;
    final c = neutral ? 0.02 : 1.0;
    if (brightness == Brightness.dark) {
      final fill = _fromOklch(0.78, 0.10 * c, hue);
      return ButtonTone(
        fill: fill,
        border: fill,
        text: _fromOklch(0.22, 0.04 * c, hue),
      );
    }
    final fill = _fromOklch(0.50, 0.12 * c, hue);
    return ButtonTone(fill: fill, border: fill, text: Colors.white);
  }
}

/// 2 色の知覚的な差（OKLab のユークリッド距離。0.02 前後がほぼ見分けられない差）
@visibleForTesting
double perceptualDistance(Color a, Color b) {
  final (la, ca, ha) = _toOklch(a);
  final (lb, cb, hb) = _toOklch(b);
  final ra = ha * math.pi / 180;
  final rb = hb * math.pi / 180;
  final da = ca * math.cos(ra) - cb * math.cos(rb);
  final db = ca * math.sin(ra) - cb * math.sin(rb);
  return math.sqrt((la - lb) * (la - lb) + da * da + db * db);
}

// --- OKLCH（https://bottosson.github.io/posts/oklab/） ---

double _toLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _toGamma(double c) => c <= 0.0031308
    ? 12.92 * c
    : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;

(double, double, double) _toOklch(Color color) {
  final r = _toLinear(color.r);
  final g = _toLinear(color.g);
  final b = _toLinear(color.b);
  final l =
      math.pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1 / 3);
  final m =
      math.pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1 / 3);
  final s =
      math.pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1 / 3);
  final lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
  final a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
  final bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
  final chroma = math.sqrt(a * a + bb * bb);
  final hue = math.atan2(bb, a) * 180 / math.pi;
  return (lightness, chroma, hue);
}

/// 色域（sRGB）に収まらない鮮やかさは、色相と明るさを保ったまま下げる。
/// 成分ごとに切り詰めると色相がずれる（青が水色に寄る等）。
Color _fromOklch(double lightness, double chroma, double hue) {
  var rgb = _oklchToLinearRgb(lightness, chroma, hue);
  if (!_inGamut(rgb)) {
    var low = 0.0;
    var high = chroma;
    for (var i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      if (_inGamut(_oklchToLinearRgb(lightness, mid, hue))) {
        low = mid;
      } else {
        high = mid;
      }
    }
    rgb = _oklchToLinearRgb(lightness, low, hue);
  }
  double channel(double v) => _toGamma(v.clamp(0.0, 1.0)).clamp(0.0, 1.0);
  return Color.from(
    alpha: 1,
    red: channel(rgb.$1),
    green: channel(rgb.$2),
    blue: channel(rgb.$3),
  );
}

bool _inGamut((double, double, double) rgb) {
  const e = 1e-4;
  bool ok(double v) => v >= -e && v <= 1 + e;
  return ok(rgb.$1) && ok(rgb.$2) && ok(rgb.$3);
}

(double, double, double) _oklchToLinearRgb(
  double lightness,
  double chroma,
  double hue,
) {
  final h = hue * math.pi / 180;
  final a = chroma * math.cos(h);
  final b = chroma * math.sin(h);
  final l = math.pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3);
  final m = math.pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3);
  final s = math.pow(lightness - 0.0894841775 * a - 1.2914855480 * b, 3);
  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  );
}
