/// FavoriteProvider テスト
///
/// TASK-0057: Riverpod Provider 構造設計
/// TC-057-013 〜 TC-057-024
///
/// 関連要件:
/// - REQ-701: お気に入り登録
/// - REQ-702: お気に入り一覧表示
/// - REQ-703: お気に入り削除
/// - REQ-704: お気に入り並び替え
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';

void main() {
  group('FavoriteProvider テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // 正常系テスト
    // =========================================================================

    group('正常系テスト', () {
      test('TC-057-013: お気に入りを追加できる', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);

        // Act
        await notifier.addFavorite('ありがとう');

        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites.length, 1);
        expect(state.favorites.first.content, 'ありがとう');
      });

      test('TC-057-014: 複数のお気に入りを追加できる', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);

        // Act
        await notifier.addFavorite('1番目');
        await notifier.addFavorite('2番目');
        await notifier.addFavorite('3番目');

        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites.length, 3);
      });

      test('TC-057-015: お気に入りを削除できる', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);
        await notifier.addFavorite('削除対象');
        final state = container.read(favoriteProvider);
        final id = state.favorites.first.id;

        // Act
        await notifier.deleteFavorite(id);

        // Assert
        final updatedState = container.read(favoriteProvider);
        expect(updatedState.favorites.length, 0);
      });

      test('TC-057-016: お気に入りの並び順を変更できる', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);
        await notifier.addFavorite('1番目');
        await notifier.addFavorite('2番目');
        await notifier.addFavorite('3番目');
        final state = container.read(favoriteProvider);
        final thirdItemId = state.favorites[2].id;

        // Act - 3番目を先頭に移動
        await notifier.reorderFavorite(thirdItemId, 0);

        // Assert
        final updatedState = container.read(favoriteProvider);
        expect(updatedState.favorites.first.content, '3番目');
      });

      test('TC-057-017: お気に入り一覧がdisplayOrder順で取得できる', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);
        await notifier.addFavorite('C');
        await notifier.addFavorite('A');
        await notifier.addFavorite('B');
        final state = container.read(favoriteProvider);
        final bId = state.favorites.firstWhere((f) => f.content == 'B').id;
        final aId = state.favorites.firstWhere((f) => f.content == 'A').id;

        // Act - A→B→Cの順に並び替え
        await notifier.reorderFavorite(aId, 0);
        await notifier.reorderFavorite(bId, 1);

        // Assert
        final updatedState = container.read(favoriteProvider);
        expect(updatedState.favorites[0].content, 'A');
        expect(updatedState.favorites[1].content, 'B');
        expect(updatedState.favorites[2].content, 'C');
      });
    });

    // =========================================================================
    // デフォルト値テスト
    // =========================================================================

    group('デフォルト値テスト', () {
      test('TC-057-018: 初期状態は空のお気に入りリスト', () {
        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites, isEmpty);
      });

      test('TC-057-019: 初期状態はローディングfalse', () {
        // Assert
        final state = container.read(favoriteProvider);
        expect(state.isLoading, false);
      });
    });

    // =========================================================================
    // 異常系テスト
    // =========================================================================

    group('異常系テスト', () {
      test('TC-057-020: 空文字のお気に入りは追加されない', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);

        // Act
        await notifier.addFavorite('');

        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites.length, 0);
      });

      test('TC-057-021: 存在しないIDの削除は無視される', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);
        await notifier.addFavorite('テスト');

        // Act
        await notifier.deleteFavorite('non-existent-id');

        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites.length, 1);
      });

      test('TC-057-022: 存在しないIDの並び替えは無視される', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);
        await notifier.addFavorite('テスト');
        final originalState = container.read(favoriteProvider);

        // Act
        await notifier.reorderFavorite('non-existent-id', 0);

        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites.length, originalState.favorites.length);
      });

      test('TC-057-023: お気に入りにUUIDが自動付与される', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);

        // Act
        await notifier.addFavorite('テスト');

        // Assert
        final state = container.read(favoriteProvider);
        final id = state.favorites.first.id;
        // UUID形式の正規表現パターン
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(id), true);
      });

      test('TC-057-024: 重複するコンテンツのお気に入りは追加されない', () async {
        // Arrange
        final notifier = container.read(favoriteProvider.notifier);

        // Act
        await notifier.addFavorite('重複テスト');
        await notifier.addFavorite('重複テスト');

        // Assert
        final state = container.read(favoriteProvider);
        expect(state.favorites.length, 1);
      });
    });
  });
}
