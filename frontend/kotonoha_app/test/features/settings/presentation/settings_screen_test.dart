library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// テスト対象のウィジェット
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';

void main() {
  group('SettingsScreen表示テスト', () {
    // SettingsScreen表示確認テスト
    // テストカテゴリ: Widget Test
    // 対応要件: （画面スケルトン作成）
    // 対応受け入れ基準: AC-003
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
      // Note: SettingsScreenは実装済みで、AppBarタイトルは「設定」
      // 本体にはTTSSpeedSettingsWidgetの「読み上げ速度」ラベルが表示される
      expect(
        find.text('読み上げ速度'),
        findsOneWidget,
        reason: 'SettingsScreenには「読み上げ速度」設定が表示される必要がある',
      );
    });

    // SettingsScreenがconstコンストラクタを持つことを確認
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

  group('TASK-0071: 設定画面セクション表示テスト', () {
    // 「表示設定」セクションが表示される
    testWidgets('TC-071-004: 表示設定セクションが表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(
        find.text('表示設定'),
        findsOneWidget,
        reason: '「表示設定」セクションが表示される必要がある',
      );
    });

    // 「音声設定」セクションが表示される
    testWidgets('TC-071-005: 音声設定セクションが表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(
        find.text('音声設定'),
        findsOneWidget,
        reason: '「音声設定」セクションが表示される必要がある',
      );
    });

    // 「AI設定」セクションが表示される
    testWidgets('TC-071-006: AI設定セクションが表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(
        find.text('AI設定'),
        findsOneWidget,
        reason: '「AI設定」セクションが表示される必要がある',
      );
    });
  });

  group('TASK-0071: 表示設定セクションテスト', () {
    // フォントサイズ設定項目が表示される
    testWidgets('TC-071-008: フォントサイズ設定項目が表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(
        find.text('フォントサイズ'),
        findsOneWidget,
        reason: 'フォントサイズ設定項目が表示される必要がある',
      );
    });

    // フォントサイズ選択肢が3つ表示される
    testWidgets('TC-071-009: フォントサイズ選択肢が3つ表示される（小/中/大）',
        (WidgetTester tester) async {
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
      await tester.pump();

      expect(find.text('小'), findsOneWidget);
      expect(find.text('中'), findsOneWidget);
      expect(find.text('大'), findsOneWidget);
    });

    // テーマ設定項目が表示される
    testWidgets('TC-071-010: テーマ設定項目が表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(
        find.text('テーマ'),
        findsOneWidget,
        reason: 'テーマ設定項目が表示される必要がある',
      );
    });

    // テーマ選択肢が3つ表示される
    testWidgets('TC-071-011: テーマ選択肢が3つ表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(find.text('ライト'), findsOneWidget);
      expect(find.text('ダーク'), findsOneWidget);
      expect(find.text('高コントラスト'), findsOneWidget);
    });
  });

  group('TASK-0071: AI設定セクションテスト', () {
    // AI丁寧さレベル設定項目が表示される
    testWidgets('TC-071-014: AI丁寧さレベル設定項目が表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(
        find.text('丁寧さレベル'),
        findsOneWidget,
        reason: 'AI丁寧さレベル設定項目が表示される必要がある',
      );
    });

    // AI丁寧さレベル選択肢が3つ表示される
    testWidgets('TC-071-015: AI丁寧さレベル選択肢が3つ表示される', (WidgetTester tester) async {
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
      await tester.pump();

      expect(find.text('カジュアル'), findsOneWidget);
      // 「普通」はTTS速度設定にも存在するため、複数見つかる
      expect(find.text('普通'), findsWidgets);
      expect(find.text('丁寧'), findsOneWidget);
    });
  });
}

/// テスト用のモックSettingsNotifier
/// ローディング状態を回避するため、buildで即座にデフォルト設定を返す。
/// これにより、SettingsScreenのTTSSpeedSettingsWidgetで
/// CircularProgressIndicator（無限アニメーション）が表示されず
/// テストが正常に動作する。
class _MockSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    // 即座にデフォルト設定を返す（SharedPreferencesの初期化をスキップ）
    return const AppSettings();
  }
}
