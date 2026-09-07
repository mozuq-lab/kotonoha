/// TTS読み上げ速度の定義
/// 読み上げ速度の4段階（とても遅い/遅い/普通/速い）を定義
/// OS標準TTSエンジンの読み上げ速度を制御する列挙型。
library;

/// TTS読み上げ速度
/// 読み上げ速度を「とても遅い」「遅い」「普通」「速い」の4段階から選択できる
enum TTSSpeed {
  /// とても遅い（0.5倍速）
  verySlow,

  /// 遅い（0.7倍速）
  slow,

  /// 普通（1.0倍速、デフォルト）
  normal,

  /// 速い（1.3倍速）
  fast,
}

/// TTSSpeed拡張メソッド
/// flutter_tts用の速度値を取得する拡張。
extension TTSSpeedExtension on TTSSpeed {
  /// 速度値を取得
  double get value {
    switch (this) {
      case TTSSpeed.verySlow:
        // 聞き取りが難しいユーザー向け
        return 0.5;
      case TTSSpeed.slow:
        // 速度設定: 0.7倍速 - 聞き取りやすさを優先
        return 0.7;
      case TTSSpeed.normal:
        // 速度設定: 1.0倍速 - 標準的な読み上げ速度
        return 1.0;
      case TTSSpeed.fast:
        // 速度設定: 1.3倍速 - 効率的なコミュニケーション
        return 1.3;
    }
  }
}
