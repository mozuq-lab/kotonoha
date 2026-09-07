/// AI変換状態クラス
library;

import '../domain/exceptions/ai_conversion_exception.dart';
import '../domain/models/politeness_level.dart';

/// AI変換の状態
/// 変換状態を管理（変換中、成功、エラー）
enum AIConversionStatus {
  /// 初期状態・アイドル
  idle,

  /// 変換中
  converting,

  /// 変換成功
  success,

  /// エラー
  error,
}

/// AI変換の状態を表す不変クラス
/// AI変換結果を表示し、採用・却下を選択可能。
/// 再生成または元の文を使用できる機能を提供。
class AIConversionState {
  /// 現在の状態
  final AIConversionStatus status;

  /// 変換元テキスト
  final String? originalText;

  /// 変換結果テキスト
  final String? convertedText;

  /// 使用した丁寧さレベル
  final PolitenessLevel? politenessLevel;

  /// エラー情報
  final AIConversionException? error;

  /// コンストラクタ
  const AIConversionState({
    this.status = AIConversionStatus.idle,
    this.originalText,
    this.convertedText,
    this.politenessLevel,
    this.error,
  });

  /// 変換中かどうか
  bool get isConverting => status == AIConversionStatus.converting;

  /// 結果があるかどうか
  bool get hasResult => status == AIConversionStatus.success;

  /// エラーがあるかどうか
  bool get hasError => status == AIConversionStatus.error;

  /// 初期状態
  static const AIConversionState initial = AIConversionState();

  /// copyWithメソッド
  AIConversionState copyWith({
    AIConversionStatus? status,
    String? originalText,
    String? convertedText,
    PolitenessLevel? politenessLevel,
    AIConversionException? error,
    bool clearOriginalText = false,
    bool clearConvertedText = false,
    bool clearPolitenessLevel = false,
    bool clearError = false,
  }) {
    return AIConversionState(
      status: status ?? this.status,
      originalText:
          clearOriginalText ? null : (originalText ?? this.originalText),
      convertedText:
          clearConvertedText ? null : (convertedText ?? this.convertedText),
      politenessLevel: clearPolitenessLevel
          ? null
          : (politenessLevel ?? this.politenessLevel),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIConversionState &&
        other.status == status &&
        other.originalText == originalText &&
        other.convertedText == convertedText &&
        other.politenessLevel == politenessLevel &&
        other.error == error;
  }

  @override
  int get hashCode =>
      Object.hash(status, originalText, convertedText, politenessLevel, error);

  @override
  String toString() {
    return 'AIConversionState(status: $status, originalText: $originalText, '
        'convertedText: $convertedText, politenessLevel: $politenessLevel, '
        'error: $error)';
  }
}
