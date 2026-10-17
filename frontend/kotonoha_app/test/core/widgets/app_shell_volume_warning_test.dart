/// 音量 0 のまま読み上げたら、どの画面にいても「音量が0です」と告げること
/// （EDGE-202、`docs/spec/kotonoha-requirements.md`）
///
/// 以前は警告をホームの本文にだけ置いていたので、履歴・お気に入り・定型文の
/// 画面から読み上げても出なかった（隠れたホームが状態だけを立て、戻ったときに
/// 出た）。本番と同じ ShellRoute（`KotonohaApp` の router）で確かめる。
/// `MaterialApp(home: …)` の 1 本の Navigator では構成が違い、偽の緑になる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_flutter_tts.dart';
import '../../mocks/mock_volume_controller.dart';

const _warning = '音量が0です';

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
  });

  /// 端末の音量を決める（外部 SDK の境界）
  void setDeviceVolume(double value) {
    when(() => volume.getVolume()).thenAnswer((_) async => value);
    when(() => volume.getMute()).thenAnswer((_) async => value == 0.0);
  }

  /// 本番と同じ router でアプリを起動する。履歴・お気に入りを 1 件ずつ入れておく
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
    await container.read(settingsNotifierProvider.future);
    await container
        .read(historyProvider.notifier)
        .addHistory('のどが渇いた', HistoryType.manualInput);
    await container.read(favoriteProvider.notifier).addFavorite('背中がかゆい');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KotonohaApp(),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// 警告が出ても、開いていた画面のまま（Navigator が作り直されてホームに戻らない）
  void expectStillOnSubScreen() {
    expect(find.byType(BackButton), findsOneWidget,
        reason: '警告が出たときに、開いていた画面が閉じた');
  }

  Future<void> openFromHome(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  group('音量 0 で読み上げると、その画面に警告が 1 つだけ出る', () {
    testWidgets('ホーム（はい）', (tester) async {
      setDeviceVolume(0.0);
      await startApp(tester);
      expect(find.text(_warning), findsNothing);

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('はい')).called(1);
      expect(find.text(_warning), findsOneWidget);
    });

    testWidgets('ホームのシンプルモード（はい）', (tester) async {
      setDeviceVolume(0.0);
      await startApp(tester, simpleMode: true);

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('はい')).called(1);
      expect(find.text(_warning), findsOneWidget);
    });

    testWidgets('履歴', (tester) async {
      setDeviceVolume(0.0);
      await startApp(tester);
      await openFromHome(tester, '履歴');

      await tester.tap(find.text('のどが渇いた'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('のどが渇いた')).called(1);
      expect(find.text(_warning), findsOneWidget);
      expectStillOnSubScreen();
    });

    testWidgets('お気に入り', (tester) async {
      setDeviceVolume(0.0);
      await startApp(tester);
      await openFromHome(tester, 'お気に入り');

      await tester.tap(find.text('背中がかゆい').first);
      await tester.pumpAndSettle();

      verify(() => tts.speak('背中がかゆい')).called(1);
      expect(find.text(_warning), findsOneWidget);
      expectStillOnSubScreen();
    });

    testWidgets('定型文', (tester) async {
      setDeviceVolume(0.0);
      await startApp(tester);
      await openFromHome(tester, '定型文');

      // 定型文の画面は開いたときに既定の定型文を入れる
      await tester.tap(find.text('おはようございます'));
      await tester.pumpAndSettle();

      verify(() => tts.speak('おはようございます')).called(1);
      expect(find.text(_warning), findsOneWidget);
      expectStillOnSubScreen();
    });
  });

  testWidgets('音量が 0 でなければ、読み上げても警告は出ない', (tester) async {
    setDeviceVolume(0.5);
    await startApp(tester);
    await openFromHome(tester, '履歴');

    await tester.tap(find.text('のどが渇いた'));
    await tester.pumpAndSettle();

    verify(() => tts.speak('のどが渇いた')).called(1);
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('閉じるボタンを押すと警告が消える', (tester) async {
    setDeviceVolume(0.0);
    await startApp(tester);
    await openFromHome(tester, '履歴');
    await tester.tap(find.text('のどが渇いた'));
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(VolumeWarningWidget),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pumpAndSettle();

    expect(find.text(_warning), findsNothing);
  });

  testWidgets('警告は画面を移っても残り、音量を上げて次に読み上げると消える', (tester) async {
    setDeviceVolume(0.0);
    final container = await startApp(tester);
    await openFromHome(tester, 'お気に入り');
    await tester.tap(find.text('背中がかゆい').first);
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsOneWidget);
    // 読み上げを終える（serviceOverride の TTSNotifier はエンジンの完了の
    // 知らせを受けないので、停止で読み上げ中でなくする）
    await container.read(ttsProvider.notifier).stop();
    await tester.pumpAndSettle();

    // ホームへ戻っても、音量は 0 のままかもしれないので消さない
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsOneWidget);

    // 音量を上げて読み上げると、その読み上げで確かめ直して消える
    setDeviceVolume(0.5);
    await tester.tap(find.text('いいえ'));
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('警告の帯はステータスバーの下に出て、画面の AppBar はその直下に続く', (tester) async {
    // ステータスバーのある端末（論理 24px）
    tester.view.padding =
        FakeViewPadding(top: 24 * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetPadding);
    setDeviceVolume(0.0);
    await startApp(tester);
    await openFromHome(tester, '履歴');
    final appBarWithoutWarning = tester.getRect(find.byType(AppBar));

    await tester.tap(find.text('のどが渇いた'));
    await tester.pumpAndSettle();

    final warning = tester.getRect(find.byType(VolumeWarningWidget));
    final appBar = tester.getRect(find.byType(AppBar));
    expect(warning.top, greaterThanOrEqualTo(24), reason: '帯がステータスバーに重なる');
    expect(appBar.top, greaterThanOrEqualTo(warning.bottom));
    expect(appBar.height, appBarWithoutWarning.height - 24,
        reason: '帯の下の AppBar がステータスバーの分の空きを残している');
  });
}
