/// テーマ適用 統合テスト
///
/// TASK-0073: テーマ切り替えUI・適用
/// テストケース: アプリ全体への反映テスト
///
/// テスト対象: テーマ設定がアプリ全体に正しく反映されること
///
/// 【TDD Redフェーズ】: HomeScreenでのテーマ反映を検証
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';

void main() {
  group('TASK-0073: テーマ適用 統合テスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // HomeScreen統合テスト
    // =========================================================================
    group('HomeScreen テーマ反映', () {
      /// TC-INT-THEME-001: ライトテーマでHomeScreenが正常表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803
      /// 検証内容: ライトテーマでHomeScreenが正常に表示されること
      testWidgets('TC-INT-THEME-001: ライトテーマでHomeScreenが正常表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: ライトテーマでHomeScreenが表示されることを確認 🔵
        // 🔵 青信号: REQ-803「ライトモード」

        // Given: 【テストデータ準備】: ライトテーマを設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(theme: AppTheme.light),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);

        container.dispose();
      });

      /// TC-INT-THEME-002: ダークテーマでHomeScreenが正常表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803
      /// 検証内容: ダークテーマでHomeScreenが正常に表示されること
      testWidgets('TC-INT-THEME-002: ダークテーマでHomeScreenが正常表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: ダークテーマでHomeScreenが表示されることを確認 🔵
        // 🔵 青信号: REQ-803「ダークモード」

        // Given: 【テストデータ準備】: ダークテーマを設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(theme: AppTheme.dark),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: darkTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);

        container.dispose();
      });

      /// TC-INT-THEME-003: 高コントラストテーマでHomeScreenが正常表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803, REQ-5006
      /// 検証内容: 高コントラストテーマでHomeScreenが正常に表示されること
      testWidgets('TC-INT-THEME-003: 高コントラストテーマでHomeScreenが正常表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 高コントラストテーマでHomeScreenが表示されることを確認 🔵
        // 🔵 青信号: REQ-803「高コントラストモード」、REQ-5006「WCAG準拠」

        // Given: 【テストデータ準備】: 高コントラストテーマを設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(theme: AppTheme.highContrast),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: highContrastTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);

        container.dispose();
      });

      /// TC-INT-THEME-004: currentThemeProviderと連携したテーマ表示
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2008
      /// 検証内容: currentThemeProviderの値に基づいてテーマが適用されること
      testWidgets('TC-INT-THEME-004: currentThemeProviderと連携したテーマ表示',
          (WidgetTester tester) async {
        // 【テスト目的】: Provider経由でテーマが正しく適用されることを確認 🔵
        // 🔵 青信号: REQ-2008「テーマ変更時に即座に変更」

        // Given: 【テストデータ準備】: ダークテーマを設定したProvider
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(theme: AppTheme.dark),
              ),
            ),
          ],
        );

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // currentThemeProviderがdarkThemeを返すことを確認
        final currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, darkTheme);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: currentTheme,
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);

        container.dispose();
      });

      /// TC-INT-THEME-005: デフォルトテーマ（ライト）でのHomeScreen表示
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803
      /// 検証内容: デフォルト設定でHomeScreenが正常に表示されること
      testWidgets('TC-INT-THEME-005: デフォルトテーマ（ライト）でのHomeScreen表示',
          (WidgetTester tester) async {
        // 【テスト目的】: デフォルト設定でHomeScreenが表示されることを確認 🔵
        // 🔵 青信号: REQ-803（デフォルトはライト）

        // Given: 【テストデータ準備】: デフォルト設定
        await tester.pumpWidget(
          ProviderScope(
            child: Builder(
              builder: (context) {
                return const MaterialApp(
                  home: HomeScreen(),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);
      });
    });

    // =========================================================================
    // テーマ切り替え動的テスト
    // =========================================================================
    group('テーマ切り替え動的テスト', () {
      /// TC-INT-THEME-006: 設定変更後のProvider状態更新
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2008
      /// 検証内容: 設定画面でテーマを変更すると、Provider状態が即座に更新される
      test('TC-INT-THEME-006: 設定変更後のProvider状態更新', () async {
        // 【テスト目的】: 設定変更がProvider状態に即座に反映されることを確認 🔵
        // 🔵 青信号: REQ-2008「テーマ変更時に即座に変更」

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // 初期状態確認（デフォルトはライト）
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);

        // currentThemeProviderも確認
        var currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, lightTheme);

        // When: 【実際の処理実行】: テーマを「ダーク」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 【結果検証】: Provider状態が即座に更新される
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        // currentThemeProviderも更新される
        currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, darkTheme);

        container.dispose();
      });
    });

    // =========================================================================
    // 高コントラストモード検証
    // =========================================================================
    group('高コントラストモード検証', () {
      /// TC-INT-THEME-007: 高コントラストテーマの背景色検証
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5006
      /// 検証内容: 高コントラストテーマの背景色が正しく設定されていること
      test('TC-INT-THEME-007: 高コントラストテーマの背景色検証', () {
        // 【テスト目的】: 高コントラストテーマの背景色が白であることを確認 🟡
        // 🟡 黄信号: REQ-5006「WCAG 2.1 AAレベル」

        // Given/When: 高コントラストテーマの背景色を取得
        final backgroundColor = highContrastTheme.scaffoldBackgroundColor;

        // Then: 背景色が白（#FFFFFF）であること
        expect(backgroundColor, AppColors.backgroundHighContrast);
        expect(backgroundColor, const Color(0xFFFFFFFF));
      });

      /// TC-INT-THEME-008: 高コントラストテーマのテキスト色検証
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5006
      /// 検証内容: 高コントラストテーマのテキスト色が正しく設定されていること
      test('TC-INT-THEME-008: 高コントラストテーマのテキスト色検証', () {
        // 【テスト目的】: 高コントラストテーマのテキスト色が黒であることを確認 🟡
        // 🟡 黄信号: REQ-5006「WCAG 2.1 AAレベル」

        // Given/When: 高コントラストテーマのテキスト色を取得
        final textColor = highContrastTheme.colorScheme.onSurface;

        // Then: テキスト色が黒（#000000）であること
        expect(textColor, AppColors.onSurfaceHighContrast);
        expect(textColor, const Color(0xFF000000));
      });

      /// TC-INT-THEME-009: 高コントラストテーマの境界線検証
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-5006
      /// 検証内容: 高コントラストテーマで要素の境界が明確であること
      test('TC-INT-THEME-009: 高コントラストテーマの境界線検証', () {
        // 【テスト目的】: 高コントラストテーマで境界線が2px以上であることを確認 🟡
        // 🟡 黄信号: REQ-5006「WCAG準拠」

        // Given/When: 高コントラストテーマのボタンスタイルを取得
        final buttonStyle = highContrastTheme.elevatedButtonTheme.style;
        final side = buttonStyle?.side?.resolve({});

        // Then: 境界線が2px以上であること
        expect(side?.width, greaterThanOrEqualTo(2.0));
        expect(side?.color, Colors.black);
      });
    });
  });
}

/// テスト用のFakeSettingsNotifier
///
/// ウィジェットテストで特定の状態を設定するために使用
class FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _settings;

  FakeSettingsNotifier(this._settings);

  @override
  Future<AppSettings> build() async {
    return _settings;
  }

  @override
  Future<void> setTheme(AppTheme theme) async {
    state = AsyncValue.data(_settings.copyWith(theme: theme));
  }
}
