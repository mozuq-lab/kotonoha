// 【Provider定義】: 履歴管理プロバイダー
// 【実装内容】: 履歴のCRUD操作、検索機能を提供
// 【設計根拠】: REQ-601, REQ-602, REQ-603, REQ-604（履歴機能）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/history.dart';
import '../domain/models/history_type.dart';

/// 【状態クラス定義】: 履歴一覧の状態
/// 🔵 信頼性レベル: 青信号 - Riverpod標準パターン
class HistoryState {
  /// 履歴一覧
  final List<History> histories;

  /// ローディング状態
  final bool isLoading;

  /// エラーメッセージ
  final String? error;

  const HistoryState({
    this.histories = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<History>? histories,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      histories: histories ?? this.histories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 【Notifier定義】: 履歴状態管理Notifier
/// 【実装内容】: 履歴のCRUD操作を提供
/// 🔵 信頼性レベル: 青信号 - REQ-601〜604に基づく
class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState());

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

  /// 【メソッド定義】: 履歴を追加する
  /// 【実装内容】: テキストと種類を受け取り、新しい履歴を追加
  /// 🔵 信頼性レベル: 青信号 - REQ-601（履歴の自動保存）
  Future<void> addHistory(String content, HistoryType type) async {
    // 空文字は追加しない
    if (content.isEmpty) return;

    final now = DateTime.now();
    final newHistory = History(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      type: type,
    );

    // 新しい履歴を先頭に追加（新しい順）
    final updatedHistories = [newHistory, ...state.histories];
    state = state.copyWith(histories: updatedHistories);
  }

  /// 【メソッド定義】: 履歴を削除する
  /// 【実装内容】: 指定IDの履歴を削除
  /// 🔵 信頼性レベル: 青信号 - REQ-603（履歴の削除）
  Future<void> deleteHistory(String id) async {
    final index = state.histories.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final updatedHistories = List<History>.from(state.histories);
    updatedHistories.removeAt(index);
    state = state.copyWith(histories: updatedHistories);
  }

  /// 【メソッド定義】: 履歴を検索する
  /// 【実装内容】: キーワードを含む履歴を返す
  /// 🔵 信頼性レベル: 青信号 - REQ-604（履歴の検索）
  List<History> searchHistory(String query) {
    if (query.isEmpty) return state.histories;

    return state.histories
        .where((h) => h.content.contains(query))
        .toList();
  }

  /// 【メソッド定義】: 履歴を読み込む
  /// 【実装内容】: ローカルストレージから履歴を読み込み
  /// 🟡 信頼性レベル: 黄信号 - 将来的にHiveから読み込み
  Future<void> loadHistories() async {
    // 現在はメモリ内での管理のみ
    // 将来的にはHiveからの読み込みを実装（TASK-0059で対応）
    state = state.copyWith(isLoading: false);
  }

  /// 【メソッド定義】: 全履歴をクリアする
  /// 【実装内容】: 全ての履歴を削除
  /// 🔵 信頼性レベル: 青信号 - REQ-603（履歴の削除）
  Future<void> clearAllHistories() async {
    state = state.copyWith(histories: []);
  }
}

/// 【Provider定義】: HistoryNotifierのProvider
/// 🔵 信頼性レベル: 青信号 - Riverpodパターンに基づく
final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
