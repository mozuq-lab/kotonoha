/// 読み上げた文は、どの入口から読み上げても履歴に残ること（REQ-601、ヘルプ）
/// 空白や改行だけの文は、空文字と同じく読み上げず、履歴にも残さないこと
///
/// 以前はお気に入り画面とシンプルモードのお気に入りから読み上げた文が
/// 履歴に残らなかった（ホームのお気に入りボタンからは残った）。
/// 本番と同じ router（`KotonohaApp`）で、利用者の操作から確かめる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/mock_flutter_tts.dart';
import '../../../mocks/mock_volume_controller.dart';

void main() {
  late MockFlutterTts tts;
  late MockVolumeController volume;
  const favorite = '背中がかゆい';

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
    registerFallbackValue(() {});
  });

  setUp(() {
    tts = MockFlutterTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    stubSpeakThatStarts(tts);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    volume = MockVolumeController();
    when(() => volume.getVolume()).thenAnswer((_) async => 0.5);
    when(() => volume.getMute()).thenAnswer((_) async => false);
  });

  Future<ProviderContainer> startApp(
    WidgetTester tester, {
    bool simpleMode = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'tutorial_completed': true,
      if (simpleMode) 'simple_mode': true,
    });
    final container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts))),
      volumeServiceProvider
          .overrideWithValue(VolumeService(volumeController: volume)),
    ]);
    addTearDown(container.dispose);
    await container.read(favoriteProvider.notifier).addFavorite(favorite);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KotonohaApp(),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  List<(String, HistoryType)> history(ProviderContainer c) => c
      .read(historyProvider)
      .histories
      .map((h) => (h.content, h.type))
      .toList();

  group('お気に入りから読み上げた文は、どこから読み上げても履歴に残る', () {
    testWidgets('ホームのお気に入りボタン', (tester) async {
      final container = await startApp(tester);

      await tester.tap(find.text(favorite));
      await tester.pumpAndSettle();

      verify(() => tts.speak(favorite)).called(1);
      expect(history(container), [(favorite, HistoryType.quickButton)]);
    });

    testWidgets('お気に入り画面', (tester) async {
      final container = await startApp(tester);
      await tester.tap(find.byTooltip('お気に入り'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(favorite).first);
      await tester.pumpAndSettle();

      verify(() => tts.speak(favorite)).called(1);
      expect(history(container), [(favorite, HistoryType.quickButton)]);
    });

    testWidgets('シンプルモードのお気に入り', (tester) async {
      final container = await startApp(tester, simpleMode: true);
      final id = container.read(favoriteProvider).favorites.single.id;

      await tester.tap(find.byKey(Key('simple_mode_favorite_$id')));
      await tester.pumpAndSettle();

      verify(() => tts.speak(favorite)).called(1);
      expect(history(container), [(favorite, HistoryType.quickButton)]);
    });
  });

  testWidgets('空白だけの文は読み上げず、履歴にも残さず、入力欄はそのまま', (tester) async {
    // iPad (A16) の縦向き。文字盤の「空白」まで画面に収める
    tester.view.physicalSize = const Size(1640, 2360);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = await startApp(tester);

    await tester.tap(find.text('空白'));
    await tester.tap(find.text('空白'));
    await tester.pumpAndSettle();
    expect(container.read(inputBufferProvider), isNotEmpty);
    final typed = container.read(inputBufferProvider);
    expect(typed.trim(), isEmpty);

    await tester.tap(find.text('読み上げ'));
    await tester.pumpAndSettle();

    verifyNever(() => tts.speak(any()));
    expect(history(container), isEmpty);
    expect(container.read(inputBufferProvider), typed);
  });
}
