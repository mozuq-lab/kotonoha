/// PresetPhraseScreen お気に入り表示テスト
///
/// Phase 3 / WP-2 / Stage 3a: 定型文UIをお気に入りの真実（favoriteProvider）から描く
///
/// 【背景】: ADR-005によりお気に入りの正はfavoriteProvider。定型文UIは
/// これまでPresetPhrase.isFavoriteという並行真実を読んでいたが、この段で
/// favoriteProviderを読むように付け替えた。
///
/// 【このテストの狙い】: PresetPhrase.isFavoriteをfalseのままにしても、
/// favoriteProviderに定型文由来（sourceType == 'preset_phrase'）のお気に入りが
/// あれば星が塗りつぶしで表示されることを、描画されたウィジェット（最も外側の境界）で
/// 確認する。これにより「UIがもうフラグを読んでいない」ことを実証する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// build()で任意の初期状態を返すテスト用Notifier
/// （他の preset_phrase_screen_*_test.dart と同じパターン）
class _TestPresetPhraseNotifier extends PresetPhraseNotifier {
  _TestPresetPhraseNotifier(this._initialState);

  final PresetPhraseState _initialState;

  @override
  PresetPhraseState build() => _initialState;
}

/// build()で任意の初期状態を返すテスト用FavoriteNotifier
///
/// 【ハング回避】: testWidgets()の中で実Hiveを触らないよう、CRUDメソッドは
/// 呼ばず、build()が直接FavoriteStateを返す形で状態を作る。
class _TestFavoriteNotifier extends FavoriteNotifier {
  _TestFavoriteNotifier(this._initialState);

  final FavoriteState _initialState;

  @override
  FavoriteState build() => _initialState;
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

PresetPhrase _createTestPhrase({
  required String id,
  required String content,
  bool isFavorite = false,
}) {
  final now = DateTime.now();
  return PresetPhrase(
    id: id,
    content: content,
    category: 'daily',
    isFavorite: isFavorite,
    displayOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PresetPhraseScreen お気に入り表示（favoriteProviderが正）', () {
    testWidgets(
      'favoriteProviderに定型文由来のお気に入りがあると、'
      'PresetPhrase.isFavoriteがfalseのままでも星が塗りつぶしで表示される',
      (tester) async {
        // Given: PresetPhrase.isFavoriteはfalseのまま（並行真実を更新しない）
        final phrase = _createTestPhrase(id: 'p1', content: 'おはようございます');
        expect(phrase.isFavorite, isFalse); // 前提確認: フラグは触っていない

        // favoriteProviderの方にだけ、定型文由来（sourceType: 'preset_phrase'）の
        // お気に入りを1件入れておく
        final favorite = Favorite(
          id: 'fav-1',
          content: phrase.content,
          createdAt: DateTime.now(),
          sourceType: 'preset_phrase',
          sourceId: phrase.id,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              presetPhraseNotifierProvider.overrideWith(
                () => _TestPresetPhraseNotifier(
                  PresetPhraseState(phrases: [phrase]),
                ),
              ),
              favoriteProvider.overrideWith(
                () => _TestFavoriteNotifier(
                  FavoriteState(favorites: [favorite]),
                ),
              ),
              ttsProvider.overrideWith(_StubTTSNotifier.new),
            ],
            child: const MaterialApp(home: PresetPhraseScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Then: お気に入りセクションに表示され、星が塗りつぶし（Icons.star）で出る。
        // 検証は最も外側の境界（描画されたウィジェット）で行う。
        expect(find.text('お気に入り'), findsOneWidget);
        expect(find.text('おはようございます'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.star_border), findsNothing);
      },
    );

    testWidgets(
      '履歴由来（sourceType: history）のお気に入りは定型文のお気に入りセクションに混ざらない',
      (tester) async {
        // Given: 定型文はお気に入りではない
        final phrase = _createTestPhrase(id: 'p1', content: 'こんにちは');

        // favoriteProviderには、同じcontentを持つ「履歴由来」のお気に入りがある
        // （sourceIdだけで絞ると誤ってこれを定型文由来として拾ってしまう）
        final historyFavorite = Favorite(
          id: 'fav-history-1',
          content: phrase.content,
          createdAt: DateTime.now(),
          sourceType: 'history',
          sourceId: phrase.id,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              presetPhraseNotifierProvider.overrideWith(
                () => _TestPresetPhraseNotifier(
                  PresetPhraseState(phrases: [phrase]),
                ),
              ),
              favoriteProvider.overrideWith(
                () => _TestFavoriteNotifier(
                  FavoriteState(favorites: [historyFavorite]),
                ),
              ),
              ttsProvider.overrideWith(_StubTTSNotifier.new),
            ],
            child: const MaterialApp(home: PresetPhraseScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Then: お気に入りセクションは出ない（sourceTypeで絞られている）
        expect(find.text('お気に入り'), findsNothing);
        expect(find.byIcon(Icons.star), findsNothing);
        expect(find.byIcon(Icons.star_border), findsOneWidget);
      },
    );
  });
}
