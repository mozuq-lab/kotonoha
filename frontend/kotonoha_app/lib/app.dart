/// メインアプリケーションウィジェット
/// アプリケーションのエントリーポイントとなるウィジェット。
/// GoRouterによるルーティング
/// テーマプロバイダーによる動的テーマ切り替え
/// AppLifecycleObserverによるバックグラウンド移行時の入力ドラフト保存・復元
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/app_state/providers/app_lifecycle_observer.dart';

/// アプリケーションのルートウィジェット
/// MaterialApp.routerを使用してGoRouterと統合し
/// テーマプロバイダーと連携してユーザー設定に応じた
/// テーマを適用する。
/// AppLifecycleObserverの配線: MaterialApp.routerの`builder`で
/// ナビゲーター全体を[AppLifecycleObserver]でラップする。これにより
/// 個々の画面（home_screen.dart等）を変更することなく、アプリ全体で
/// バックグラウンド移行/復帰時のセッション状態・入力ドラフトの
/// 保存/復元が有効になる。
/// 実装要件
/// MaterialApp.routerとの統合
/// ConsumerWidgetでrouterProviderをwatch
/// テーマ設定（ライト・ダーク・高コントラスト）
/// アプリ状態復元・クラッシュリカバリ
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
      // アプリの言語は端末の言語に依らず日本語（文言はすべて日本語）。
      // Flutter はこの言語を OS に伝え（`setApplicationLocale`）、iOS の VoiceOver は
      // それを読み上げの言語に使う。渡さないと既定の英語になり、日本語のボタン名を
      // 英語の声で読んでいた（物理 iPad、2026-10-17）。
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) {
        return AppLifecycleObserver(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
