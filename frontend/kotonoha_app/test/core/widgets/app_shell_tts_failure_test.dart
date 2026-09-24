/// 読み上げに失敗したら、どの画面にいても利用者に告げること（守る約束 ④）
///
/// 読み上げの失敗は、以前は状態に持つだけで画面のどこにも出なかった。
/// 利用者は、読み上げたつもりで相手に伝わっていないことに気づけない。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
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
}
