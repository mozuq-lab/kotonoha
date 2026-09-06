/// アプリセッション状態管理プロバイダー
///
/// TASK-0079: アプリ状態復元・クラッシュリカバリ実装
///
/// 信頼性レベル: 青信号（要件定義書ベース）
/// 関連要件:
/// - NFR-302: データ整合性の保持
/// - EDGE-201: バックグラウンド復帰時の状態復元
/// - REQ-5003: クラッシュ時のデータ保持
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 定数定義
// =============================================================================

/// SharedPreferencesのキー
class _SessionKeys {
  _SessionKeys._();

  /// 入力中のテキスト
  static const String draftText = 'draft_text';

  /// 最後に表示したルート
  static const String lastRoute = 'last_route';

  /// セッションタイムスタンプ
  static const String sessionTimestamp = 'session_timestamp';
}

// =============================================================================
// AppSessionState
// =============================================================================

/// アプリセッション状態
class AppSessionState {
  /// 入力中のテキスト
  final String draftText;

  /// 最後に表示したルート
  final String? lastRoute;

  /// 初期化完了フラグ
  final bool isInitialized;

  /// セッションタイムスタンプ
  final DateTime? sessionTimestamp;

  /// コンストラクタ
  const AppSessionState({
    this.draftText = '',
    this.lastRoute,
    this.isInitialized = false,
    this.sessionTimestamp,
  });

  /// コピーを作成
  AppSessionState copyWith({
    String? draftText,
    String? lastRoute,
    bool? isInitialized,
    DateTime? sessionTimestamp,
  }) {
    return AppSessionState(
      draftText: draftText ?? this.draftText,
      lastRoute: lastRoute ?? this.lastRoute,
      isInitialized: isInitialized ?? this.isInitialized,
      sessionTimestamp: sessionTimestamp ?? this.sessionTimestamp,
    );
  }

  /// 状態をクリアしたコピー
  AppSessionState cleared() {
    return const AppSessionState(isInitialized: true);
  }
}

// =============================================================================
// AppSessionNotifier
// =============================================================================

/// アプリセッション状態管理Notifier
///
/// バックグラウンド復帰時の状態復元、入力中テキストの保存、
/// クラッシュ時のデータ保持を管理する。
class AppSessionNotifier extends Notifier<AppSessionState> {
  /// 初期状態
  @override
  AppSessionState build() => const AppSessionState();

  /// 入力中のテキストを取得
  String get draftText => state.draftText;

  /// 最後に表示したルートを取得
  String? get lastRoute => state.lastRoute;

  /// 初期化
  ///
  /// EDGE-201: バックグラウンド復帰時の状態復元
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final draftText = prefs.getString(_SessionKeys.draftText) ?? '';
    final lastRoute = prefs.getString(_SessionKeys.lastRoute);
    final timestampStr = prefs.getString(_SessionKeys.sessionTimestamp);

    DateTime? sessionTimestamp;
    if (timestampStr != null) {
      sessionTimestamp =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
    }

    state = AppSessionState(
      draftText: draftText,
      lastRoute: lastRoute,
      isInitialized: true,
      sessionTimestamp: sessionTimestamp,
    );
  }

  /// 入力中のテキストを保存
  ///
  /// REQ-5003: クラッシュ時のデータ保持
  Future<void> saveDraftText(String text) async {
    state = state.copyWith(draftText: text);

    final prefs = await SharedPreferences.getInstance();
    if (text.isEmpty) {
      await prefs.remove(_SessionKeys.draftText);
    } else {
      await prefs.setString(_SessionKeys.draftText, text);
    }
  }

  /// 最後に表示したルートを保存
  ///
  /// EDGE-201: バックグラウンド復帰時の状態復元
  Future<void> saveLastRoute(String route) async {
    state = state.copyWith(lastRoute: route);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_SessionKeys.lastRoute, route);
  }

  /// アプリがバックグラウンドに移行した時の処理
  ///
  /// EDGE-201: バックグラウンド移行時の状態保存
  Future<void> onAppPaused() async {
    final prefs = await SharedPreferences.getInstance();

    // 現在の状態を永続化
    if (state.draftText.isNotEmpty) {
      await prefs.setString(_SessionKeys.draftText, state.draftText);
    }
    if (state.lastRoute != null) {
      await prefs.setString(_SessionKeys.lastRoute, state.lastRoute!);
    }

    // タイムスタンプを保存
    await prefs.setString(
      _SessionKeys.sessionTimestamp,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// アプリがフォアグラウンドに復帰した時の処理
  ///
  /// EDGE-201: バックグラウンド復帰時の状態復元
  Future<void> onAppResumed() async {
    // 状態を再読み込み
    await initialize();
  }

  /// セッション状態をクリア
  ///
  /// ログアウトやアプリリセット時に使用
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_SessionKeys.draftText);
    await prefs.remove(_SessionKeys.lastRoute);
    await prefs.remove(_SessionKeys.sessionTimestamp);

    state = state.cleared();
  }
}

// =============================================================================
// Provider定義
// =============================================================================

/// アプリセッション状態プロバイダー
final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionState>(
  AppSessionNotifier.new,
);
