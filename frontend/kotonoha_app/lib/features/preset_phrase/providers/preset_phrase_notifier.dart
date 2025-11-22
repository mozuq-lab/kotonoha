/// PresetPhraseNotifier - 定型文状態管理
///
/// TASK-0041: 定型文CRUD機能実装
/// TDD Refactorフェーズ: ドキュメント改善
///
/// 関連要件:
/// - REQ-104: 定型文の追加・編集・削除機能
/// - REQ-105: お気に入り定型文を一覧上部に優先表示
/// - CRUD-003: UUID形式の一意識別子を自動付与
/// - CRUD-007: お気に入りフラグを切り替える機能
/// - CRUD-008: createdAt/updatedAtタイムスタンプを自動設定
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// 【テスト対応】: TC-041-032〜TC-041-042
/// 🔵 信頼性レベル: 青信号 - REQ-104, REQ-105に基づく
///
/// 定型文のCRUD操作を提供するStateNotifier。
/// 追加、更新、削除、お気に入り切り替え機能を実装。
class PresetPhraseNotifier extends StateNotifier<PresetPhraseState> {
  PresetPhraseNotifier() : super(const PresetPhraseState());

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
  /// 【実装内容】: 指定IDの定型文を削除
  /// 【テスト対応】: TC-041-037
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  Future<void> deletePhrase(String id) async {
    // 対象の定型文を検索 (EDGE-010対応)
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      // 存在しないIDの場合は何もしない
      return;
    }

    final updatedPhrases = List<PresetPhrase>.from(state.phrases);
    updatedPhrases.removeAt(index);
    state = state.copyWith(phrases: updatedPhrases);
  }

  /// 【メソッド】: お気に入りを切り替える
  /// 【実装内容】: 指定IDの定型文のお気に入りフラグを反転
  /// 【テスト対応】: TC-041-038, TC-041-039, TC-041-040
  /// 🔵 信頼性レベル: 青信号 - CRUD-007, CRUD-106に基づく
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
  }

  /// 【メソッド】: 定型文一覧を読み込む
  /// 【実装内容】: ローカルストレージから定型文を読み込み
  /// 🔵 信頼性レベル: 青信号 - CRUD-205に基づく
  Future<void> loadPhrases() async {
    // 現在はメモリ内での管理のみ
    // 将来的にはHiveからの読み込みを実装
    state = state.copyWith(isLoading: false);
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
/// 🔵 信頼性レベル: 青信号 - Riverpodパターンに基づく
final presetPhraseNotifierProvider =
    StateNotifierProvider<PresetPhraseNotifier, PresetPhraseState>((ref) {
  return PresetPhraseNotifier();
});
