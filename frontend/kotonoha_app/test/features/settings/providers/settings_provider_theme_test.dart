/// テーマ設定 Providerテスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';

import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';

import '../../../support/contrast_helpers.dart';

void main() {
  group('TASK-0073: テーマ設定 Providerテスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // 正常系テストケース（基本動作）
    group('正常系テストケース', () {
      /// テーマ「ライト」の選択と適用
      test('TC-073-002: テーマ「ライト」の選択と適用', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: テーマを「ライト」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.light);

        // Then: 結果検証: テーマがlightに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);

        container.dispose();
      });

      /// テーマ「ダーク」の選択と適用
      test('TC-073-003: テーマ「ダーク」の選択と適用', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: テーマを「ダーク」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 結果検証: テーマがdarkに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        container.dispose();
      });

      /// テーマ「高コントラスト」の選択と適用
      test('TC-073-004: テーマ「高コントラスト」の選択と適用', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 実際の処理実行: テーマを「高コントラスト」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.highContrast);

        // Then: 結果検証: テーマがhighContrastに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.highContrast);

        container.dispose();
      });

      /// テーマ変更が即座に反映される
      test('TC-073-005: テーマ変更が即座に反映される', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // 初期状態確認（デフォルトはライト）
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);

        // When: 実際の処理実行: テーマを「ダーク」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 結果検証: 即座に状態が更新されている
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        container.dispose();
      });

      /// アプリ再起動後のテーマ設定復元
      test('TC-073-006: アプリ再起動後のテーマ設定復元', () async {
        // Given: テストデータ準備: SharedPreferencesにダークテーマを保存
        // 後方互換性: 旧形式（enum index int）で保存されたデータでも
        // 正しく復元できることを検証する（マイグレーション対応）
        SharedPreferences.setMockInitialValues({
          'theme': AppTheme.dark.index,
        });

        // When: 実際の処理実行: Provider初期化（再起動をシミュレート）
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: ダークテーマが復元されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        container.dispose();
      });

      /// currentThemeProviderがテーマ変更に追従する
      test('TC-073-007: currentThemeProviderがテーマ変更に追従する', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // 初期状態: ライトテーマ
        var currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, lightTheme);

        // When: 実際の処理実行: テーマを「ダーク」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 結果検証: currentThemeProviderがdarkThemeを返す
        currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, darkTheme);

        // When: テーマを「高コントラスト」に変更
        await notifier.setTheme(AppTheme.highContrast);

        // Then: currentThemeProviderがhighContrastThemeを返す
        currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, highContrastTheme);

        container.dispose();
      });
    });

    // 異常系テストケース（エラーハンドリング）
    group('異常系テストケース', () {
      /// 設定読み込み中のデフォルトテーマ使用
      test('TC-073-009: 設定読み込み中のデフォルトテーマ使用', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();

        // When: 実際の処理実行: ローディング中の状態を確認
        // ローディング状態の場合、currentThemeProviderはデフォルト（ライト）を返す
        final currentTheme = container.read(currentThemeProvider);

        // Then: 結果検証: デフォルトテーマ（ライト）が返される
        expect(currentTheme, lightTheme);

        container.dispose();
      });

      /// 不正な保存値のフォールバック
      test('TC-073-010: 不正な保存値のフォールバック', () async {
        // Given: テストデータ準備: 範囲外のindex値をSharedPreferencesに保存
        SharedPreferences.setMockInitialValues({
          'theme': 99, // 範囲外（AppTheme enum は 0-2）
        });

        // When: 実際の処理実行: Provider初期化
        final container = ProviderContainer();

        // Then: 結果検証: エラーにならず、デフォルト値（ライト）が使用される
        // RangeErrorが発生する可能性があるため、try-catchで確認
        try {
          await container.read(settingsNotifierProvider.future);
          final state = container.read(settingsNotifierProvider);
          // 不正値の場合はデフォルト値が使用されるべき
          expect(state.requireValue.theme, AppTheme.light);
        } catch (e) {
          // RangeErrorが発生した場合はテスト失敗
          fail('不正値でアプリがクラッシュしました: $e');
        }

        container.dispose();
      });
    });

    // 境界値テストケース
    group('境界値テストケース', () {
      /// AppTheme enum の最小値（light = 0）
      test('TC-073-011: AppTheme enum の最小値（light = 0）', () async {
        // Given: テストデータ準備: SharedPreferencesにindex=0を保存
        SharedPreferences.setMockInitialValues({
          'theme': 0, // AppTheme.light.index
        });

        // When: 実際の処理実行: Provider初期化
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: ライトテーマが正しく復元される
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);
        expect(AppTheme.light.index, 0);

        container.dispose();
      });

      /// AppTheme enum の最大値（highContrast = 2）
      test('TC-073-012: AppTheme enum の最大値（highContrast = 2）', () async {
        // Given: テストデータ準備: SharedPreferencesにindex=2を保存
        SharedPreferences.setMockInitialValues({
          'theme': 2, // AppTheme.highContrast.index
        });

        // When: 実際の処理実行: Provider初期化
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: 高コントラストテーマが正しく復元される
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.highContrast);
        expect(AppTheme.highContrast.index, 2);

        container.dispose();
      });

      /// 高コントラストモードのコントラスト比検証
      test('TC-073-013: 高コントラストモードのコントラスト比検証', () {
        // Given: テストデータ準備: 高コントラストモードの色定義
        const backgroundColor = AppColors.backgroundHighContrast; // #FFFFFF
        const textColor = AppColors.onBackgroundHighContrast; // #000000

        // When: 実際の処理実行: コントラスト比を計算
        // コントラスト比の計算式: (L1 + 0.05) / (L2 + 0.05)
        // L1 = 白 (1.0), L2 = 黒 (0.0)
        // 白と黒のコントラスト比は 21:1
        final ratio = contrastRatio(backgroundColor, textColor);

        // Then: 結果検証: コントラスト比が4.5:1以上であること
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '高コントラストモードはWCAG 2.1 AAレベル（4.5:1以上）を満たす必要があります',
        );

        // 追加検証: 実際には21:1（最大コントラスト）
        expect(
          ratio,
          greaterThanOrEqualTo(21.0),
          reason: '白と黒のコントラスト比は21:1であるべき',
        );
      });
    });

    // テーマ連続切り替えテスト
    group('テーマ連続切り替えテスト', () {
      /// テーマを連続して切り替えても正常動作すること
      test('テーマを連続切り替えしても正常動作する', () async {
        // Given: テストデータ準備: ProviderContainer作成
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When/Then: light → dark → highContrast → light の順に変更
        await notifier.setTheme(AppTheme.light);
        expect(
          container.read(settingsNotifierProvider).requireValue.theme,
          AppTheme.light,
        );

        await notifier.setTheme(AppTheme.dark);
        expect(
          container.read(settingsNotifierProvider).requireValue.theme,
          AppTheme.dark,
        );

        await notifier.setTheme(AppTheme.highContrast);
        expect(
          container.read(settingsNotifierProvider).requireValue.theme,
          AppTheme.highContrast,
        );

        await notifier.setTheme(AppTheme.light);
        expect(
          container.read(settingsNotifierProvider).requireValue.theme,
          AppTheme.light,
        );

        container.dispose();
      });
    });
  });
}
