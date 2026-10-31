/// 読み上げに失敗したら、どの画面にいても利用者に告げること（守る約束 ③）
///
/// 読み上げの失敗は、以前は状態に持つだけで画面のどこにも出なかった。
/// 利用者は、読み上げたつもりで相手に伝わっていないことに気づけない。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_failure_banner.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_flutter_tts.dart';

void main() {
  late MockFlutterTts tts;
  late ProviderContainer container;
  void Function()? onStart;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
    registerFallbackValue(() {});
    registerFallbackValue((dynamic _) {});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});
    tts = MockFlutterTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    onStart = null;
    when(() => tts.setStartHandler(any())).thenAnswer(
        (i) => onStart = i.positionalArguments[0] as void Function());
    // エンジンが応答しない: 読み上げを頼んでも返らない
    when(() => tts.speak(any())).thenAnswer((_) => Completer<dynamic>().future);
    container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(() => TTSNotifier(
            serviceOverride: TTSService(
              tts: tts,
              speakTimeout: const Duration(milliseconds: 100),
            ),
          )),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: AppShell(child: Scaffold(body: Text('画面の中身'))),
      ),
    ));
    await tester.pump();
  }

  testWidgets('読み上げを始められなければ告げ、次に読み上げが始まれば消える', (tester) async {
    await pumpShell(tester);
    expect(find.textContaining('読み上げできませんでした'), findsNothing);

    unawaited(container.read(ttsProvider.notifier).speak('いいえ'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('読み上げできませんでした'), findsOneWidget,
        reason: '読み上げに失敗しても画面が黙っている');

    // エンジンが戻った: 頼めば開始の知らせを返す
    when(() => tts.speak(any())).thenAnswer((_) async {
      onStart?.call();
      return 1;
    });
    await container.read(ttsProvider.notifier).speak('痛い');
    await tester.pump();

    expect(find.textContaining('読み上げできませんでした'), findsNothing,
        reason: '読み上げが始まったのに失敗の告知が残る');
  });

  group('起動時に読み上げを準備できなかったとき（まだ押していない）', () {
    setUp(() {
      // 起動時の初期化が失敗するエンジン
      when(() => tts.setLanguage(any()))
          .thenAnswer((_) async => throw Exception('no voice'));
    });

    testWidgets('起動時用の文言で告げ、「押したが失敗した」文言は出さない', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      expect(find.text(TtsFailureBanner.startupMessage), findsOneWidget);
      expect(find.text(TtsFailureBanner.message), findsNothing);
    });

    testWidgets('押しても準備できなければ、押したときの文言に変わる', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();

      await container.read(ttsProvider.notifier).speak('いいえ');
      await tester.pumpAndSettle();

      expect(find.text(TtsFailureBanner.message), findsOneWidget);
      expect(find.text(TtsFailureBanner.startupMessage), findsNothing);
    });

    testWidgets('押して読み上げが始まれば、帯は消える', (tester) async {
      await pumpShell(tester);
      await tester.pumpAndSettle();
      expect(find.text(TtsFailureBanner.startupMessage), findsOneWidget);

      // エンジンが戻った
      when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => tts.speak(any())).thenAnswer((_) async {
        onStart?.call();
        return 1;
      });
      await container.read(ttsProvider.notifier).speak('痛い');
      await tester.pumpAndSettle();

      expect(find.byType(TtsFailureBanner), findsOneWidget);
      expect(find.text(TtsFailureBanner.startupMessage), findsNothing);
      expect(find.text(TtsFailureBanner.message), findsNothing);
    });
  });
}
