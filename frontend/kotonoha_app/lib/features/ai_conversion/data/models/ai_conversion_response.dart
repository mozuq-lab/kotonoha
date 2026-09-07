/// AI変換レスポンスモデル
library;

import '../../domain/models/politeness_level.dart';

/// AI変換レスポンス
/// POST /api/v1/ai/convert のレスポンスデータ
class AIConversionResponse {
  /// 変換後のテキスト
  final String convertedText;

  /// 変換元のテキスト
  final String originalText;

  /// 使用した丁寧さレベル
  final PolitenessLevel politenessLevel;

  /// 処理時間（ミリ秒）
  final int processingTimeMs;

  /// コンストラクタ
  const AIConversionResponse({
    required this.convertedText,
    required this.originalText,
    required this.politenessLevel,
    required this.processingTimeMs,
  });

  /// JSONから変換
  /// API仕様のsnake_case形式からcamelCaseへ変換
  factory AIConversionResponse.fromJson(Map<String, dynamic> json) {
    return AIConversionResponse(
      convertedText: json['converted_text'] as String,
      originalText: json['original_text'] as String,
      politenessLevel: PolitenessLevel.values.firstWhere(
        (e) => e.name == json['politeness_level'],
      ),
      processingTimeMs: json['processing_time_ms'] as int,
    );
  }
}
