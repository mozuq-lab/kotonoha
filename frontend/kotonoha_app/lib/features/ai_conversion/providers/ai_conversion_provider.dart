/// AI変換Provider・状態管理
///
/// TASK-0070: AI変換Provider・状態管理
///
/// 信頼性レベル: 🔵 青信号（interfaces.dartベース）
/// 関連要件: REQ-901, REQ-902, REQ-903, REQ-904
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/providers/network_provider.dart';
import '../data/api/ai_conversion_api_client.dart';
import '../domain/exceptions/ai_conversion_exception.dart';
import '../domain/models/politeness_level.dart';
import 'ai_conversion_state.dart';

/// AI変換APIクライアントのProvider
///
/// 環境変数からベースURLを取得（デフォルト: localhost:8000）
final aiConversionApiClientProvider = Provider<AIConversionApiClient>((ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  const apiKey = String.fromEnvironment('AI_API_KEY');
  final client = AIConversionApiClient(baseUrl: baseUrl, apiKey: apiKey);
  // Provider破棄時にDioの接続リソースを解放（リソースリーク防止）
  ref.onDispose(client.dio.close);
  return client;
});

/// AI変換Providerの定義
///
/// REQ-901〜REQ-904: AI変換機能の状態管理
final aiConversionProvider =
    NotifierProvider<AIConversionNotifier, AIConversionState>(
  AIConversionNotifier.new,
);

/// AI変換の状態管理Notifier
///
/// REQ-901: 短い入力をより丁寧で自然な文章に変換
/// REQ-902: AI変換結果を表示し、採用・却下を選択可能
/// REQ-903: 丁寧さレベルを3段階から選択可能
/// REQ-904: 再生成または元の文を使用できる機能を提供
class AIConversionNotifier extends Notifier<AIConversionState> {
  /// 初期状態
  @override
  AIConversionState build() => AIConversionState.initial;

  /// APIクライアントを取得
  AIConversionApiClient get _apiClient =>
      ref.read(aiConversionApiClientProvider);

  /// ネットワーク状態Notifierを取得
  NetworkNotifier get _networkNotifier => ref.read(networkProvider.notifier);

  /// AI変換を実行
  ///
  /// [inputText] 変換対象テキスト（2文字以上）
  /// [politenessLevel] 丁寧さレベル
  ///
  /// REQ-901: 短い入力をより丁寧で自然な文章に変換
  /// REQ-903: 丁寧さレベルを3段階から選択可能
  /// REQ-1001, REQ-3004: オフライン時はエラー
  Future<void> convert({
    required String inputText,
    required PolitenessLevel politenessLevel,
  }) async {
    // ネットワーク状態チェック
    if (!_networkNotifier.isAIConversionAvailable) {
      state = state.copyWith(
        status: AIConversionStatus.error,
        originalText: inputText,
        politenessLevel: politenessLevel,
        error: const AIConversionException(
          code: 'NETWORK_ERROR',
          message: 'ネットワーク接続を確認してください。',
        ),
      );
      return;
    }

    // 変換中状態に遷移
    state = state.copyWith(
      status: AIConversionStatus.converting,
      originalText: inputText,
      politenessLevel: politenessLevel,
      clearConvertedText: true,
      clearError: true,
    );

    try {
      // API呼び出し
      final response = await _apiClient.convert(
        inputText: inputText,
        politenessLevel: politenessLevel,
      );

      // 成功状態に遷移
      state = state.copyWith(
        status: AIConversionStatus.success,
        convertedText: response.convertedText,
      );
    } on AIConversionException catch (e) {
      // エラー状態に遷移
      state = state.copyWith(
        status: AIConversionStatus.error,
        error: e,
      );
    } catch (e) {
      // 予期しないエラー
      state = state.copyWith(
        status: AIConversionStatus.error,
        error: AIConversionException(
          code: 'INTERNAL_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  /// 再生成を実行
  ///
  /// 前回の変換情報を使用して再変換を実行
  ///
  /// REQ-904: 再生成機能
  Future<void> regenerate() async {
    // 前回の変換結果がない場合は何もしない
    if (state.originalText == null ||
        state.convertedText == null ||
        state.politenessLevel == null) {
      return;
    }

    final originalText = state.originalText!;
    final politenessLevel = state.politenessLevel!;
    final previousResult = state.convertedText!;

    // ネットワーク状態チェック
    if (!_networkNotifier.isAIConversionAvailable) {
      state = state.copyWith(
        status: AIConversionStatus.error,
        error: const AIConversionException(
          code: 'NETWORK_ERROR',
          message: 'ネットワーク接続を確認してください。',
        ),
      );
      return;
    }

    // 変換中状態に遷移
    state = state.copyWith(
      status: AIConversionStatus.converting,
      clearError: true,
    );

    try {
      // API呼び出し（再生成）
      final response = await _apiClient.regenerate(
        inputText: originalText,
        politenessLevel: politenessLevel,
        previousResult: previousResult,
      );

      // 成功状態に遷移
      state = state.copyWith(
        status: AIConversionStatus.success,
        convertedText: response.convertedText,
      );
    } on AIConversionException catch (e) {
      // エラー状態に遷移
      state = state.copyWith(
        status: AIConversionStatus.error,
        error: e,
      );
    } catch (e) {
      // 予期しないエラー
      state = state.copyWith(
        status: AIConversionStatus.error,
        error: AIConversionException(
          code: 'INTERNAL_ERROR',
          message: e.toString(),
        ),
      );
    }
  }

  /// 状態をクリア
  ///
  /// 初期状態に戻す
  void clear() {
    state = AIConversionState.initial;
  }
}
