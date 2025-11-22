/// Application routing configuration using go_router
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/core/router/error_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
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
}

/// GoRouterプロバイダー
///
/// 実装要件:
/// - FR-001: Riverpod Providerを使用したプロバイダー定義
/// - FR-002: initialLocation: '/' でホーム画面を初期表示
/// - FR-003: 4つの主要ルート定義（home, settings, history, favorites）
/// - FR-004: errorBuilderでエラー画面を設定
/// - FR-006: MaterialApp.routerとの統合
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
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
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
