/// PresetPhraseScreen デバウンステスト
///
/// 改善: 定型文タップは即時TTS読み上げ+履歴保存を行うが、DebounceMixinが
/// 未適用だったため誤タップの連続発話（同じ定型文が何度も読み上げられる）
/// リスクがあった。他画面（クイック応答ボタン等）と同様にデバウンスを
/// 適用したことを検証する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// build()で初期状態を返すテスト用Notifier
///
/// initializeDefaultPhrases()はphrasesが空の場合のみ動作するため、
/// 非空の初期状態を与えることで実データ投入をスキップさせる。
class _TestPresetPhraseNotifier extends PresetPhraseNotifier {
  final PresetPhraseState _initialState;
  _TestPresetPhraseNotifier(this._initialState);
  @override
  PresetPhraseState build() => _initialState;
}

/// TTSNotifierのモック
class MockTTSNotifier extends TTSNotifier with Mock {
  @override
  TTSServiceState build() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );

  @override
  Future<void> speak(String text) =>
      super.noSuchMethod(Invocation.method(#speak, [text])) as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> stop() =>
      super.noSuchMethod(Invocation.method(#stop, [])) as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> initialize() =>
      super.noSuchMethod(Invocation.method(#initialize, [])) as Future<void>? ??
      Future<void>.value();

  @override
  Future<void> setSpeed(TTSSpeed speed) =>
      super.noSuchMethod(Invocation.method(#setSpeed, [speed]))
          as Future<void>? ??
      Future<void>.value();
}

PresetPhrase _createTestPhrase({required String id, required String content}) {
  final now = DateTime.now();
  return PresetPhrase(
    id: id,
    content: content,
    category: 'daily',
    isFavorite: false,
    displayOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PresetPhraseScreen デバウンステスト', () {
    testWidgets('短時間の連続タップではTTS読み上げが1回しか呼ばれない', (tester) async {
      final phrase = _createTestPhrase(id: '1', content: 'こんにちは');
      final mockTTSNotifier = MockTTSNotifier();
      when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            presetPhraseNotifierProvider.overrideWith(
              () => _TestPresetPhraseNotifier(
                PresetPhraseState(phrases: [phrase]),
              ),
            ),
            ttsProvider.overrideWith(() => mockTTSNotifier),
          ],
          child: const MaterialApp(home: PresetPhraseScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // When: 短時間に3回連続タップする（誤タップを想定）
      await tester.tap(find.text('こんにちは'));
      await tester.tap(find.text('こんにちは'));
      await tester.tap(find.text('こんにちは'));
      await tester.pump();

      // Then: デバウンスにより1回しか読み上げられない
      verify(() => mockTTSNotifier.speak('こんにちは')).called(1);
    });

    testWidgets('デバウンス期間経過後に再タップすると再度読み上げられる', (tester) async {
      final phrase = _createTestPhrase(id: '1', content: 'こんにちは');
      final mockTTSNotifier = MockTTSNotifier();
      when(() => mockTTSNotifier.speak(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            presetPhraseNotifierProvider.overrideWith(
              () => _TestPresetPhraseNotifier(
                PresetPhraseState(phrases: [phrase]),
              ),
            ),
            ttsProvider.overrideWith(() => mockTTSNotifier),
          ],
          child: const MaterialApp(home: PresetPhraseScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('こんにちは'));
      await tester.pump();

      // デバウンス期間（300ms）より長く実時間を待つ
      // checkDebounce()はDateTime.now()（実時間）で判定するため、
      // 仮想時間を進めるpump(duration)ではなくrunAsyncで実待機する。
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });

      await tester.tap(find.text('こんにちは'));
      await tester.pump();

      // Then: デバウンス期間経過後は再度読み上げられる（計2回）
      verify(() => mockTTSNotifier.speak('こんにちは')).called(2);
    });
  });
}
