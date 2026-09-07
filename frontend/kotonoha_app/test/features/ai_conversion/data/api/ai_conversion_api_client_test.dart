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

    // Dioのタイムアウト設定が正しく適用される

    group('TC-067-019: Dioのタイムアウト設定が正しく適用される', () {
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

    // HTTPヘッダーが正しく設定される

    group('TC-067-020: HTTPヘッダーが正しく設定される', () {
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

    // AI変換が正常に実行される（politeレベル）

    group('TC-067-001: AI変換が正常に実行される（politeレベル）', () {
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

    // AI変換が正常に実行される（casualレベル）

    group('TC-067-002: AI変換が正常に実行される（casualレベル）', () {
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

    // AI変換が正常に実行される（normalレベル）

    group('TC-067-003: AI変換が正常に実行される（normalレベル）', () {
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

    // AI再変換が正常に実行される

    group('TC-067-004: AI再変換が正常に実行される', () {
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

    // 接続タイムアウト時にAI_API_TIMEOUTエラーがスローされる

    group('TC-067-006: 接続タイムアウト時にAI_API_TIMEOUTエラーがスローされる', () {
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

    // 受信タイムアウト時にAI_API_TIMEOUTエラーがスローされる

    group('TC-067-007: 受信タイムアウト時にAI_API_TIMEOUTエラーがスローされる', () {
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

    // ネットワーク接続エラー時にNETWORK_ERRORがスローされる

    group('TC-067-008: ネットワーク接続エラー時にNETWORK_ERRORがスローされる', () {
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

    // サーバーエラー（500）時にAI_API_ERRORがスローされる

    group('TC-067-009: サーバーエラー（500）時にAI_API_ERRORがスローされる', () {
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

    // レート制限超過時にRATE_LIMIT_EXCEEDEDがスローされる

    group('TC-067-010: レート制限超過時にRATE_LIMIT_EXCEEDEDがスローされる', () {
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

    // バリデーションエラー（400）時にVALIDATION_ERRORがスローされる

    group('TC-067-011: バリデーションエラー（400）時にVALIDATION_ERRORがスローされる', () {
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

    // 不正なJSONレスポンス時にエラーがスローされる

    group('TC-067-012: 不正なJSONレスポンス時にエラーがスローされる', () {
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

    // 最小文字数（2文字）の入力が正常に処理される

    group('TC-067-013: 最小文字数（2文字）の入力が正常に処理される', () {
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

    // 最大文字数（500文字）の入力が正常に処理される

    group('TC-067-014: 最大文字数（500文字）の入力が正常に処理される', () {
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
