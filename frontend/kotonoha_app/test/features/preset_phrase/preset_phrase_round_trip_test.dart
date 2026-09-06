/// 定型文の往復テスト（Phase 3 / WP-3）
///
/// **UI → provider → repository → 実 Hive box → 再起動相当 → UI** を1本で通す。
///
/// お気に入りトグルを選んだ理由: WP-2 で「定型文がお気に入りか」の真実を
/// `favoriteProvider` へ寄せた（ADR-005）。`PresetPhrase.isFavorite` は削除済みで、
/// 定型文 UI は favorites box の内容から星を描く。**2つの box をまたぐ往復**なので、
/// 真実が1つに寄っていることを最も外側の境界で確かめられる。
///
/// 制約と対処（実 Hive × testWidgets）は
/// `test/features/history/history_round_trip_test.dart` の冒頭コメントを参照。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const phraseId = 'p-1';
  const phraseContent = 'すこし休みたいです';

  setUp(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );

    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('preset_round_trip_');
    Hive.init(tempDir.path);
    registerPersistedTypeAdapters();
    await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
    await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
    await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

    await Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName).put(
      phraseId,
      PresetPhrase(
        id: phraseId,
        content: phraseContent,
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime(2026, 8, 31, 9),
        updatedAt: DateTime(2026, 8, 31, 9),
      ),
    );
  });

  tearDown(() async {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('定型文の星をタップすると favorites box に残り、再起動相当でも星が付いている', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PresetPhraseScreen())),
    );
    await tester.pump();

    expect(find.text(phraseContent), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget,
        reason: 'まだお気に入りではないこと（往復の出発点）');

    // When: 星をタップする
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.star_border).first);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Then: favorites box を閉じて開き直しても（＝再起動相当）残っている
    late List<FavoriteItem> persisted;
    await tester.runAsync(() async {
      await Hive.box<FavoriteItem>(PersistedArea.favorites.boxName).close();
      final reopened =
          await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);
      persisted = reopened.values.toList();
    });

    expect(persisted, hasLength(1));
    expect(persisted.single.content, phraseContent);
    expect(persisted.single.sourceType, 'preset_phrase',
        reason: '定型文由来であることが記録されていること');
    expect(persisted.single.sourceId, phraseId,
        reason: '同じ文言の定型文どうしを区別できるよう、出所は id で持つこと（ADR-005）');

    // And: 新しい ProviderScope（＝再起動相当）で星が付いた状態から描かれる
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PresetPhraseScreen())),
    );
    await tester.pump();

    expect(find.byIcon(Icons.star), findsOneWidget,
        reason: '定型文 UI が favorites box の内容から星を描いていること'
            '（PresetPhrase 側にフラグを持たない＝1概念1真実）');
    expect(find.byIcon(Icons.star_border), findsNothing);
  });
}
