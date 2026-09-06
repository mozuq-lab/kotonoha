/// AI変換例外クラス
///
/// TASK-0067: AI変換APIクライアント実装
/// TDD Redフェーズ: スタブファイル
///
/// 信頼性レベル: 青信号（api-endpoints.mdベース）
/// 関連要件: EDGE-001, EDGE-002
library;

/// AI変換処理で発生する例外
///
/// エラーコード一覧:
/// - AI_API_TIMEOUT: タイムアウト
/// - AI_API_ERROR: APIエラー
/// - NETWORK_ERROR: ネットワークエラー
/// - RATE_LIMIT_EXCEEDED: レート制限超過
/// - VALIDATION_ERROR: バリデーションエラー
/// - INTERNAL_ERROR: 内部エラー
class AIConversionException implements Exception {
  /// エラーコード
  final String code;

  /// エラーメッセージ
  final String message;

  /// コンストラクタ
  const AIConversionException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'AIConversionException: $code - $message';
}
