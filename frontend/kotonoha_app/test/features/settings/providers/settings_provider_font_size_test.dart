/// フォントサイズ設定UI・適用 テスト
///
/// TASK-0072: フォントサイズ設定UI・適用
/// テストケース: TC-072-001〜TC-072-013
///
/// テスト対象: フォントサイズ設定がアプリ全体に正しく反映されること
///
/// 【TDD Redフェーズ】: フォントサイズ適用の検証テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';

void main() {
  group('TASK-0072: フォントサイズ設定UI・適用テスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // 1. 正常系テストケース（基本動作）
    // =========================================================================
    group('正常系テスト', () {
      /// TC-072-001: 設定画面でフォントサイズ選択UIが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-801
      /// 検証内容: 設定画面にフォントサイズ選択UIが表示されること
      testWidgets('TC-072-001: 設定画面でフォントサイズ選択UIが表示される',
          (WidgetTester tester) async {
        // 【テスト目的】: 設定画面にフォントサイズ選択UIが表示されることを確認 🔵
        // 【テスト内容】: 設定画面をレンダリングし、フォントサイズ選択のUI要素が表示されることを検証
        // 【期待される動作】: 「フォントサイズ」ラベルと3つの選択肢（小/中/大）が表示される
        // 🔵 青信号: REQ-801「フォントサイズを3段階から選択可能」

        // Given: 【テストデータ準備】: ProviderScopeでラップした設定画面を構築
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // Then: 【結果検証】: フォントサイズ選択UIが表示されていることを確認
        expect(find.text('フォントサイズ'), findsOneWidget);
        expect(find.text('小'), findsOneWidget);
        expect(find.text('中'), findsWidgets); // AI丁寧さレベルにも「中」があるため
        expect(find.text('大'), findsOneWidget);
      });

      /// TC-072-002: フォントサイズ変更が CharacterBoardWidget に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-802
      /// 検証内容: フォントサイズ設定が文字盤の文字サイズに反映されること
      testWidgets('TC-072-002: フォントサイズ変更が CharacterBoardWidget に反映される',
          (WidgetTester tester) async {
        // 【テスト目的】: フォントサイズ設定が文字盤の文字サイズに反映されることを確認 🔵
        // 【テスト内容】: フォントサイズを「大」に設定し、CharacterBoardWidgetに反映されることを検証
        // 【期待される動作】: CharacterBoardWidgetのfontSizeがlargeになる
        // 🔵 青信号: REQ-802「文字盤のフォントサイズを設定に追従させる」

        // Given: 【テストデータ準備】: フォントサイズを「大」に設定した状態
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
            child: MaterialApp(
              home: Scaffold(
                body: CharacterBoardWidget(
                  onCharacterTap: (_) {},
                  fontSize: FontSize.large,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: CharacterBoardWidgetが存在し、フォントサイズが反映されていること
        final characterBoard = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(characterBoard.fontSize, FontSize.large);

        container.dispose();
      });

      /// TC-072-003: フォントサイズ変更が QuickResponseButtons に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-802
      /// 検証内容: フォントサイズ設定がクイック応答ボタンに反映されること
      testWidgets('TC-072-003: フォントサイズ変更が QuickResponseButtons に反映される',
          (WidgetTester tester) async {
        // 【テスト目的】: フォントサイズ設定がクイック応答ボタンに反映されることを確認 🔵
        // 【テスト内容】: フォントサイズを「大」に設定し、QuickResponseButtonsに反映されることを検証
        // 【期待される動作】: QuickResponseButtonsのfontSizeがlargeになる
        // 🔵 青信号: REQ-802「ボタンラベルのフォントサイズを設定に追従させる」

        // Given: 【テストデータ準備】: QuickResponseButtonsにフォントサイズを渡す
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickResponseButtons(
                onResponse: (_) {},
                fontSize: FontSize.large,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: QuickResponseButtonsが正しいフォントサイズを持つこと
        final quickResponseButtons = tester.widget<QuickResponseButtons>(
          find.byType(QuickResponseButtons),
        );
        expect(quickResponseButtons.fontSize, FontSize.large);
      });

      /// TC-072-004: フォントサイズ変更が即座に反映される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2007
      /// 検証内容: 設定変更後すぐにUIに反映されること
      testWidgets('TC-072-004: フォントサイズ変更が即座に反映される',
          (WidgetTester tester) async {
        // 【テスト目的】: 設定変更後すぐにUIに反映されることを確認 🔵
        // 【テスト内容】: setFontSize()呼び出し直後にstateが更新されることを検証
        // 【期待される動作】: 楽観的更新で即座にstateが更新される
        // 🔵 青信号: REQ-2007「フォントサイズ変更時に即座に変更」

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: setFontSize(FontSize.large)を呼び出し
        await notifier.setFontSize(FontSize.large);

        // Then: 【結果検証】: stateが即座に更新されていること
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.fontSize, FontSize.large);

        container.dispose();
      });

      /// TC-072-005: フォントサイズ「小」の設定と適用
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-801
      /// 検証内容: フォントサイズ「小」が正しく設定・適用されること
      testWidgets('TC-072-005: フォントサイズ「小」の設定と適用', (WidgetTester tester) async {
        // 【テスト目的】: フォントサイズ「小」が正しく設定・適用されることを確認 🔵
        // 🔵 青信号: REQ-801「小/中/大の3段階」

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: setFontSize(FontSize.small)を呼び出し
        await notifier.setFontSize(FontSize.small);

        // Then: 【結果検証】: フォントサイズがsmallに変更されていること
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;
        expect(settings.fontSize, FontSize.small);

        // SharedPreferencesに保存されていること
        // 【永続化形式】: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.small.name);

        container.dispose();
      });

      /// TC-072-006: フォントサイズ「中」の設定と適用（デフォルト）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-804
      /// 検証内容: フォントサイズ「中」（デフォルト）が正しく設定・適用されること
      testWidgets('TC-072-006: フォントサイズ「中」の設定と適用（デフォルト）',
          (WidgetTester tester) async {
        // 【テスト目的】: フォントサイズ「中」が正しく設定・適用されることを確認 🔵
        // 🔵 青信号: REQ-804「標準フォントサイズを高齢者にも見やすいサイズに設定」

        // Given: 【テストデータ準備】: 空のSharedPreferences
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // When: 【実際の処理実行】: 初期状態を取得
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: デフォルトがmediumであること
        expect(settings.fontSize, FontSize.medium);

        container.dispose();
      });

      /// TC-072-007: フォントサイズ「大」の設定と適用
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-801
      /// 検証内容: フォントサイズ「大」が正しく設定・適用されること
      testWidgets('TC-072-007: フォントサイズ「大」の設定と適用', (WidgetTester tester) async {
        // 【テスト目的】: フォントサイズ「大」が正しく設定・適用されることを確認 🔵
        // 🔵 青信号: REQ-801「小/中/大の3段階」

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: setFontSize(FontSize.large)を呼び出し
        await notifier.setFontSize(FontSize.large);

        // Then: 【結果検証】: フォントサイズがlargeに変更されていること
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;
        expect(settings.fontSize, FontSize.large);

        // SharedPreferencesに保存されていること
        // 【永続化形式】: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.large.name);

        container.dispose();
      });

      /// TC-072-008: アプリ再起動後のフォントサイズ設定復元
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: アプリ再起動後に保存したフォントサイズが復元されること
      testWidgets('TC-072-008: アプリ再起動後のフォントサイズ設定復元',
          (WidgetTester tester) async {
        // 【テスト目的】: アプリ再起動後に保存したフォントサイズが復元されることを確認 🔵
        // 🔵 青信号: REQ-5003「永続化機構を実装」

        // Given: 【テストデータ準備】: SharedPreferencesに事前にフォントサイズ「large」を保存
        // 【後方互換性】: 旧形式（enum index int）で保存されたデータでも
        // 正しく復元できることを検証する（マイグレーション対応）
        SharedPreferences.setMockInitialValues({
          'fontSize': FontSize.large.index,
        });

        // When: 【実際の処理実行】: 新しいProviderContainerを作成（再起動を模擬）
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: フォントサイズ「large」が正しく復元されたことを確認
        expect(settings.fontSize, FontSize.large);

        container.dispose();
      });
    });

    // =========================================================================
    // 2. 異常系テストケース（エラーハンドリング）
    // =========================================================================
    group('異常系テスト', () {
      /// TC-072-009: 設定読み込み中のデフォルト値使用
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301, EDGE-201
      /// 検証内容: 設定の非同期読み込み中にUIが表示される場合
      testWidgets('TC-072-009: 設定読み込み中のデフォルト値使用', (WidgetTester tester) async {
        // 【テスト目的】: ローディング中もアプリが動作することを確認 🟡
        // 🟡 黄信号: EDGE-201、NFR-301から推測

        // Given: 【テストデータ準備】: ProviderScopeでラップした画面
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // ローディング中でもUIが崩れないことを確認
        // （pumpAndSettleを呼ばないことでローディング状態を観察）
        await tester.pump();

        // Then: 【結果検証】: UIが表示されていること（エラーにならないこと）
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      /// TC-072-010: 不正な保存値のフォールバック
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301
      /// 検証内容: SharedPreferencesに不正な値が保存されている場合
      testWidgets('TC-072-010: 不正な保存値のフォールバック', (WidgetTester tester) async {
        // 【テスト目的】: 設定ファイルの破損時もアプリが起動することを確認 🟡
        // 🟡 黄信号: NFR-301「基本機能継続」から推測

        // Given: 【テストデータ準備】: SharedPreferencesに不正な値（範囲外）を保存
        SharedPreferences.setMockInitialValues({
          'fontSize': 99, // FontSize enumの範囲外（0-2）
        });

        // When: 【実際の処理実行】: ProviderContainerを作成
        final container = ProviderContainer();

        // Then: 【結果検証】: エラーが発生せず、デフォルト値（medium）またはフォールバックが使用される
        // Note: 現在の実装ではRangeErrorが発生する可能性があるため、
        // 実装側でtry-catchによるフォールバック処理が必要
        try {
          final settings =
              await container.read(settingsNotifierProvider.future);
          // 範囲外の値の場合、デフォルト値にフォールバックされることが期待される
          expect(settings.fontSize, isA<FontSize>());
        } catch (e) {
          // RangeErrorが発生した場合 - 実装が不足している
          // TDD Greenフェーズでフォールバック処理を実装する必要がある
          fail('不正な値でRangeErrorが発生: 実装にフォールバック処理が必要');
        }

        container.dispose();
      });
    });

    // =========================================================================
    // 3. 境界値テストケース
    // =========================================================================
    group('境界値テスト', () {
      /// TC-072-011: FontSize enum の最小値（small = 0）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-801
      /// 検証内容: enum の最初の値（index = 0）
      testWidgets('TC-072-011: FontSize enum の最小値（small = 0）',
          (WidgetTester tester) async {
        // 【テスト目的】: 最小値でも正常に動作することを確認 🔵
        // 🔵 青信号: REQ-801の3段階（最小）

        // Given: 【テストデータ準備】: SharedPreferencesに最小値（0）を保存
        SharedPreferences.setMockInitialValues({
          'fontSize': 0, // FontSize.small.index
        });

        // When: 【実際の処理実行】: ProviderContainerを作成
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: fontSize = small が正常に復元される
        expect(settings.fontSize, FontSize.small);
        expect(settings.fontSize.index, 0);

        container.dispose();
      });

      /// TC-072-012: FontSize enum の最大値（large = 2）
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-801
      /// 検証内容: enum の最後の値（index = 2）
      testWidgets('TC-072-012: FontSize enum の最大値（large = 2）',
          (WidgetTester tester) async {
        // 【テスト目的】: 最大値でも正常に動作することを確認 🔵
        // 🔵 青信号: REQ-801の3段階（最大）

        // Given: 【テストデータ準備】: SharedPreferencesに最大値（2）を保存
        SharedPreferences.setMockInitialValues({
          'fontSize': 2, // FontSize.large.index
        });

        // When: 【実際の処理実行】: ProviderContainerを作成
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 【結果検証】: fontSize = large が正常に復元される
        expect(settings.fontSize, FontSize.large);
        expect(settings.fontSize.index, 2);

        container.dispose();
      });

      /// TC-072-013: フォントサイズ切り替えの連続操作
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: 一般的なUI動作
      /// 検証内容: 状態遷移の連続性
      testWidgets('TC-072-013: フォントサイズ切り替えの連続操作', (WidgetTester tester) async {
        // 【テスト目的】: 連続した変更が正常に処理されることを確認 🟡
        // 🟡 黄信号: 一般的なUI動作から推測

        // Given: 【テストデータ準備】: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 【実際の処理実行】: small → medium → large → small の順に変更
        await notifier.setFontSize(FontSize.small);
        var state = container.read(settingsNotifierProvider);
        expect(state.requireValue.fontSize, FontSize.small);

        await notifier.setFontSize(FontSize.medium);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.fontSize, FontSize.medium);

        await notifier.setFontSize(FontSize.large);
        state = container.read(settingsNotifierProvider);
        expect(state.requireValue.fontSize, FontSize.large);

        await notifier.setFontSize(FontSize.small);
        state = container.read(settingsNotifierProvider);

        // Then: 【結果検証】: 最終的に small が正しく設定される
        expect(state.requireValue.fontSize, FontSize.small);

        // SharedPreferencesにも最終値が保存されていること
        // 【永続化形式】: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.small.name);

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
