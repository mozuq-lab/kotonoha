/// 読み上げの声を選ぶ
///
/// 端末に入っている声から選び、保存して、次の起動でもその声で読み上げる。
/// 端末の外で読み上げる声は選べない（守る約束 ②）。選んだ声が使えなくなっても
/// 標準の声で読み上げ、黙らない（守る約束 ③）。
/// モックは外部 SDK（flutter_tts）の境界だけ。保存は SharedPreferences の
/// メモリ上の store を通す。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_flutter_tts.dart';

/// iOS の AVSpeechSynthesisVoice を flutter_tts が写した形
Map<String, String> _ios(
  String name,
  String quality,
  String gender, {
  String locale = 'ja-JP',
}) =>
    {
      'name': name,
      'locale': locale,
      'quality': quality,
      'gender': gender,
      'identifier': 'com.apple.voice.$quality.$locale.$name',
    };

/// Android の android.speech.tts.Voice を flutter_tts が写した形
Map<String, String> _android(
  String name, {
  bool network = false,
  String features = '',
}) =>
    {
      'name': name,
      'locale': 'ja-JP',
      'quality': 'high',
      'latency': 'normal',
      'network_required': network ? '1' : '0',
      'features': features,
    };

final _kyokoEnhanced = _ios('Kyoko', 'enhanced', 'female');
const _kyokoEnhancedId = 'com.apple.voice.enhanced.ja-JP.Kyoko';

