/// 読み上げエンジンが応答しないときに、黙ったまま固まらないこと（守る約束 ④）
///
/// Android エミュレータで実測した形（2026-09-24）: エンジンへの接続が使えなく
/// なると、`speak` は返るのに開始・完了の知らせが来ず、状態が「読み上げ中」の
/// まま残った。次の `speak` は呼び出し自体が返らなかった（プラグインが保留に
/// 回したまま）。利用者には何も告げられず、読み上げボタンは「停止」のままだった。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_flutter_tts.dart';

void main() {
  late MockFlutterTts tts;
  late TTSService service;
  late int notified;
  VoidCallback? onStart;
  VoidCallback? onComplete;
  void Function(dynamic)? onError;

  const speakTimeout = Duration(milliseconds: 100);
  const startTimeout = Duration(milliseconds: 200);

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
    registerFallbackValue(() {});
    registerFallbackValue((dynamic _) {});
  });

  setUp(() {
    tts = MockFlutterTts();
    notified = 0;
    onStart = null;
    onComplete = null;
    onError = null;
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.speak(any())).thenAnswer((_) async => 1);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    when(() => tts.setStartHandler(any()))
        .thenAnswer((i) => onStart = i.positionalArguments[0] as VoidCallback);
    when(() => tts.setCompletionHandler(any())).thenAnswer(
        (i) => onComplete = i.positionalArguments[0] as VoidCallback);
    when(() => tts.setErrorHandler(any())).thenAnswer(
        (i) => onError = i.positionalArguments[0] as void Function(dynamic));
    service = TTSService(
      tts: tts,
      onStateChanged: () => notified++,
      speakTimeout: speakTimeout,
      startTimeout: startTimeout,
    );
  });

  Future<void> wait(Duration d) => Future<void>.delayed(d);

  test('speak が返らなければ、上限の後にエラーになり、呼び出しも返る', () async {
    when(() => tts.speak(any())).thenAnswer((_) => Completer<dynamic>().future);
    await service.initialize();

    await service.speak('いいえ').timeout(const Duration(seconds: 2));

    expect(service.state, TTSState.error);
    expect(service.errorMessage, isNotNull);
  });

  test('読み上げ中に次を頼み、前の停止が返らなくても、呼び出しは返ってエラーになる', () async {
    await service.initialize();
    await service.speak('いいえ');
    when(() => tts.stop()).thenAnswer((_) => Completer<dynamic>().future);

    await service.speak('痛い').timeout(const Duration(seconds: 2));

    expect(service.state, TTSState.error);
  });

  test('開始も完了も知らせが来なければ、上限の後にエラーになり、知らせる', () async {
    await service.initialize();
    await service.speak('いいえ');
    expect(service.state, TTSState.speaking);
    final before = notified;

    await wait(startTimeout * 2);

    expect(service.state, TTSState.error, reason: '黙ったまま「読み上げ中」に残った');
    expect(notified, greaterThan(before), reason: '状態の変化を画面へ知らせていない');
  });

  test('開始の知らせが来れば、長い読み上げでもエラーにしない', () async {
    await service.initialize();
    await service.speak('長い文');
    onStart!();

    await wait(startTimeout * 2);

    expect(service.state, TTSState.speaking);
    onComplete!();
    expect(service.state, TTSState.idle);
  });

  test('開始の前に完了の知らせが来ても、エラーにしない', () async {
    await service.initialize();
    await service.speak('はい');
    onComplete!();

    await wait(startTimeout * 2);

    expect(service.state, TTSState.idle);
  });

  test('エンジンのエラーの知らせで、エラーになり、知らせる', () async {
    await service.initialize();
    await service.speak('いいえ');
    final before = notified;

    onError!('synthesis failed');

    expect(service.state, TTSState.error);
    expect(notified, greaterThan(before));
  });

  test('エラーの後の読み上げは、また普通に始まる', () async {
    when(() => tts.speak(any())).thenAnswer((_) => Completer<dynamic>().future);
    await service.initialize();
    await service.speak('いいえ');
    expect(service.state, TTSState.error);

    when(() => tts.speak(any())).thenAnswer((_) async => 1);
    await service.speak('痛い');
    onStart!();

    expect(service.state, TTSState.speaking);
    expect(service.errorMessage, isNull);
  });

  test('前の読み上げの開始待ちが、次の読み上げをエラーにしない', () async {
    await service.initialize();
    await service.speak('いいえ');
    onStart!();
    onComplete!();
    await service.speak('痛い');
    onStart!();

    await wait(startTimeout * 2);

    expect(service.state, TTSState.speaking);
  });

  // レビューの指摘（誤発報と固まり）: 以下は 2026-09-25 に足した

  test('止めた後に届く interrupted のエラーの知らせでは、失敗と告げない', () async {
    await service.initialize();
    await service.speak('いいえ');
    onStart!();
    await service.stop();

    onError!('interrupted');

    expect(service.state, TTSState.stopped, reason: '止めただけなのに失敗と告げる');
  });

  test('次の読み上げに割り込まれた前の読み上げの interrupted では、失敗と告げない', () async {
    await service.initialize();
    await service.speak('いいえ');
    onStart!();
    await service.speak('痛い');
    onStart!();

    onError!('interrupted');

    expect(service.state, TTSState.speaking);
  });

  test('前の読み上げの待ち時間切れが、次の読み上げを失敗にしない', () async {
    final pending = Completer<dynamic>();
    when(() => tts.speak('いいえ')).thenAnswer((_) => pending.future);
    await service.initialize();
    final first = service.speak('いいえ');
    await Future<void>.delayed(Duration.zero);
    await service.stop();
    await service.speak('痛い');
    onStart!();

    await first;
    await wait(speakTimeout * 2);

    expect(service.state, TTSState.speaking, reason: '前の待ち時間切れで、読み上げ中の次を失敗にした');
  });

  test('待ち時間切れの後で読み上げが始まったら、失敗を取り消して読み上げ中に戻す', () async {
    when(() => tts.speak(any())).thenAnswer((_) => Completer<dynamic>().future);
    await service.initialize();
    await service.speak('いいえ');
    expect(service.state, TTSState.error);
    final before = notified;

    onStart!();

    expect(service.state, TTSState.speaking, reason: '実際は読み上げているのに失敗のまま');
    expect(service.errorMessage, isNull);
    expect(notified, greaterThan(before));
  });

  test('初期化の呼び出しが返らなくても、読み上げは返ってエラーになる', () async {
    when(() => tts.setLanguage(any()))
        .thenAnswer((_) => Completer<dynamic>().future);

    await service.speak('いいえ').timeout(const Duration(seconds: 2));

    expect(service.state, TTSState.error);
  });

  test('破棄した後は、見張りが知らせない', () async {
    final pending = Completer<dynamic>();
    when(() => tts.speak(any())).thenAnswer((_) => pending.future);
    await service.initialize();
    final speaking = service.speak('いいえ');
    await Future<void>.delayed(Duration.zero);
    await service.dispose();
    final before = notified;

    pending.complete(1);
    await speaking;
    await wait(startTimeout * 2);

    expect(notified, before, reason: '破棄した後に知らせた');
  });
}
