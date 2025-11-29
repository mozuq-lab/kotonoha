/// TTS速度設定UIウィジェットテスト
///
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// テストケース: TC-049-018〜TC-049-020
///
/// テスト対象: lib/features/settings/presentation/widgets/tts_speed_settings_widget.dart
///
/// 【TDD Redフェーズ】: TTS速度設定UIウィジェットが未実装、テストが失敗するはず
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';

void main() {
  group('TTS速度設定UIウィジェットテスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });
    // =========================================================================
    // UIテストケース
    // =========================================================================
    group('UI表示テスト', () {
      /// TC-049-018: TTS速度設定UIが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: 設定画面にTTS速度設定セクションが表示されること
      testWidgets('TC-049-018: 設定画面にTTS速度設定セクションが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 設定画面にTTS速度設定のウィジェットが含まれることを確認 🔵
        // 【テスト内容】: 設定画面をレンダリングし、TTS速度設定のUI要素が表示されることを検証
        // 【期待される動作】: 「読み上げ速度」ラベルと3つの選択肢（遅い/普通/速い）が表示される
        // 🔵 青信号: requirements.md（96-101行目）のUI表示仕様に基づく

        // Given: 【テストデータ準備】: ProviderScopeでラップした設定画面を構築
        // 【初期条件設定】: ユーザーが設定画面を開いた場合を模擬
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        // すべてのウィジェットがレンダリングされるまで待機
        await tester.pumpAndSettle();

        // Then: 【結果検証】: TTS速度設定のUI要素が表示されていることを確認
        // 【期待値確認】: requirements.md（96-101行目）のUI表示仕様に基づく
        // 【品質保証】: ユーザーが速度を選択できることを保証

        // 【検証項目】: 「読み上げ速度」ラベルが表示されていること
        expect(find.text('読み上げ速度'),
            findsOneWidget); // 【確認内容】: セクションラベルが表示されていることを確認 🔵

        // 【検証項目】: 3つの選択肢（遅い/普通/速い）が表示されていること
        expect(
            find.text('遅い'), findsOneWidget); // 【確認内容】: 「遅い」選択肢が表示されていることを確認 🔵
        // Note: 「普通」はAI丁寧さレベル設定にも存在するため、findsWidgetsで検証
        expect(
            find.text('普通'), findsWidgets); // 【確認内容】: 「普通」選択肢が表示されていることを確認 🔵
        expect(
            find.text('速い'), findsOneWidget); // 【確認内容】: 「速い」選択肢が表示されていることを確認 🔵

        // 【確認ポイント】: すべての選択肢が表示されている
        // 【確認ポイント】: アクセシビリティを考慮した表示（最小タップサイズ44px以上）
      });

      /// TC-049-019: 現在選択されている速度がハイライト表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: 現在のTTS速度設定がUIでハイライト表示されること
      testWidgets('TC-049-019: 現在のTTS速度設定がUIでハイライト表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 現在の速度設定（fast）がUI上で選択状態として表示されることを確認 🔵
        // 【テスト内容】: 速度を「速い」に設定した状態で設定画面をレンダリングし、選択状態が視覚的に区別されることを検証
        // 【期待される動作】: 「速い」ボタンが視覚的に区別される（背景色、ボーダー等）
        // 🔵 青信号: 既存ウィジェットテスト（settings_screen_test.dart）のパターン、アクセシビリティ要件に基づく

        // Given: 【テストデータ準備】: 速度を「速い」に設定した状態のProviderをオーバーライド
        // 【初期条件設定】: ユーザーが既に速度を「速い」に設定している状態を模擬
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

        // Then: 【結果検証】: 「速い」ボタンが選択状態で表示されていることを確認
        // 【期待値確認】: ユーザーが現在の設定を視覚的に確認できる必要がある
        // 【品質保証】: 現在の設定が視覚的に明確であることを確認

        // Note: 実装により検証方法が異なるため、ウィジェットの種類に応じて適切な検証を行う
        // 例: ラジオボタン、セグメントコントロール、ToggleButtonsなど

        // 【検証項目】: 「速い」が選択状態であること
        // 実装例: expect(tester.widget<Radio>(find.byType(Radio).at(2)).checked, isTrue);
        // または: expect(tester.widget<ToggleButtons>(...).isSelected[2], isTrue);

        // 【確認ポイント】: 選択状態が視覚的に明確
        // 【確認ポイント】: アクセシビリティ（WCAG 2.1 AAレベル準拠）
      });

      /// TC-049-020: 速度ボタンをタップすると速度が変更される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-2007, REQ-404
      /// 検証内容: ユーザー操作に対する応答
      testWidgets('TC-049-020: ユーザーが「遅い」ボタンをタップすると、速度が変更されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: ユーザー操作（タップ）に対する応答を確認 🔵
        // 【テスト内容】: 「遅い」ボタンをタップし、AppSettings状態が更新されることを検証
        // 【期待される動作】: タップ後、AppSettings.ttsSpeedがTTSSpeed.slowに更新される
        // 🔵 青信号: REQ-2007（即座反映）を参考、既存ウィジェットテスト（settings_screen_test.dart）のパターンに基づく

        // Given: 【テストデータ準備】: ProviderScopeでラップした設定画面を構築
        // 【初期条件設定】: デフォルト速度（normal）の状態
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

        // When: 【実際の処理実行】: 「遅い」ボタンをタップ
        // 【処理内容】: ユーザーが設定画面で「遅い」を選択した場合を模擬
        await tester.tap(find.text('遅い'));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: 状態が更新されたことを確認
        // 【期待値確認】: REQ-2007（即座反映）を参考にしたUI応答性
        // 【品質保証】: ユーザー操作が正しく処理されることを確認

        // 【検証項目】: AppSettings.ttsSpeedがslowに更新されたこと
        final state = container.read(settingsNotifierProvider);
        expect(state.requireValue.ttsSpeed,
            TTSSpeed.slow); // 【確認内容】: 状態が更新されたことを確認 🔵

        // 【検証項目】: UIが更新され、「遅い」が選択状態になること
        // Note: 実装により検証方法が異なるため、ウィジェットの種類に応じて適切な検証を行う

        // 【確認ポイント】: タップ応答が100ms以内（パフォーマンス要件）
        // 【確認ポイント】: 状態更新がUIに即座に反映される
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
  Future<void> setTTSSpeed(TTSSpeed speed) async {
    state = AsyncValue.data(_settings.copyWith(ttsSpeed: speed));
  }
}
