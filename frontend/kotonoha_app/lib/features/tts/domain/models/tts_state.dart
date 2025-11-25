/// TTS読み上げ状態の定義
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// 読み上げの状態遷移を管理
library;

/// TTS読み上げ状態
///
/// 参照: requirements.md（168-176行目）
enum TTSState {
  /// アイドル状態（初期状態、読み上げ完了後）
  idle,

  /// 読み上げ中
  speaking,

  /// 停止
  stopped,

  /// 完了
  completed,

  /// エラー
  error,
}
