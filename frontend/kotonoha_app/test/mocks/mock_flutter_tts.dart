/// FlutterTtsモッククラス
/// flutter_ttsパッケージのモック
/// テスト用にFlutterTtsの動作をシミュレートする。
library;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';

/// FlutterTtsのモッククラス
/// flutter_tts パッケージの FlutterTts クラスをモック化。
/// 使用例
/// ```dart
/// final mockTts = MockFlutterTts;
/// when( => mockTts.setLanguage(any)).thenAnswer((_) async => 1);
/// when( => mockTts.speak(any)).thenAnswer((_) async => 1);
/// ```
class MockFlutterTts extends Mock implements FlutterTts {}

/// 本物のエンジンと同じく、`speak` を頼むと開始の知らせを返すようにする
/// 読み上げサービスは、開始か完了の知らせが一定時間来ないと「読み上げを
/// 始められなかった」としてエラーにする（エンジンが応答しない端末で黙ったまま
/// 固まらないため）。知らせを返さないモックだと、その見張りが働いてしまう。
void stubSpeakThatStarts(MockFlutterTts tts) {
  void Function()? onStart;
  when(() => tts.setStartHandler(any()))
      .thenAnswer((i) => onStart = i.positionalArguments[0] as void Function());
  when(() => tts.speak(any())).thenAnswer((_) async {
    onStart?.call();
    return 1;
  });
}
