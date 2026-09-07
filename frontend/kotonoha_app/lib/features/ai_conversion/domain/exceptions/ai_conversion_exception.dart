/// AI変換例外クラス
library;

/// AI変換処理で発生する例外
/// エラーコード一覧
/// AI_API_TIMEOUT: タイムアウト
/// AI_API_ERROR: APIエラー
/// NETWORK_ERROR: ネットワークエラー
/// RATE_LIMIT_EXCEEDED: レート制限超過
/// VALIDATION_ERROR: バリデーションエラー
/// INTERNAL_ERROR: 内部エラー
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
