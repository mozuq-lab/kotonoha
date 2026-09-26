import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/favorite/data/favorite_repository.dart';
import 'package:kotonoha_app/features/favorite/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _FavoriteBoxBoundary extends Mock implements Box<FavoriteItem> {}

Box<FavoriteItem> _boundary(
  Box<FavoriteItem> box, {
  bool failInitialWrite = false,
  String? failDeleteId,
  bool failDeleteAll = false,
  Completer<void>? beforeSaveAll,
}) {
  final boundary = _FavoriteBoxBoundary();
  when(() => boundary.get(any()))
      .thenAnswer((call) => box.get(call.positionalArguments.first));
  when(() => boundary.values).thenAnswer((_) => box.values);
  when(() => boundary.compact()).thenAnswer((_) => box.compact());
  when(() => boundary.flush()).thenAnswer((_) => box.flush());
  when(() => boundary.put(any(), any())).thenAnswer((call) async {
    final item = call.positionalArguments[1] as FavoriteItem;
    if (failInitialWrite && item.content.isEmpty) {
      throw StateError('seed write failed');
    }
    await box.put(call.positionalArguments.first, item);
  });
  when(() => boundary.putAll(any())).thenAnswer((call) async {
    if (beforeSaveAll != null) await beforeSaveAll.future;
    final entries =
        call.positionalArguments.first as Map<dynamic, FavoriteItem>;
    if (failInitialWrite &&
        entries.values.any((item) => item.content.isEmpty)) {
      throw StateError('seed write failed');
    }
    await box.putAll(entries);
  });
  when(() => boundary.delete(any())).thenAnswer((call) async {
    final id = call.positionalArguments.first;
    if (id == failDeleteId) throw StateError('delete failed');
    await box.delete(id);
  });
  when(() => boundary.deleteAll(any())).thenAnswer((call) async {
    if (failDeleteAll) throw StateError('delete all failed');
    await box.deleteAll(call.positionalArguments.first as Iterable<dynamic>);
  });
  return boundary;
}

