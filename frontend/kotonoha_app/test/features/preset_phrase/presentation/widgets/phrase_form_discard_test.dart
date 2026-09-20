/// 入力中の文が、戻る操作で黙って消えないこと（台帳 L-136）
///
/// 利用者は文字盤で 1 文字ずつ打つ。打ち終わった文が確認なしに消えると、
/// **打ち直すしかない**（発話で訂正できないので、他に伝える手段が無い）。
/// #149〜#153 はこの害を「取り消しと実行を 16px 離す」ことで減らしたが、
/// **端末の戻るボタンという別の扉**が確認なしに開いたままだった
/// （`barrierDismissible: false` は外タップだけを塞ぐ。`PopScope` は
/// リポジトリ全体に 1 つも無かった。2026-09-20 実測）。
///
/// 本番の入口（`PresetPhraseScreen` の ＋ と ✏️）から開いて確かめる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

class _Phrases extends PresetPhraseNotifier {
  _Phrases(this._state);
  final PresetPhraseState _state;
  @override
  PresetPhraseState build() => _state;
}

class _StubTts extends TTSNotifier {
  @override
  TTSServiceState build() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );
  @override
  Future<void> speak(String text) async {}
}

PresetPhrase _phrase() => PresetPhrase(
      id: 'p1',
      content: '元の文言',
      category: 'daily',
      displayOrder: 0,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

Future<void> _openScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetPhraseNotifierProvider.overrideWith(
          () => _Phrases(PresetPhraseState(phrases: [_phrase()])),
        ),
        ttsProvider.overrideWith(_StubTts.new),
      ],
      child: MaterialApp(theme: lightTheme, home: const PresetPhraseScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// 端末の戻るボタン（Android のシステムバック）を投げる
Future<bool> _systemBack(WidgetTester tester) =>
    tester.binding.handlePopRoute();

void main() {
  for (final (name, icon, label) in [
    ('定型文の追加', Icons.add, '打った文'),
    ('定型文の編集', Icons.edit, '打ち直した文'),
  ]) {
    testWidgets('$name: 入力があると、戻る操作では黙って閉じない', (tester) async {
      await _openScreen(tester);
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), label);
      await tester.pumpAndSettle();

      await _systemBack(tester);
      await tester.pumpAndSettle();

      // 打った文が残っているか、破棄してよいか訊かれるかの**どちらか**。
      // 黙って閉じるのは駄目
      final stillOpen = find.byType(TextField).evaluate().isNotEmpty;
      final asked = find.text('入力中の内容を破棄しますか？').evaluate().isNotEmpty;
      expect(stillOpen || asked, isTrue,
          reason: '$name: 戻る操作で、確認も無くダイアログが閉じて入力が消えた');
    });

    testWidgets('$name: 捨てるものが無ければ、戻る操作でそのまま閉じてよい', (tester) async {
      await _openScreen(tester);
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      // 追加は何も打っていない状態、編集は**元の文言のまま触っていない**状態。
      // 編集で空にするのは「元の文言を消した」という変更なので、ここには来ない
      // （下の「編集で空にしたら訊く」で別に見る）

      await _systemBack(tester);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing,
          reason: '$name: 捨てるものが無いのに閉じない（余計な確認で足止めしない）');
    });
  }

  testWidgets('編集で元の文言を消したときも、戻る操作では黙って閉じない', (tester) async {
    // 空にするのも「元の文言を消した」という取り消せない変更。
    // 保存せずに閉じれば元へ戻るが、**打ち直した内容は戻らない**
    await _openScreen(tester);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    await _systemBack(tester);
    await tester.pumpAndSettle();

    expect(find.text('入力中の内容を破棄しますか？'), findsOneWidget,
        reason: '元の文言を消した状態で、確認も無く閉じた');
  });

  testWidgets('破棄を選べば閉じる／やめるを選べば入力は残る', (tester) async {
    await _openScreen(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '打った文');
    await tester.pumpAndSettle();

    // 1 回目: やめる → 入力が残る
    await _systemBack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('書き続ける'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('打った文'), findsWidgets, reason: '入力が消えている');

    // 2 回目: 破棄する → 閉じる
    await _systemBack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄する'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing, reason: '破棄を選んでも閉じない');
  });
}
