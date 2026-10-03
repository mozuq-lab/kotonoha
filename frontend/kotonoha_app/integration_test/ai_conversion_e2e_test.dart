/// AI 変換の利用シナリオの結合テスト（ADR-007 条件 5）
///
/// 本物のアプリで、利用者が AI 変換を使う流れを確かめる。初回の同意、
/// 送る中身（入力した文と丁寧さ、再生成では前回の結果）、採用・再生成・
/// 元の文を使う、上限に達したときの告知、押せないとき。
/// iOS シミュレータ（iPad）と Android エミュレータで走らせる。
///
/// 偽物にするのはネットワークの境界（Dio）だけ。backend と同じ形の応答を返し、
/// アプリが送った要求をすべて記録する（同意しなければ何も送らない、を見るため）。
/// 実 backend との往復は、公開時に確かめた（台帳 L-58、ADR-002）。
@Tags(['e2e'])
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/data/api/ai_conversion_api_client.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:kotonoha_app/features/network/domain/services/connectivity_service.dart';

import 'helpers/test_helpers.dart';

/// backend の代わりに応答し、届いた要求を記録する。
class _FakeBackend {
  _FakeBackend({Response<dynamic> Function(RequestOptions)? respond})
      : respond = respond ?? _converted;

  final Response<dynamic> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  /// backend の ConversionResponse と同じ形（`backend/app/schemas.py`）
  static Response<dynamic> _converted(RequestOptions o) {
    final body = o.data as Map<String, dynamic>;
    final regenerating = o.path.endsWith('/regenerate');
    return Response<dynamic>(
      requestOptions: o,
      statusCode: 200,
      data: <String, dynamic>{
        'converted_text': regenerating ? '心より感謝申し上げます' : 'ありがとうございます',
        'original_text': body['input_text'],
        'politeness_level': body['politeness_level'],
        'processing_time_ms': 420,
      },
    );
  }

  Dio dio() {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final response = respond(options);
      if ((response.statusCode ?? 500) >= 400) {
        handler.reject(DioException.badResponse(
          statusCode: response.statusCode!,
          requestOptions: options,
          response: response,
        ));
      } else {
        handler.resolve(response);
      }
    }));
    return dio;
  }

  /// 接続状態は SDK（connectivity_plus）の境界で偽物にする。アプリは起動時に
  /// 接続を確かめ直すので、networkProvider を上書きしても実際の状態に戻される。
  List<Override> overrides({bool online = true}) => [
        aiConversionApiClientProvider
            .overrideWithValue(AIConversionApiClient.withDio(dio())),
        connectivityServiceProvider.overrideWithValue(ConnectivityService(
            connectivity: _FakeConnectivity(
                online ? ConnectivityResult.wifi : ConnectivityResult.none))),
      ];
}

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity(this.result);

  final ConnectivityResult result;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [result];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

const _consentTitle = 'AI変換の利用確認';
const _resultTitle = 'AI変換結果';