void main() {
  late Directory directory;
  late Box<FavoriteItem> box;

  setUpAll(() {
    registerFallbackValue(FavoriteItem(
      id: 'fallback',
      content: '',
      createdAt: DateTime(2026),
      displayOrder: 0,
    ));
  });

  setUp(() async {
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('favorite_defaults_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FavoriteItemAdapter());
    }
    box = await Hive.openBox<FavoriteItem>('favorites');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('初回だけ必須8件を作り、削除後の再起動では復活しない', () async {
    var repository = FavoriteRepository(box: box);
    await repository.ensureInitialFavorites();
    expect(
      repository.loadAllSortedSync().map((item) => item.content).toList(),
      ['痛い', 'トイレ', '暑い', '寒い', '水', '眠い', '助けて', '待って'],
    );

    await repository.deleteAll();
    await box.close();
    box = await Hive.openBox<FavoriteItem>('favorites');
    repository = FavoriteRepository(box: box);
    await repository.ensureInitialFavorites();
    expect(repository.loadAllSortedSync(), isEmpty);
  });

  test('初期化の印の保存が失敗しても、利用者が消せる初期項目だけを残さない', () async {
    final failedRepository = FavoriteRepository(
      box: _boundary(box, failInitialWrite: true),
    );
    expect(await failedRepository.ensureInitialFavorites(), isFalse);
    expect(failedRepository.loadAllSortedSync(), isEmpty);

    final repository = FavoriteRepository(box: box);
    await repository.ensureInitialFavorites();
    await repository.delete('initial-favorite-0');
    await box.close();
    box = await Hive.openBox<FavoriteItem>('favorites');
    final reopened = FavoriteRepository(box: box);
    await reopened.ensureInitialFavorites();
    expect(reopened.loadAllSortedSync().map((item) => item.content),
        isNot(contains('痛い')));
  });

  test('色と並び順を保存し、box の開き直し後も維持する', () async {
    var repository = FavoriteRepository(box: box);
    await repository.ensureInitialFavorites();
    final favorite = repository.loadAllSortedSync().first;
    await repository
        .save(favorite.copyWith(colorValue: 0xFF123456, displayOrder: 9));

    await box.close();
    box = await Hive.openBox<FavoriteItem>('favorites');
    repository = FavoriteRepository(box: box);
    final reloaded = await repository.getById(favorite.id);
    expect(reloaded?.colorValue, 0xFF123456);
    expect(reloaded?.displayOrder, 9);
  });

  for (final source in ['input', 'history', 'preset_phrase']) {
    test('$source から削除後に追加しても再起動で並び順が変わらない', () async {
      await FavoriteRepository(box: box).ensureInitialFavorites();
      var container = ProviderContainer();
      final notifier = container.read(favoriteProvider.notifier);
      await notifier.deleteFavorite('initial-favorite-0');
      switch (source) {
        case 'input':
          await notifier.addFavorite('最後に追加');
        case 'history':
          await notifier.addFavoriteFromHistory('最後に追加', 'history-id');
        case 'preset_phrase':
          await notifier.addFavoriteFromPresetPhrase('最後に追加', 'preset-id');
      }
      const expected = ['トイレ', '暑い', '寒い', '水', '眠い', '助けて', '待って', '最後に追加'];
      expect(container.read(favoriteProvider).favorites.map((f) => f.content),
          expected);
      container.dispose();
      await box.close();
      box = await Hive.openBox<FavoriteItem>('favorites');
      container = ProviderContainer();
      expect(container.read(favoriteProvider).favorites.map((f) => f.content),
          expected);
      container.dispose();
    });
  }

  testWidgets('保存中に上へを2回押した操作がどちらも再起動後に残る', (tester) async {
    await tester
        .runAsync(() => FavoriteRepository(box: box).ensureInitialFavorites());
    final gate = (await tester.runAsync(() async => Completer<void>()))!;
    final repository =
        FavoriteRepository(box: _boundary(box, beforeSaveAll: gate));
    final container = ProviderContainer(overrides: [
      favoriteRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: FavoritesScreen()),
    ));
    await tester.pumpAndSettle();
    final up = find.byKey(const Key('move_up_initial-favorite-3'));
    await tester.tap(find.byTooltip('並び替え'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(up);
    await tester.pumpAndSettle();
    expect(up.hitTestable(), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(up);
      await tester.tap(up);
      gate.complete();
      await container.read(favoriteProvider.notifier).loadFavorites();
    });
    await tester.pump();
    expect(container.read(favoriteProvider).favorites[1].content, '寒い');
    await tester.runAsync(() async {
      await box.close();
      box = await Hive.openBox<FavoriteItem>('favorites');
    });
    expect(FavoriteRepository(box: box).loadAllSortedSync()[1].content, '寒い');
    expect(tester.takeException(), isNull);
  });

  test('provider で変えた色が実 box と再起動後の provider に残る', () async {
    await FavoriteRepository(box: box).ensureInitialFavorites();
    var container = ProviderContainer();
    final first = container.read(favoriteProvider).favorites.first;
    final changed = await container
        .read(favoriteProvider.notifier)
        .updateFavoriteColor(first.id, 0xFF123456);
    expect(changed, isTrue);
    expect(box.get(first.id)?.colorValue, 0xFF123456);
    container.dispose();

    await box.close();
    box = await Hive.openBox<FavoriteItem>('favorites');
    container = ProviderContainer();
    expect(container.read(favoriteProvider).favorites.first.colorValue,
        0xFF123456);
    container.dispose();
  });

  test('色変更の保存中に並べ替えても、色と順序を別の項目へ移さない', () async {
    await FavoriteRepository(box: box).ensureInitialFavorites();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = container.read(favoriteProvider).favorites.first;
    final notifier = container.read(favoriteProvider.notifier);
    final colorSave = notifier.updateFavoriteColor(first.id, 0xFF123456);
    final reorder = notifier.reorderFavorite(first.id, 7);
    await Future.wait([colorSave, reorder]);

    final favorites = container.read(favoriteProvider).favorites;
    expect(favorites.map((favorite) => favorite.id).toSet(), hasLength(8));
    expect(favorites.last.id, first.id);
    expect(favorites.last.colorValue, 0xFF123456);
    expect(box.get(first.id)?.colorValue, 0xFF123456);
    expect(box.get(first.id)?.displayOrder, 7);
  });

  test('色変更・移動・削除を続けても、実 box の再open後に削除が戻らない', () async {
    await FavoriteRepository(box: box).ensureInitialFavorites();
    final container = ProviderContainer();
    final original = container.read(favoriteProvider).favorites;
    final notifier = container.read(favoriteProvider.notifier);
    final color = notifier.updateFavoriteColor(original[1].id, 0xFF123456);
    final move = notifier.reorderFavorite(original[2].id, 0);
    final deletion = notifier.deleteFavorite(original[0].id);
    await Future.wait([color, move, deletion]);
    expect(container.read(favoriteProvider).favorites.first.id, original[2].id);
    expect(container.read(favoriteProvider).favorites, hasLength(7));
    container.dispose();

    await box.close();
    box = await Hive.openBox<FavoriteItem>('favorites');
    final reloaded = FavoriteRepository(box: box).loadAllSortedSync();
    expect(reloaded.first.id, original[2].id);
    expect(reloaded.map((favorite) => favorite.id),
        isNot(contains(original[0].id)));
    expect(
        reloaded
            .singleWhere((favorite) => favorite.id == original[1].id)
            .colorValue,
        0xFF123456);
    expect(reloaded, hasLength(7));
  });

  test('全削除を取り消しても、その間に登録したお気に入りを消さない', () async {
    await FavoriteRepository(box: box).ensureInitialFavorites();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(favoriteProvider.notifier);
    await notifier.clearAllFavorites();
    await notifier.addFavorite('削除後に登録した文');
    await notifier.restoreClearedFavorites();
    expect(container.read(favoriteProvider).favorites, hasLength(9));
    expect(
        container.read(favoriteProvider).favorites.last.content, '削除後に登録した文');
    expect(FavoriteRepository(box: box).loadAllSortedSync(), hasLength(9));
  });

  testWidgets('入力欄から登録した文が実 box とホームの上位8件に反映される', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(
      () => FavoriteRepository(box: box).ensureInitialFavorites(),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('home_input_field')), 'ありがとう');
    await tester.pump();
    expect(container.read(inputBufferProvider), 'ありがとう');
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('favorite_current_input')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(box.values.where((item) => item.content == 'ありがとう'), hasLength(1));

    final favorite = container.read(favoriteProvider).favorites.last;
    await tester.runAsync(() => container
        .read(favoriteProvider.notifier)
        .reorderFavorite(favorite.id, 0));
    await tester.pump();
    final shortcuts = tester
        .widgetList<FavoriteShortcutButton>(find.byType(FavoriteShortcutButton))
        .toList();
    expect(shortcuts, hasLength(8));
    expect(shortcuts.first.favorite.content, 'ありがとう');
    expect(shortcuts.map((button) => button.favorite.content),
        isNot(contains('待って')));
  });

  testWidgets('お気に入り box への保存失敗を登録成功と表示しない', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(
      () => FavoriteRepository(box: box).ensureInitialFavorites(),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(box.close);

    await tester.enterText(find.byKey(const Key('home_input_field')), '保存失敗');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('favorite_current_input')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.text('お気に入りを保存できませんでした'), findsOneWidget);
    expect(
      container
          .read(favoriteProvider)
          .favorites
          .where((favorite) => favorite.content == '保存失敗'),
      isEmpty,
    );
  });

  testWidgets('保存先がない入力欄の登録は重複ではなく一時保存と伝える', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(box.close);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('home_input_field')), '一時的な文');
    await tester.pump();
    await tester.tap(find.byKey(const Key('favorite_current_input')));
    await tester.pumpAndSettle();
    expect(find.text('すでにお気に入りに登録されています'), findsNothing);
    expect(find.text('一時的に登録しました。保存できないため、再起動すると消えます'), findsOneWidget);
    expect(container.read(favoriteProvider).favorites.single.content, '一時的な文');
    expect(tester.takeException(), isNull);
  });

  for (final deleteAll in [false, true]) {
    testWidgets('${deleteAll ? '全削除' : '個別削除'}の失敗時に成功やUndoを表示せず、実 box を保持する',
        (tester) async {
      await tester.runAsync(
          () => FavoriteRepository(box: box).ensureInitialFavorites());
      final repository = FavoriteRepository(
          box: _boundary(
        box,
        failDeleteId: deleteAll ? null : 'initial-favorite-1',
        failDeleteAll: deleteAll,
      ));
      final container = ProviderContainer(overrides: [
        favoriteRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);
      await tester.runAsync(() => container
          .read(favoriteProvider.notifier)
          .deleteFavorite('initial-favorite-0'));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FavoritesScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(deleteAll ? '全削除' : '削除').first);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.text('削除'),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.text(deleteAll ? 'すべてのお気に入りを削除できませんでした' : 'お気に入りを削除できませんでした'),
          findsOneWidget);
      expect(find.text('元に戻す'), findsNothing);
      expect(box.get('initial-favorite-0'), isNull);
      expect(box.get('initial-favorite-1'), isNotNull);
      expect(container.read(favoriteProvider).favorites, hasLength(7));
    });
  }
}
