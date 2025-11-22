/// メインアプリケーションウィジェット
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// アプリケーションのエントリーポイントとなるウィジェット。
/// - GoRouterによるルーティング
/// - テーマプロバイダーによる動的テーマ切り替え
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';

/// アプリケーションのルートウィジェット
///
/// MaterialApp.routerを使用してGoRouterと統合し、
/// テーマプロバイダーと連携してユーザー設定に応じた
/// テーマを適用する。
///
/// 実装要件:
/// - FR-006: MaterialApp.routerとの統合
/// - FR-001: ConsumerWidgetでrouterProviderをwatch
/// - REQ-803: テーマ設定（ライト・ダーク・高コントラスト）
class KotonohaApp extends ConsumerWidget {
  /// アプリケーションウィジェットを作成する。
  const KotonohaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(currentThemeProvider);

    return MaterialApp.router(
      title: 'kotonoha',
      theme: theme,
      routerConfig: router,
    );
  }
}