/// AI 変換ボタンを押す。変換中はボタンのくるくるが回り続けて
/// pumpAndSettle が終わらないので、時間を区切って描き直す。
Future<void> _tapConvert(WidgetTester tester) async {
  final button = find.text('AI変換');
  expect(button, findsOneWidget, reason: 'AI変換ボタンが見つからない');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

/// [finder] が出るまで描き直す（最大 10 秒）
Future<void> _waitFor(WidgetTester tester, Finder finder) =>
    waitForWidget(tester, finder, timeout: const Duration(seconds: 10));

/// ダイアログのボタンを押し、閉じる動きが終わるまで描き直す
Future<void> _tapInDialog(WidgetTester tester, String label) async {
  final target = find.text(label);
  expect(target, findsOneWidget, reason: '「$label」が見つからない');
  await tester.tap(target);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 入力欄に [text] が入っている
Finder _inputShowing(String text) => find.descendant(
      of: find.byType(HomeInputField),
      matching: find.text(text),
    );

ElevatedButton _convertButton(WidgetTester tester) {
  final button = find.descendant(
    of: find.byType(AIConversionButton),
    matching: find.byType(ElevatedButton),
  );
  expect(button, findsOneWidget, reason: 'AI変換ボタンの本体が見つからない');
  return tester.widget<ElevatedButton>(button);
}

void main() {
  initializeE2ETestBinding();

  testWidgets('1. 初回は同意を求め、同意すると入力した文と丁寧さだけを送り、採用した結果を読み上げて履歴に残す',
      (tester) async {
    final backend = _FakeBackend();
    await pumpApp(tester, overrides: backend.overrides());

    await typeOnCharacterBoard(tester, 'ありがとう');
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_consentTitle));
    expect(backend.requests, isEmpty, reason: '同意する前に送ってはいけない');

    await _tapInDialog(tester, '同意して利用');
    await _waitFor(tester, find.text(_resultTitle));

    expect(backend.requests, hasLength(1));
    final sent = backend.requests.single;
    expect(sent.path, '/api/v1/ai/convert');
    expect(sent.data, {'input_text': 'ありがとう', 'politeness_level': 'normal'},
        reason: '送るのは入力した文と丁寧さだけ');
    expect(find.text('ありがとうございます'), findsOneWidget);

    await _tapInDialog(tester, '採用');
    expect(find.text(_resultTitle), findsNothing);
    expect(_inputShowing('ありがとうございます'), findsOneWidget,
        reason: '採用した結果が入力欄に入る');

    await tapAndExpectSpeech(tester, find.text('読み上げ'));
    await stopSpeechIfSpeaking(tester);

    await tester.tap(find.byTooltip('履歴'));
    await tester.pumpAndSettle();
    expect(find.text('ありがとうございます'), findsOneWidget, reason: '読み上げた変換結果が履歴に残る');
  });

  testWidgets('2. 同意しないと何も送らず入力はそのまま。一度同意すれば次からは聞かない', (tester) async {
    final backend = _FakeBackend();
    await pumpApp(tester, overrides: backend.overrides());

    await typeOnCharacterBoard(tester, 'ありがとう');
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_consentTitle));
    await _tapInDialog(tester, '同意しない');

    expect(find.text(_consentTitle), findsNothing);
    expect(find.text(_resultTitle), findsNothing);
    expect(backend.requests, isEmpty, reason: '同意しなければ送らない');
    expect(_inputShowing('ありがとう'), findsOneWidget);
    expect(_convertButton(tester).onPressed, isNotNull,
        reason: '断った後もボタンは押せる（くるくるのまま固まらない）');

    // 断った後に押すと、もう一度聞く
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_consentTitle));
    await _tapInDialog(tester, '同意して利用');
    await _waitFor(tester, find.text(_resultTitle));
    await _tapInDialog(tester, '元の文を使う');
    expect(backend.requests, hasLength(1));

    // 同意した後は聞かずに変換する
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_resultTitle));
    expect(find.text(_consentTitle), findsNothing);
    expect(backend.requests, hasLength(2));
  });

  testWidgets('3. 再生成は前回の結果を添えて送り、新しい結果を採用できる', (tester) async {
    final backend = _FakeBackend();
    await pumpApp(tester, overrides: backend.overrides());

    await typeOnCharacterBoard(tester, 'ありがとう');
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_consentTitle));
    await _tapInDialog(tester, '同意して利用');
    await _waitFor(tester, find.text(_resultTitle));

    await _tapInDialog(tester, '再生成');
    await _waitFor(tester, find.text('心より感謝申し上げます'));

    expect(backend.requests, hasLength(2));
    final sent = backend.requests.last;
    expect(sent.path, '/api/v1/ai/regenerate');
    expect(sent.data, {
      'input_text': 'ありがとう',
      'politeness_level': 'normal',
      'previous_result': 'ありがとうございます',
    });

    await _tapInDialog(tester, '採用');
    expect(_inputShowing('心より感謝申し上げます'), findsOneWidget);
  });

  testWidgets('4. 「元の文を使う」と入力は元のまま', (tester) async {
    final backend = _FakeBackend();
    await pumpApp(tester, overrides: backend.overrides());

    await typeOnCharacterBoard(tester, 'ありがとう');
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_consentTitle));
    await _tapInDialog(tester, '同意して利用');
    await _waitFor(tester, find.text(_resultTitle));

    await _tapInDialog(tester, '元の文を使う');
    expect(find.text(_resultTitle), findsNothing);
    expect(_inputShowing('ありがとう'), findsOneWidget);
    expect(find.text('ありがとうございます'), findsNothing);
  });

  testWidgets('5. 上限に達したら backend の文言で告げ、入力を残す', (tester) async {
    // backend の AI_RATE_LIMIT と同じ形（`backend/app/main.py` の _error_body）
    const message = 'いまAI変換を使えません。混み合っているか、利用の上限に達しています。'
        '時間をおいて試すか、元の文をお使いください。';
    final backend = _FakeBackend(
      respond: (o) => Response<dynamic>(
        requestOptions: o,
        statusCode: 429,
        data: <String, dynamic>{
          'success': false,
          'data': null,
          'error': {
            'code': 'AI_RATE_LIMIT',
            'message': message,
            'status_code': 429,
          },
        },
      ),
    );
    await pumpApp(tester, overrides: backend.overrides());

    await typeOnCharacterBoard(tester, 'ありがとう');
    await _tapConvert(tester);
    await _waitFor(tester, find.text(_consentTitle));
    await _tapInDialog(tester, '同意して利用');
    await _waitFor(tester, find.text(message));

    expect(backend.requests, hasLength(1));
    expect(find.text(_resultTitle), findsNothing);
    expect(_inputShowing('ありがとう'), findsOneWidget, reason: '失敗しても入力を消さない');
    expect(_convertButton(tester).onPressed, isNotNull);
  });

  testWidgets('6. 1 文字以下とオフラインではボタンが押せず、何も送らない', (tester) async {
    final backend = _FakeBackend();
    await pumpApp(tester, overrides: backend.overrides());
    expect(_convertButton(tester).onPressed, isNull, reason: '空では押せない');

    await typeOnCharacterBoard(tester, 'あ');
    expect(_convertButton(tester).onPressed, isNull, reason: '1 文字では押せない');

    await typeOnCharacterBoard(tester, 'い');
    expect(_convertButton(tester).onPressed, isNotNull, reason: '2 文字から押せる');

    final offline = _FakeBackend();
    await restartApp(tester, overrides: offline.overrides(online: false));
    await typeOnCharacterBoard(tester, 'ありがとう');
    expect(_convertButton(tester).onPressed, isNull, reason: 'オフラインでは押せない');
    await tester.tap(find.text('AI変換'), warnIfMissed: false);
    await tester.pump();
    expect(find.text(_consentTitle), findsNothing);
    expect(backend.requests, isEmpty);
    expect(offline.requests, isEmpty);
  });
}
