/// チュートリアル状態管理プロバイダー
/// 初回起動時の簡易チュートリアル表示
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';

/// チュートリアル状態
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
  /// shared_preferences にフラグを保存する。保存に失敗しても画面は先へ進め、
  /// 失敗は設定と同じ経路で利用者に伝える（ADR-005、台帳 L-104）。
  Future<void> completeTutorial() async {
    var succeeded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      succeeded = await prefs.setBool(_tutorialCompletedKey, true);
    } catch (_) {
      succeeded = false;
    }
    if (!ref.mounted) return;
    state = state.copyWith(isCompleted: true);
    ref
        .read(settingsWriteFailureProvider.notifier)
        .record(key: _tutorialCompletedKey, succeeded: succeeded);
  }

  /// チュートリアルをリセット
  /// ヘルプ画面の「もう一度見る」から呼ぶ。shared_preferences のフラグ削除に
  /// 失敗しても画面は前へ戻れるよう状態は戻す。削除の失敗は報告しない
  /// （フラグの削除失敗は利用者のデータの損失ではなく、次回起動でチュートリアルが
  /// 再表示されないだけ）。
  Future<void> resetTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tutorialCompletedKey);
    } catch (_) {
      // 失敗は報告しない（利用者のデータではない）
    }
    if (!ref.mounted) return;
    state = state.copyWith(isCompleted: false);
  }
}

/// チュートリアルプロバイダー
/// アプリ全体でチュートリアル状態を共有する。
final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(
  TutorialNotifier.new,
);
