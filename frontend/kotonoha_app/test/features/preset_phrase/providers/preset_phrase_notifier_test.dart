/// PresetPhraseNotifier テスト
///
/// TASK-0041: 定型文CRUD機能実装
/// テストケース: TC-041-032〜TC-041-042
///
/// テスト対象: lib/features/preset_phrase/providers/preset_phrase_notifier.dart
///
/// 【TDD Redフェーズ】: Notifierが未実装のため、このテストは失敗する
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    // =========================================================================
    // TC-041-032: 定型文を追加できる
    // =========================================================================
    /// TC-041-032: addPhrase()で定型文を追加できる
    ///
    /// 【テスト目的】: 追加機能の確認
    /// 【テスト内容】: 追加機能
    /// 【期待される動作】: 新しい定型文が状態に追加される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-104, AC-002
    /// 優先度: P0 必須
    test('TC-041-032: addPhrase()で定型文を追加できる', () async {
      // 【入力データ】: 新規定型文
      const content = 'おはようございます';
      const category = 'daily';

      // 【実行】: 定型文を追加
      await notifier.addPhrase(content, category);

      // 【結果検証】: 状態に追加されていることを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(1)); // 【確認内容】: 状態の変化 🔵
      expect(state.phrases.first.content, equals(content)); // 【確認内容】: 内容が正しい 🔵
      expect(state.phrases.first.category, equals(category)); // 【確認内容】: カテゴリが正しい 🔵
    });

    // =========================================================================
    // TC-041-033: 追加時にUUIDが自動付与される
    // =========================================================================
    /// TC-041-033: 追加された定型文にUUID形式のIDが自動付与される
    ///
    /// 【テスト目的】: ID自動生成の確認
    /// 【テスト内容】: ID自動生成
    /// 【期待される動作】: UUID形式のIDが付与される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-003
    /// 優先度: P0 必須
    test('TC-041-033: 追加された定型文にUUID形式のIDが自動付与される', () async {
      // 【入力データ】: 新規定型文（ID未指定）
      const content = 'テスト';
      const category = 'daily';

      // 【実行】: 定型文を追加
      await notifier.addPhrase(content, category);

      // 【結果検証】: UUID形式のIDがあることを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.first.id, isNotEmpty); // 【確認内容】: IDが存在する 🔵
      // UUID形式の確認（8-4-4-4-12の形式）
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(
        uuidRegex.hasMatch(state.phrases.first.id),
        isTrue,
      ); // 【確認内容】: IDの形式 🔵
    });

    // =========================================================================
    // TC-041-034: 追加時にcreatedAt/updatedAtが設定される
    // =========================================================================
    /// TC-041-034: 追加された定型文にcreatedAt/updatedAtが自動設定される
    ///
    /// 【テスト目的】: タイムスタンプ設定の確認
    /// 【テスト内容】: タイムスタンプ自動設定
    /// 【期待される動作】: 現在時刻が設定される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: CRUD-008
    /// 優先度: P1 重要
    test('TC-041-034: 追加された定型文にcreatedAt/updatedAtが自動設定される', () async {
      // 【入力データ】: 新規定型文
      final beforeAdd = DateTime.now();
      const content = 'テスト';
      const category = 'daily';

      // 【実行】: 定型文を追加
      await notifier.addPhrase(content, category);
      final afterAdd = DateTime.now();

      // 【結果検証】: タイムスタンプが設定されていることを確認
      final state = container.read(presetPhraseNotifierProvider);
      final phrase = state.phrases.first;

      // createdAtが適切な範囲内であることを確認
      expect(
        phrase.createdAt.isAfter(beforeAdd.subtract(const Duration(seconds: 1))),
        isTrue,
      ); // 【確認内容】: createdAtの値 🟡
      expect(
        phrase.createdAt.isBefore(afterAdd.add(const Duration(seconds: 1))),
        isTrue,
      );

      // updatedAtも同様に設定されていることを確認
      expect(
        phrase.updatedAt.isAfter(beforeAdd.subtract(const Duration(seconds: 1))),
        isTrue,
      ); // 【確認内容】: updatedAtの値 🟡
    });
  });

  group('PresetPhraseNotifier - 更新機能テスト', () {
    // =========================================================================
    // TC-041-035: 定型文の内容を更新できる
    // =========================================================================
    /// TC-041-035: updatePhrase()で定型文の内容を更新できる
    ///
    /// 【テスト目的】: 内容更新の確認
    /// 【テスト内容】: 内容更新機能
    /// 【期待される動作】: 指定した定型文の内容が更新される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-104, AC-004
    /// 優先度: P0 必須
    test('TC-041-035: updatePhrase()で定型文の内容を更新できる', () async {
      // 【前提条件】: 定型文を1件追加
      await notifier.addPhrase('元の内容', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;

      // 【入力データ】: 内容変更
      const newContent = '更新後の内容';

      // 【実行】: 定型文を更新
      await notifier.updatePhrase(existingId, content: newContent);

      // 【結果検証】: 内容が更新されていることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.content, equals(newContent)); // 【確認内容】: 更新後のcontent 🔵
    });

    // =========================================================================
    // TC-041-036: 定型文のカテゴリを更新できる
    // =========================================================================
    /// TC-041-036: updatePhrase()で定型文のカテゴリを更新できる
    ///
    /// 【テスト目的】: カテゴリ更新の確認
    /// 【テスト内容】: カテゴリ更新機能
    /// 【期待される動作】: 指定した定型文のカテゴリが更新される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: REQ-104
    /// 優先度: P1 重要
    test('TC-041-036: updatePhrase()で定型文のカテゴリを更新できる', () async {
      // 【前提条件】: 定型文を1件追加
      await notifier.addPhrase('テスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;

      // 【入力データ】: カテゴリ変更
      const newCategory = 'health';

      // 【実行】: 定型文を更新
      await notifier.updatePhrase(existingId, category: newCategory);

      // 【結果検証】: カテゴリが更新されていることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.category, equals(newCategory)); // 【確認内容】: 更新後のcategory 🟡
    });
  });

  group('PresetPhraseNotifier - 削除機能テスト', () {
    // =========================================================================
    // TC-041-037: 定型文を削除できる
    // =========================================================================
    /// TC-041-037: deletePhrase()で定型文を削除できる
    ///
    /// 【テスト目的】: 削除機能の確認
    /// 【テスト内容】: 削除機能
    /// 【期待される動作】: 指定した定型文が状態から削除される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-104, AC-006
    /// 優先度: P0 必須
    test('TC-041-037: deletePhrase()で定型文を削除できる', () async {
      // 【前提条件】: 定型文を1件追加
      await notifier.addPhrase('削除テスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;
      expect(state.phrases.length, equals(1));

      // 【入力データ】: 削除対象ID

      // 【実行】: 定型文を削除
      await notifier.deletePhrase(existingId);

      // 【結果検証】: 削除されていることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.length, equals(0)); // 【確認内容】: 状態から削除されていること 🔵
    });
  });

  group('PresetPhraseNotifier - お気に入り機能テスト', () {
    // =========================================================================
    // TC-041-038: お気に入りフラグを切り替えできる
    // =========================================================================
    /// TC-041-038: toggleFavorite()でお気に入りフラグを切り替えできる
    ///
    /// 【テスト目的】: お気に入り切替の確認
    /// 【テスト内容】: お気に入り切替機能
    /// 【期待される動作】: isFavoriteが反転する
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-007, CRUD-106, AC-007
    /// 優先度: P0 必須
    test('TC-041-038: toggleFavorite()でお気に入りフラグを切り替えできる（false→true）', () async {
      // 【前提条件】: 定型文を1件追加（isFavorite: false）
      await notifier.addPhrase('お気に入りテスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;
      expect(state.phrases.first.isFavorite, isFalse);

      // 【実行】: お気に入りを切り替え
      await notifier.toggleFavorite(existingId);

      // 【結果検証】: フラグが反転していることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.isFavorite, isTrue); // 【確認内容】: isFavoriteの値 🔵
    });

    // =========================================================================
    // TC-041-039: お気に入り解除ができる
    // =========================================================================
    /// TC-041-039: toggleFavorite()でお気に入り解除ができる
    ///
    /// 【テスト目的】: お気に入り解除の確認
    /// 【テスト内容】: お気に入り解除機能
    /// 【期待される動作】: isFavoriteがtrue→falseに変わる
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: CRUD-007
    /// 優先度: P0 必須
    test('TC-041-039: toggleFavorite()でお気に入り解除ができる（true→false）', () async {
      // 【前提条件】: お気に入り登録済みの定型文を作成
      await notifier.addPhrase('お気に入りテスト', 'daily');
      final state = container.read(presetPhraseNotifierProvider);
      final existingId = state.phrases.first.id;

      // まずお気に入りに設定
      await notifier.toggleFavorite(existingId);
      final favoriteState = container.read(presetPhraseNotifierProvider);
      expect(favoriteState.phrases.first.isFavorite, isTrue);

      // 【実行】: お気に入りを解除
      await notifier.toggleFavorite(existingId);

      // 【結果検証】: フラグが反転していることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.isFavorite, isFalse); // 【確認内容】: isFavoriteの値 🔵
    });

    // =========================================================================
    // TC-041-040: お気に入り切替後に一覧表示位置が更新される
    // =========================================================================
    /// TC-041-040: お気に入り切替後に一覧の表示順序が更新される
    ///
    /// 【テスト目的】: 表示順序更新の確認
    /// 【テスト内容】: 一覧更新機能
    /// 【期待される動作】: お気に入りが上部に移動する
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-105, AC-008
    /// 優先度: P0 必須
    test('TC-041-040: お気に入り切替後に一覧の表示順序が更新される', () async {
      // 【前提条件】: 複数の定型文を追加
      await notifier.addPhrase('定型文1', 'daily'); // お気に入りにしない
      await notifier.addPhrase('定型文2', 'daily'); // これをお気に入りにする

      final state = container.read(presetPhraseNotifierProvider);
      final phrase2Id = state.phrases[1].id;

      // 【実行】: 定型文2をお気に入りに
      await notifier.toggleFavorite(phrase2Id);

      // 【結果検証】: お気に入りが上部に表示されることを確認
      final updatedState = container.read(presetPhraseNotifierProvider);
      expect(updatedState.phrases.first.content, equals('定型文2')); // 【確認内容】: 並び順 🔵
      expect(updatedState.phrases.first.isFavorite, isTrue);
    });
  });

  group('PresetPhraseNotifier - エラーハンドリングテスト', () {
    // =========================================================================
    // TC-041-041: 存在しないIDで更新しようとするとエラー
    // =========================================================================
    /// TC-041-041: 存在しないIDでupdatePhrase()を呼び出すとエラーハンドリングされる
    ///
    /// 【テスト目的】: エラーハンドリングの確認
    /// 【テスト内容】: 不正ID時のエラーハンドリング
    /// 【期待される動作】: エラーが発生し、状態は変化しない
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: EDGE-009
    /// 優先度: P1 重要
    test('TC-041-041: 存在しないIDでupdatePhrase()を呼び出すとエラーハンドリングされる', () async {
      // 【前提条件】: 空の状態
      final initialState = container.read(presetPhraseNotifierProvider);
      expect(initialState.phrases.length, equals(0));

      // 【入力データ】: 存在しないID
      const nonExistentId = 'non-existent-id';

      // 【実行】: 存在しないIDで更新を試みる
      await notifier.updatePhrase(nonExistentId, content: '更新');

      // 【結果検証】: エラーハンドリングされ、状態は変化しないことを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(0)); // 【確認内容】: 状態は変化しない 🟡
      // エラー状態が設定されているか、またはログ出力されていることを確認
      // （実装によってはerrorフィールドに設定される可能性がある）
    });

    // =========================================================================
    // TC-041-042: 存在しないIDで削除しようとするとエラー
    // =========================================================================
    /// TC-041-042: 存在しないIDでdeletePhrase()を呼び出すとエラーハンドリングされる
    ///
    /// 【テスト目的】: エラーハンドリングの確認
    /// 【テスト内容】: 不正ID時のエラーハンドリング
    /// 【期待される動作】: エラーが発生し、状態は変化しない
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: EDGE-010
    /// 優先度: P1 重要
    test('TC-041-042: 存在しないIDでdeletePhrase()を呼び出すとエラーハンドリングされる', () async {
      // 【前提条件】: 定型文を1件追加
      await notifier.addPhrase('テスト', 'daily');
      final initialState = container.read(presetPhraseNotifierProvider);
      expect(initialState.phrases.length, equals(1));

      // 【入力データ】: 存在しないID
      const nonExistentId = 'non-existent-id';

      // 【実行】: 存在しないIDで削除を試みる
      await notifier.deletePhrase(nonExistentId);

      // 【結果検証】: エラーハンドリングされ、状態は変化しないことを確認
      final state = container.read(presetPhraseNotifierProvider);
      expect(state.phrases.length, equals(1)); // 【確認内容】: 状態は変化しない 🟡
    });
  });
}
