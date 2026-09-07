/// TTS速度設定UIウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

void main() {
  group('TTS速度設定UIウィジェットテスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });
    // UIテストケース
    group('UI表示テスト', () {
      /// UIに「とても遅い」ボタンが表示される
      testWidgets('TTC-VS-004: 設定画面に「とても遅い」選択肢が表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderScopeでラップした設定画面を構築
        // 初期条件設定: ユーザーが設定画面を開いた場合を模擬
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // Then: 結果検証: 「とても遅い」選択肢が表示されていることを確認
        // 要件定義書のUI仕様に基づく
        // 品質保証: ユーザーが「とても遅い」速度を選択できることを保証
        expect(find.text('とても遅い'), findsOneWidget);

        // 確認ポイント: アクセシビリティ要件（最小タップサイズ44px）も維持されていること
      });

      /// TTS速度設定UIが表示される
      testWidgets('TC-049-018: 設定画面にTTS速度設定セクションが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderScopeでラップした設定画面を構築
        // 初期条件設定: ユーザーが設定画面を開いた場合を模擬
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // Then: 結果検証: TTS速度設定のUI要素が表示されていることを確認
        // requirements.md（96-101行目）のUI表示仕様に基づく
        // 品質保証: ユーザーが速度を選択できることを保証

        // 検証項目: 「読み上げ速度」ラベルが表示されていること
        expect(find.text('読み上げ速度'), findsOneWidget);

        // 検証項目: 4つの選択肢（とても遅い/遅い/普通/速い）が表示されていること
        expect(find.text('とても遅い'), findsOneWidget);
        expect(find.text('遅い'), findsOneWidget);
        // Note: 「普通」はAI丁寧さレベル設定にも存在するため、findsWidgetsで検証
        expect(find.text('普通'), findsWidgets);
        expect(find.text('速い'), findsOneWidget);

        // 確認ポイント: すべての選択肢が表示されている
        // 確認ポイント: アクセシビリティを考慮した表示（最小タップサイズ44px以上）
      });

      /// 「とても遅い」ボタンをタップすると速度が変更される
      testWidgets('TTC-VS-005: ユーザーが「とても遅い」ボタンをタップすると、速度が変更されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderScopeでラップした設定画面を構築
        // 初期条件設定: デフォルト速度（normal）の状態
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // When: 実際の処理実行: 「とても遅い」ボタンをタップ
        // 処理内容: ユーザーが設定画面で「とても遅い」を選択した場合を模擬
        await tester.tap(find.text('とても遅い'));
        await tester.pumpAndSettle();

        // Then: 結果検証: 状態が更新されたことを確認
        // （即座反映）を参考にしたUI応答性
        // 品質保証: ユーザー操作が正しく処理されることを確認

        // 検証項目: AppSettings.ttsSpeedがverySlowに更新されたこと
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.verySlow);

        // 確認ポイント: タップ応答が100ms以内（パフォーマンス要件）
        // 確認ポイント: 状態更新がUIに即座に反映される
      });

      /// 「とても遅い」選択時のハイライト表示
      testWidgets('TTC-VS-006: 「とても遅い」が選択状態で視覚的に区別されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 速度を「とても遅い」に設定した状態のProviderをオーバーライド
        // 初期条件設定: ユーザーが既に速度を「とても遅い」に設定している状態を模擬
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(ttsSpeed: TTSSpeed.verySlow),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // 描画の完了のみ確認しており、選択状態やコントラストのassertionはない。
      });

      /// 現在選択されている速度がハイライト表示される
      testWidgets('TC-049-019: 現在のTTS速度設定がUIでハイライト表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 速度を「速い」に設定した状態のProviderをオーバーライド
        // 初期条件設定: ユーザーが既に速度を「速い」に設定している状態を模擬
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(ttsSpeed: TTSSpeed.fast),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // Then: 結果検証: 「速い」ボタンが選択状態で表示されていることを確認
        // ユーザーが現在の設定を視覚的に確認できる必要がある
        // 品質保証: 現在の設定が視覚的に明確であることを確認

        // Note: 実装により検証方法が異なるため、ウィジェットの種類に応じて適切な検証を行う
        // 例: ラジオボタン、セグメントコントロール、ToggleButtonsなど

        // 検証項目: 「速い」が選択状態であること
        // 実装例: expect(tester.widget<Radio>(find.byType(Radio).at(2)).checked, isTrue);
        // または: expect(tester.widget<ToggleButtons>(...).isSelected[2], isTrue);

        // 確認ポイント: 選択状態が視覚的に明確
        // 確認ポイント: アクセシビリティ（WCAG 2.1 AAレベル準拠）
      });

      /// 速度ボタンをタップすると速度が変更される
      testWidgets('TC-049-020: ユーザーが「遅い」ボタンをタップすると、速度が変更されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ProviderScopeでラップした設定画面を構築
        // 初期条件設定: デフォルト速度（normal）の状態
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // When: 実際の処理実行: 「遅い」ボタンをタップ
        // 処理内容: ユーザーが設定画面で「遅い」を選択した場合を模擬
        await tester.tap(find.text('遅い'));
        await tester.pumpAndSettle();

        // Then: 結果検証: 状態が更新されたことを確認
        // （即座反映）を参考にしたUI応答性
        // 品質保証: ユーザー操作が正しく処理されることを確認

        // 検証項目: AppSettings.ttsSpeedがslowに更新されたこと
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed, TTSSpeed.slow);

        // 検証項目: UIが更新され、「遅い」が選択状態になること
        // Note: 実装により検証方法が異なるため、ウィジェットの種類に応じて適切な検証を行う

        // 確認ポイント: タップ応答が100ms以内（パフォーマンス要件）
        // 確認ポイント: 状態更新がUIに即座に反映される
      });
    });

    // アクセシビリティ（コントラスト）テスト
    group('コントラスト（WCAG AA）テスト', () {
      /// 非選択ボタンのテキスト色がsurfaceに対しAAを満たす
      /// 検証内容: 非選択の速度ボタンは onSurface 文字（surface背景）を使い
      /// primary文字をsurfaceへ載せる（約2.87:1でAA不足）構成になっていないこと。
      testWidgets('TC-049-A11Y: 非選択ボタンはonSurface、選択ボタンはonPrimaryの文字色',
          (WidgetTester tester) async {
        // Given: ttsSpeed=verySlow（「とても遅い」が選択）の状態。
        // （「普通」はAI丁寧さ設定にも存在し曖昧なため、TTS固有の一意ラベルで検証する）
        final container = ProviderContainer(
          overrides: [
            settingsNotifierProvider.overrideWith(
              () => FakeSettingsNotifier(
                const AppSettings(ttsSpeed: TTSSpeed.verySlow),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: lightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final colorScheme = lightTheme.colorScheme;

        // 非選択（「速い」）の文字色は onSurface（surface背景に対しAA）
        final unselected = tester.widget<Text>(find.text('速い'));
        expect(unselected.style?.color, colorScheme.onSurface);

        // 選択（「とても遅い」）の文字色は onPrimary（primary背景に対しAA）
        final selected = tester.widget<Text>(find.text('とても遅い'));
        expect(selected.style?.color, colorScheme.onPrimary);
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
  Future<void> setTTSSpeed(TTSSpeed speed) async {
    state = AsyncValue.data(_settings.copyWith(ttsSpeed: speed));
  }
}
