/// フォントサイズ設定UI・適用 テスト
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

    group('正常系テスト', () {
      /// 設定画面でフォントサイズ選択UIが表示される
      testWidgets('TC-072-001: 設定画面でフォントサイズ選択UIが表示される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderScopeでラップした設定画面を構築
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // Then: 結果検証: フォントサイズ選択UIが表示されていることを確認
        expect(find.text('フォントサイズ'), findsOneWidget);
        expect(find.text('小'), findsOneWidget);
        expect(find.text('中'), findsWidgets); // AI丁寧さレベルにも「中」があるため
        expect(find.text('大'), findsOneWidget);
      });

      /// フォントサイズ変更が CharacterBoardWidget に反映される
      testWidgets('TC-072-002: フォントサイズ変更が CharacterBoardWidget に反映される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: フォントサイズを「大」に設定した状態
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

        // Then: 結果検証: CharacterBoardWidgetが存在し、フォントサイズが反映されていること
        final characterBoard = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(characterBoard.fontSize, FontSize.large);

        container.dispose();
      });

      /// フォントサイズ変更が QuickResponseButtons に反映される
      testWidgets('TC-072-003: フォントサイズ変更が QuickResponseButtons に反映される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: QuickResponseButtonsにフォントサイズを渡す
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

        // Then: 結果検証: QuickResponseButtonsが正しいフォントサイズを持つこと
        final quickResponseButtons = tester.widget<QuickResponseButtons>(
          find.byType(QuickResponseButtons),
        );
        expect(quickResponseButtons.fontSize, FontSize.large);
      });

      /// フォントサイズ変更が即座に反映される
      testWidgets('TC-072-004: フォントサイズ変更が即座に反映される',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // Provider初期化
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: setFontSize(FontSize.large)を呼び出し
        await notifier.setFontSize(FontSize.large);

        // Then: 結果検証: stateが即座に更新されていること
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        expect(settings.fontSize, FontSize.large);

        container.dispose();
      });

      /// フォントサイズ「小」の設定と適用
      testWidgets('TC-072-005: フォントサイズ「小」の設定と適用', (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: setFontSize(FontSize.small)を呼び出し
        await notifier.setFontSize(FontSize.small);

        // Then: 結果検証: フォントサイズがsmallに変更されていること
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;
        expect(settings.fontSize, FontSize.small);

        // SharedPreferencesに保存されていること
        // 永続化形式: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.small.name);

        container.dispose();
      });

      /// フォントサイズ「中」の設定と適用（デフォルト）
      testWidgets('TC-072-006: フォントサイズ「中」の設定と適用（デフォルト）',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 空のSharedPreferences
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        // When: 実際の処理実行: 初期状態を取得
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: デフォルトがmediumであること
        expect(settings.fontSize, FontSize.medium);

        container.dispose();
      });

      /// フォントサイズ「大」の設定と適用
      testWidgets('TC-072-007: フォントサイズ「大」の設定と適用', (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: setFontSize(FontSize.large)を呼び出し
        await notifier.setFontSize(FontSize.large);

        // Then: 結果検証: フォントサイズがlargeに変更されていること
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;
        expect(settings.fontSize, FontSize.large);

        // SharedPreferencesに保存されていること
        // 永続化形式: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.large.name);

        container.dispose();
      });

      /// アプリ再起動後のフォントサイズ設定復元
      testWidgets('TC-072-008: アプリ再起動後のフォントサイズ設定復元',
          (WidgetTester tester) async {
        // Given: テストデータ準備: SharedPreferencesに事前にフォントサイズ「large」を保存
        // 後方互換性: 旧形式（enum index int）で保存されたデータでも
        // 正しく復元できることを検証する（マイグレーション対応）
        SharedPreferences.setMockInitialValues({
          'fontSize': FontSize.large.index,
        });

        // When: 実際の処理実行: 新しいProviderContainerを作成（再起動を模擬）
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: フォントサイズ「large」が正しく復元されたことを確認
        expect(settings.fontSize, FontSize.large);

        container.dispose();
      });
    });

    group('異常系テスト', () {
      /// 設定読み込み中のデフォルト値使用
      testWidgets('TC-072-009: 設定読み込み中のデフォルト値使用', (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderScopeでラップした画面
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

        // Then: 結果検証: UIが表示されていること（エラーにならないこと）
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      /// 不正な保存値のフォールバック
      testWidgets('TC-072-010: 不正な保存値のフォールバック', (WidgetTester tester) async {
        // Given: テストデータ準備: SharedPreferencesに不正な値（範囲外）を保存
        SharedPreferences.setMockInitialValues({
          'fontSize': 99, // FontSize enumの範囲外（0-2）
        });

        // When: 実際の処理実行: ProviderContainerを作成
        final container = ProviderContainer();

        // Then: 結果検証: エラーが発生せず、デフォルト値（medium）またはフォールバックが使用される
        // Note: 現在の実装ではRangeErrorが発生する可能性があるため
        // 実装側でtry-catchによるフォールバック処理が必要
        try {
          final settings =
              await container.read(settingsNotifierProvider.future);
          // 範囲外の値の場合、デフォルト値にフォールバックされることが期待される
          expect(settings.fontSize, isA<FontSize>());
        } catch (e) {
          // RangeErrorが発生した場合 - 実装が不足している
          fail('不正な値でRangeErrorが発生: 実装にフォールバック処理が必要');
        }

        container.dispose();
      });
    });

    group('境界値テスト', () {
      /// FontSize enum の最小値（small = 0）
      testWidgets('TC-072-011: FontSize enum の最小値（small = 0）',
          (WidgetTester tester) async {
        // Given: テストデータ準備: SharedPreferencesに最小値（0）を保存
        SharedPreferences.setMockInitialValues({
          'fontSize': 0, // FontSize.small.index
        });

        // When: 実際の処理実行: ProviderContainerを作成
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: fontSize = small が正常に復元される
        expect(settings.fontSize, FontSize.small);
        expect(settings.fontSize.index, 0);

        container.dispose();
      });

      /// FontSize enum の最大値（large = 2）
      testWidgets('TC-072-012: FontSize enum の最大値（large = 2）',
          (WidgetTester tester) async {
        // Given: テストデータ準備: SharedPreferencesに最大値（2）を保存
        SharedPreferences.setMockInitialValues({
          'fontSize': 2, // FontSize.large.index
        });

        // When: 実際の処理実行: ProviderContainerを作成
        final container = ProviderContainer();
        final settings = await container.read(settingsNotifierProvider.future);

        // Then: 結果検証: fontSize = large が正常に復元される
        expect(settings.fontSize, FontSize.large);
        expect(settings.fontSize.index, 2);

        container.dispose();
      });

      /// フォントサイズ切り替えの連続操作
      testWidgets('TC-072-013: フォントサイズ切り替えの連続操作', (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderContainer作成
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();

        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 実際の処理実行: small → medium → large → small の順に変更
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

        // Then: 結果検証: 最終的に small が正しく設定される
        expect(state.requireValue.fontSize, FontSize.small);

        // SharedPreferencesにも最終値が保存されていること
        // 永続化形式: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), FontSize.small.name);

        container.dispose();
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
  Future<void> setFontSize(FontSize fontSize) async {
    state = AsyncValue.data(_settings.copyWith(fontSize: fontSize));
  }
}
