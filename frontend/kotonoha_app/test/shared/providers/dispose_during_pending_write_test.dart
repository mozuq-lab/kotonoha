/// 書き込みや読み上げの呼び出しを待つ間に破棄されても、破棄済みの状態を
/// 書き換えない（UnmountedRefException を出さない）
///
/// 読み上げ中を画面へすぐ知らせるようにしたところ、結合テストがそれを見届けて
/// すぐ終わり、`speak` や履歴の保存が返る前にコンテナが破棄されるようになった
/// （iPad シミュレータで実測、2026-09-25）。本番ではアプリを閉じるときに当たる。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_flutter_tts.dart';

class _HistoryBox extends Mock implements Box<HistoryItem> {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
    registerFallbackValue(() {});
    registerFallbackValue((dynamic _) {});
    registerFallbackValue(HistoryItem(
      id: 'x',
      content: 'x',
      createdAt: DateTime(2026),
      type: HistoryType.quickButton.name,
    ));
  });

  test('読み上げの呼び出しを待つ間に破棄されても、例外を出さない', () async {
    final tts = MockFlutterTts();
    final speaking = Completer<dynamic>();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => tts.speak(any())).thenAnswer((_) => speaking.future);
    final container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts))),
    ]);
    final notifier = container.read(ttsProvider.notifier);
    await notifier.initialize();

    final call = notifier.speak('いいえ');
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    speaking.complete(1);

    await expectLater(call, completes);
  });

  test('履歴の保存を待つ間に破棄されても、例外を出さない', () async {
    final box = _HistoryBox();
    final saving = Completer<void>();
    when(() => box.length).thenReturn(0);
    when(() => box.get(any<dynamic>())).thenReturn(null);
    when(() => box.values).thenReturn(<HistoryItem>[]);
    when(() => box.put(any<dynamic>(), any())).thenAnswer((_) => saving.future);
    when(() => box.flush()).thenAnswer((_) async {});
    when(() => box.compact()).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      historyBoxProvider.overrideWithValue(box),
    ]);

    final call = container
        .read(historyProvider.notifier)
        .addHistory('はい', HistoryType.quickButton);
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    saving.complete();

    await expectLater(call, completes);
  });
}
