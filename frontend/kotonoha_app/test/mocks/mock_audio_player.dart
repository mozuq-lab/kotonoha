/// AudioPlayerモッククラス
///
/// TASK-0047: 緊急音・画面赤表示実装
/// audioplayersパッケージのモック
///
/// テスト用にAudioPlayerの動作をシミュレートする。
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:mocktail/mocktail.dart';

/// AudioPlayerのモッククラス
///
/// audioplayers パッケージの AudioPlayer クラスをモック化。
///
/// 使用例:
/// ```dart
/// final mockPlayer = MockAudioPlayer();
/// when(() => mockPlayer.play(any())).thenAnswer((_) async {});
/// ```
class MockAudioPlayer extends Mock implements AudioPlayer {}

/// AudioPlayerインターフェース（テスト互換性のため保持）
///
/// 実際のAudioPlayerと同じインターフェースを持つ抽象クラス。
/// EmergencyAudioServiceのテストで使用。
abstract class AudioPlayerInterface {
  /// 音声を再生する
  Future<void> play(Source source);

  /// 音声を停止する
  Future<void> stop();

  /// 音量を設定する（0.0〜1.0）
  Future<void> setVolume(double volume);

  /// リリースモードを設定する
  Future<void> setReleaseMode(ReleaseMode mode);

  /// リソースを解放する
  Future<void> dispose();
}
