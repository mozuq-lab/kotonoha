/// AI丁寧さレベル設定ウィジェット テスト
///
/// TASK-0074: TTS速度・AI丁寧さレベル設定UI
/// テストケース: TC-074-002
///
/// テスト対象: AI丁寧さレベル設定ウィジェットが正しく表示・動作すること
///
/// 【TDD Redフェーズ】: AI丁寧さレベル設定UIのウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/presentation/widgets/ai_politeness_settings_widget.dart';

void main() {
  group('TASK-0074: AI丁寧さレベル設定ウィジェット テスト', () {
    setUp(() async {
      // SharedPreferencesのモックを初期化
      SharedPreferences.setMockInitialValues({});
    });

    // =========================================================================
    // 1. UI表示テスト
    // =========================================================================
    group('UI表示テスト', () {
      /// TC-074-002: 設定画面でAI丁寧さレベル選択UIが表示される
      testWidgets('TC-074-002: 設定画面でAI丁寧さレベル選択UIが表示される',
          (WidgetTester tester) async {
        // Given: ProviderScopeでラップしたウィジェットを構築
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AIPolitenessSettingsWidget(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: AI丁寧さレベル選択UIが表示されていることを確認
        expect(find.text('丁寧さレベル'), findsOneWidget);
        expect(find.text('カジュアル'), findsOneWidget);
        expect(find.text('普通'), findsOneWidget);
        expect(find.text('丁寧'), findsOneWidget);
      });
    });
  });
}
