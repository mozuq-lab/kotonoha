/// 設定画面で読み上げの声を選ぶ
///
/// 端末の声を名前・性別・品質で並べ、選ぶとその声で試しに読み上げる。
/// モックは外部 SDK（flutter_tts）の境界だけ。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/settings/presentation/widgets/tts_voice_settings_widget.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../mocks/mock_flutter_tts.dart';

void main() {
  late MockFlutterTts tts;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tts = MockFlutterTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.setVoice(any())).thenAnswer((_) async => 1);
    when(() => tts.getVoices).thenAnswer((_) async => [
          {
            'name': 'Kyoko',
            'locale': 'ja-JP',
            'quality': 'default',
            'gender': 'female',
            'identifier': 'com.apple.voice.compact.ja-JP.Kyoko',
          },
          {
            'name': 'Kyoko',
            'locale': 'ja-JP',
            'quality': 'enhanced',
            'gender': 'female',
            'identifier': 'com.apple.voice.enhanced.ja-JP.Kyoko',
          },
          {
            'name': 'Otoya',
            'locale': 'ja-JP',
            'quality': 'premium',
            'gender': 'male',
            'identifier': 'com.apple.voice.premium.ja-JP.Otoya',
          },
        ]);
    when(() => tts.setCompletionHandler(any())).thenReturn(null);
    when(() => tts.setErrorHandler(any())).thenReturn(null);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    stubSpeakThatStarts(tts);
  });

  Future<void> pumpVoiceSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ttsProvider.overrideWith(
            () => TTSNotifier(serviceOverride: TTSService(tts: tts)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TTSVoiceSettingsWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('端末の声を、性別と品質を添えて並べる。初めは「標準」', (tester) async {
    await pumpVoiceSettings(tester);

    expect(find.text('読み上げの声'), findsOneWidget);
    for (final label in [
      '標準',
      'Otoya（男性・プレミアム）',
      'Kyoko（女性・拡張）',
      'Kyoko（女性）'
    ]) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget,
          reason: label);
    }
    final standard =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '標準'));
    expect(standard.selected, isTrue);
  });

  testWidgets('iOS では声を足す場所（読み上げコンテンツ）を案内する', (tester) async {
    await pumpVoiceSettings(tester);

    expect(find.textContaining('読み上げコンテンツ'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android では声を足す場所（テキスト読み上げ）を案内する', (tester) async {
    await pumpVoiceSettings(tester);

    expect(find.textContaining('テキスト読み上げ'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('声を選ぶと保存し、その声で試しに読み上げる', (tester) async {
    await pumpVoiceSettings(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Kyoko（女性・拡張）'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getString('tts_voice'), 'com.apple.voice.enhanced.ja-JP.Kyoko');
    final chip = tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Kyoko（女性・拡張）'));
    expect(chip.selected, isTrue);
    verifyInOrder([
      () => tts.setVoice(any()),
      () => tts.speak(TTSVoiceSettingsWidget.sampleText),
    ]);
  });

  testWidgets('保存した声が端末に無ければ「標準」を選んだ状態で見せる', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'tts_voice': 'com.apple.voice.enhanced.ja-JP.Hattori'});
    await pumpVoiceSettings(tester);

    final standard =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '標準'));
    expect(standard.selected, isTrue);
  });
}
