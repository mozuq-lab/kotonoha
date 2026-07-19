/// HomeScreen シンプルモード統合テスト（fix/improvement-p0-p2）
///
/// シンプルモード（疲労時・症状進行時の簡易画面）がホーム画面に正しく
/// 統合されていることを確認する。
///
/// - AppBarにトグルアイコンが表示され、タップで設定がONになる
/// - シンプルモードON時は文字盤が非表示になり、SimpleModeViewが表示される
/// - シンプルモード中もTTS読み上げが機能する
/// - シンプルモード中もVolumeWarningWidgetが機能する
/// - 「通常モードに戻る」操作、AppBarトグル操作の両方でOFFに戻せる
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/simple_mode/presentation/simple_mode_view.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';

import '../../../mocks/mock_flutter_tts.dart';
import '../../../mocks/mock_volume_controller.dart';

TTSNotifier _createTestTTSNotifier(MockFlutterTts mockFlutterTts) {
  final service = TTSService(tts: mockFlutterTts);
  return TTSNotifier(serviceOverride: service);
}

void main() {
  late MockFlutterTts mockFlutterTts;
  late MockVolumeController mockVolumeController;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockFlutterTts = MockFlutterTts();
    when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => mockFlutterTts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
    when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    when(() => mockFlutterTts.setCompletionHandler(any())).thenReturn(null);

    mockVolumeController = MockVolumeController();
    when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.5);
    when(() => mockVolumeController.getMute()).thenAnswer((_) async => false);
  });

  ProviderContainer buildContainer({double volume = 0.5}) {
    when(() => mockVolumeController.getVolume())
        .thenAnswer((_) async => volume);
    when(() => mockVolumeController.getMute())
        .thenAnswer((_) async => volume == 0.0);

    return ProviderContainer(
      overrides: [
        ttsProvider.overrideWith(() => _createTestTTSNotifier(mockFlutterTts)),
        volumeServiceProvider.overrideWithValue(
          VolumeService(volumeController: mockVolumeController),
        ),
      ],
    );
  }

  group('シンプルモード切替導線', () {
    testWidgets('通常モードではAppBarに「シンプルモードに切替」アイコンが表示される', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('シンプルモードに切替'), findsOneWidget);
      expect(find.byType(CharacterBoardWidget), findsOneWidget);
      expect(find.byType(SimpleModeView), findsNothing);
    });

    testWidgets('トグルアイコンをタップするとシンプルモードに切り替わり、文字盤が非表示になる', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('シンプルモードに切替'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleModeView), findsOneWidget);
      expect(find.byType(CharacterBoardWidget), findsNothing);
      expect(find.byTooltip('シンプルモードを解除'), findsOneWidget);

      final settings = container.read(settingsNotifierProvider).requireValue;
      expect(settings.simpleMode, isTrue);
    });

    testWidgets('シンプルモード中は他のナビゲーションアイコンが表示されない', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .setSimpleMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('対面表示'), findsNothing);
      expect(find.byTooltip('定型文'), findsNothing);
      expect(find.byTooltip('履歴'), findsNothing);
      expect(find.byTooltip('お気に入り'), findsNothing);
      expect(find.byTooltip('設定'), findsNothing);
    });

    testWidgets('シンプルモード画面の「通常モードに戻る」ボタンで通常モードに戻せる', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .setSimpleMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('exit_simple_mode_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CharacterBoardWidget), findsOneWidget);
      expect(find.byType(SimpleModeView), findsNothing);

      final settings = container.read(settingsNotifierProvider).requireValue;
      expect(settings.simpleMode, isFalse);
    });

    testWidgets('AppBarのトグルアイコンでも通常モードに戻せる', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .setSimpleMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('シンプルモードを解除'));
      await tester.pumpAndSettle();

      expect(find.byType(CharacterBoardWidget), findsOneWidget);
    });
  });

  group('シンプルモード中の各種機能', () {
    testWidgets('シンプルモード中もクイック応答タップでTTS読み上げが呼ばれる', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .setSimpleMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      verify(() => mockFlutterTts.speak('はい')).called(1);
    });

    testWidgets('シンプルモード中も音量ゼロ警告が機能する', (tester) async {
      final container = buildContainer(volume: 0.0);
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .setSimpleMode(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('音量が0です'), findsNothing);

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      expect(find.byType(VolumeWarningWidget), findsOneWidget);
      expect(find.text('音量が0です'), findsOneWidget);
    });
  });
}
