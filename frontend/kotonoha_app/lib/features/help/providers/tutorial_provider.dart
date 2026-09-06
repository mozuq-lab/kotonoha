/// チュートリアル状態管理プロバイダー
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
///
/// 信頼性レベル: 黄信号（REQ-3001から推測）
/// 関連要件:
/// - REQ-3001: 初回起動時の簡易チュートリアル表示
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// チュートリアル状態
///
/// チュートリアルの完了状態と表示フラグを管理する。
class TutorialState {
  /// チュートリアル完了フラグ
  final bool isCompleted;

  /// 読み込み中フラグ
  final bool isLoading;

  /// コンストラクタ
  const TutorialState({
    this.isCompleted = false,
    this.isLoading = true,
  });

  /// チュートリアルを表示すべきかどうか
  bool get shouldShowTutorial => !isCompleted && !isLoading;

  /// copyWith
  TutorialState copyWith({
    bool? isCompleted,
    bool? isLoading,
  }) {
    return TutorialState(
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// チュートリアル状態管理Notifier
class TutorialNotifier extends Notifier<TutorialState> {
  /// shared_preferencesキー
  static const String _tutorialCompletedKey = 'tutorial_completed';

  @override
  TutorialState build() => const TutorialState();

  /// 初期化
  ///
  /// shared_preferencesからチュートリアル完了フラグを読み込む。
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool(_tutorialCompletedKey) ?? false;

    state = state.copyWith(
      isCompleted: isCompleted,
      isLoading: false,
    );
  }

  /// チュートリアルを完了としてマーク
  ///
  /// shared_preferencesにフラグを保存する。
  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);

    state = state.copyWith(isCompleted: true);
  }

  /// チュートリアルをリセット（テスト用）
  ///
  /// shared_preferencesからフラグを削除する。
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);

    state = state.copyWith(isCompleted: false);
  }
}

/// チュートリアルプロバイダー
///
/// アプリ全体でチュートリアル状態を共有する。
final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(
  TutorialNotifier.new,
);
