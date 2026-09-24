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
}
