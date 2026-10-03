/// 定型文画面の「＋」（追加）ボタンが、一覧の最後の行の操作ボタンを覆わないこと。
/// 一覧を最後までスクロールしても、最後の行の削除ボタンが「＋」の下に隠れると
/// その行を消せない。描画された位置（最も外側）で確かめる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

class _TestPresetPhraseNotifier extends PresetPhraseNotifier {
  _TestPresetPhraseNotifier(this._initialState);

  final PresetPhraseState _initialState;

  @override
  PresetPhraseState build() => _initialState;

  @override
  Future<void> initializeDefaultPhrases() async {}
}

class _TestFavoriteNotifier extends FavoriteNotifier {
  @override
  FavoriteState build() => const FavoriteState();
}

class _StubTTSNotifier extends TTSNotifier {
  @override
  TTSServiceState build() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );
}

void main() {
  // 下端の余白: 0（ホームボタンの iPad 等）、34（ホームインジケータの iPhone）、
  // 48（Android の 3 ボタンナビ）。「＋」はこの余白の上に置かれる
  for (final (size, bottomInset) in const [
    (Size(1032, 1376), 0.0),
    (Size(440, 956), 0.0),
    (Size(440, 956), 34.0),
    (Size(412, 915), 48.0),
  ]) {
    testWidgets('最後までスクロールすると、最後の行の削除ボタンが「＋」に隠れない（$size 下端$bottomInset）',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(bottom: bottomInset);
      tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
      addTearDown(tester.view.reset);

      final now = DateTime(2026, 1, 1);
      final phrases = [
        for (var i = 0; i < 30; i++)
          PresetPhrase(
            id: 'p$i',
            content: '定型文$i',
            category: 'daily',
            displayOrder: i,
            createdAt: now,
            updatedAt: now,
          ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            presetPhraseNotifierProvider.overrideWith(
              () => _TestPresetPhraseNotifier(
                PresetPhraseState(phrases: phrases),
              ),
            ),
            favoriteProvider.overrideWith(_TestFavoriteNotifier.new),
            ttsProvider.overrideWith(_StubTTSNotifier.new),
          ],
          child: const MaterialApp(home: PresetPhraseScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('定型文29'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      // 端まで送り切る
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();

      final lastRow = find.ancestor(
        of: find.text('定型文29'),
        matching: find.byType(Card),
      );
      final delete = find.descendant(
        of: lastRow,
        matching: find.byTooltip('削除'),
      );
      expect(delete, findsOneWidget);

      final fabRect = tester.getRect(find.byType(FloatingActionButton));
      final deleteRect = tester.getRect(delete);
      expect(
        fabRect.overlaps(deleteRect),
        isFalse,
        reason: '「＋」$fabRect が最後の行の削除ボタン $deleteRect を覆っている',
      );
    });
  }
}
