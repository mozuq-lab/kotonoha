/// テーマ適用 統合テスト
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

    // HomeScreen統合テスト
    group('HomeScreen テーマ反映', () {
      /// ライトテーマでHomeScreenが正常表示される
      testWidgets('TC-INT-THEME-001: ライトテーマでHomeScreenが正常表示される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ライトテーマを設定
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

        // Then: 結果検証: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);

        container.dispose();
      });

      /// ダークテーマでHomeScreenが正常表示される
      testWidgets('TC-INT-THEME-002: ダークテーマでHomeScreenが正常表示される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ダークテーマを設定
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

        // Then: 結果検証: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);

        container.dispose();
      });

      /// 高コントラストテーマでHomeScreenが正常表示される
      testWidgets('TC-INT-THEME-003: 高コントラストテーマでHomeScreenが正常表示される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 高コントラストテーマを設定
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

        // Then: 結果検証: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);

        container.dispose();
      });

      /// currentThemeProviderと連携したテーマ表示
      testWidgets('TC-INT-THEME-004: currentThemeProviderと連携したテーマ表示',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ダークテーマを設定したProvider
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

        // Then: 結果検証: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);

        container.dispose();
      });

      /// デフォルトテーマ（ライト）でのHomeScreen表示
      testWidgets('TC-INT-THEME-005: デフォルトテーマ（ライト）でのHomeScreen表示',
          (WidgetTester tester) async {
        // Given: テストデータ準備: デフォルト設定
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

        // Then: 結果検証: HomeScreenが表示されている
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('kotonoha'), findsOneWidget);
      });
    });

    // テーマ切り替え動的テスト
    group('テーマ切り替え動的テスト', () {
      /// 設定変更後のProvider状態更新
      test('TC-INT-THEME-006: 設定変更後のProvider状態更新', () async {
        // Given: テストデータ準備: ProviderContainer作成
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

        // When: 実際の処理実行: テーマを「ダーク」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 結果検証: Provider状態が即座に更新される
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        // currentThemeProviderも更新される
        currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, darkTheme);

        container.dispose();
      });
    });

    // 高コントラストモード検証
    group('高コントラストモード検証', () {
      /// 高コントラストテーマの背景色検証
      test('TC-INT-THEME-007: 高コントラストテーマの背景色検証', () {
        // Given/When: 高コントラストテーマの背景色を取得
        final backgroundColor = highContrastTheme.scaffoldBackgroundColor;

        // Then: 背景色が白（#FFFFFF）であること
        expect(backgroundColor, AppColors.backgroundHighContrast);
        expect(backgroundColor, const Color(0xFFFFFFFF));
      });

      /// 高コントラストテーマのテキスト色検証
      test('TC-INT-THEME-008: 高コントラストテーマのテキスト色検証', () {
        // Given/When: 高コントラストテーマのテキスト色を取得
        final textColor = highContrastTheme.colorScheme.onSurface;

        // Then: テキスト色が黒（#000000）であること
        expect(textColor, AppColors.onSurfaceHighContrast);
        expect(textColor, const Color(0xFF000000));
      });

      /// 高コントラストテーマの境界線検証
      test('TC-INT-THEME-009: 高コントラストテーマの境界線検証', () {
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
