// ナビゲーション統合 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test + flutter_riverpod + go_router
// 対象: 画面遷移フロー統合テスト
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// テスト対象のプロバイダーとウィジェット
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/core/router/error_screen.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';

void main() {
  group('ナビゲーション統合テスト', () {
    // テスト用のProviderContainerを保持
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      // settingsNotifierProviderをモックでオーバーライドして
      // CircularProgressIndicator（無限アニメーション）を回避
      container = ProviderContainer(
        overrides: [
          settingsNotifierProvider.overrideWith(() => _MockSettingsNotifier()),
        ],
      );
      router = container.read(routerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    // テスト用のアプリウィジェットをビルドするヘルパー関数
    Widget buildTestApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    // TC-011: /から/settingsへのナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-003
    // 青信号: タスクファイルで設定画面ルート（/settings）が明示
    testWidgets('TC-011: /から/settingsへナビゲートできる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 初期画面がホーム画面であることを確認（文字盤UIの存在で検証）
      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: '初期表示はホーム画面である必要がある',
      );

      // When（実行フェーズ）
      // /settingsへナビゲート
      router.go('/settings');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      // Note: SettingsScreenは実装済みで、TTSSpeedSettingsWidgetを含むため
      // プレースホルダー「設定画面」ではなく、実際のコンテンツ「読み上げ速度」を確認
      expect(
        find.text('読み上げ速度'),
        findsOneWidget,
        reason: '/settingsへのナビゲーション後、設定画面が表示される必要がある',
      );
    });

    // TC-012: /settingsから/へ戻るナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-003
    // 青信号: ホーム画面への復帰は基本機能
    testWidgets('TC-012: /settingsから/へ戻れる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 設定画面へ遷移
      router.go('/settings');
      await tester.pumpAndSettle();

      expect(
        find.text('読み上げ速度'),
        findsOneWidget,
        reason: '設定画面に遷移済みである必要がある',
      );

      // When（実行フェーズ）
      // ホーム画面へ戻る
      router.go('/');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: '/への遷移後、ホーム画面が表示される必要がある',
      );
    });

    // TC-013: /から/historyへのナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-004
    // 青信号: タスクファイルで履歴画面ルート（/history）が明示
    testWidgets('TC-013: /から/historyへナビゲートできる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: '初期表示はホーム画面である必要がある',
      );

      // When（実行フェーズ）
      router.go('/history');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      expect(
        find.text('履歴画面'),
        findsOneWidget,
        reason: '/historyへのナビゲーション後、履歴画面が表示される必要がある',
      );
    });

    // TC-014: /から/favoritesへのナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-005
    // 青信号: タスクファイルでお気に入り画面ルート（/favorites）が明示
    testWidgets('TC-014: /から/favoritesへナビゲートできる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: '初期表示はホーム画面である必要がある',
      );

      // When（実行フェーズ）
      router.go('/favorites');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      expect(
        find.text('お気に入り画面'),
        findsOneWidget,
        reason: '/favoritesへのナビゲーション後、お気に入り画面が表示される必要がある',
      );
    });

    // TC-015: 不正パスアクセス時のエラー画面表示
    // テストカテゴリ: Integration Test
    // 対応要件: FR-004（エラーページ対応）
    // 対応受け入れ基準: AC-006
    // 黄信号: NFR-204から推測（エラーメッセージ表示、復旧方法提示）
    testWidgets('TC-015: 不正パスでErrorScreenが表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // When（実行フェーズ）
      // 存在しないルートへナビゲート
      router.go('/unknown');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      // ErrorScreenが表示されることを確認
      expect(
        find.byType(ErrorScreen),
        findsOneWidget,
        reason: '存在しないルートへのアクセス時にErrorScreenが表示される必要がある',
      );

      // エラーメッセージが表示されることを確認
      expect(
        find.textContaining('エラー'),
        findsWidgets,
        reason: 'ErrorScreenにはエラーメッセージが表示される必要がある',
      );

      // ホームへの復帰ボタンが表示されることを確認
      expect(
        find.text('ホームに戻る'),
        findsOneWidget,
        reason: 'ErrorScreenにはホームへの復帰ボタンが必要（NFR-204準拠）',
      );
    });
  });

  group('名前付きルーティングテスト', () {
    // テスト用のProviderContainerを保持
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      // settingsNotifierProviderをモックでオーバーライドして
      // CircularProgressIndicator（無限アニメーション）を回避
      container = ProviderContainer(
        overrides: [
          settingsNotifierProvider.overrideWith(() => _MockSettingsNotifier()),
        ],
      );
      router = container.read(routerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    // テスト用のアプリウィジェットをビルドするヘルパー関数
    Widget buildTestApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    // TC-011a: goNamed('settings')でのナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-007
    // 青信号: 名前付きルーティング対応が要件として明示
    testWidgets('goNamed("settings")で設定画面へナビゲートできる',
        (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // When（実行フェーズ）
      router.goNamed('settings');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      // Note: SettingsScreenは実装済みで「読み上げ速度」ラベルを含む
      expect(
        find.text('読み上げ速度'),
        findsOneWidget,
        reason: 'goNamed("settings")で設定画面へ遷移できる必要がある',
      );
    });

    // TC-013a: goNamed('history')でのナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-007
    // 青信号: 名前付きルーティング対応が要件として明示
    testWidgets('goNamed("history")で履歴画面へナビゲートできる',
        (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // When（実行フェーズ）
      router.goNamed('history');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      expect(
        find.text('履歴画面'),
        findsOneWidget,
        reason: 'goNamed("history")で履歴画面へ遷移できる必要がある',
      );
    });

    // TC-014a: goNamed('favorites')でのナビゲーション
    // テストカテゴリ: Integration Test
    // 対応要件: FR-003（主要ルート定義）
    // 対応受け入れ基準: AC-007
    // 青信号: 名前付きルーティング対応が要件として明示
    testWidgets('goNamed("favorites")でお気に入り画面へナビゲートできる',
        (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // When（実行フェーズ）
      router.goNamed('favorites');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      expect(
        find.text('お気に入り画面'),
        findsOneWidget,
        reason: 'goNamed("favorites")でお気に入り画面へ遷移できる必要がある',
      );
    });

    // goNamed('home')でホーム画面へナビゲートできることを確認
    // 青信号: 名前付きルーティング対応が要件として明示
    testWidgets('goNamed("home")でホーム画面へナビゲートできる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 設定画面へ遷移
      router.go('/settings');
      await tester.pumpAndSettle();

      expect(find.text('読み上げ速度'), findsOneWidget);

      // When（実行フェーズ）
      router.goNamed('home');
      await tester.pumpAndSettle();

      // Then（検証フェーズ）
      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: 'goNamed("home")でホーム画面へ遷移できる必要がある',
      );
    });
  });

  group('連続ナビゲーションテスト', () {
    // テスト用のProviderContainerを保持
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      // settingsNotifierProviderをモックでオーバーライドして
      // CircularProgressIndicator（無限アニメーション）を回避
      container = ProviderContainer(
        overrides: [
          settingsNotifierProvider.overrideWith(() => _MockSettingsNotifier()),
        ],
      );
      router = container.read(routerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    // テスト用のアプリウィジェットをビルドするヘルパー関数
    Widget buildTestApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    // 複数画面の連続遷移テスト
    // 黄信号: NFR-201から推測（主要操作を3タップ以内で完了）
    testWidgets('複数画面を連続でナビゲートできる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // When/Then（実行・検証フェーズ）
      // ホーム -> 設定
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('読み上げ速度'), findsOneWidget);

      // 設定 -> 履歴
      router.go('/history');
      await tester.pumpAndSettle();
      expect(find.text('履歴画面'), findsOneWidget);

      // 履歴 -> お気に入り
      router.go('/favorites');
      await tester.pumpAndSettle();
      expect(find.text('お気に入り画面'), findsOneWidget);

      // お気に入り -> ホーム
      router.go('/');
      await tester.pumpAndSettle();
      expect(
        find.text('入力してください...'),
        findsOneWidget,
        reason: '連続ナビゲーション後も正常にホーム画面へ戻れる必要がある',
      );
    });
  });
}

/// テスト用のモックSettingsNotifier
///
/// ローディング状態を回避するため、build()で即座にデフォルト設定を返す。
/// これにより、SettingsScreenのTTSSpeedSettingsWidgetで
/// CircularProgressIndicator（無限アニメーション）が表示されず、
/// pumpAndSettle()がタイムアウトしなくなる。
class _MockSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    // 即座にデフォルト設定を返す（SharedPreferencesの初期化をスキップ）
    return const AppSettings();
  }
}
