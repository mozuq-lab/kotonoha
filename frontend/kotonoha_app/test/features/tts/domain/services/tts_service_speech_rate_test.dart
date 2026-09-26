/// 読み上げの速さを、flutter_tts の尺度に直して渡す
///
/// flutter_tts の `setSpeechRate` は 0.0〜1.0 で 0.5 が標準の速さ
/// （iOS は AVSpeechUtterance.rate にそのまま入れ、Android は 2 倍して
/// TextToSpeech に渡す）。Web だけは Web Speech API の rate にそのまま入れ、
/// 1.0 が標準。アプリの速さ（「普通」＝ 1.0 倍）をそのまま渡すと、
/// iOS では最速、Android では 2 倍速になっていた。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';

import '../../../../mocks/mock_flutter_tts.dart';

void main() {
  late MockFlutterTts tts;
  late TTSService service;

  setUp(() {
    tts = MockFlutterTts();
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    service = TTSService(tts: tts);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('${platform.name}: 「普通」はプラグインの標準（0.5）、他はその倍率で渡す', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      for (final (speed, rate) in [
        (TTSSpeed.verySlow, 0.25),
        (TTSSpeed.slow, 0.35),
        (TTSSpeed.normal, 0.5),
        (TTSSpeed.fast, 0.65),
      ]) {
        await service.setSpeed(speed);
        final passed =
            verify(() => tts.setSpeechRate(captureAny())).captured.single;
        expect(passed, closeTo(rate, 1e-9), reason: '${speed.name} の速さ');
      }
    });
  }
}
