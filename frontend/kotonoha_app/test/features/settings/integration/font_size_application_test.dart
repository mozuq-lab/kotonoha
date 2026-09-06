/// フォントサイズ適用 統合テスト
///
/// TASK-0072: フォントサイズ設定UI・適用
/// テストケース: アプリ全体への反映テスト
///
/// テスト対象: フォントサイズ設定がアプリ全体に正しく反映されること
///
/// TDD Redフェーズ: HomeScreenでのフォントサイズ反映を検証
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

void main() {
  group('TASK-0072: フォントサイズ適用 統合テスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // HomeScreen統合テスト
    // =========================================================================
    group('HomeScreen フォントサイズ反映', () {
      /// TC-INT-001: HomeScreenでCharacterBoardWidgetにフォントサイズが渡される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-802
      /// 検証内容: HomeScreen内のCharacterBoardWidgetに設定のフォントサイズが適用されること
      testWidgets('TC-INT-001: CharacterBoardWidgetにフォントサイズが渡される',
          (WidgetTester tester) async {
        // テスト目的: HomeScreenでフォントサイズ設定がCharacterBoardWidgetに反映されること
        // 青信号: REQ-802「文字盤のフォントサイズを設定に追従させる」

        // Given: テストデータ準備: フォントサイズを「大」に設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(fontSize: FontSize.large),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: CharacterBoardWidgetにfontSize=largeが渡されている
        final characterBoard = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(characterBoard.fontSize, FontSize.large);

        container.dispose();
      });

      /// TC-INT-002: HomeScreenでQuickResponseButtonsにフォントサイズが渡される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-802
      /// 検証内容: HomeScreen内のQuickResponseButtonsに設定のフォントサイズが適用されること
      testWidgets('TC-INT-002: QuickResponseButtonsにフォントサイズが渡される',
          (WidgetTester tester) async {
        // テスト目的: HomeScreenでフォントサイズ設定がQuickResponseButtonsに反映されること
        // 青信号: REQ-802「ボタンラベルのフォントサイズを設定に追従させる」

        // Given: テストデータ準備: フォントサイズを「大」に設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(fontSize: FontSize.large),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: QuickResponseButtonsにfontSize=largeが渡されている
        final quickResponseButtons = tester.widget<QuickResponseButtons>(
          find.byType(QuickResponseButtons),
        );
        expect(quickResponseButtons.fontSize, FontSize.large);

        container.dispose();
      });

      /// TC-INT-003: 入力欄のフォントサイズが設定に追従する
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-802
      /// 検証内容: HomeScreen内の入力表示エリアに設定のフォントサイズが適用されること
      /// TDD Redフェーズ: この機能は未実装のため、テストが失敗することを期待
      testWidgets('TC-INT-003: 入力欄のフォントサイズが設定に追従する',
          (WidgetTester tester) async {
        // テスト目的: 入力表示エリアのフォントサイズが設定に追従することを確認
        // 青信号: REQ-802「入力欄のフォントサイズを設定に追従させる」

        // Given: テストデータ準備: フォントサイズを「大」に設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(fontSize: FontSize.large),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 入力欄のフォントサイズがlargeサイズ（24px）であること
        // 入力欄のプレースホルダーテキストを探す
        final inputText = tester.widget<Text>(
          find.text('入力してください...'),
        );

        // フォントサイズがlargeサイズ（24px = AppSizes.fontSizeLarge）であることを確認
        expect(
          inputText.style?.fontSize,
          AppSizes.fontSizeLarge,
          reason: '入力欄のフォントサイズが設定に追従していない（REQ-802）',
        );

        container.dispose();
      });

      /// TC-INT-004: フォントサイズ「小」でのHomeScreen表示
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: フォントサイズ「小」でも正常に表示されること
      testWidgets('TC-INT-004: フォントサイズ「小」でのHomeScreen表示',
          (WidgetTester tester) async {
        // テスト目的: フォントサイズ「小」でも正常に表示されることを確認

        // Given: テストデータ準備: フォントサイズを「小」に設定
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(fontSize: FontSize.small),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 各ウィジェットにfontSize=smallが渡されている
        final characterBoard = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(characterBoard.fontSize, FontSize.small);

        final quickResponseButtons = tester.widget<QuickResponseButtons>(
          find.byType(QuickResponseButtons),
        );
        expect(quickResponseButtons.fontSize, FontSize.small);

        container.dispose();
      });

      /// TC-INT-005: デフォルトフォントサイズ（中）でのHomeScreen表示
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-804
      /// 検証内容: デフォルト設定（フォントサイズ「中」）で正常に表示されること
      testWidgets('TC-INT-005: デフォルトフォントサイズ（中）でのHomeScreen表示',
          (WidgetTester tester) async {
        // テスト目的: デフォルト設定で正常に表示されることを確認
        // 青信号: REQ-804「標準フォントサイズを高齢者にも見やすいサイズに設定」

        // Given: テストデータ準備: デフォルト設定
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: 各ウィジェットにfontSize=medium（デフォルト）が渡されている
        final characterBoard = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(characterBoard.fontSize, FontSize.medium);

        final quickResponseButtons = tester.widget<QuickResponseButtons>(
          find.byType(QuickResponseButtons),
        );
        expect(quickResponseButtons.fontSize, FontSize.medium);
      });
    });

    // =========================================================================
    // 設定画面からの変更反映テスト
    // =========================================================================
    group('設定変更の反映', () {
      /// TC-INT-006: 設定変更後のProvider状態更新
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2007
      /// 検証内容: 設定画面でフォントサイズを変更すると、Provider状態が即座に更新される
      testWidgets('TC-INT-006: 設定変更後のProvider状態更新',
          (WidgetTester tester) async {
        // テスト目的: 設定変更がProvider状態に即座に反映されることを確認
        // 青信号: REQ-2007「フォントサイズ変更時に即座に変更」

        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        // 初期状態確認
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.fontSize, FontSize.medium);

        // When: 実際の処理実行: フォントサイズを「大」に変更
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.setFontSize(FontSize.large);

        // Then: 結果検証: Provider状態が即座に更新される
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.fontSize, FontSize.large);

        container.dispose();
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
  Future<void> setFontSize(FontSize fontSize) async {
    state = AsyncValue.data(_settings.copyWith(fontSize: fontSize));
  }
}
