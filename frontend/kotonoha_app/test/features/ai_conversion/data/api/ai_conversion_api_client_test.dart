/// AI変換APIクライアント テスト
///
/// TASK-0067: AI変換APIクライアント実装
/// TDD Redフェーズ: TC-067-001〜004, TC-067-006〜014, TC-067-019〜020
///
/// 信頼性レベル: 青信号（api-endpoints.mdベース）
/// 関連要件: REQ-901, REQ-902, REQ-903, REQ-904, NFR-002
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/ai_conversion/data/api/ai_conversion_api_client.dart';
import 'package:kotonoha_app/features/ai_conversion/data/models/ai_conversion_response.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<dynamic> {}

void main() {
  group('AI変換APIクライアント テスト', () {
    late MockDio mockDio;
    late AIConversionApiClient client;

    setUp(() {
      mockDio = MockDio();
      client = AIConversionApiClient.withDio(mockDio);
    });

    // =========================================================================
    // TC-067-019: Dioのタイムアウト設定が正しく適用される
    // =========================================================================

    group('TC-067-019: Dioのタイムアウト設定が正しく適用される', () {
      // テスト目的: NFR-002タイムアウト設定の検証
      // テスト内容: connectTimeout/receiveTimeoutが10秒に設定される
      // 期待される動作: Dio BaseOptionsに正しい設定が適用される
      // 青信号: NFR-002に明確に定義

      test('connectTimeoutが10秒に設定される', () {
        // テストデータ準備: 実際のAPIクライアント（baseUrl指定）
        final realClient =
            AIConversionApiClient(baseUrl: 'http://localhost:8000');

        // 結果検証: connectTimeoutが10秒であること
        expect(
          realClient.dio.options.connectTimeout,
          const Duration(seconds: 10),
        );
      });

      test('receiveTimeoutが10秒に設定される', () {
        // テストデータ準備: 実際のAPIクライアント
        final realClient =
            AIConversionApiClient(baseUrl: 'http://localhost:8000');

        // 結果検証: receiveTimeoutが10秒であること
        expect(
          realClient.dio.options.receiveTimeout,
          const Duration(seconds: 10),
        );
      });
    });

    // =========================================================================
    // TC-067-020: HTTPヘッダーが正しく設定される
    // =========================================================================

    group('TC-067-020: HTTPヘッダーが正しく設定される', () {
      // テスト目的: API仕様準拠の検証
      // テスト内容: Content-TypeとAcceptヘッダーがJSON形式で設定される
      // 期待される動作: ヘッダーが正しく設定されている
      // 青信号: api-endpoints.mdに明確に定義

      test('Content-Typeがapplication/jsonに設定される', () {
        // テストデータ準備: 実際のAPIクライアント
        final realClient =
            AIConversionApiClient(baseUrl: 'http://localhost:8000');

        // 結果検証: Content-Typeヘッダーが正しいこと
        expect(
          realClient.dio.options.headers['Content-Type'],
          'application/json',
        );
      });

      test('Acceptがapplication/jsonに設定される', () {
        // テストデータ準備: 実際のAPIクライアント
        final realClient =
            AIConversionApiClient(baseUrl: 'http://localhost:8000');

        // 結果検証: Acceptヘッダーが正しいこと
        expect(
          realClient.dio.options.headers['Accept'],
          'application/json',
        );
      });

      test('baseUrlが正しく設定される', () {
        // テストデータ準備: 実際のAPIクライアント
        final realClient =
            AIConversionApiClient(baseUrl: 'http://localhost:8000');

        // 結果検証: baseUrlが正しいこと
        expect(realClient.dio.options.baseUrl, 'http://localhost:8000');
      });
    });

    // =========================================================================
    // TC-067-001: AI変換が正常に実行される（politeレベル）
    // =========================================================================

    group('TC-067-001: AI変換が正常に実行される（politeレベル）', () {
      // テスト目的: REQ-901（短い入力を丁寧な文章に変換）の検証
      // テスト内容: /api/v1/ai/convert エンドポイントへの正常なリクエストと応答
      // 期待される動作: 入力テキストが丁寧な表現に変換される
      // 青信号: api-endpoints.mdに明確に定義

      test('politeレベルでの変換が正常に実行される', () async {
        // テストデータ準備: モックレスポンスを設定
        final responseData = {
          'converted_text': 'お水をぬるめでお願いします',
          'original_text': '水 ぬるく',
          'politeness_level': 'polite',
          'processing_time_ms': 1500,
        };

        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
            ));

        // 実行: convert メソッドを呼び出し
        final result = await client.convert(
          inputText: '水 ぬるく',
          politenessLevel: PolitenessLevel.polite,
        );

        // 結果検証: レスポンスフィールドが全て正しく設定されること
        expect(result, isA<AIConversionResponse>());
        expect(result.convertedText, 'お水をぬるめでお願いします');
        expect(result.originalText, '水 ぬるく');
        expect(result.politenessLevel, PolitenessLevel.polite);
        expect(result.processingTimeMs, 1500);
      });
    });

    // =========================================================================
    // TC-067-002: AI変換が正常に実行される（casualレベル）
    // =========================================================================

    group('TC-067-002: AI変換が正常に実行される（casualレベル）', () {
      // テスト目的: REQ-903（丁寧さレベル3段階）の検証
      // テスト内容: casualレベルでの変換が適切に動作すること
      // 期待される動作: 入力テキストがカジュアルな表現に変換される
      // 青信号

      test('casualレベルでの変換が正常に実行される', () async {
        // テストデータ準備: casualレスポンス
        final responseData = {
          'converted_text': 'ありがと！',
          'original_text': 'ありがとう',
          'politeness_level': 'casual',
          'processing_time_ms': 800,
        };

        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
            ));

        // 実行: convert メソッドを呼び出し
        final result = await client.convert(
          inputText: 'ありがとう',
          politenessLevel: PolitenessLevel.casual,
        );

        // 結果検証: casualレベルが正しく適用されること
        expect(result.politenessLevel, PolitenessLevel.casual);
      });
    });

    // =========================================================================
    // TC-067-003: AI変換が正常に実行される（normalレベル）
    // =========================================================================

    group('TC-067-003: AI変換が正常に実行される（normalレベル）', () {
      // テスト目的: REQ-903（丁寧さレベル3段階）の検証
      // テスト内容: normalレベルでの変換が適切に動作すること
      // 青信号

      test('normalレベルでの変換が正常に実行される', () async {
        // テストデータ準備: normalレスポンス
        final responseData = {
          'converted_text': '腰が痛いです',
          'original_text': '痛い 腰',
          'politeness_level': 'normal',
          'processing_time_ms': 1200,
        };

        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
            ));

        // 実行: convert メソッドを呼び出し
        final result = await client.convert(
          inputText: '痛い 腰',
          politenessLevel: PolitenessLevel.normal,
        );

        // 結果検証: normalレベルが正しく適用されること
        expect(result.politenessLevel, PolitenessLevel.normal);
      });
    });

    // =========================================================================
    // TC-067-004: AI再変換が正常に実行される
    // =========================================================================

    group('TC-067-004: AI再変換が正常に実行される', () {
      // テスト目的: REQ-904（再生成機能）の検証
      // テスト内容: /api/v1/ai/regenerate エンドポイントへの正常なリクエストと応答
      // 期待される動作: 前回の結果と異なる新しい変換結果が生成される
      // 青信号

      test('regenerateメソッドが正常に動作する', () async {
        // テストデータ準備: 再生成レスポンス
        final responseData = {
          'converted_text': 'お水をぬるめにしてください',
          'original_text': '水 ぬるく',
          'politeness_level': 'polite',
          'processing_time_ms': 1800,
        };

        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/regenerate'),
            ));

        // 実行: regenerate メソッドを呼び出し
        final result = await client.regenerate(
          inputText: '水 ぬるく',
          politenessLevel: PolitenessLevel.polite,
          previousResult: 'お水をぬるめでお願いします',
        );

        // 結果検証: 新しい変換結果が返されること
        expect(result, isA<AIConversionResponse>());
        expect(result.convertedText, 'お水をぬるめにしてください');
      });
    });

    // =========================================================================
    // TC-067-006: 接続タイムアウト時にAI_API_TIMEOUTエラーがスローされる
    // =========================================================================

    group('TC-067-006: 接続タイムアウト時にAI_API_TIMEOUTエラーがスローされる', () {
      // テスト目的: NFR-002タイムアウト処理の検証
      // テスト内容: 10秒のタイムアウト超過時に適切な例外がスローされる
      // 期待される動作: AIConversionException(code: AI_API_TIMEOUT)がスローされる
      // 青信号: EDGE-001に明確に定義

      test('接続タイムアウト時にAIConversionExceptionがスローされる', () async {
        // テストデータ準備: DioExceptionType.connectionTimeoutをモック
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
        ));

        // 実行・検証: AI_API_TIMEOUT例外がスローされること
        expect(
          () => client.convert(
            inputText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>().having(
            (e) => e.code,
            'code',
            'AI_API_TIMEOUT',
          )),
        );
      });
    });

    // =========================================================================
    // TC-067-007: 受信タイムアウト時にAI_API_TIMEOUTエラーがスローされる
    // =========================================================================

    group('TC-067-007: 受信タイムアウト時にAI_API_TIMEOUTエラーがスローされる', () {
      // テスト目的: タイムアウト処理の網羅性確認
      // テスト内容: レスポンス受信中にタイムアウトした場合の処理
      // 青信号

      test('受信タイムアウト時にAIConversionExceptionがスローされる', () async {
        // テストデータ準備: DioExceptionType.receiveTimeoutをモック
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
        ));

        // 実行・検証: AI_API_TIMEOUT例外がスローされること
        expect(
          () => client.convert(
            inputText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>().having(
            (e) => e.code,
            'code',
            'AI_API_TIMEOUT',
          )),
        );
      });
    });

    // =========================================================================
    // TC-067-008: ネットワーク接続エラー時にNETWORK_ERRORがスローされる
    // =========================================================================

    group('TC-067-008: ネットワーク接続エラー時にNETWORK_ERRORがスローされる', () {
      // テスト目的: オフライン時のエラーハンドリング検証
      // テスト内容: インターネット接続不可時の処理
      // 青信号: REQ-1002に関連

      test('接続エラー時にNETWORK_ERROR例外がスローされる', () async {
        // テストデータ準備: DioExceptionType.connectionErrorをモック
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
        ));

        // 実行・検証: NETWORK_ERROR例外がスローされること
        expect(
          () => client.convert(
            inputText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>().having(
            (e) => e.code,
            'code',
            'NETWORK_ERROR',
          )),
        );
      });
    });

    // =========================================================================
    // TC-067-009: サーバーエラー（500）時にAI_API_ERRORがスローされる
    // =========================================================================

    group('TC-067-009: サーバーエラー（500）時にAI_API_ERRORがスローされる', () {
      // テスト目的: サーバーエラー時のフォールバック検証
      // テスト内容: バックエンドが500エラーを返した場合の処理
      // 青信号: EDGE-002に明確に定義

      test('HTTP 500エラー時にAI_API_ERROR例外がスローされる', () async {
        // テストデータ準備: HTTP 500レスポンスをモック
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            data: {
              'error': {'code': 'AI_API_ERROR', 'message': 'Internal error'}
            },
            requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
          ),
          requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
        ));

        // 実行・検証: AI_API_ERROR例外がスローされること
        expect(
          () => client.convert(
            inputText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>().having(
            (e) => e.code,
            'code',
            'AI_API_ERROR',
          )),
        );
      });
    });

    // =========================================================================
    // TC-067-010: レート制限超過時にRATE_LIMIT_EXCEEDEDがスローされる
    // =========================================================================

    group('TC-067-010: レート制限超過時にRATE_LIMIT_EXCEEDEDがスローされる', () {
      // テスト目的: レート制限エラーの適切な処理
      // テスト内容: HTTP 429レスポンス時の処理
      // 青信号: api-endpoints.mdに定義

      test('HTTP 429エラー時にRATE_LIMIT_EXCEEDED例外がスローされる', () async {
        // テストデータ準備: HTTP 429レスポンスをモック
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 429,
            data: {
              'error': {
                'code': 'RATE_LIMIT_EXCEEDED',
                'message': 'Too many requests'
              }
            },
            requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
          ),
          requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
        ));

        // 実行・検証: RATE_LIMIT_EXCEEDED例外がスローされること
        expect(
          () => client.convert(
            inputText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>().having(
            (e) => e.code,
            'code',
            'RATE_LIMIT_EXCEEDED',
          )),
        );
      });
    });

    // =========================================================================
    // TC-067-011: バリデーションエラー（400）時にVALIDATION_ERRORがスローされる
    // =========================================================================

    group('TC-067-011: バリデーションエラー（400）時にVALIDATION_ERRORがスローされる', () {
      // テスト目的: クライアント側エラーハンドリング検証
      // テスト内容: 入力値が不正な場合のエラー処理
      // 黄信号（API仕様から推測）

      test('HTTP 400エラー時にVALIDATION_ERROR例外がスローされる', () async {
        // テストデータ準備: HTTP 400レスポンスをモック
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            data: {
              'error': {'code': 'VALIDATION_ERROR', 'message': 'Invalid input'}
            },
            requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
          ),
          requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
        ));

        // 実行・検証: VALIDATION_ERROR例外がスローされること
        expect(
          () => client.convert(
            inputText: 'あ',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>().having(
            (e) => e.code,
            'code',
            'VALIDATION_ERROR',
          )),
        );
      });
    });

    // =========================================================================
    // TC-067-012: 不正なJSONレスポンス時にエラーがスローされる
    // =========================================================================

    group('TC-067-012: 不正なJSONレスポンス時にエラーがスローされる', () {
      // テスト目的: 堅牢なエラーハンドリング検証
      // テスト内容: レスポンスがJSONとしてパースできない場合
      // 黄信号

      test('不正なJSONレスポンス時に例外がスローされる', () async {
        // テストデータ準備: 不正なレスポンスデータ
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: 'invalid json', // 文字列として返される場合
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
            ));

        // 実行・検証: 何らかの例外がスローされること
        expect(
          () => client.convert(
            inputText: '水 ぬるく',
            politenessLevel: PolitenessLevel.polite,
          ),
          throwsA(isA<AIConversionException>()),
        );
      });
    });

    // =========================================================================
    // TC-067-013: 最小文字数（2文字）の入力が正常に処理される
    // =========================================================================

    group('TC-067-013: 最小文字数（2文字）の入力が正常に処理される', () {
      // テスト目的: 入力文字数下限の検証
      // テスト内容: 2文字入力でのAI変換が成功する
      // 青信号

      test('2文字の入力で正常に変換される', () async {
        // テストデータ準備: 2文字入力のレスポンス
        final responseData = {
          'converted_text': 'お水ください',
          'original_text': '水水',
          'politeness_level': 'polite',
          'processing_time_ms': 1000,
        };

        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
            ));

        // 実行: 2文字で変換
        final result = await client.convert(
          inputText: '水水',
          politenessLevel: PolitenessLevel.polite,
        );

        // 結果検証: 正常に変換されること
        expect(result, isA<AIConversionResponse>());
      });
    });

    // =========================================================================
    // TC-067-014: 最大文字数（500文字）の入力が正常に処理される
    // =========================================================================

    group('TC-067-014: 最大文字数（500文字）の入力が正常に処理される', () {
      // テスト目的: 入力文字数上限の検証
      // テスト内容: 500文字入力でのAI変換が成功する
      // 青信号

      test('500文字の入力で正常に変換される', () async {
        // テストデータ準備: 500文字入力とレスポンス
        final longInput = 'あ' * 500;
        final responseData = {
          'converted_text': '長文の変換結果',
          'original_text': longInput,
          'politeness_level': 'normal',
          'processing_time_ms': 3000,
        };

        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/ai/convert'),
            ));

        // 実行: 500文字で変換
        final result = await client.convert(
          inputText: longInput,
          politenessLevel: PolitenessLevel.normal,
        );

        // 結果検証: 正常に変換されること
        expect(result, isA<AIConversionResponse>());
        expect(result.originalText.length, 500);
      });
    });
  });
}
