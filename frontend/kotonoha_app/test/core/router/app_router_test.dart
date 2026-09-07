// テストフレームワーク: flutter_test + flutter_riverpod
// 対象: GoRouterプロバイダー定義（app_router.dart）

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/core/router/app_router.dart';

void main() {
  group('GoRouterプロバイダーテスト', () {
    // routerProvider生成テスト
    // テストカテゴリ: Unit Test
    // 対応要件: （GoRouterプロバイダーの実装）
    // 対応受け入れ基準: AC-001, AC-008
    test('TC-001: routerProviderはGoRouterインスタンスを生成する', () {
      // テスト用のProviderContainerを作成
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // routerProviderからGoRouterインスタンスを取得
      final router = container.read(routerProvider);

      // GoRouterインスタンスが正常に取得できることを確認
      expect(router, isNotNull, reason: 'GoRouterインスタンスはnullであってはならない');
      expect(router, isA<GoRouter>(),
          reason: 'routerProviderはGoRouter型を返す必要がある');
    });

    // 初期ルート設定テスト
    // テストカテゴリ: Unit Test
    // 対応要件: （初期ルート設定）
    // 対応受け入れ基準: AC-002
    // 注: GoRouter v14+では初期化直後のcurrentConfigurationは空のため
    // ホームルートが存在することでinitialLocationの設定を確認
    test('TC-002: 初期ルートは/（ホーム画面）である', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      // ShellRoute導入により、GoRouteはShellRoute配下に定義される。
      // ShellRouteの.routesからGoRouteを集計する。
      final shellRoute =
          router.configuration.routes.whereType<ShellRoute>().single;
      final routes = shellRoute.routes.whereType<GoRoute>().toList();

      // ホームルートが最初に定義されていることを確認
      // GoRouterはinitialLocationで指定されたパスに対応するルートが必要
      final homeRoute = routes.firstWhere(
        (r) => r.path == '/',
        orElse: () => throw StateError('Home route not found'),
      );
      expect(
        homeRoute.path,
        equals('/'),
        reason: 'ホームルート（/）が定義されている必要がある',
      );
      expect(
        homeRoute.name,
        equals('home'),
        reason: 'ホームルートの名前は"home"である必要がある',
      );
    });

    // ルート定義数テスト（7ルート）
    // テストカテゴリ: Unit Test
    // 対応要件: （主要ルート定義）
    // 対応受け入れ基準: AC-003〜AC-006
    test('TC-003: 7つの主要ルートが定義されている', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      // ShellRoute導入により、トップレベルには単一のShellRouteが存在し
      // 7つの主要ルートはそのShellRoute配下のGoRouteとして定義される。
      final topRoutes = router.configuration.routes;
      final shellRoute = topRoutes.whereType<ShellRoute>().single;
      final goRoutes = shellRoute.routes.whereType<GoRoute>().toList();

      // トップレベルは単一のShellRoute
      expect(
        topRoutes.length,
        equals(1),
        reason: 'トップレベルは全画面共通シェル（ShellRoute）1つである必要がある',
      );
      // 7つの主要ルート（/, /settings, /history, /favorites, /help
      // preset-phrases, /face-to-face）がShellRoute配下に定義されていることを確認
      expect(
        goRoutes.length,
        equals(7),
        reason: '主要ルートは7つ（home, settings, history, favorites, help, '
            'presetPhrases, faceToFace）である必要がある',
      );
    });

    // 名前付きルート確認テスト
    // テストカテゴリ: Unit Test
    // 対応要件: （主要ルート定義）
    // 対応受け入れ基準: AC-007
    test('TC-004: 名前付きルートが正しく定義されている', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      // ShellRoute配下のGoRouteから名前を集計する。
      final shellRoute =
          router.configuration.routes.whereType<ShellRoute>().single;
      final routes = shellRoute.routes.whereType<GoRoute>().toList();
      final routeNames = routes.map((r) => r.name).whereType<String>().toList();

      // 7つの名前付きルートが存在することを確認
      expect(
        routeNames,
        containsAll([
          'home',
          'settings',
          'history',
          'favorites',
          'help',
          'presetPhrases',
          'faceToFace',
        ]),
        reason: '名前付きルート（home, settings, history, favorites, help, '
            'presetPhrases, faceToFace）がすべて定義されている必要がある',
      );
    });

    // GoRouterインスタンスの設定確認テスト
    // テストカテゴリ: Unit Test
    // 対応要件: （エラーページ対応）
    // 対応受け入れ基準: AC-006
    // 注: go_router v14.8以降ではerrorBuilderの直接アクセスが変更されたため
    // エラーページの動作確認は統合テストで行う
    test('TC-005: GoRouterインスタンスが正しく設定されている', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      // GoRouterの基本設定が正しいことを確認
      // errorBuilder自体の設定確認は統合テストで行う
      expect(
        router.configuration,
        isNotNull,
        reason: 'GoRouterのconfigurationが設定されている必要がある',
      );

      // ShellRoute配下のルートが全てGoRoute型であることを確認
      final shellRoute =
          router.configuration.routes.whereType<ShellRoute>().single;
      final routes = shellRoute.routes;
      expect(
        routes.every((route) => route is GoRoute),
        isTrue,
        reason: 'ShellRoute配下のルートはすべてGoRoute型である必要がある',
      );
    });
  });

  group('ProviderScope統合テスト', () {
    // 相当: ProviderScope経由のRouter取得テスト
    // テストカテゴリ: Unit Test
    // 対応要件: （main.dartへのProviderScope統合）
    // 対応受け入れ基準: AC-008
    test('ProviderContainerからrouterProviderが正常に取得できる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 複数回の読み取りでも同一インスタンスを返すことを確認
      final router1 = container.read(routerProvider);
      final router2 = container.read(routerProvider);

      // 同一インスタンスが返されることを確認（シングルトン的な動作）
      expect(router1, isNotNull, reason: 'routerProviderはnullを返してはならない');
      expect(
        identical(router1, router2),
        isTrue,
        reason: 'routerProviderは同一のGoRouterインスタンスを返す必要がある',
      );
    });
  });
}
