/// PresetPhraseNotifier - 定型文状態管理
///
/// TASK-0041: 定型文CRUD機能実装
/// TASK-0042: 定型文初期データ投入機能追加
/// TDD-FAVORITE-SYNC: お気に入り画面との連動機能追加
/// TDD Refactorフェーズ: ドキュメント改善
///
/// 関連要件:
/// - REQ-104: 定型文の追加・編集・削除機能
/// - REQ-105: お気に入り定型文を一覧上部に優先表示
/// - REQ-107: 初期データとして50-100個の汎用定型文を提供
/// - REQ-701: 定型文をお気に入りとして登録
/// - CRUD-003: UUID形式の一意識別子を自動付与
/// - CRUD-007: お気に入りフラグを切り替える機能
/// - CRUD-008: createdAt/updatedAtタイムスタンプを自動設定
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/data/default_phrases.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:uuid/uuid.dart';

/// 【状態管理】: 定型文一覧の状態
/// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
class PresetPhraseState {
  /// 定型文一覧
  final List<PresetPhrase> phrases;

  /// ローディング状態
  final bool isLoading;

  /// エラーメッセージ
  final String? error;

  const PresetPhraseState({
    this.phrases = const [],
    this.isLoading = false,
    this.error,
  });

  PresetPhraseState copyWith({
    List<PresetPhrase>? phrases,
    bool? isLoading,
    String? error,
  }) {
    return PresetPhraseState(
      phrases: phrases ?? this.phrases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 【機能概要】: 定型文状態管理Notifier
/// 【実装方針】: Riverpod StateNotifierで状態管理
/// 【テスト対応】: TC-041-032〜TC-041-042, TC-SYNC-001〜TC-SYNC-303
/// 🔵 信頼性レベル: 青信号 - REQ-104, REQ-105, REQ-701に基づく
///
/// 定型文のCRUD操作を提供するStateNotifier。
/// 追加、更新、削除、お気に入り切り替え機能を実装。
/// お気に入り操作時はFavoriteNotifierと連動する。
class PresetPhraseNotifier extends Notifier<PresetPhraseState> {
  /// 【フィールド定義】: FavoriteNotifierへの参照
  /// 【実装内容】: お気に入り連動のために使用
  /// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件に基づく
  late FavoriteNotifier? _favoriteNotifier;

  @override
  PresetPhraseState build() {
    _favoriteNotifier = ref.read(favoriteProvider.notifier);
    return const PresetPhraseState();
  }

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

  /// 【メソッド】: 定型文を追加する
  /// 【実装内容】: 新しい定型文をUUID付きで追加
  /// 【テスト対応】: TC-041-032, TC-041-033, TC-041-034
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  Future<void> addPhrase(String content, String category) async {
    final now = DateTime.now();
    final newPhrase = PresetPhrase(
      id: _uuid.v4(), // UUID形式のID自動生成 (CRUD-003)
      content: content,
      category: category,
      isFavorite: false,
      displayOrder: state.phrases.length,
      createdAt: now, // タイムスタンプ自動設定 (CRUD-008)
      updatedAt: now,
    );

    // 状態を更新し、お気に入り順でソート (REQ-105)
    final updatedPhrases = [...state.phrases, newPhrase];
    state = state.copyWith(phrases: _sortPhrases(updatedPhrases));
  }

  /// 【メソッド】: 定型文を更新する
  /// 【実装内容】: 指定IDの定型文を更新
  /// 【テスト対応】: TC-041-035, TC-041-036
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  Future<void> updatePhrase(
    String id, {
    String? content,
    String? category,
    bool? isFavorite,
  }) async {
    // 対象の定型文を検索 (EDGE-009対応)
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      // 存在しないIDの場合は何もしない
      return;
    }

    final original = state.phrases[index];
    final updatedPhrase = original.copyWith(
      content: content ?? original.content,
      category: category ?? original.category,
      isFavorite: isFavorite ?? original.isFavorite,
      updatedAt: DateTime.now(), // タイムスタンプ更新 (CRUD-008)
    );

    final updatedPhrases = List<PresetPhrase>.from(state.phrases);
    updatedPhrases[index] = updatedPhrase;
    state = state.copyWith(phrases: _sortPhrases(updatedPhrases));
  }

  /// 【メソッド】: 定型文を削除する
  /// 【実装内容】: 指定IDの定型文を削除し、お気に入りの場合はFavoriteからも削除
  /// 【テスト対応】: TC-041-037, TC-SYNC-202
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  Future<void> deletePhrase(String id) async {
    // 対象の定型文を検索 (EDGE-010対応)
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      // 存在しないIDの場合は何もしない
      return;
    }

    // 【連動処理】: お気に入り済みの定型文を削除する場合、Favoriteからも削除（TC-SYNC-202）
    // 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件に基づく
    final phrase = state.phrases[index];
    if (phrase.isFavorite && _favoriteNotifier != null) {
      await _favoriteNotifier!.deleteFavoriteBySourceId(id);
    }

    final updatedPhrases = List<PresetPhrase>.from(state.phrases);
    updatedPhrases.removeAt(index);
    state = state.copyWith(phrases: updatedPhrases);
  }

  /// 【メソッド】: お気に入りを切り替える
  /// 【実装内容】: 指定IDの定型文のお気に入りフラグを反転し、Favoriteと連動
  /// 【テスト対応】: TC-041-038〜040, TC-SYNC-001, TC-SYNC-002, TC-SYNC-003
  /// 🔵 信頼性レベル: 青信号 - CRUD-007, CRUD-106, REQ-701に基づく
  Future<void> toggleFavorite(String id) async {
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      return;
    }

    final original = state.phrases[index];
    final updatedPhrase = original.copyWith(
      isFavorite: !original.isFavorite,
      updatedAt: DateTime.now(),
    );

    final updatedPhrases = List<PresetPhrase>.from(state.phrases);
    updatedPhrases[index] = updatedPhrase;
    // お気に入り順でソート (REQ-105)
    state = state.copyWith(phrases: _sortPhrases(updatedPhrases));

    // 【連動処理】: FavoriteNotifierへの連動（TC-SYNC-001, TC-SYNC-002）
    // 【処理方針】: お気に入り追加時はFavoriteにも追加、解除時はFavoriteからも削除
    // 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件に基づく
    if (_favoriteNotifier != null) {
      if (updatedPhrase.isFavorite) {
        // 【お気に入り追加】: Favoriteにも追加
        await _favoriteNotifier!.addFavoriteFromPresetPhrase(
          updatedPhrase.content,
          updatedPhrase.id,
        );
      } else {
        // 【お気に入り解除】: Favoriteからも削除
        await _favoriteNotifier!.deleteFavoriteBySourceId(updatedPhrase.id);
      }
    }
  }

