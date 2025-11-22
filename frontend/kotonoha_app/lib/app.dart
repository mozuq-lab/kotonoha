/// Main application widget
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/router/app_router.dart';

/// アプリケーションのルートウィジェット
///
/// MaterialApp.routerを使用してGoRouterと統合する。
/// Riverpodを使用してルーターインスタンスを取得する。
///
/// 実装要件:
/// - FR-006: MaterialApp.routerとの統合
/// - FR-001: ConsumerWidgetでrouterProviderをwatch
class KotonohaApp extends ConsumerWidget {
  /// アプリケーションウィジェットを作成する。
  const KotonohaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'kotonoha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
