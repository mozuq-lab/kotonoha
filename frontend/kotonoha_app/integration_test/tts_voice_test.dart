/// 読み上げの声を選ぶ（本物のエンジンで）
///
/// 設定画面に端末の声が並び、選ぶとその声で読み上げ、起動し直しても残る。
/// 並ぶ声に、端末の外で読み上げる声が無いこと（守る約束 ②）を本物の一覧で見る。
/// Web では声を選ばせない。
@Tags(['e2e'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/persistence/recreated_areas_provider.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/settings/presentation/widgets/tts_voice_settings_widget.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_voice.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';

import 'helpers/test_helpers.dart';

/// 端末に残った設定を消さずに、アプリを起動し直す
Future<void> _relaunchKeepingSettings(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  final outcomes = await initHive();
  await tester.pumpWidget(ProviderScope(
    overrides: [corruptionOutcomesProvider.overrideWithValue(outcomes)],
    child: const KotonohaApp(),
  ));
  await tester.pumpAndSettle();
}

/// 設定画面の声の一覧が届くまで待つ（最大 6 秒）
Future<List<TTSVoice>> _waitForVoices(WidgetTester tester) async {
  final chips = find.descendant(
    of: find.byType(TTSVoiceSettingsWidget),
    matching: find.byType(ChoiceChip),
  );
  for (var i = 0; i < 60 && chips.evaluate().length < 2; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return appContainer(tester).read(ttsVoicesProvider.future);
}

void main() {
  initializeE2ETestBinding();

  testWidgets('端末の声を選ぶとその声で読み上げ、起動し直しても残る', (tester) async {
    // エンジンの一覧はアプリの起動より前に聞く。FlutterTts は作るたびにチャネルの
    // 受け口を付け替えるので、起動の後に作るとアプリが開始の知らせを受け取れない
    final raw = (await FlutterTts().getVoices as List).cast<Map>();
    await pumpApp(tester);
    await openFromHome(tester, '設定');

    final voices = await _waitForVoices(tester);
    expect(voices, isNotEmpty, reason: '端末の日本語の声が一覧に出ない');

    // 一覧の声はどれも、エンジンが「通信が要らない」と言う声
    for (final voice in voices) {
      final match = raw.where((r) =>
          r['name'] == voice.name &&
          r['locale'] == voice.locale &&
          (voice.identifier == null || r['identifier'] == voice.identifier));
      expect(match, isNotEmpty, reason: '${voice.id} がエンジンの一覧に無い');
      expect(match.every((r) => r['network_required'] != '1'), isTrue,
          reason: '${voice.id} は端末の外で読み上げる声');
    }

    // 「標準」の次（品質がいちばん高い声）を選ぶ
    final chosen = voices.first;
    final chip = find
        .descendant(
          of: find.byType(TTSVoiceSettingsWidget),
          matching: find.byType(ChoiceChip),
        )
        .at(1);
    await scrollIntoView(tester, chip);
    await tapAndExpectSpeech(tester, chip);
    await waitUntilQuiet(tester);
    expect(appContainer(tester).read(ttsProvider).errorMessage, isNull,
        reason: '選んだ声で読み上げられない');

    var settings =
        await appContainer(tester).read(settingsNotifierProvider.future);
    expect(settings.ttsVoiceId, chosen.id, reason: '選んだ声が設定に残らない');

    await _relaunchKeepingSettings(tester);
    settings = await appContainer(tester).read(settingsNotifierProvider.future);
    expect(settings.ttsVoiceId, chosen.id, reason: '選んだ声が再起動で戻る');

    await typeOnCharacterBoard(tester, 'こんにちは');
    await tapAndExpectSpeech(tester, find.text('読み上げ'));
    await waitUntilQuiet(tester);
    expect(appContainer(tester).read(ttsProvider).errorMessage, isNull,
        reason: '起動し直した後、選んだ声で読み上げられない');
  }, skip: kIsWeb);

  testWidgets('Web では声を選ばせない', (tester) async {
    await pumpApp(tester);
    await openFromHome(tester, '設定');
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('読み上げの声'), findsNothing);
  }, skip: !kIsWeb);
}