void main() {
  late MockFlutterTts tts;
  late List<Object?> engineVoices;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tts = MockFlutterTts();
    engineVoices = [
      _ios('Kyoko', 'default', 'female'),
      _kyokoEnhanced,
      _ios('Otoya', 'premium', 'male'),
      _ios('Samantha', 'enhanced', 'female', locale: 'en-US'),
    ];
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.setVoice(any())).thenAnswer((_) async => 1);
    when(() => tts.getVoices).thenAnswer((_) async => engineVoices);
    when(() => tts.setCompletionHandler(any())).thenReturn(null);
    when(() => tts.setErrorHandler(any())).thenReturn(null);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    stubSpeakThatStarts(tts);
  });

  ProviderContainer containerWithEngine() {
    final container = ProviderContainer(
      overrides: [
        ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts)),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('選べる声', () {
    test('日本語の声だけを、品質の高い順に並べる', () async {
      final container = containerWithEngine();

      final voices = await container.read(ttsProvider.notifier).voices();

      expect(voices.map((v) => v.id), [
        'com.apple.voice.premium.ja-JP.Otoya',
        _kyokoEnhancedId,
        'com.apple.voice.default.ja-JP.Kyoko',
      ]);
    });

    test('端末の外で読み上げる声と、使うとダウンロードが始まる声は出さない', () async {
      engineVoices = [
        _android('ja-jp-x-htm-local'),
        _android('ja-jp-x-htm-network', network: true),
        _android('ja-jp-x-jab-local',
            features: 'networkTimeoutMs\tnotInstalled'),
      ];
      final container = containerWithEngine();

      final voices = await container.read(ttsProvider.notifier).voices();

      expect(voices.map((v) => v.id), ['ja-jp-x-htm-local']);
    });

    test('エンジンが声の一覧を返さなくても、空の一覧にして落ちない', () async {
      when(() => tts.getVoices).thenThrow(Exception('engine not bound'));
      final container = containerWithEngine();

      final voices = await container.read(ttsProvider.notifier).voices();

      expect(voices, isEmpty);
    });
  });

  group('声を選ぶ', () {
    test('選んだ声を保存し、エンジンにその声を渡す', () async {
      final container = containerWithEngine();
      await container.read(settingsNotifierProvider.future);
      // 本番と同じく、読み上げは設定を変える前に準備を終えている
      await container.read(ttsProvider.notifier).initialize();

      await container
          .read(settingsNotifierProvider.notifier)
          .setTTSVoice(_kyokoEnhancedId);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tts_voice'), _kyokoEnhancedId);
      expect(
        container.read(settingsNotifierProvider).requireValue.ttsVoiceId,
        _kyokoEnhancedId,
      );
      final passed = verify(() => tts.setVoice(captureAny())).captured.single
          as Map<String, String>;
      expect(passed['identifier'], _kyokoEnhancedId);
      expect(passed['name'], 'Kyoko');
      expect(passed['locale'], 'ja-JP');
    });

    test('「標準」に戻すと保存を消し、エンジンを日本語の標準の声に戻す', () async {
      SharedPreferences.setMockInitialValues({'tts_voice': _kyokoEnhancedId});
      final container = containerWithEngine();
      await container.read(settingsNotifierProvider.future);
      await container.read(ttsProvider.notifier).initialize();
      clearInteractions(tts);

      await container.read(settingsNotifierProvider.notifier).setTTSVoice(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('tts_voice'), isFalse);
      expect(
        container.read(settingsNotifierProvider).requireValue.ttsVoiceId,
        isNull,
      );
      verify(() => tts.setLanguage('ja-JP')).called(1);
      verifyNever(() => tts.setVoice(any()));
    });

    test('エンジンが声を切り替えられなかったら、標準の声に戻す', () async {
      when(() => tts.setVoice(any())).thenAnswer((_) async => 0);
      final container = containerWithEngine();
      await container.read(settingsNotifierProvider.future);
      await container.read(ttsProvider.notifier).initialize();
      clearInteractions(tts);

      await container
          .read(settingsNotifierProvider.notifier)
          .setTTSVoice(_kyokoEnhancedId);

      verifyInOrder([
        () => tts.setVoice(any()),
        () => tts.setLanguage('ja-JP'),
      ]);
    });

    test('声の切り替えが例外で失敗しても、標準の声に戻す', () async {
      when(() => tts.setVoice(any())).thenThrow(Exception('voice failed'));
      final container = containerWithEngine();
      await container.read(settingsNotifierProvider.future);
      await container.read(ttsProvider.notifier).initialize();
      clearInteractions(tts);

      await container
          .read(settingsNotifierProvider.notifier)
          .setTTSVoice(_kyokoEnhancedId);

      verify(() => tts.setLanguage('ja-JP')).called(1);
    });
  });

  group('次の起動', () {
    test('保存した声を、起動したときエンジンに渡す', () async {
      SharedPreferences.setMockInitialValues({'tts_voice': _kyokoEnhancedId});
      final container = containerWithEngine();
      final settings = await container.read(settingsNotifierProvider.future);
      expect(settings.ttsVoiceId, _kyokoEnhancedId);

      await container.read(ttsProvider.notifier).initialize();
      // 保存済みの設定の反映は初期化の後で走る
      await Future<void>.delayed(Duration.zero);

      final passed = verify(() => tts.setVoice(captureAny())).captured.single
          as Map<String, String>;
      expect(passed['identifier'], _kyokoEnhancedId);
    });

    test('保存した声が端末から消えていたら、標準の声で読み上げる。保存は消さない', () async {
      SharedPreferences.setMockInitialValues({'tts_voice': _kyokoEnhancedId});
      engineVoices = [_ios('Kyoko', 'default', 'female')];
      final container = containerWithEngine();
      await container.read(settingsNotifierProvider.future);

      await container.read(ttsProvider.notifier).initialize();
      await Future<void>.delayed(Duration.zero);
      await container.read(ttsProvider.notifier).speak('こんにちは');

      verifyNever(() => tts.setVoice(any()));
      verify(() => tts.speak('こんにちは')).called(1);
      // 声を入れ直せば、また選んだ声で読む
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tts_voice'), _kyokoEnhancedId);
    });

    test('保存された値が文字列でなくても、ほかの設定は復元する', () async {
      SharedPreferences.setMockInitialValues({
        'tts_voice': 3,
        'tts_speed': 'slow',
      });
      final container = containerWithEngine();

      final settings = await container.read(settingsNotifierProvider.future);

      expect(settings.ttsVoiceId, isNull);
      expect(settings.ttsSpeed.name, 'slow');
    });
  });

  test('初期化をやり直しても、選んだ声を言語の設定で上書きしない', () async {
    final service = TTSService(tts: tts);
    await service.setVoice(_kyokoEnhancedId);
    clearInteractions(tts);

    await service.initialize();

    verifyInOrder([
      () => tts.setLanguage('ja-JP'),
      () => tts.setVoice(any()),
    ]);
  });
}
