/// ホームのお気に入りボタンと「読み上げ」ボタンも、大ボタン・定型文と同じく
/// 300ms 以内の連続タップを誤操作として無視すること（2026-10-17 の人の決定）
///
/// 以前は、お気に入りボタンを二度押しすると履歴が 2 件でき、読み上げも頭から
/// やり直しになった。「読み上げ」ボタンは押すとすぐ「停止」に変わるので、
/// 二度押しの 2 回目で読み上げが黙った。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
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

  Future<ProviderContainer> startApp(WidgetTester tester) async {
    // iPad (A16) の縦向き。文字盤まで画面に収める
    tester.view.physicalSize = const Size(1640, 2360);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});
    final container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts))),
      volumeServiceProvider
          .overrideWithValue(VolumeService(volumeController: volume)),
    ]);
    addTearDown(container.dispose);
    await container.read(favoriteProvider.notifier).addFavorite('痛い');
    await container.read(favoriteProvider.notifier).addFavorite('トイレ');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KotonohaApp(),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// デバウンスは実時間（DateTime.now）で判定するので、実時間で待つ
  Future<void> waitRealTime(WidgetTester tester, int ms) async {
    await tester
        .runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    await tester.pump();
  }

  List<String> history(ProviderContainer c) =>
      c.read(historyProvider).histories.map((h) => h.content).toList();

  group('ホームのお気に入りボタン', () {
    testWidgets('100ms 間隔の二度押しは 1 回に扱う（読み上げ 1 回・履歴 1 件）', (tester) async {
      final container = await startApp(tester);

      await tester.tap(find.text('痛い'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('痛い'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('痛い')).called(1);
      expect(history(container), ['痛い']);
    });

    testWidgets('すぐ隣のボタンに触れても、300ms 以内なら 1 回目だけ', (tester) async {
      final container = await startApp(tester);

      await tester.tap(find.text('痛い'));
      await tester.tap(find.text('トイレ'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('痛い')).called(1);
      verifyNever(() => tts.speak('トイレ'));
      expect(history(container), ['痛い']);
    });

    testWidgets('300ms より後に押せば、もう一度読み上げる', (tester) async {
      final container = await startApp(tester);

      await tester.tap(find.text('痛い'));
      await tester.pump();
      await waitRealTime(tester, 400);
      await tester.tap(find.text('トイレ'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('痛い')).called(1);
      verify(() => tts.speak('トイレ')).called(1);
      expect(history(container), ['トイレ', '痛い']);
    });
  });

  group('ホームの「読み上げ」ボタン', () {
    Future<ProviderContainer> typeAndSpeak(WidgetTester tester) async {
      final container = await startApp(tester);
      await tester.tap(find.text('あ'));
      await tester.pump();
      await tester.tap(find.text('読み上げ'));
      await tester.pump();
      expect(container.read(ttsProvider).state, TTSState.speaking);
      expect(find.text('停止'), findsOneWidget);
      return container;
    }

    testWidgets('二度押しの 2 回目（100ms 後の「停止」）は無視し、読み上げを続ける', (tester) async {
      final container = await typeAndSpeak(tester);
      clearInteractions(tts);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('停止'));
      await tester.pump();

      verifyNever(() => tts.stop());
      expect(container.read(ttsProvider).state, TTSState.speaking);
      expect(history(container), ['あ']);
    });

    testWidgets('300ms より後に押した「停止」は、今までどおり止める', (tester) async {
      final container = await typeAndSpeak(tester);
      clearInteractions(tts);

      await waitRealTime(tester, 400);
      await tester.tap(find.text('停止'));
      await tester.pump();

      verify(() => tts.stop()).called(1);
      expect(container.read(ttsProvider).state, isNot(TTSState.speaking));
    });
  });
}
