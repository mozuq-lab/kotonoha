/// PresetPhraseNotifier テスト
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/data/default_phrases.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';

void main() {
  late ProviderContainer container;
  late PresetPhraseNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(presetPhraseNotifierProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('PresetPhraseNotifier - 追加機能テスト', () {
    // 定型文を追加できる
    /// addPhraseで定型文を追加できる
    test('TC-041-032: addPhrase()で定型文を追加できる', () async {
      // 入力データ: 新規定型文
      const content = 'おはようございます';
      const category = 'daily';

      // 実行: 定型文を追加
      await notifier.addPhrase(content, category);

      // 結果検証: 状態に追加されていることを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(1));
      expect(state.phrases.first.content, equals(content));
      expect(state.phrases.first.category, equals(category));
    });

    // 追加時にUUIDが自動付与される
    /// 追加された定型文にUUID形式のIDが自動付与される
    test('TC-041-033: 追加された定型文にUUID形式のIDが自動付与される', () async {
      // 入力データ: 新規定型文（ID未指定）
      const content = 'テスト';
      const category = 'daily';

      // 実行: 定型文を追加
      await notifier.addPhrase(content, category);

      // 結果検証: UUID形式のIDがあることを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.first.id, isNotEmpty);
      // UUID形式の確認（8-4-4-4-12の形式）
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(
        uuidRegex.hasMatch(state.phrases.first.id),
        isTrue,
      );
    });

    // 追加時にcreatedAt/updatedAtが設定される
    /// 追加された定型文にcreatedAt/updatedAtが自動設定される
    test('TC-041-034: 追加された定型文にcreatedAt/updatedAtが自動設定される', () async {
      // 入力データ: 新規定型文
      final beforeAdd = DateTime.now();
      const content = 'テスト';
      const category = 'daily';

      // 実行: 定型文を追加
      await notifier.addPhrase(content, category);
      final afterAdd = DateTime.now();

      // 結果検証: タイムスタンプが設定されていることを確認
      final state = container.read(presetPhraseNotifierProvider);
      final phrase = state.phrases.first;

      // createdAtが適切な範囲内であることを確認
      expect(
        phrase.createdAt
            .isAfter(beforeAdd.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        phrase.createdAt.isBefore(afterAdd.add(const Duration(seconds: 1))),
        isTrue,
      );

      // updatedAtも同様に設定されていることを確認
      expect(
        phrase.updatedAt
            .isAfter(beforeAdd.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('PresetPhraseNotifier - 更新機能テスト', () {
    // 定型文の内容を更新できる
    /// updatePhraseで定型文の内容を更新できる
    test('TC-041-035: updatePhrase()で定型文の内容を更新できる', () async {
      // 前提条件: 定型文を1件追加
      await notifier.addPhrase('元の内容', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;

      // 入力データ: 内容変更
      const newContent = '更新後の内容';

      // 実行: 定型文を更新
      await notifier.updatePhrase(existingId, content: newContent);

      // 結果検証: 内容が更新されていることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.content, equals(newContent));
    });

    // 定型文のカテゴリを更新できる
    /// updatePhraseで定型文のカテゴリを更新できる
    test('TC-041-036: updatePhrase()で定型文のカテゴリを更新できる', () async {
      // 前提条件: 定型文を1件追加
      await notifier.addPhrase('テスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;

      // 入力データ: カテゴリ変更
      const newCategory = 'health';

      // 実行: 定型文を更新
      await notifier.updatePhrase(existingId, category: newCategory);

      // 結果検証: カテゴリが更新されていることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.category, equals(newCategory));
    });
  });

  group('PresetPhraseNotifier - 削除機能テスト', () {
    // 定型文を削除できる
    /// deletePhraseで定型文を削除できる
    test('TC-041-037: deletePhrase()で定型文を削除できる', () async {
      // 前提条件: 定型文を1件追加
      await notifier.addPhrase('削除テスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;
      expect(state.phrases.length, equals(1));

      // 入力データ: 削除対象ID

      // 実行: 定型文を削除
      await notifier.deletePhrase(existingId);

      // 結果検証: 削除されていることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.length, equals(0));
    });
  });

  group('PresetPhraseNotifier - お気に入り機能テスト', () {
    // お気に入りフラグを切り替えできる
    /// toggleFavoriteでお気に入りフラグを切り替えできる
    test('TC-041-038: toggleFavorite()でお気に入りにできる（未登録→登録）', () async {
      // 前提条件: 定型文を1件追加
      await notifier.addPhrase('お気に入りテスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;
      expect(container.read(favoriteProvider).favorites, isEmpty);

      // 実行: お気に入りを切り替え
      await notifier.toggleFavorite(existingId);

      // 結果検証: お気に入りの正に、この定型文由来の1件が入る
      final favorites = container.read(favoriteProvider).favorites;
      expect(favorites.length, equals(1));
      expect(favorites.first.sourceType, equals('preset_phrase'));
      expect(favorites.first.sourceId, equals(existingId));
      expect(favorites.first.content, equals('お気に入りテスト'));
    });

    // お気に入り解除ができる
    /// toggleFavoriteでお気に入り解除ができる
    test('TC-041-039: toggleFavorite()でお気に入り解除ができる（登録→未登録）', () async {
      // 前提条件: お気に入り登録済みの定型文を作成
      await notifier.addPhrase('お気に入りテスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;

      // まずお気に入りに設定
      await notifier.toggleFavorite(existingId);
      expect(container.read(favoriteProvider).favorites.length, equals(1));

      // 実行: お気に入りを解除
      await notifier.toggleFavorite(existingId);

      // 結果検証: お気に入りの正から消えていること
      expect(container.read(favoriteProvider).favorites, isEmpty);
      // 定型文そのものは残っている（解除は削除ではない）
      expect(container.read(presetPhraseNotifierProvider).phrases.length,
          equals(1));
    });
  });

  group('PresetPhraseNotifier - エラーハンドリングテスト', () {
    // 存在しないIDで更新しようとするとエラー
    /// 存在しないIDでupdatePhraseを呼び出すとエラーハンドリングされる
    test('TC-041-041: 存在しないIDでupdatePhrase()を呼び出すとエラーハンドリングされる', () async {
      // 前提条件: 空の状態
      final initialState = container.read(presetPhraseNotifierProvider);
      expect(initialState.phrases.length, equals(0));

      // 入力データ: 存在しないID
      const nonExistentId = 'non-existent-id';

      // 実行: 存在しないIDで更新を試みる
      await notifier.updatePhrase(nonExistentId, content: '更新');

      // 結果検証: エラーハンドリングされ、状態は変化しないことを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(0));
      // エラー状態が設定されているか、またはログ出力されていることを確認
      // （実装によってはerrorフィールドに設定される可能性がある）
    });

    // 存在しないIDで削除しようとするとエラー
    /// 存在しないIDでdeletePhraseを呼び出すとエラーハンドリングされる
    test('TC-041-042: 存在しないIDでdeletePhrase()を呼び出すとエラーハンドリングされる', () async {
      // 前提条件: 定型文を1件追加
      await notifier.addPhrase('テスト', 'daily');
      final initialState = container.read(presetPhraseNotifierProvider);
      expect(initialState.phrases.length, equals(1));

      // 入力データ: 存在しないID
      const nonExistentId = 'non-existent-id';

      // 実行: 存在しないIDで削除を試みる
      await notifier.deletePhrase(nonExistentId);

      // 結果検証: エラーハンドリングされ、状態は変化しないことを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(1));
    });
  });

  group('PresetPhraseNotifier - 初期データ投入機能テスト (TASK-0042)', () {
    // 初期データが投入される
    /// initializeDefaultPhrasesで初期データが投入される
    test('TC-042-001: initializeDefaultPhrases()で50個以上の定型文が投入される', () async {
      // 前提条件: 空の状態
      final initialState = container.read(presetPhraseNotifierProvider);
      expect(initialState.phrases.length, equals(0));

      // 実行: 初期データを投入
      await notifier.initializeDefaultPhrases();

      // 結果検証: 50個以上の定型文があることを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, greaterThanOrEqualTo(50));
      expect(state.phrases.length, lessThanOrEqualTo(100));
    });

    // カテゴリごとに適切に分類される
    /// 投入される定型文がカテゴリごとに分類されている
    test('TC-042-002: 投入される定型文が3カテゴリに分類されている', () async {
      // 実行: 初期データを投入
      await notifier.initializeDefaultPhrases();

      // 結果検証: 各カテゴリにデータがあることを確認
      final state = container.read(presetPhraseNotifierProvider);

      final dailyPhrases = state.phrases.where((p) => p.category == 'daily');
      final healthPhrases = state.phrases.where((p) => p.category == 'health');
      final otherPhrases = state.phrases.where((p) => p.category == 'other');

      expect(dailyPhrases.length, greaterThan(0));
      expect(healthPhrases.length, greaterThan(0));
      expect(otherPhrases.length, greaterThan(0));
    });

    // 重複投入されない
    /// 既にデータがある場合は投入されない
    test('TC-042-003: 既にデータがある場合は初期データが投入されない', () async {
      // 前提条件: 手動でデータを追加
      await notifier.addPhrase('手動追加', 'daily');
      final initialState = container.read(presetPhraseNotifierProvider);
      expect(initialState.phrases.length, equals(1));

      // 実行: 初期データを投入しようとする
      await notifier.initializeDefaultPhrases();

      // 結果検証: データが増えていないことを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(1));
      expect(state.phrases.first.content, equals('手動追加'));
    });

    // 初期データにUUIDが付与される
    /// 投入される初期データにUUIDが自動付与される
    test('TC-042-004: 投入される初期データにユニークなUUIDが付与される', () async {
      // 実行: 初期データを投入
      await notifier.initializeDefaultPhrases();

      // 結果検証: すべてのIDがユニークであることを確認
      final state = container.read(presetPhraseNotifierProvider);
      final ids = state.phrases.map((p) => p.id).toSet();
      expect(ids.length, equals(state.phrases.length));

      // UUID形式の確認
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      for (final phrase in state.phrases) {
        expect(uuidRegex.hasMatch(phrase.id), isTrue);
      }
    });

    // 初期データとDefaultPhrasesの整合性
    /// 投入される定型文の数がDefaultPhrasesと一致する
    test('TC-042-005: 投入される定型文の数がDefaultPhrasesと一致する', () async {
      // 実行: 初期データを投入
      await notifier.initializeDefaultPhrases();

      // 結果検証: 数が一致することを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(DefaultPhrases.totalCount));
    });

    // リセット機能のテスト
    /// resetToDefaultsでデータを初期状態に戻せる
    test('TC-042-006: resetToDefaults()でデータを初期状態に戻せる', () async {
      // 前提条件: 手動でデータを追加し、初期データを投入しない状態
      await notifier.addPhrase('手動追加1', 'daily');
      await notifier.addPhrase('手動追加2', 'health');

      // 実行: リセット
      await notifier.resetToDefaults();

      // 結果検証: 初期データに戻っていることを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(DefaultPhrases.totalCount));

      // 手動追加のデータがないことを確認
      final manualPhrases = state.phrases.where(
        (p) => p.content == '手動追加1' || p.content == '手動追加2',
      );
      expect(manualPhrases.isEmpty, isTrue);
    });
  });
}