  /// 【メソッド】: 定型文一覧を読み込む
  /// 【実装内容】: ローカルストレージから定型文を読み込み
  /// 🔵 信頼性レベル: 青信号 - CRUD-205に基づく
  Future<void> loadPhrases() async {
    // 現在はメモリ内での管理のみ
    // 将来的にはHiveからの読み込みを実装
    state = state.copyWith(isLoading: false);
  }

  /// 【メソッド】: 初期定型文データを投入する
  /// 【実装内容】: DefaultPhrasesから70個程度の定型文を読み込み、状態に追加
  /// 【テスト対応】: TASK-0042
  /// 🔵 信頼性レベル: 青信号 - REQ-107に基づく
  ///
  /// 初回起動時に呼び出され、デフォルトの定型文を投入する。
  /// 既に定型文が存在する場合は何もしない（重複投入防止）。
  Future<void> initializeDefaultPhrases() async {
    // 既にデータがある場合は何もしない
    if (state.phrases.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final allPhrases = DefaultPhrases.getAllPhrases();
      final now = DateTime.now();
      final phrases = <PresetPhrase>[];
      var displayOrder = 0;

      // カテゴリ順: daily -> health -> other
      for (final category in ['daily', 'health', 'other']) {
        final categoryPhrases = allPhrases[category] ?? [];
        for (final content in categoryPhrases) {
          phrases.add(PresetPhrase(
            id: _uuid.v4(),
            content: content,
            category: category,
            isFavorite: false,
            displayOrder: displayOrder++,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }

      state = state.copyWith(
        phrases: phrases,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '初期データの読み込みに失敗しました: $e',
      );
    }
  }

  /// 【メソッド】: 定型文データをリセットする
  /// 【実装内容】: 全定型文を削除し、初期データを再投入
  /// 🔵 信頼性レベル: 青信号 - REQ-107に基づく
  ///
  /// 設定画面等から呼び出され、定型文を初期状態に戻す。
  Future<void> resetToDefaults() async {
    state = state.copyWith(phrases: [], isLoading: true);
    await initializeDefaultPhrases();
  }

  /// 【プライベートメソッド】: 定型文をソートする
  /// 【実装内容】: お気に入りを上部に、それ以外は表示順で並べ替え
  /// 🔵 信頼性レベル: 青信号 - REQ-105に基づく
  List<PresetPhrase> _sortPhrases(List<PresetPhrase> phrases) {
    final sorted = List<PresetPhrase>.from(phrases);
    sorted.sort((a, b) {
      // まずお気に入りを優先
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      // 同じお気に入り状態なら表示順で並べ替え
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return sorted;
  }
}

/// 【Provider定義】: PresetPhraseNotifierのProvider
/// 【実装内容】: FavoriteNotifierを渡してお気に入り連動を有効化
/// 【テスト対応】: TC-SYNC-001, TC-SYNC-002（連動機能の依存関係）
/// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNCに基づく
final presetPhraseNotifierProvider =
    NotifierProvider<PresetPhraseNotifier, PresetPhraseState>(
  PresetPhraseNotifier.new,
);
