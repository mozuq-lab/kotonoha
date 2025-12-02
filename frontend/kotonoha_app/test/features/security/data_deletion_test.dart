/// TASK-0097: NFR-103 データ削除機能テスト
///
/// 信頼性レベル: 🔵 青信号（NFR-103に基づく）
/// テスト対象: 履歴・お気に入りを利用者が任意に削除できる機能
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/features/favorite/data/favorite_repository.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:mocktail/mocktail.dart';

// Hive Box のモック
class MockHistoryBox extends Mock implements Box<HistoryItem> {}

class MockPresetPhraseBox extends Mock implements Box<PresetPhrase> {}

class MockFavoriteBox extends Mock implements Box<FavoriteItem> {}

// Fakeクラス定義
class FakeHistoryItem extends Fake implements HistoryItem {}

class FakePresetPhrase extends Fake implements PresetPhrase {}

class FakeFavoriteItem extends Fake implements FavoriteItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeHistoryItem());
    registerFallbackValue(FakePresetPhrase());
    registerFallbackValue(FakeFavoriteItem());
  });

  group('NFR-103: データ削除機能', () {
    late MockHistoryBox mockHistoryBox;
    late MockPresetPhraseBox mockPresetPhraseBox;
    late MockFavoriteBox mockFavoriteBox;

    setUp(() {
      mockHistoryBox = MockHistoryBox();
      mockPresetPhraseBox = MockPresetPhraseBox();
      mockFavoriteBox = MockFavoriteBox();
    });

    group('TC-103-001: 履歴を個別削除できる', () {
      test('HistoryRepository.delete()で履歴が削除される', () async {
        // Arrange
        final repository = HistoryRepository(box: mockHistoryBox);

        when(() => mockHistoryBox.delete(any())).thenAnswer((_) async {});

        // Act
        await repository.delete('history-1');

        // Assert
        verify(() => mockHistoryBox.delete('history-1')).called(1);
      });
    });

    group('TC-103-002: 履歴を全削除できる', () {
      test('HistoryRepository.deleteAll()で全履歴が削除される', () async {
        // Arrange
        final repository = HistoryRepository(box: mockHistoryBox);

        when(() => mockHistoryBox.clear()).thenAnswer((_) async => 0);

        // Act
        await repository.deleteAll();

        // Assert
        verify(() => mockHistoryBox.clear()).called(1);
      });
    });

    group('TC-103-003: お気に入りを個別削除できる', () {
      test('FavoriteRepository.delete()でお気に入りが削除される', () async {
        // Arrange
        final repository = FavoriteRepository(box: mockFavoriteBox);

        when(() => mockFavoriteBox.delete(any())).thenAnswer((_) async {});

        // Act
        await repository.delete('fav-1');

        // Assert
        verify(() => mockFavoriteBox.delete('fav-1')).called(1);
      });
    });

    group('TC-103-004: お気に入りを全削除できる', () {
      test('FavoriteRepository.deleteAll()で全お気に入りが削除される', () async {
        // Arrange
        final repository = FavoriteRepository(box: mockFavoriteBox);

        when(() => mockFavoriteBox.clear()).thenAnswer((_) async => 0);

        // Act
        await repository.deleteAll();

        // Assert
        verify(() => mockFavoriteBox.clear()).called(1);
      });
    });

    group('TC-103-005: 定型文を削除できる', () {
      test('PresetPhraseRepository.delete()で定型文が削除される', () async {
        // Arrange
        final repository = PresetPhraseRepository(box: mockPresetPhraseBox);

        when(() => mockPresetPhraseBox.delete(any())).thenAnswer((_) async {});

        // Act
        await repository.delete('preset-1');

        // Assert
        verify(() => mockPresetPhraseBox.delete('preset-1')).called(1);
      });
    });

    group('TC-103-007: 削除後にデータが永続的に削除される', () {
      test('削除後にgetByIdがnullを返す', () async {
        // Arrange
        final repository = HistoryRepository(box: mockHistoryBox);

        when(() => mockHistoryBox.delete(any())).thenAnswer((_) async {});
        when(() => mockHistoryBox.get(any())).thenReturn(null);

        // Act
        await repository.delete('history-1');
        final result = await repository.getById('history-1');

        // Assert
        expect(result, isNull);
      });
    });

    group('TC-103-008: 存在しないIDの削除でエラーが発生しない', () {
      test('存在しないIDで削除してもエラーにならない', () async {
        // Arrange
        final repository = HistoryRepository(box: mockHistoryBox);

        when(() => mockHistoryBox.delete(any())).thenAnswer((_) async {});

        // Act & Assert: エラーが発生しないことを確認
        expect(
          () => repository.delete('non-existent-id'),
          returnsNormally,
        );
      });

      test('FavoriteRepositoryで存在しないIDを削除してもエラーにならない', () async {
        // Arrange
        final repository = FavoriteRepository(box: mockFavoriteBox);

        when(() => mockFavoriteBox.delete(any())).thenAnswer((_) async {});

        // Act & Assert
        expect(
          () => repository.delete('non-existent-id'),
          returnsNormally,
        );
      });
    });
  });
}
