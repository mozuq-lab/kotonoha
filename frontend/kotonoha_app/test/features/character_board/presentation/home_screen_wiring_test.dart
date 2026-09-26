/// HomeScreen 配線確認テスト（fix/improvement-p0-p2）
/// バッチAで達成したレスポンシブ対応を踏襲しつつ、実装済みだが
/// 画面に配線されていなかった以下の機能をホーム画面へ統合したことを確認する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';

import '../../../mocks/mock_flutter_tts.dart';
import '../../../mocks/mock_volume_controller.dart';

/// モックFlutterTtsを使用するTTSNotifierを作成するヘルパー
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
    registerFallbackValue(() {});
  });

  setUp(() {
    mockFlutterTts = MockFlutterTts();
    when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => mockFlutterTts.setSpeechRate(any())).thenAnswer((_) async => 1);
    stubSpeakThatStarts(mockFlutterTts);
    when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
    when(() => mockFlutterTts.setCompletionHandler(any())).thenReturn(null);

    mockVolumeController = MockVolumeController();
    // デフォルトは音量正常（0.5）とする
    when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.5);
    when(() => mockVolumeController.getMute()).thenAnswer((_) async => false);
  });

  Future<ProviderContainer> buildContainer({double volume = 0.5}) async {
    when(() => mockVolumeController.getVolume())
        .thenAnswer((_) async => volume);
    when(() => mockVolumeController.getMute())
        .thenAnswer((_) async => volume == 0.0);

    final container = ProviderContainer(
      overrides: [
        ttsProvider.overrideWith(() => _createTestTTSNotifier(mockFlutterTts)),
        volumeServiceProvider.overrideWithValue(
          VolumeService(volumeController: mockVolumeController),
        ),
      ],
    );
    for (final content in [
      '痛い',
      'トイレ',
      '暑い',
      '寒い',
      '水',
      '眠い',
      '助けて',
      '待って',
    ]) {
      await container.read(favoriteProvider.notifier).addFavorite(content);
    }
    return container;
  }

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(820, 1180),
  ]) {
    testWidgets('標準アプリの$sizeでは入力後にAI変換を表示し、読み上げ・削除・全消去も使える', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const KotonohaApp(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('あ').first);
      await tester.tap(find.text('い').first);
      await tester.pumpAndSettle();
      expect(container.read(inputBufferProvider), 'あい');
      // 初回リリースから AI 変換を含める（ADR-007）
      expect(find.byType(AIConversionButton), findsOneWidget);
      expect(find.text('AI変換'), findsOneWidget);

      // 横持ちでは入力1行を確保した操作域をスクロールして使う。
      await tester.ensureVisible(find.text('読み上げ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('読み上げ'));
      await tester.pumpAndSettle();
      verify(() => mockFlutterTts.speak('あい')).called(1);
      expect(container.read(historyProvider).histories.first.content, 'あい');

      await tester.ensureVisible(find.byType(DeleteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DeleteButton));
      await tester.pumpAndSettle();
      expect(container.read(inputBufferProvider), 'あ');

      await tester.ensureVisible(find.byType(ClearAllButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ClearAllButton));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('はい'),
      ));
      await tester.pumpAndSettle();
      expect(container.read(inputBufferProvider), isEmpty);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  group('お気に入りのホーム画面統合', () {
    testWidgets('お気に入り上位8件がホーム画面に表示される', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteShortcutButton), findsNWidgets(8));
      expect(find.text('痛い'), findsOneWidget);
      expect(find.text('トイレ'), findsOneWidget);
    });

    testWidgets('お気に入りをタップすると読み上げが呼ばれ、履歴が大ボタン扱いで保存される', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('痛い'));
      await tester.pumpAndSettle();

      // TTS読み上げが呼ばれたことを確認
      verify(() => mockFlutterTts.speak('痛い')).called(1);

      // 履歴に大ボタン(quickButton)として保存されたことを確認
      final histories = container.read(historyProvider).histories;
      expect(histories, isNotEmpty);
      expect(histories.first.content, '痛い');
      expect(
        histories.first.type,
        HistoryType.quickButton,
        reason: 'お気に入りボタン由来の履歴はHistoryType.quickButtonである必要がある',
      );
    });

    testWidgets('横持ちスマホ幅の小さい可視高さでもお気に入りが表示される', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FavoriteShortcutButton), findsWidgets);
    });
  });

  group('クイック応答・履歴種類の修正確認', () {
    testWidgets('クイック応答（はい）タップでspeak()が1回だけ呼ばれ、履歴が大ボタン扱いで保存される',
        (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      // バグ修正従来はonTTSSpeakとonResponse双方でspeakが
      // 呼ばれ二重に読み上げられていた。1回のみ呼ばれることを確認する。
      verify(() => mockFlutterTts.speak('はい')).called(1);

      final histories = container.read(historyProvider).histories;
      expect(histories, isNotEmpty);
      expect(histories.first.content, 'はい');
      expect(
        histories.first.type,
        HistoryType.quickButton,
        reason: 'クイック応答由来の履歴は「文字盤入力」ではなくHistoryType.quickButton'
            '（大ボタン）である必要がある',
      );
    });
  });

  group('音量ゼロ警告のTTS側配線', () {
    testWidgets('音量が0の状態で読み上げを実行すると警告が表示される', (tester) async {
      final container = await buildContainer(volume: 0.0);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 警告はまだ表示されていない
      expect(find.text('音量が0です'), findsNothing);

      // クイック応答ボタンをタップして読み上げを実行する
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      // 音量0のため警告が表示される
      expect(find.byType(VolumeWarningWidget), findsOneWidget);
      expect(find.text('音量が0です'), findsOneWidget);
    });

    testWidgets('音量が正常な場合は読み上げを実行しても警告が表示されない', (tester) async {
      final container = await buildContainer(volume: 0.5);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      expect(find.text('音量が0です'), findsNothing);
    });

    testWidgets('警告表示中に閉じるボタンをタップすると警告が消える', (tester) async {
      final container = await buildContainer(volume: 0.0);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();
      expect(find.text('音量が0です'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('音量が0です'), findsNothing);
    });
  });

  group('文字盤（手動入力）の履歴種類の確認', () {
    testWidgets('文字盤で入力して読み上げると履歴はHistoryType.manualInputで保存される',
        (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 文字盤から「あ」を入力する
      await tester.tap(find.text('あ').first);
      await tester.pumpAndSettle();

      // 読み上げボタンをタップ
      await tester.tap(find.text('読み上げ'));
      await tester.pumpAndSettle();

      final histories = container.read(historyProvider).histories;
      expect(histories, isNotEmpty);
      expect(histories.first.type, HistoryType.manualInput);
    });
  });

  group('対面表示モードへの導線 (TASK-0052/0053)', () {
    testWidgets('AppBarに対面表示アイコンが表示される', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('対面表示'), findsOneWidget);
    });
  });

  group('入力上限の告知 (L-73)', () {
    testWidgets('入力欄が 1000 文字に達すると、入力欄の下に告知が出る（L-73）', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      container
          .read(inputBufferProvider.notifier)
          .setText('あ' * InputBufferNotifier.maxLength);
      await tester.pump();
      expect(find.text(InputLimitNotice.message), findsOneWidget);
    });
  });
}
