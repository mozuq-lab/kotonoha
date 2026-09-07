/// AI変換リクエストモデル
library;

import '../../domain/models/politeness_level.dart';

/// AI変換リクエスト
/// POST /api/v1/ai/convert へ送信するリクエストデータ
class AIConversionRequest {
  /// 変換元テキスト（2文字以上500文字以下）
  final String inputText;

  /// 丁寧さレベル
  final PolitenessLevel politenessLevel;

  /// コンストラクタ
  const AIConversionRequest({
    required this.inputText,
    required this.politenessLevel,
  });

  /// JSONへ変換
  /// API仕様に準拠したsnake_case形式でJSONを生成
  Map<String, dynamic> toJson() {
    return {
      'input_text': inputText,
      'politeness_level': politenessLevel.name,
    };
  }
}

/// AI再変換リクエスト
/// POST /api/v1/ai/regenerate へ送信するリクエストデータ
class AIRegenerateRequest {
  /// 変換元テキスト
  final String inputText;

  /// 丁寧さレベル
  final PolitenessLevel politenessLevel;

  /// 前回の変換結果（重複回避用）
  final String previousResult;

  /// コンストラクタ
  const AIRegenerateRequest({
    required this.inputText,
    required this.politenessLevel,
    required this.previousResult,
  });

  /// JSONへ変換
  /// API仕様に準拠したsnake_case形式でJSONを生成
  Map<String, dynamic> toJson() {
    return {
      'input_text': inputText,
      'politeness_level': politenessLevel.name,
      'previous_result': previousResult,
    };
  }
}
