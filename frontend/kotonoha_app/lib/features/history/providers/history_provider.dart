// 【Provider定義】: 履歴管理プロバイダー
// 【実装内容】: 履歴のCRUD操作、検索機能を提供
// 【設計根拠】: REQ-601, REQ-602, REQ-603, REQ-604（履歴機能）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
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
class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    // 【永続化配線】: Repositoryが利用可能（Boxオープン済み）の場合はHiveから初期化
    // 【フォールバック】: repo==nilの場合は従来どおりインメモリ空状態
    final repo = ref.read(historyRepositoryProvider);
    if (repo == null) return const HistoryState();
    return HistoryState(
      histories: repo.loadAllSortedSync().map(_toDomain).toList(),
    );
  }

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

  /// 【変換ヘルパー】: Hiveモデル HistoryItem → ドメイン History
  History _toDomain(HistoryItem item) => History(
        id: item.id,
        content: item.content,
        createdAt: item.createdAt,
        type: HistoryType.values.byName(item.type),
      );

  /// 【変換ヘルパー】: ドメイン History → Hiveモデル HistoryItem
  HistoryItem _toItem(History h) => HistoryItem(
        id: h.id,
        content: h.content,
        createdAt: h.createdAt,
        type: h.type.name,
        isFavorite: false,
      );

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

    final repo = ref.read(historyRepositoryProvider);
    if (repo != null) {
      // 【永続化】: 保存後、Hiveから再読込（50件上限の自動削除を反映）
      await repo.save(_toItem(newHistory));
      state = state.copyWith(
        histories: repo.loadAllSortedSync().map(_toDomain).toList(),
      );
      return;
    }

    // 【フォールバック】: 新しい履歴を先頭に追加（新しい順）
    final updatedHistories = [newHistory, ...state.histories];
    state = state.copyWith(histories: updatedHistories);
  }

  /// 【メソッド定義】: 履歴を削除する
  /// 【実装内容】: 指定IDの履歴を削除
  /// 🔵 信頼性レベル: 青信号 - REQ-603（履歴の削除）
  Future<void> deleteHistory(String id) async {
    final repo = ref.read(historyRepositoryProvider);
    if (repo != null) {
      // 【永続化】: Hiveから削除後、再読込
      await repo.delete(id);
      state = state.copyWith(
        histories: repo.loadAllSortedSync().map(_toDomain).toList(),
      );
      return;
    }

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

    return state.histories.where((h) => h.content.contains(query)).toList();
  }

  /// 【メソッド定義】: 履歴を読み込む
  /// 【実装内容】: ローカルストレージから履歴を読み込み
  /// 🟡 信頼性レベル: 黄信号 - 将来的にHiveから読み込み
  Future<void> loadHistories() async {
    final repo = ref.read(historyRepositoryProvider);
    if (repo != null) {
      // 【永続化】: Hiveから履歴を読み込み
      state = state.copyWith(
        histories: repo.loadAllSortedSync().map(_toDomain).toList(),
        isLoading: false,
      );
      return;
    }
    // 【フォールバック】: インメモリ管理のみ
    state = state.copyWith(isLoading: false);
  }

  /// 【メソッド定義】: 全履歴をクリアする
  /// 【実装内容】: 全ての履歴を削除
  /// 🔵 信頼性レベル: 青信号 - REQ-603（履歴の削除）
  Future<void> clearAllHistories() async {
    final repo = ref.read(historyRepositoryProvider);
    if (repo != null) {
      // 【永続化】: Hiveの全履歴を削除
      await repo.deleteAll();
    }
    state = state.copyWith(histories: []);
  }
}

/// 【Provider定義】: HistoryNotifierのProvider
/// 🔵 信頼性レベル: 青信号 - Riverpodパターンに基づく
final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);
