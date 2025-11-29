/// モックAPIサーバー設定
///
/// TASK-0081: E2Eテスト環境構築
/// 信頼性レベル: 🟡 黄信号（テスト戦略は要件定義書から推測）
///
/// AI変換APIのモックレスポンスを提供。
library;

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// モックAPIサーバー
///
/// E2Eテスト用のAI変換APIモックを提供。
class MockApiServer {
  /// モックアダプターを作成
  ///
  /// [dio]: Dioインスタンス
  static DioAdapter createMockAdapter(Dio dio) {
    final dioAdapter = DioAdapter(dio: dio);

    // AI変換APIのモック
    _setupAIConversionMock(dioAdapter);

    // ヘルスチェックAPIのモック
    _setupHealthCheckMock(dioAdapter);

    return dioAdapter;
  }

  /// AI変換APIのモック設定
  static void _setupAIConversionMock(DioAdapter adapter) {
    // 成功レスポンス
    adapter.onPost(
      '/api/v1/ai/convert',
      (server) => server.reply(200, {
        'success': true,
        'converted_text': 'ありがとうございます',
        'original_text': 'ありがとう',
        'politeness_level': 'polite',
      }),
      data: Matchers.any,
    );

    // 再生成APIのモック
    adapter.onPost(
      '/api/v1/ai/regenerate',
      (server) => server.reply(200, {
        'success': true,
        'converted_text': '心より感謝申し上げます',
        'original_text': 'ありがとう',
        'politeness_level': 'polite',
      }),
      data: Matchers.any,
    );
  }

  /// ヘルスチェックAPIのモック設定
  static void _setupHealthCheckMock(DioAdapter adapter) {
    adapter.onGet(
      '/api/v1/health',
      (server) => server.reply(200, {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}

/// テスト用の定型文データ
class MockTestData {
  /// テスト用定型文リスト
  static const List<Map<String, String>> presetPhrases = [
    {'text': 'おはようございます', 'category': 'あいさつ'},
    {'text': 'こんにちは', 'category': 'あいさつ'},
    {'text': 'ありがとう', 'category': 'あいさつ'},
    {'text': 'お腹が空きました', 'category': '体調'},
    {'text': '喉が渇きました', 'category': '体調'},
    {'text': '痛いです', 'category': '体調'},
    {'text': 'はい', 'category': '返答'},
    {'text': 'いいえ', 'category': '返答'},
    {'text': 'わからない', 'category': '返答'},
  ];

  /// テスト用履歴データ
  static List<Map<String, dynamic>> createTestHistory(int count) {
    return List.generate(count, (index) {
      return {
        'id': 'history-$index',
        'text': 'テスト履歴 $index',
        'type': index % 4 == 0
            ? 'character_board'
            : index % 4 == 1
                ? 'preset_phrase'
                : index % 4 == 2
                    ? 'ai_conversion'
                    : 'large_button',
        'timestamp': DateTime.now()
            .subtract(Duration(minutes: index * 5))
            .toIso8601String(),
      };
    });
  }

  /// テスト用お気に入りデータ
  static List<Map<String, dynamic>> createTestFavorites(int count) {
    return List.generate(count, (index) {
      return {
        'id': 'favorite-$index',
        'text': 'お気に入り $index',
        'displayOrder': index,
        'createdAt':
            DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      };
    });
  }
}

/// パフォーマンス要件定数
class PerformanceThresholds {
  /// 文字盤タップ応答時間（ミリ秒）- NFR-003
  static const int characterBoardTap = 100;

  /// TTS読み上げ開始時間（ミリ秒）- NFR-001
  static const int ttsStart = 1000;

  /// 定型文一覧表示時間（ミリ秒）- NFR-004
  static const int phraseListDisplay = 1000;

  /// AI変換応答時間（ミリ秒）- NFR-002
  static const int aiConversion = 3000;

  /// ローディング表示開始時間（ミリ秒）- REQ-2006
  static const int loadingDisplayThreshold = 3000;
}
