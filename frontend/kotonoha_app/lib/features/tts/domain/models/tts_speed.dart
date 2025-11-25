/// TTS読み上げ速度の定義
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// 読み上げ速度の3段階（遅い/普通/速い）を定義
library;

/// TTS読み上げ速度
///
/// REQ-404: 読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない
enum TTSSpeed {
  /// 遅い（0.7倍速）
  slow,

  /// 普通（1.0倍速、デフォルト）
  normal,

  /// 速い（1.3倍速）
  fast,
}

/// TTSSpeed拡張メソッド
///
/// 各速度のdouble値を取得するためのゲッター
extension TTSSpeedExtension on TTSSpeed {
  /// 速度値を取得
  ///
  /// - slow: 0.7
  /// - normal: 1.0
  /// - fast: 1.3
  ///
  /// 参照: interfaces.dart（298-319行目）、requirements.md（148-158行目）
  double get value {
    switch (this) {
      case TTSSpeed.slow:
        return 0.7;
      case TTSSpeed.normal:
        return 1.0;
      case TTSSpeed.fast:
        return 1.3;
    }
  }
}
