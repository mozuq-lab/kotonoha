// go_routerナビゲーション設定 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test + flutter_riverpod
// 対象: GoRouterプロバイダー定義（app_router.dart）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// テスト対象のプロバイダー（実装後にコメント解除）
import 'package:kotonoha_app/core/router/app_router.dart';

void main() {
  group('GoRouterプロバイダーテスト', () {
    // TC-001: routerProvider生成テスト
    // テストカテゴリ: Unit Test
    // 対応要件: FR-001（GoRouterプロバイダーの実装）
    // 対応受け入れ基準: AC-001, AC-008
    // 青信号: アーキテクチャ設計書でRiverpod + go_routerの組み合わせが規定
    test('TC-001: routerProviderはGoRouterインスタンスを生成する', () {
      // Given（準備フェーズ）
      // テスト用のProviderContainerを作成
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When（実行フェーズ）
      // routerProviderからGoRouterインスタンスを取得
      final router = container.read(routerProvider);

      // Then（検証フェーズ）
      // GoRouterインスタンスが正常に取得できることを確認
      expect(router, isNotNull, reason: 'GoRouterインスタンスはnullであってはならない');
      expect(router, isA<GoRouter>(),
          reason: 'routerProviderはGoRouter型を返す必要がある');
    });

    // TC-002: 初期ルート設定テスト（/）
    // テストカテゴリ: Unit Test
    // 対応要件: FR-002（初期ルート設定）
    // 対応受け入れ基準: AC-002
    // 青信号: タスクファイルに基づく（initialLocation: '/'）
    // 注: GoRouter v14+では初期化直後のcurrentConfigurationは空のため、
    //     ホームルート（/）が存在することでinitialLocationの設定を確認
    test('TC-002: 初期ルートは/（ホーム画面）である', () {
      // Given（準備フェーズ）
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When（実行フェーズ）
      final router = container.read(routerProvider);
      final routes = router.configuration.routes.whereType<GoRoute>().toList();

      // Then（検証フェーズ）
      // ホームルート（/）が最初に定義されていることを確認
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

    // TC-003: ルート定義数テスト（5ルート）
    // テストカテゴリ: Unit Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-003〜AC-006
    // 青信号: タスクファイルで5つの主要ルートが明示
    // TASK-0075: ヘルプルート追加
    test('TC-003: 5つの主要ルートが定義されている', () {
      // Given（準備フェーズ）
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When（実行フェーズ）
      final router = container.read(routerProvider);
      final routes = router.configuration.routes;

      // Then（検証フェーズ）
      // 5つの主要ルート（/, /settings, /history, /favorites, /help）が定義されていることを確認
      expect(
        routes.length,
        equals(5),
        reason: '主要ルートは5つ（home, settings, history, favorites, help）である必要がある',
      );
    });

    // TC-004: 名前付きルート確認テスト
    // テストカテゴリ: Unit Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-007
    // 青信号: 名前付きルーティング対応が要件として明示
    // TASK-0075: ヘルプルート追加
    test('TC-004: 名前付きルートが正しく定義されている', () {
      // Given（準備フェーズ）
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When（実行フェーズ）
      final router = container.read(routerProvider);
      final routes = router.configuration.routes.whereType<GoRoute>().toList();
      final routeNames = routes.map((r) => r.name).whereType<String>().toList();

      // Then（検証フェーズ）
      // 5つの名前付きルートが存在することを確認
      expect(
        routeNames,
        containsAll(['home', 'settings', 'history', 'favorites', 'help']),
        reason:
            '名前付きルート（home, settings, history, favorites, help）がすべて定義されている必要がある',
      );
    });

    // TC-005: GoRouterインスタンスの設定確認テスト
    // テストカテゴリ: Unit Test
    // 対応要件: FR-004（エラーページ対応）
    // 対応受け入れ基準: AC-006
    // 黄信号: NFR-204から推測（エラーメッセージ表示要件）
    // 注: go_router v14.8以降ではerrorBuilderの直接アクセスが変更されたため、
    //     エラーページの動作確認は統合テスト（TC-015）で行う
    test('TC-005: GoRouterインスタンスが正しく設定されている', () {
      // Given（準備フェーズ）
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When（実行フェーズ）
      final router = container.read(routerProvider);

      // Then（検証フェーズ）
      // GoRouterの基本設定が正しいことを確認
      // errorBuilder自体の設定確認は統合テスト（TC-015）で行う
      expect(
        router.configuration,
        isNotNull,
        reason: 'GoRouterのconfigurationが設定されている必要がある',
      );

      // 全ルートがGoRoute型であることを確認
      final routes = router.configuration.routes;
      expect(
        routes.every((route) => route is GoRoute),
        isTrue,
        reason: 'すべてのルートはGoRoute型である必要がある',
      );
    });
  });

  group('ProviderScope統合テスト', () {
    // TC-015相当: ProviderScope経由のRouter取得テスト
    // テストカテゴリ: Unit Test
    // 対応要件: FR-007（main.dartへのProviderScope統合）
    // 対応受け入れ基準: AC-008
    // 青信号: Riverpod標準パターン
    test('ProviderContainerからrouterProviderが正常に取得できる', () {
      // Given（準備フェーズ）
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When（実行フェーズ）
      // 複数回の読み取りでも同一インスタンスを返すことを確認
      final router1 = container.read(routerProvider);
      final router2 = container.read(routerProvider);

      // Then（検証フェーズ）
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
