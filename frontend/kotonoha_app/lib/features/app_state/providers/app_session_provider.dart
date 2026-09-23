/// アプリセッション状態管理プロバイダー
/// データ整合性の保持
/// バックグラウンド復帰時の状態復元
/// クラッシュ時のデータ保持
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';

// 定数定義

/// SharedPreferencesのキー
class _SessionKeys {
  _SessionKeys._();

  /// 入力中のテキスト
  static const String draftText = draftTextWriteKey;

  /// 最後に表示したルート
  static const String lastRoute = 'last_route';

  /// セッションタイムスタンプ
  static const String sessionTimestamp = 'session_timestamp';

  /// 消した機能（定型文フォームの下書き）が使っていたキー。読み書きはしない
  static const String retiredPhraseDrafts = 'preset_phrase_drafts';
}

// AppSessionState

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

// AppSessionNotifier

/// アプリセッション状態管理Notifier
/// バックグラウンド復帰時の状態復元、入力中テキストの保存
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
  /// バックグラウンド復帰時の状態復元
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
  /// クラッシュ時のデータ保持。失敗は利用者に報告する（NFR-302、台帳 L-104）。
  Future<void> saveDraftText(String text) async {
    state = state.copyWith(draftText: text);
    await _persist(
      _SessionKeys.draftText,
      (prefs) => text.isEmpty
          ? prefs.remove(_SessionKeys.draftText)
          : prefs.setString(_SessionKeys.draftText, text),
    );
  }

  /// 最後に表示したルートを保存（セッションの記録。失敗は報告しない）
  Future<void> saveLastRoute(String route) async {
    state = state.copyWith(lastRoute: route);
    await _persist(
      _SessionKeys.lastRoute,
      (prefs) => prefs.setString(_SessionKeys.lastRoute, route),
      report: false,
    );
  }

  /// アプリがバックグラウンドに移行した時の処理
  Future<void> onAppPaused() async {
    if (state.draftText.isNotEmpty) {
      await _persist(
        _SessionKeys.draftText,
        (prefs) => prefs.setString(_SessionKeys.draftText, state.draftText),
      );
    }
    final lastRoute = state.lastRoute;
    if (lastRoute != null) {
      await _persist(
        _SessionKeys.lastRoute,
        (prefs) => prefs.setString(_SessionKeys.lastRoute, lastRoute),
        report: false,
      );
    }
    await _persist(
      _SessionKeys.sessionTimestamp,
      (prefs) => prefs.setString(
        _SessionKeys.sessionTimestamp,
        DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      report: false,
    );
  }

  /// SharedPreferences への書き込みを行い、成否を報告する
  /// [report] が false のキーは、失敗しても未処理エラーにしないだけで報告しない
  /// （セッションの記録であって利用者のデータではない）。
  Future<void> _persist(
    String key,
    Future<bool> Function(SharedPreferences prefs) write, {
    bool report = true,
  }) async {
    var succeeded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      succeeded = await write(prefs);
    } catch (_) {
      succeeded = false;
    }
    if (!report || !ref.mounted) return;
    ref
        .read(settingsWriteFailureProvider.notifier)
        .record(key: key, succeeded: succeeded);
  }

  /// 消した機能のデータを端末から消す（起動時に 1 回）
  /// 定型文フォームの下書きは要件から外して機能ごと消した（NFR-302 は文字盤の
  /// 入力中の文だけ）。公開文からも記述を消したので、それ以前に使った端末に
  /// 残すと公開文と食い違う。失敗しても利用者のデータは失われないので告げず、
  /// 次の起動でまた消す。
  Future<void> removeRetiredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_SessionKeys.retiredPhraseDrafts);
    } catch (_) {}
  }

  /// アプリがフォアグラウンドに復帰した時の処理
  /// バックグラウンド復帰時の状態復元
  Future<void> onAppResumed() async {
    // 状態を再読み込み
    await initialize();
  }

  /// セッション状態をクリア
  /// ログアウトやアプリリセット時に使用
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_SessionKeys.draftText);
    await prefs.remove(_SessionKeys.lastRoute);
    await prefs.remove(_SessionKeys.sessionTimestamp);

    state = state.cleared();
  }
}

// Provider定義

/// アプリセッション状態プロバイダー
final appSessionProvider =
    NotifierProvider<AppSessionNotifier, AppSessionState>(
  AppSessionNotifier.new,
);
