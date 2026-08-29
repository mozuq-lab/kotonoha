/// PresetPhraseScreen エラー復帰テスト（回帰テスト）
///
/// 改善対応: copyWith のエラー引数パターン統一に伴う退行の修正
///
/// 【背景】: `_buildBody()` は `state.error != null` のときリスト全体を
/// 「エラーが発生しました: …」に差し替える。エラーを消す経路は
///
/// - `loadPhrases()` … lib/ に呼び出し元が無い
/// - `resetToDefaults()` … lib/ に呼び出し元が無い
/// - `initializeDefaultPhrases()` … `phrases` が非空だと早期returnする
///
/// の3つしかないため、「初期化に失敗 → 定型文が1件でも増える」と
/// エラー表示がプロセス終了まで解除できなくなる。
/// 成功したCRUD操作で `clearError: true` を立てることで画面が復帰する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// build()で任意の初期状態を返すテスト用Notifier（CRUDは実装をそのまま使う）
class _TestPresetPhraseNotifier extends PresetPhraseNotifier {
  _TestPresetPhraseNotifier(this._initialState);

  final PresetPhraseState _initialState;

  @override
  PresetPhraseState build() => _initialState;
}

/// 実プラグイン（FlutterTts）を触らせないためのスタブ
class _StubTTSNotifier extends TTSNotifier {
  @override
  TTSServiceState build() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );

  @override
  Future<void> speak(String text) async {}
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
  group('PresetPhraseScreen エラー表示からの復帰', () {
    /// 「初期化失敗 → 1件追加済み」で固着した状態を初期状態として与える。
    /// phrases が非空なので initState の initializeDefaultPhrases() は
    /// 早期returnし、エラーは自力では解除されない。
    const stuckError = '初期データの読み込みに失敗しました: Exception';

    Future<ProviderContainer> pumpStuckScreen(WidgetTester tester) async {
      final phrase = _createTestPhrase(id: '1', content: 'こんにちは');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            presetPhraseNotifierProvider.overrideWith(
              () => _TestPresetPhraseNotifier(
                PresetPhraseState(phrases: [phrase], error: stuckError),
              ),
            ),
            ttsProvider.overrideWith(_StubTTSNotifier.new),
          ],
          child: const MaterialApp(home: PresetPhraseScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Given: エラー表示に差し替わっており、リストは見えていない
      expect(find.textContaining('エラーが発生しました'), findsOneWidget);
      expect(find.text('こんにちは'), findsNothing);

      return ProviderScope.containerOf(
        tester.element(find.byType(PresetPhraseScreen)),
      );
    }

    testWidgets('定型文の追加に成功すると画面がリスト表示へ復帰する', (tester) async {
      final container = await pumpStuckScreen(tester);

      // When: FAB相当の操作（定型文の追加）が成功する
      await container
          .read(presetPhraseNotifierProvider.notifier)
          .addPhrase('ありがとうございます', 'daily');
      await tester.pumpAndSettle();

      // Then: エラー表示が消え、定型文一覧が表示される
      expect(find.textContaining('エラーが発生しました'), findsNothing);
      expect(find.text('こんにちは'), findsOneWidget);
      expect(find.text('ありがとうございます'), findsOneWidget);
    });

    testWidgets('定型文の編集に成功すると画面がリスト表示へ復帰する', (tester) async {
      final container = await pumpStuckScreen(tester);

      await container
          .read(presetPhraseNotifierProvider.notifier)
          .updatePhrase('1', content: 'こんばんは');
      await tester.pumpAndSettle();

      expect(find.textContaining('エラーが発生しました'), findsNothing);
      expect(find.text('こんばんは'), findsOneWidget);
    });

    testWidgets('定型文の削除に成功すると画面がリスト表示へ復帰する', (tester) async {
      final container = await pumpStuckScreen(tester);

      await container
          .read(presetPhraseNotifierProvider.notifier)
          .deletePhrase('1');
      await tester.pumpAndSettle();

      expect(find.textContaining('エラーが発生しました'), findsNothing);
      expect(find.text('こんにちは'), findsNothing);
    });
  });
}
