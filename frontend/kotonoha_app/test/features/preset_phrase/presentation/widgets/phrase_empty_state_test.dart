/// PhraseEmptyState ウィジェットテスト
///
/// TASK-0040: 定型文一覧UI実装
/// テストケース: TC-040-022〜TC-040-023
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_empty_state.dart
///
/// TDD Redフェーズ: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_empty_state.dart';

void main() {
  group('PhraseEmptyState - 正常系テスト', () {
    // =========================================================================
    // TC-040-022: 空状態メッセージが表示される
    // =========================================================================
    /// TC-040-022: PhraseEmptyStateが空状態メッセージを表示することを確認
    ///
    /// テスト目的: 空状態UI確認
    /// テスト内容: 空状態のUI表示
    /// 期待される動作: 「定型文がありません」メッセージが表示される
    ///
    /// 信頼性レベル: 青信号
    /// 関連要件: AC-005, EDGE-104
    /// 優先度: P0 必須
    testWidgets('TC-040-022: PhraseEmptyStateが空状態メッセージを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(),
          ),
        ),
      );

      // 結果検証: デフォルトメッセージが表示されることを確認
      expect(find.text('定型文がありません'), findsOneWidget); // 確認内容: デフォルトメッセージ
    });

    // =========================================================================
    // TC-040-023: 空状態アイコンが表示される
    // =========================================================================
    /// TC-040-023: PhraseEmptyStateにアイコンが表示されることを確認
    ///
    /// テスト目的: 視覚的要素確認
    /// テスト内容: 空状態の視覚的表示
    /// 期待される動作: アイコン（インフォメーションなど）が表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: UX
    /// 優先度: P2 低
    testWidgets('TC-040-023: PhraseEmptyStateにアイコンが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(),
          ),
        ),
      );

      // 結果検証: アイコンが表示されることを確認
      expect(find.byType(Icon), findsOneWidget); // 確認内容: アイコン表示
    });

    // =========================================================================
    // カスタムメッセージが表示される
    // =========================================================================
    /// カスタムメッセージが正しく表示されることを確認
    ///
    /// テスト目的: カスタマイズ確認
    /// テスト内容: カスタムメッセージの表示
    /// 期待される動作: 指定したメッセージが表示される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: UX
    /// 優先度: P2 低
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
      expect(find.text('カスタムメッセージ'), findsOneWidget); // 確認内容: カスタムメッセージ
    });
  });

  group('PhraseEmptyState - レイアウトテスト', () {
    // =========================================================================
    // 中央配置で表示される
    // =========================================================================
    /// 空状態ウィジェットが中央に配置されることを確認
    ///
    /// テスト目的: レイアウト確認
    /// テスト内容: 中央配置の確認
    /// 期待される動作: コンテンツが中央に配置される
    ///
    /// 信頼性レベル: 黄信号
    /// 関連要件: UX
    /// 優先度: P2 低
    testWidgets('空状態ウィジェットが中央に配置される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhraseEmptyState(),
          ),
        ),
      );

      // 結果検証: Centerウィジェットが使用されていることを確認
      expect(find.byType(Center), findsWidgets); // 確認内容: 中央配置
    });
  });
}
