/// FlutterTtsモッククラス
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// flutter_ttsパッケージのモック
///
/// テスト用にFlutterTtsの動作をシミュレートする。
library;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';

/// FlutterTtsのモッククラス
///
/// flutter_tts パッケージの FlutterTts クラスをモック化。
///
/// 使用例:
/// ```dart
/// final mockTts = MockFlutterTts();
/// when(() => mockTts.setLanguage(any())).thenAnswer((_) async => 1);
/// when(() => mockTts.speak(any())).thenAnswer((_) async => 1);
/// ```
class MockFlutterTts extends Mock implements FlutterTts {}
