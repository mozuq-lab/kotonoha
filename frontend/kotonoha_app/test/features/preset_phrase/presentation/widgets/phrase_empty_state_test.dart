/// PhraseEmptyState ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_empty_state.dart';

void main() {
  group('PhraseEmptyState - 正常系テスト', () {
    // 空状態メッセージが表示される
    /// PhraseEmptyStateが空状態メッセージを表示することを確認
    testWidgets('TC-040-022: PhraseEmptyStateが空状態メッセージを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(),
          ),
        ),
      );

      // 結果検証: デフォルトメッセージが表示されることを確認
      expect(find.text('定型文がありません'), findsOneWidget);
    });

    // 空状態アイコンが表示される
    /// PhraseEmptyStateにアイコンが表示されることを確認
    testWidgets('TC-040-023: PhraseEmptyStateにアイコンが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(),
          ),
        ),
      );

      // 結果検証: アイコンが表示されることを確認
      expect(find.byType(Icon), findsOneWidget);
    });

    // カスタムメッセージが表示される
    /// カスタムメッセージが正しく表示されることを確認
    testWidgets('カスタムメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(
              message: 'カスタムメッセージ',
            ),
          ),
        ),
      );

      // 結果検証: カスタムメッセージが表示されることを確認
      expect(find.text('カスタムメッセージ'), findsOneWidget);
    });
  });

  group('PhraseEmptyState - レイアウトテスト', () {
    // 中央配置で表示される
    /// 空状態ウィジェットが中央に配置されることを確認
    testWidgets('空状態ウィジェットが中央に配置される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(),
          ),
        ),
      );

      // 結果検証: Centerウィジェットが使用されていることを確認
      expect(find.byType(Center), findsWidgets);
    });
  });
}
