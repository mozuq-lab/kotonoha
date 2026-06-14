/// AI変換APIクライアント
///
/// TASK-0067: AI変換APIクライアント実装
///
/// 信頼性レベル: 🔵 青信号（api-endpoints.mdベース）
/// 関連要件: REQ-901, REQ-902, REQ-903, REQ-904, NFR-002
library;

import 'package:dio/dio.dart';

import '../../domain/exceptions/ai_conversion_exception.dart';
import '../../domain/models/politeness_level.dart';
import '../models/ai_conversion_request.dart';
import '../models/ai_conversion_response.dart';

/// AI変換APIクライアント
///
/// バックエンドのAI変換API（/api/v1/ai/convert, /api/v1/ai/regenerate）
/// を呼び出すHTTPクライアント。
class AIConversionApiClient {
  /// Dioインスタンス
  final Dio dio;

  /// コンストラクタ
  ///
  /// [baseUrl] APIのベースURL（例: http://localhost:8000）
  AIConversionApiClient({
    required String baseUrl,
    String apiKey = '',
  }) : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
          },
        ));

  /// テスト用コンストラクタ（モックDioを注入）
  AIConversionApiClient.withDio(this.dio);

  /// AI変換を実行
  ///
  /// [inputText] 変換元テキスト（2文字以上500文字以下）
  /// [politenessLevel] 丁寧さレベル
  ///
  /// REQ-901: 短い入力を丁寧な文章に変換
  /// REQ-903: 丁寧さレベル3段階
  Future<AIConversionResponse> convert({
    required String inputText,
    required PolitenessLevel politenessLevel,
  }) async {
    try {
      final request = AIConversionRequest(
        inputText: inputText,
        politenessLevel: politenessLevel,
      );

      final response = await dio.post<dynamic>(
        '/api/v1/ai/convert',
        data: request.toJson(),
      );

      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// AI再変換を実行
  ///
  /// [inputText] 変換元テキスト
  /// [politenessLevel] 丁寧さレベル
  /// [previousResult] 前回の変換結果
  ///
  /// REQ-904: 再生成機能
  Future<AIConversionResponse> regenerate({
    required String inputText,
    required PolitenessLevel politenessLevel,
    required String previousResult,
  }) async {
    try {
      final request = AIRegenerateRequest(
        inputText: inputText,
        politenessLevel: politenessLevel,
        previousResult: previousResult,
      );

      final response = await dio.post<dynamic>(
        '/api/v1/ai/regenerate',
        data: request.toJson(),
      );

      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// レスポンスをパース
  AIConversionResponse _parseResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AIConversionException(
        code: 'INTERNAL_ERROR',
        message: 'サーバーからの応答が不正な形式です。',
      );
    }
    return AIConversionResponse.fromJson(data);
  }

  /// DioExceptionを適切なAIConversionExceptionに変換
  AIConversionException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AIConversionException(
          code: 'AI_API_TIMEOUT',
          message: 'AI変換APIがタイムアウトしました。しばらく時間をおいて再試行してください。',
        );

      case DioExceptionType.connectionError:
        return const AIConversionException(
          code: 'NETWORK_ERROR',
          message: 'ネットワーク接続を確認してください。',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);

      default:
        return const AIConversionException(
          code: 'AI_API_ERROR',
          message: 'AI変換APIでエラーが発生しました。',
        );
    }
  }

  /// HTTPエラーレスポンスを処理
  AIConversionException _handleBadResponse(Response<dynamic>? response) {
    if (response == null) {
      return const AIConversionException(
        code: 'AI_API_ERROR',
        message: 'AI変換APIからのレスポンスがありません。',
      );
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // エラーレスポンスからコードとメッセージを抽出
    String? errorCode;
    String? errorMessage;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        errorCode = error['code'] as String?;
        errorMessage = error['message'] as String?;
      } else if (error is String) {
        errorMessage = error;
        errorCode = data['error_code'] as String?;
      }
    }

    switch (statusCode) {
      case 401:
        return AIConversionException(
          code: errorCode ?? 'AUTHENTICATION_ERROR',
          message: errorMessage ?? 'AI変換APIの認証設定を確認してください。',
        );

      case 400:
      case 422:
        return AIConversionException(
          code: errorCode ?? 'VALIDATION_ERROR',
          message: errorMessage ?? '入力内容を確認してください。',
        );

      case 429:
        return AIConversionException(
          code: errorCode ?? 'RATE_LIMIT_EXCEEDED',
          message: errorMessage ?? 'リクエスト数が上限に達しました。1分後に再試行してください。',
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AIConversionException(
          code: errorCode ?? 'AI_API_ERROR',
          message: errorMessage ?? 'AI変換APIでエラーが発生しました。しばらく時間をおいて再試行してください。',
        );

      default:
        return AIConversionException(
          code: errorCode ?? 'AI_API_ERROR',
          message: errorMessage ?? 'AI変換APIでエラーが発生しました。',
        );
    }
  }
}
