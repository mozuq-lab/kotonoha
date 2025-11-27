// SettingsScreen表示確認 TDDテスト（Redフェーズ）
// TASK-0015: go_routerナビゲーション設定・ルーティング実装
//
// テストフレームワーク: flutter_test
// 対象: SettingsScreen（設定画面スケルトン）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// テスト対象のウィジェット
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';

void main() {
  group('SettingsScreen表示テスト', () {
    // TC-007: SettingsScreen表示確認テスト
    // テストカテゴリ: Widget Test
    // 対応要件: FR-005（画面スケルトン作成）
    // 対応受け入れ基準: AC-003
    // 青信号: タスクファイルでSettingsScreen作成が明示
    testWidgets('TC-007: SettingsScreenが正常に表示される', (WidgetTester tester) async {
      // Given（準備フェーズ）
      // ProviderScope内でSettingsScreenをラップ

      // When（実行フェーズ）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsNotifierProvider
                .overrideWith(() => _MockSettingsNotifier()),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      // AsyncNotifierのビルドを完了させる
      await tester.pump();

      // Then（検証フェーズ）
      // SettingsScreenウィジェットが存在することを確認
      expect(
        find.byType(SettingsScreen),
        findsOneWidget,
        reason: 'SettingsScreenウィジェットが表示される必要がある',
      );

      // Scaffoldが存在することを確認
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'SettingsScreenはScaffold構造を持つ必要がある',
      );

      // AppBarが存在することを確認
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: 'SettingsScreenはAppBarを持つ必要がある',
      );

      // 画面識別テキスト（AppBarタイトル「設定」または設定コンテンツ「読み上げ速度」）を確認
      // Note: SettingsScreenは実装済みで、AppBarタイトルは「設定」、
      // 本体にはTTSSpeedSettingsWidgetの「読み上げ速度」ラベルが表示される
      expect(
        find.text('読み上げ速度'),
        findsOneWidget,
        reason: 'SettingsScreenには「読み上げ速度」設定が表示される必要がある',
      );
    });

    // SettingsScreenがconstコンストラクタを持つことを確認
    // 青信号: CLAUDE.mdで「constコンストラクタを可能な限り使用」が明示
    testWidgets('SettingsScreenはconstコンストラクタを持つ', (WidgetTester tester) async {
      // Given/When（準備・実行フェーズ）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsNotifierProvider
                .overrideWith(() => _MockSettingsNotifier()),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Then（検証フェーズ）
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // SettingsScreenがkeyパラメータを受け取れることを確認
    // 青信号: CLAUDE.mdで「ウィジェットはkeyパラメータを持つ」が明示
    testWidgets('SettingsScreenはkeyパラメータを受け取れる', (WidgetTester tester) async {
      // Given（準備フェーズ）
      const testKey = Key('settings_screen_test_key');

      // When（実行フェーズ）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsNotifierProvider
                .overrideWith(() => _MockSettingsNotifier()),
          ],
          child: const MaterialApp(
            home: SettingsScreen(key: testKey),
          ),
        ),
      );

      // Then（検証フェーズ）
      expect(
        find.byKey(testKey),
        findsOneWidget,
        reason: 'SettingsScreenは指定されたkeyで識別可能である必要がある',
      );
    });
  });
}

/// テスト用のモックSettingsNotifier
///
/// ローディング状態を回避するため、build()で即座にデフォルト設定を返す。
/// これにより、SettingsScreenのTTSSpeedSettingsWidgetで
/// CircularProgressIndicator（無限アニメーション）が表示されず、
/// テストが正常に動作する。
class _MockSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    // 即座にデフォルト設定を返す（SharedPreferencesの初期化をスキップ）
    return const AppSettings();
  }
}
