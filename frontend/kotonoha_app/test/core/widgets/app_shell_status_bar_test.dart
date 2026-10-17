/// 全画面共通の帯（保存できない・読み上げ失敗・オフライン）が、OS のステータスバーに
/// 重ならないこと
///
/// 以前は帯を画面の一番上（ステータスバーの裏）に描いていた。iPad では、
/// 読み上げ失敗の帯の文頭が時計・日付と重なって読めなかった（シミュレータで撮影）。
/// 保存できない告知（守る約束 ①）・読み上げ失敗の告知（③）が読めなくなる。
/// 本番と同じ router（`KotonohaApp`）で、ステータスバーのある端末を作って確かめる。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_failure_banner.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_flutter_tts.dart';

const _statusBar = 24.0;

void main() {
  late MockFlutterTts tts;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
  });

  setUp(() {
    tts = MockFlutterTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.stop()).thenAnswer((_) async => 1);
  });

  /// [storageReady]: 保存できる状態にして、保存できない帯を出さない
  /// （テストの環境には Hive が無いので、既定では保存できない帯が出る）
  Future<ProviderContainer> startApp(
    WidgetTester tester, {
    bool storageReady = true,
  }) async {
    // ステータスバーのある端末（上に論理 24px）
    tester.view.padding =
        FakeViewPadding(top: _statusBar * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetPadding);
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});
    final container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts))),
      if (storageReady)
        persistenceStateProvider.overrideWithValue(const PersistenceReady()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KotonohaApp(),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// 帯がステータスバーの下にあり、画面の AppBar（ツールバー）が帯より下にある
  void expectBelowStatusBar(WidgetTester tester, Finder banner) {
    expect(banner, findsOneWidget);
    final rect = tester.getRect(banner);
    expect(rect.height, greaterThan(0));
    expect(rect.top, greaterThanOrEqualTo(_statusBar),
        reason: '帯が OS のステータスバーに重なる');
    expect(tester.getRect(find.byType(NavigationToolbar)).top,
        greaterThanOrEqualTo(rect.bottom));
  }

  testWidgets('保存できない帯', (tester) async {
    await startApp(tester, storageReady: false);
    expect(find.textContaining('保存できません'), findsOneWidget);

    expectBelowStatusBar(tester, find.byType(PersistenceBanner));
  });

  testWidgets('読み上げ失敗の帯', (tester) async {
    when(() => tts.setLanguage(any()))
        .thenAnswer((_) async => throw Exception('no voice'));
    await startApp(tester);

    expectBelowStatusBar(tester, find.byType(TtsFailureBanner));
  });

  testWidgets('オフラインの帯', (tester) async {
    final container = await startApp(tester);
    await container.read(networkProvider.notifier).setOffline();
    await tester.pumpAndSettle();

    expectBelowStatusBar(tester, find.byType(OfflineBanner));
  });

  testWidgets('帯が無いとき、AppBar のツールバーはステータスバーの直下（今までと同じ位置）', (tester) async {
    await startApp(tester);
    expect(find.byType(PersistenceBanner), findsOneWidget);
    expect(tester.getRect(find.byType(PersistenceBanner)).height, 0);

    final toolbar = tester.getRect(find.byType(NavigationToolbar));
    expect(toolbar.top, _statusBar);
    expect(toolbar.height, kToolbarHeight);
  });

  testWidgets('ステータスバーの文字色だけを決め、Android のナビゲーションバーの色は変えない', (tester) async {
    await startApp(tester);
    final regions = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(find.descendant(
          of: find.byType(AppShell),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ))
        .map((r) => r.value)
        .toList();
    // シェルの一番上（ステータスバーの帯）が決める
    final style = regions.first;
    expect(style.statusBarIconBrightness, Brightness.dark,
        reason: '明るいテーマでは暗い文字');
    expect(style.systemNavigationBarColor, isNull,
        reason: 'AppBar と同じく、ナビゲーションバーには触れない（黒くなる）');
    expect(style.systemNavigationBarIconBrightness, isNull);
  });
}
