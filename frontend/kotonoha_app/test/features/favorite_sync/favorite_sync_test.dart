/// 定型文お気に入りとお気に入り画面の連動機能 - テスト
///
/// TDD-FAVORITE-SYNC: Greenフェーズ完了 → Refactorフェーズ完了
/// テストケース: TC-SYNC-001〜TC-SYNC-303（全13件成功）
///
/// テスト対象:
/// - lib/features/preset_phrase/providers/preset_phrase_notifier.dart
/// - lib/features/favorite/providers/favorite_provider.dart
/// - lib/features/favorite/domain/models/favorite.dart
///
/// TDD完了: 連動機能が実装され、全テストが成功
/// 品質保証: セキュリティ・パフォーマンスレビュー完了
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';

void main() {
  late ProviderContainer container;
  late PresetPhraseNotifier presetPhraseNotifier;
  late FavoriteNotifier favoriteNotifier;

  setUp(() {
    // テスト前準備: 共通のProviderContainerを作成し、両Notifierを取得
    // 環境初期化: 各テストを独立して実行するため、新しいコンテナを作成
    container = ProviderContainer();
    presetPhraseNotifier =
        container.read(presetPhraseNotifierProvider.notifier);
    favoriteNotifier = container.read(favoriteProvider.notifier);
  });

  tearDown(() {
    // テスト後処理: ProviderContainerをディスポーズ
    // 状態復元: リソースリークを防止
    container.dispose();
  });

  // ===========================================================================
  // 1. 正常系テストケース（基本的な動作）
  // ===========================================================================
  group('正常系テスト - 定型文お気に入りとFavoriteの連動', () {
    // =========================================================================
    // TC-SYNC-001: 定型文をお気に入りにするとFavoriteにも追加される
    // =========================================================================
    /// TC-SYNC-001: 定型文お気に入り追加時のFavorite連動
    ///
    /// テスト目的: toggleFavorite()で定型文をお気に入りにした際、
    ///                FavoriteNotifierにも自動追加されることを確認
    /// テスト内容: toggleFavorite()でお気に入りになった際の連動
    /// 期待される動作: 両方のProviderに同じcontentが登録される
    ///
    /// 信頼性レベル: 青信号 - REQ-701に基づく
    /// 関連要件: REQ-701（定型文をお気に入りとして登録）
    test('TC-SYNC-001: 定型文をお気に入りにするとFavoriteにも追加される', () async {
      // テストデータ準備: 定型文を1件追加
      // 初期条件設定: お気に入りでない定型文を作成
      const content = 'おはようございます';
      await presetPhraseNotifier.addPhrase(content, 'daily');

      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;
      // 設計変更: Phase 3 / WP-2 / Stage 3b - お気に入りの正は favoriteProvider
      // だけ（ADR-005）。初期状態は「お気に入りが0件」で確認する。
      expect(container.read(favoriteProvider).favorites,
          isEmpty); // 確認内容: 初期状態確認

      // 実際の処理実行: toggleFavorite()でお気に入りに追加
      // 処理内容: 定型文のお気に入りを切り替え
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 結果検証: お気に入りの正に、この定型文由来の1件が入ること
      // 期待値確認: REQ-701「定型文をお気に入りとして登録」の実現
      final favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length,
          equals(1)); // 確認内容: Favoriteに追加されている
      expect(favoriteState.favorites.first.content,
          equals(content)); // 確認内容: 同じcontentが登録
      expect(favoriteState.favorites.first.sourceId,
          equals(phraseId)); // 確認内容: どの定型文由来かが分かる
    });

    // =========================================================================
    // TC-SYNC-002: 定型文のお気に入りを解除するとFavoriteからも削除される
    // =========================================================================
    /// TC-SYNC-002: 定型文お気に入り解除時のFavorite連動削除
    ///
    /// テスト目的: お気に入り済みの定型文を解除した際、
    ///                FavoriteNotifierからも自動削除されることを確認
    /// テスト内容: toggleFavorite()でお気に入りを解除した際の連動
    /// 期待される動作: 両方のProviderから該当項目が削除される
    ///
    /// 信頼性レベル: 青信号 - REQ-701に基づく
    test('TC-SYNC-002: 定型文のお気に入りを解除するとFavoriteからも削除される', () async {
      // テストデータ準備: 定型文を追加してお気に入りにする
      // 初期条件設定: お気に入り済みの状態を作成
      const content = 'ありがとうございます';
      await presetPhraseNotifier.addPhrase(content, 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;

      // お気に入りに追加
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 連動でFavoriteにも追加されていることを確認
      var favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length,
          equals(1)); // 確認内容: Favoriteに追加済み
      expect(favoriteState.favorites.first.sourceId,
          equals(phraseId)); // 確認内容: この定型文由来である

      // 実際の処理実行: toggleFavorite()でお気に入りを解除
      // 処理内容: 定型文のお気に入りを解除
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 結果検証: 定型文自体は残っていること（お気に入り解除は削除ではない）
      final updatedPresetState = container.read(presetPhraseNotifierProvider);
      expect(
          updatedPresetState.phrases.length, equals(1)); // 確認内容: 定型文は消えない

      // 結果検証: Favoriteからも削除されること
      // 期待値確認: UX一貫性のため、解除時も連動が必要
      favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length,
          equals(0)); // 確認内容: Favoriteから削除されている
    });

    // =========================================================================
    // TC-SYNC-003: Favoriteにsourceとして定型文情報が保存される
    // =========================================================================
    /// TC-SYNC-003: Favorite追加時のsource情報保存
    ///
    /// テスト目的: Favoriteエンティティに元データの情報（sourceType, sourceId）
    ///                が保存されることを確認
    /// テスト内容: addFavoriteFromPresetPhrase()でsourceType, sourceIdが設定される
    /// 期待される動作: Favoriteエンティティに追跡情報が含まれる
    ///
    /// 信頼性レベル: 黄信号 - 実装設計に基づく推測
    test('TC-SYNC-003: Favoriteにsourceとして定型文情報が保存される', () async {
      // テストデータ準備: 定型文を追加
      const content = 'こんにちは';
      await presetPhraseNotifier.addPhrase(content, 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;

      // 実際の処理実行: お気に入りに追加
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 結果検証: FavoriteにsourceType, sourceIdが設定されていること
      // 期待値確認: 双方向連動のために元データを追跡する必要がある
      final favoriteState = container.read(favoriteProvider);
      final favorite = favoriteState.favorites.first;

      // NOTE: sourceType, sourceIdフィールドの追加が必要（Greenフェーズで実装）
      expect(favorite.sourceType,
          equals('preset_phrase')); // 確認内容: sourceType
      expect(favorite.sourceId, equals(phraseId)); // 確認内容: sourceId
    });

    // =========================================================================
    // TC-SYNC-005: 複数の定型文を連続してお気に入りにできる
    // =========================================================================
    /// TC-SYNC-005: 複数定型文の連続お気に入り追加
    ///
    /// テスト目的: 複数の定型文を連続してお気に入りにした場合、
    ///                すべてがFavoriteに追加されることを確認
    /// テスト内容: 3件の定型文をそれぞれtoggleFavorite()で追加
    /// 期待される動作: FavoriteState.favorites.length == 3
    ///
    /// 信頼性レベル: 青信号 - 基本機能の確認
    test('TC-SYNC-005: 複数の定型文を連続してお気に入りにできる', () async {
      // テストデータ準備: 3件の定型文を準備
      await presetPhraseNotifier.addPhrase('定型文A', 'daily');
      await presetPhraseNotifier.addPhrase('定型文B', 'daily');
      await presetPhraseNotifier.addPhrase('定型文C', 'daily');

      final presetState = container.read(presetPhraseNotifierProvider);
      expect(presetState.phrases.length, equals(3)); // 確認内容: 3件追加済み

      // 実際の処理実行: 各定型文をお気に入りに追加
      for (final phrase in presetState.phrases) {
        await presetPhraseNotifier.toggleFavorite(phrase.id);
      }

      // 結果検証: Favoriteに3件追加されていること
      final favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(3)); // 確認内容: 3件の連動追加
    });
  });

  // ===========================================================================
  // 2. 異常系テストケース（エラーハンドリング）
  // ===========================================================================
  group('異常系テスト - エラーハンドリング', () {
    // =========================================================================
    // TC-SYNC-101: 存在しない定型文IDでtoggleFavoriteを呼び出しても例外が発生しない
    // =========================================================================
    /// TC-SYNC-101: 存在しないIDでのtoggleFavorite呼び出し
    ///
    /// テスト目的: 存在しない定型文IDで操作を試みた場合の安全性確認
    /// テスト内容: 存在しないIDでtoggleFavorite()を呼び出し
    /// 期待される動作: 例外なし、状態変化なし
    ///
    /// 信頼性レベル: 黄信号 - エラーハンドリングの推測
    test('TC-SYNC-101: 存在しない定型文IDでtoggleFavoriteを呼び出しても例外が発生しない', () async {
      // テストデータ準備: 何も追加しない空の状態
      final initialPresetState = container.read(presetPhraseNotifierProvider);
      final initialFavoriteState = container.read(favoriteProvider);

      // 実際の処理実行: 存在しないIDでtoggleFavorite()を実行
      // 処理内容: 不正なIDでの操作
      await presetPhraseNotifier.toggleFavorite('non-existent-id');

      // 結果検証: 例外なし、状態変化なし
      final updatedPresetState = container.read(presetPhraseNotifierProvider);
      final updatedFavoriteState = container.read(favoriteProvider);

      expect(updatedPresetState.phrases.length,
          equals(initialPresetState.phrases.length)); // 確認内容: 状態変化なし
      expect(updatedFavoriteState.favorites.length,
          equals(initialFavoriteState.favorites.length)); // 確認内容: 連動なし
    });

    // =========================================================================
    // TC-SYNC-102: 同じ定型文を重複してお気に入りに追加しようとしても1件のみ登録される
    // =========================================================================
    /// TC-SYNC-102: 重複登録の防止
    ///
    /// テスト目的: 同じ定型文を複数回お気に入りにした場合の重複防止確認
    /// テスト内容: 同じ定型文に対してtoggleFavorite()を3回実行（追加→解除→追加）
    /// 期待される動作: Favoriteリストに該当contentが1件のみ存在
    ///
    /// 信頼性レベル: 青信号 - 要件定義3.2に基づく
    test('TC-SYNC-102: 同じ定型文を重複してお気に入りに追加しようとしても1件のみ登録される', () async {
      // テストデータ準備: 定型文を1件追加
      const content = 'テスト文';
      await presetPhraseNotifier.addPhrase(content, 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;

      // 実際の処理実行: toggleFavorite()を3回実行（追加→解除→追加）
      await presetPhraseNotifier.toggleFavorite(phraseId); // 追加
      await presetPhraseNotifier.toggleFavorite(phraseId); // 解除
      await presetPhraseNotifier.toggleFavorite(phraseId); // 追加

      // 結果検証: Favoriteリストに1件のみ存在
      final favoriteState = container.read(favoriteProvider);
      final matchingFavorites =
          favoriteState.favorites.where((f) => f.content == content).toList();
      expect(matchingFavorites.length, equals(1)); // 確認内容: 重複なし
    });

    // =========================================================================
    // TC-SYNC-103: 同じcontentの履歴由来と定型文由来が共存できる
    // =========================================================================
    /// TC-SYNC-103: 履歴由来と定型文由来の共存
    ///
    /// テスト目的: 同じcontentで異なるsourceの項目が共存できることを確認
    /// テスト内容: 履歴と定型文の両方から同じcontentをお気に入りに追加
    /// 期待される動作: 2件の独立したFavoriteが存在（sourceIdが異なる）
    ///
    /// 信頼性レベル: 黄信号 - 設計判断に基づく推測
    test('TC-SYNC-103: 同じcontentの履歴由来と定型文由来が共存できる', () async {
      // テストデータ準備: 履歴由来のお気に入りを直接追加
      const content = 'おはようございます';
      await favoriteNotifier.addFavorite(content); // 履歴由来（sourceなし）

      // 定型文を追加してお気に入りに
      await presetPhraseNotifier.addPhrase(content, 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;

      // 実際の処理実行: 定型文をお気に入りに追加
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 結果検証: 2件の独立したFavoriteが存在
      // 期待値確認: sourceIdで管理するため、contentの重複は許容
      final favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(2)); // 確認内容: 2件存在

      // sourceIdが異なることを確認
      final favoriteWithSource =
          favoriteState.favorites.where((f) => f.sourceId == phraseId);
      final favoriteWithoutSource =
          favoriteState.favorites.where((f) => f.sourceId == null);
      expect(favoriteWithSource.length, equals(1)); // 確認内容: 定型文由来
      expect(favoriteWithoutSource.length, equals(1)); // 確認内容: 履歴由来
    });
  });

  // ===========================================================================
  // 3. 境界値テストケース
  // ===========================================================================
  group('境界値テスト', () {
    // =========================================================================
    // TC-SYNC-201: お気に入りが0件の状態から定型文を追加
    // =========================================================================
    /// TC-SYNC-201: 空状態からの最初のお気に入り追加
    ///
    /// テスト目的: お気に入り0件からの追加が正常動作することを確認
    /// テスト内容: お気に入り0件の状態で定型文をお気に入りに追加
    /// 期待される動作: FavoriteState.favorites.length == 1
    ///
    /// 信頼性レベル: 青信号 - EDGE-104関連
    test('TC-SYNC-201: お気に入りが0件の状態から定型文を追加', () async {
      // テストデータ準備: お気に入り0件の状態を確認
      var favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(0)); // 確認内容: 初期状態

      // 定型文を追加
      await presetPhraseNotifier.addPhrase('はじめてのお気に入り', 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;

      // 実際の処理実行: お気に入りに追加
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 結果検証: Favoriteに1件追加されていること
      favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(1)); // 確認内容: 1件追加
    });

    // =========================================================================
    // TC-SYNC-202: お気に入り済み定型文を削除した場合、Favoriteからも削除される
    // =========================================================================
    /// TC-SYNC-202: 定型文削除時の連動Favorite削除
    ///
    /// テスト目的: 定型文削除時にFavoriteも連動削除されることを確認
    /// テスト内容: お気に入り済みの定型文を削除
    /// 期待される動作: 対応するFavoriteも削除される
    ///
    /// 信頼性レベル: 青信号 - 要件定義3.2「孤立データ防止」
    test('TC-SYNC-202: お気に入り済み定型文を削除した場合、Favoriteからも削除される', () async {
      // テストデータ準備: 定型文を追加してお気に入りにする
      const content = '削除テスト';
      await presetPhraseNotifier.addPhrase(content, 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;

      await presetPhraseNotifier.toggleFavorite(phraseId);

      // Favoriteに追加されていることを確認
      var favoriteState = container.read(favoriteProvider);
      expect(
          favoriteState.favorites.length, equals(1)); // 確認内容: Favorite追加済み

      // 実際の処理実行: 定型文を削除
      await presetPhraseNotifier.deletePhrase(phraseId);

      // 結果検証: 定型文が削除されていること
      final updatedPresetState = container.read(presetPhraseNotifierProvider);
      expect(updatedPresetState.phrases.length, equals(0)); // 確認内容: 定型文削除

      // 結果検証: Favoriteからも削除されていること
      // 期待値確認: 孤立データを防止するための連動削除
      favoriteState = container.read(favoriteProvider);
      expect(
          favoriteState.favorites.length, equals(0)); // 確認内容: Favoriteも削除
    });

    // =========================================================================
    // TC-SYNC-203: 全削除後に定型文をお気に入りにできる
    // =========================================================================
    /// TC-SYNC-203: 全削除後のお気に入り追加
    ///
    /// テスト目的: 全削除後も正常にお気に入り追加できることを確認
    /// テスト内容: clearAllFavorites()後に定型文をお気に入りに追加
    /// 期待される動作: FavoriteState.favorites.length == 1
    ///
    /// 信頼性レベル: 黄信号 - エッジケースの推測
    test('TC-SYNC-203: 全削除後に定型文をお気に入りにできる', () async {
      // テストデータ準備: 定型文を追加してお気に入りにし、全削除
      await presetPhraseNotifier.addPhrase('削除対象', 'daily');
      final presetState = container.read(presetPhraseNotifierProvider);
      final phraseId = presetState.phrases.first.id;
      await presetPhraseNotifier.toggleFavorite(phraseId);

      // 全削除
      await favoriteNotifier.clearAllFavorites();
      var favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(0)); // 確認内容: 全削除確認

      // 実際の処理実行: 新たにお気に入りに追加
      await presetPhraseNotifier.addPhrase('新規追加', 'daily');
      final newPresetState = container.read(presetPhraseNotifierProvider);
      final newPhraseId =
          newPresetState.phrases.firstWhere((p) => p.content == '新規追加').id;
      await presetPhraseNotifier.toggleFavorite(newPhraseId);

      // 結果検証: 正常にお気に入り追加できること
      favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(1)); // 確認内容: 追加成功
    });
  });

  // ===========================================================================
  // 4. FavoriteNotifier拡張テストケース
  // ===========================================================================
  group('FavoriteNotifier拡張テスト', () {
    // =========================================================================
    // TC-SYNC-301: addFavoriteFromPresetPhrase()で定型文由来のFavoriteが追加される
    // =========================================================================
    /// TC-SYNC-301: 定型文由来Favorite追加メソッド
    ///
    /// テスト目的: 新規メソッドaddFavoriteFromPresetPhrase()の動作確認
    /// テスト内容: 定型文由来のFavoriteを追加
    /// 期待される動作: sourceType, sourceIdが正しく設定される
    ///
    /// 信頼性レベル: 黄信号 - 新規実装
    test('TC-SYNC-301: addFavoriteFromPresetPhrase()で定型文由来のFavoriteが追加される',
        () async {
      // テストデータ準備: テスト用のcontent, sourceId
      const content = 'テスト定型文';
      const sourceId = '123e4567-e89b-12d3-a456-426614174000';

      // 実際の処理実行: addFavoriteFromPresetPhrase()を実行
      // NOTE: このメソッドはGreenフェーズで追加する
      await favoriteNotifier.addFavoriteFromPresetPhrase(content, sourceId);

      // 結果検証: Favoriteが追加されていること
      final favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(1)); // 確認内容: 追加

      // 結果検証: sourceType, sourceIdが正しく設定されていること
      final favorite = favoriteState.favorites.first;
      expect(favorite.sourceType,
          equals('preset_phrase')); // 確認内容: sourceType
      expect(favorite.sourceId, equals(sourceId)); // 確認内容: sourceId
      expect(favorite.content, equals(content)); // 確認内容: content
    });

    // =========================================================================
    // TC-SYNC-302: deleteFavoriteBySourceId()でsourceIdに一致するFavoriteが削除される
    // =========================================================================
    /// TC-SYNC-302: sourceIdによるFavorite削除メソッド
    ///
    /// テスト目的: 新規メソッドdeleteFavoriteBySourceId()の動作確認
    /// テスト内容: sourceIdに一致するFavoriteを削除
    /// 期待される動作: 該当Favoriteのみ削除される
    ///
    /// 信頼性レベル: 黄信号 - 新規実装
    test('TC-SYNC-302: deleteFavoriteBySourceId()でsourceIdに一致するFavoriteが削除される',
        () async {
      // テストデータ準備: 複数のFavoriteを準備（異なるsourceId）
      const sourceId1 = 'source-id-1';
      const sourceId2 = 'source-id-2';
      await favoriteNotifier.addFavoriteFromPresetPhrase('定型文1', sourceId1);
      await favoriteNotifier.addFavoriteFromPresetPhrase('定型文2', sourceId2);

      var favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(2)); // 確認内容: 2件追加

      // 実際の処理実行: deleteFavoriteBySourceId()を実行
      // NOTE: このメソッドはGreenフェーズで追加する
      await favoriteNotifier.deleteFavoriteBySourceId(sourceId1);

      // 結果検証: 該当Favoriteのみ削除されること
      favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(1)); // 確認内容: 1件に減少
      expect(favoriteState.favorites.first.content,
          equals('定型文2')); // 確認内容: 正しい方が残る
    });

    // =========================================================================
    // TC-SYNC-303: deleteFavoriteBySourceId()で該当なしの場合は何も削除されない
    // =========================================================================
    /// TC-SYNC-303: sourceIdに該当なしの場合の安全性
    ///
    /// テスト目的: 存在しないsourceIdで削除を試みた場合の動作確認
    /// テスト内容: 存在しないsourceIdでdeleteFavoriteBySourceId()を実行
    /// 期待される動作: 例外なし、状態変化なし
    ///
    /// 信頼性レベル: 黄信号 - エラーハンドリング
    test('TC-SYNC-303: deleteFavoriteBySourceId()で該当なしの場合は何も削除されない', () async {
      // テストデータ準備: Favoriteを準備
      const sourceId = 'existing-source-id';
      await favoriteNotifier.addFavoriteFromPresetPhrase('テスト', sourceId);

      var favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(1)); // 確認内容: 1件追加

      // 実際の処理実行: 存在しないsourceIdで削除を試みる
      await favoriteNotifier.deleteFavoriteBySourceId('non-existent-source-id');

      // 結果検証: 例外なし、状態変化なし
      favoriteState = container.read(favoriteProvider);
      expect(favoriteState.favorites.length, equals(1)); // 確認内容: 変化なし
    });
  });
}
