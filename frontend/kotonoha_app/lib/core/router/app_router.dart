/// Application routing configuration using go_router
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/core/router/error_screen.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/screens/face_to_face_screen.dart';
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/help/presentation/screens/help_screen.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';

/// アプリケーションのルートパス定義
///
/// 一元管理により、パス文字列のtypoを防止し、
/// リファクタリング時の変更箇所を最小化する。
abstract final class AppRoutes {
  /// ホーム画面（文字盤）
  static const String home = '/';

  /// 設定画面
  static const String settings = '/settings';

  /// 履歴画面
  static const String history = '/history';

  /// お気に入り画面
  static const String favorites = '/favorites';

  /// ヘルプ画面
  static const String help = '/help';

  /// 定型文画面
  static const String presetPhrases = '/preset-phrases';

  /// 対面表示モード画面
  static const String faceToFace = '/face-to-face';
}

/// GoRouterプロバイダー
///
/// 実装要件:
/// - FR-001: Riverpod Providerを使用したプロバイダー定義
/// - FR-002: initialLocation: '/' でホーム画面を初期表示
/// - FR-003: 4つの主要ルート定義（home, settings, history, favorites）
/// - FR-004: errorBuilderでエラー画面を設定
/// - FR-006: MaterialApp.routerとの統合
///
/// ## ShellRoute採用
///
/// 全6ルートを単一の [ShellRoute] で内包する。ShellRouteのbuilderは
/// [AppShell] を返し、全画面共通の横断的関心事（ネットワーク監視の起動・
/// 緊急機能の全画面配線）を一箇所で配線する。
/// ShellRouteのchildはShell配下のNavigatorに属するため、緊急ボタンの
/// 確認ダイアログ（Navigator.of(context)を使用）が正しく動作する。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.help,
            name: 'help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: AppRoutes.presetPhrases,
            name: 'presetPhrases',
            builder: (context, state) => const PresetPhraseScreen(),
          ),
          GoRoute(
            path: AppRoutes.faceToFace,
            name: 'faceToFace',
            // TASK-0052/0053: 対面表示モード。表示テキストは入力中テキスト/
            // 直近の読み上げテキストを呼び出し元（HomeScreen）からextra経由で渡す。
            builder: (context, state) => FaceToFaceScreen(
              displayText: (state.extra as String?) ?? '',
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
