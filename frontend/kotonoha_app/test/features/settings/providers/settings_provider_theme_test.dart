/// テーマ設定 Providerテスト
///
/// TASK-0073: テーマ切り替えUI・適用
/// テストケース: TC-073-001〜TC-073-013
///
/// テスト対象: テーマ設定がProviderで正しく管理されること
///
/// 【TDD Redフェーズ】: テーマ設定の全テストケースを作成
library;

import 'dart:math' show exp, log;
import 'dart:ui' show Color;
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

void main() {
  group('TASK-0073: テーマ設定 Providerテスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // 正常系テストケース（基本動作）
    // =========================================================================
    group('正常系テストケース', () {
      /// TC-073-002: テーマ「ライト」の選択と適用
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803
      /// 検証内容: テーマ「ライト」が正しく選択・適用されること
      test('TC-073-002: テーマ「ライト」の選択と適用', () async {
        // 【テスト目的】: テーマ「ライト」が正しく設定されることを確認 🔵
        // 🔵 青信号: REQ-803「ライトモード」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: テーマを「ライト」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.light);

        // Then: 【結果検証】: テーマがlightに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);

        container.dispose();
      });

      /// TC-073-003: テーマ「ダーク」の選択と適用
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803
      /// 検証内容: テーマ「ダーク」が正しく選択・適用されること
      test('TC-073-003: テーマ「ダーク」の選択と適用', () async {
        // 【テスト目的】: テーマ「ダーク」が正しく設定されることを確認 🔵
        // 🔵 青信号: REQ-803「ダークモード」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: テーマを「ダーク」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 【結果検証】: テーマがdarkに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        container.dispose();
      });

      /// TC-073-004: テーマ「高コントラスト」の選択と適用
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803
      /// 検証内容: テーマ「高コントラスト」が正しく選択・適用されること
      test('TC-073-004: テーマ「高コントラスト」の選択と適用', () async {
        // 【テスト目的】: テーマ「高コントラスト」が正しく設定されることを確認 🔵
        // 🔵 青信号: REQ-803「高コントラストモード」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // When: 【実際の処理実行】: テーマを「高コントラスト」に設定
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.highContrast);

        // Then: 【結果検証】: テーマがhighContrastに更新されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.highContrast);

        container.dispose();
      });

      /// TC-073-005: テーマ変更が即座に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2008
      /// 検証内容: 設定変更後すぐにUIに反映されること
      test('TC-073-005: テーマ変更が即座に反映される', () async {
        // 【テスト目的】: テーマ変更が楽観的更新で即座に反映されることを確認 🔵
        // 🔵 青信号: REQ-2008「テーマ変更時に即座に変更」

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // 初期状態確認（デフォルトはライト）
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);

        // When: 【実際の処理実行】: テーマを「ダーク」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 【結果検証】: 即座に状態が更新されている
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        container.dispose();
      });

      /// TC-073-006: アプリ再起動後のテーマ設定復元
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: アプリ再起動後に保存したテーマが復元されること
      test('TC-073-006: アプリ再起動後のテーマ設定復元', () async {
        // 【テスト目的】: SharedPreferencesに保存した値が復元されることを確認 🔵
        // 🔵 青信号: REQ-5003「アプリ強制終了しても設定を失わない」

        // Given: 【テストデータ準備】: SharedPreferencesにダークテーマを保存
        // 【後方互換性】: 旧形式（enum index int）で保存されたデータでも
        // 正しく復元できることを検証する（マイグレーション対応）
        SharedPreferences.setMockInitialValues({
          'theme': AppTheme.dark.index,
        });

        // When: 【実際の処理実行】: Provider初期化（再起動をシミュレート）
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: ダークテーマが復元されている
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.dark);

        container.dispose();
      });

      /// TC-073-007: currentThemeProviderがテーマ変更に追従する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-803, REQ-2008
      /// 検証内容: テーマ変更時にcurrentThemeProviderが正しいThemeDataを返すこと
      test('TC-073-007: currentThemeProviderがテーマ変更に追従する', () async {
        // 【テスト目的】: currentThemeProviderが設定と連携していることを確認 🔵
        // 🔵 青信号: REQ-803、REQ-2008

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // 初期状態: ライトテーマ
        var currentTheme = container.read(currentThemeProvider);
        expect(currentTheme, lightTheme);

        // When: 【実際の処理実行】: テーマを「ダーク」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setTheme(AppTheme.dark);

        // Then: 【結果検証】: currentThemeProviderがdarkThemeを返す
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

    // =========================================================================
    // 異常系テストケース（エラーハンドリング）
    // =========================================================================
    group('異常系テストケース', () {
      /// TC-073-009: 設定読み込み中のデフォルトテーマ使用
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301, EDGE-201
      /// 検証内容: ローディング中もアプリが動作すること
      test('TC-073-009: 設定読み込み中のデフォルトテーマ使用', () async {
        // 【テスト目的】: ローディング中もデフォルトテーマで動作することを確認 🟡
        // 🟡 黄信号: EDGE-201、NFR-301 から推測

        // Given: 【テストデータ準備】: ProviderContainer作成
        final container = ProviderContainer();

        // When: 【実際の処理実行】: ローディング中の状態を確認
        // ローディング状態の場合、currentThemeProviderはデフォルト（ライト）を返す
        final currentTheme = container.read(currentThemeProvider);

        // Then: 【結果検証】: デフォルトテーマ（ライト）が返される
        expect(currentTheme, lightTheme);

        container.dispose();
      });

      /// TC-073-010: 不正な保存値のフォールバック
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301
      /// 検証内容: 不正な値が保存されていてもアプリが起動すること
      test('TC-073-010: 不正な保存値のフォールバック', () async {
        // 【テスト目的】: 不正値でもアプリがクラッシュしないことを確認 🟡
        // 🟡 黄信号: NFR-301「基本機能継続」から推測

        // Given: 【テストデータ準備】: 範囲外のindex値をSharedPreferencesに保存
        SharedPreferences.setMockInitialValues({
          'theme': 99, // 範囲外（AppTheme enum は 0-2）
        });

        // When: 【実際の処理実行】: Provider初期化
        final container = ProviderContainer();

        // Then: 【結果検証】: エラーにならず、デフォルト値（ライト）が使用される
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

    // =========================================================================
    // 境界値テストケース
    // =========================================================================
    group('境界値テストケース', () {
      /// TC-073-011: AppTheme enum の最小値（light = 0）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-803
      /// 検証内容: enum最小値でも正常に動作すること
      test('TC-073-011: AppTheme enum の最小値（light = 0）', () async {
        // 【テスト目的】: 境界値（最小）で正常動作することを確認 🔵
        // 🔵 青信号: REQ-803 の3種類（最小）

        // Given: 【テストデータ準備】: SharedPreferencesにindex=0を保存
        SharedPreferences.setMockInitialValues({
          'theme': 0, // AppTheme.light.index
        });

        // When: 【実際の処理実行】: Provider初期化
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: ライトテーマが正しく復元される
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.light);
        expect(AppTheme.light.index, 0);

        container.dispose();
      });

      /// TC-073-012: AppTheme enum の最大値（highContrast = 2）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-803
      /// 検証内容: enum最大値でも正常に動作すること
      test('TC-073-012: AppTheme enum の最大値（highContrast = 2）', () async {
        // 【テスト目的】: 境界値（最大）で正常動作することを確認 🔵
        // 🔵 青信号: REQ-803 の3種類（最大）

        // Given: 【テストデータ準備】: SharedPreferencesにindex=2を保存
        SharedPreferences.setMockInitialValues({
          'theme': 2, // AppTheme.highContrast.index
        });

        // When: 【実際の処理実行】: Provider初期化
        final container = ProviderContainer();
        await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: 高コントラストテーマが正しく復元される
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.theme, AppTheme.highContrast);
        expect(AppTheme.highContrast.index, 2);

        container.dispose();
      });

      /// TC-073-013: 高コントラストモードのコントラスト比検証
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5006
      /// 検証内容: WCAG 2.1 AAレベル（4.5:1以上）のコントラスト比を確保
      test('TC-073-013: 高コントラストモードのコントラスト比検証', () {
        // 【テスト目的】: WCAG 2.1 AAレベル準拠を確認 🟡
        // 🟡 黄信号: REQ-5006「WCAG 2.1 AAレベル」

        // Given: 【テストデータ準備】: 高コントラストモードの色定義
        const backgroundColor = AppColors.backgroundHighContrast; // #FFFFFF
        const textColor = AppColors.onBackgroundHighContrast; // #000000

        // When: 【実際の処理実行】: コントラスト比を計算
        // コントラスト比の計算式: (L1 + 0.05) / (L2 + 0.05)
        // L1 = 白 (1.0), L2 = 黒 (0.0)
        // 白と黒のコントラスト比は 21:1
        final contrastRatio =
            _calculateContrastRatio(backgroundColor, textColor);

        // Then: 【結果検証】: コントラスト比が4.5:1以上であること
        expect(
          contrastRatio,
          greaterThanOrEqualTo(4.5),
          reason: '高コントラストモードはWCAG 2.1 AAレベル（4.5:1以上）を満たす必要があります',
        );

        // 追加検証: 実際には21:1（最大コントラスト）
        expect(
          contrastRatio,
          greaterThanOrEqualTo(21.0),
          reason: '白と黒のコントラスト比は21:1であるべき',
        );
      });
    });

    // =========================================================================
    // テーマ連続切り替えテスト
    // =========================================================================
    group('テーマ連続切り替えテスト', () {
      /// テーマを連続して切り替えても正常動作すること
      test('テーマを連続切り替えしても正常動作する', () async {
        // 【テスト目的】: 連続操作でも状態が一貫することを確認

        // Given: 【テストデータ準備】: ProviderContainer作成
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

/// コントラスト比を計算するヘルパー関数
///
/// WCAG 2.1のコントラスト比計算式に基づく
/// コントラスト比 = (L1 + 0.05) / (L2 + 0.05)
/// L1は明るい色の相対輝度、L2は暗い色の相対輝度
double _calculateContrastRatio(Color color1, Color color2) {
  final luminance1 = _getRelativeLuminance(color1);
  final luminance2 = _getRelativeLuminance(color2);

  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;

  return (lighter + 0.05) / (darker + 0.05);
}

/// 相対輝度を計算するヘルパー関数
///
/// WCAG 2.1の相対輝度計算式に基づく
double _getRelativeLuminance(Color color) {
  // Flutter 3.10以降: color.red/green/blueは0-255の整数値
  double r = color.red / 255.0;
  double g = color.green / 255.0;
  double b = color.blue / 255.0;

  r = r <= 0.03928 ? r / 12.92 : _pow((r + 0.055) / 1.055, 2.4);
  g = g <= 0.03928 ? g / 12.92 : _pow((g + 0.055) / 1.055, 2.4);
  b = b <= 0.03928 ? b / 12.92 : _pow((b + 0.055) / 1.055, 2.4);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// べき乗計算のヘルパー関数
double _pow(double base, double exponent) {
  return base <= 0 ? 0 : exp(exponent * log(base));
}
