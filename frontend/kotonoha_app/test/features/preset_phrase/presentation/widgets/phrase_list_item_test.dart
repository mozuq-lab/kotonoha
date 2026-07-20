/// PhraseListItem ウィジェットテスト
///
/// TASK-0040: 定型文一覧UI実装
/// テストケース: TC-040-011〜TC-040-016, TC-040-033〜TC-040-035
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_list_item.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // ==========================================================================
  // テストデータ準備
  // ==========================================================================

  /// 【テストデータ準備】: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    bool isFavorite = false,
    int displayOrder = 0,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      isFavorite: isFavorite,
      displayOrder: displayOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PhraseListItem - 正常系テスト', () {
    // =========================================================================
    // TC-040-011: 定型文アイテムが正しく表示される
    // =========================================================================
    /// TC-040-011: PhraseListItemが定型文内容を正しく表示することを確認
    ///
    /// 【テスト目的】: アイテム表示の確認
    /// 【テスト内容】: 個別アイテムの表示
    /// 【期待される動作】: contentが表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-101
    /// 優先度: P0 必須
    testWidgets('TC-040-011: PhraseListItemが定型文内容を正しく表示する', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'こんにちは');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
            ),
          ),
        ),
      );

      // 【結果検証】: 定型文内容が表示されることを確認
      expect(find.text('こんにちは'), findsOneWidget); // 【確認内容】: テキスト表示 🔵
    });

    // =========================================================================
    // TC-040-012: お気に入りアイコンが表示される
    // =========================================================================
    /// TC-040-012: お気に入り定型文にお気に入りアイコンが表示されることを確認
    ///
    /// 【テスト目的】: お気に入り表示の確認
    /// 【テスト内容】: お気に入りフラグの視覚的表示
    /// 【期待される動作】: isFavorite=trueの場合、お気に入りアイコンが表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: REQ-105
    /// 優先度: P1 重要
    testWidgets('TC-040-012: お気に入り定型文にお気に入りアイコンが表示される', (tester) async {
      final phrase =
          createTestPhrase(id: '1', content: 'お気に入り', isFavorite: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
            ),
          ),
        ),
      );

      // 【結果検証】: お気に入りアイコンが表示されることを確認
      expect(find.byIcon(Icons.star), findsOneWidget); // 【確認内容】: 星アイコン表示 🟡
    });

    // =========================================================================
    // TC-040-013: タップ時にコールバックが発火する
    // =========================================================================
    /// TC-040-013: PhraseListItemタップでonTapコールバックが発火することを確認
    ///
    /// 【テスト目的】: タップハンドリング確認
    /// 【テスト内容】: タップイベントの伝播
    /// 【期待される動作】: タップでonTapが呼び出される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-004
    /// 優先度: P0 必須
    testWidgets('TC-040-013: PhraseListItemタップでonTapコールバックが発火する',
        (tester) async {
      bool tapped = false;
      final phrase = createTestPhrase(id: '1', content: 'タップテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // 【実際の処理実行】: アイテムをタップ
      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      // 【結果検証】: コールバックが呼び出されたことを確認
      expect(tapped, isTrue); // 【確認内容】: コールバック発火 🔵
    });

    // =========================================================================
    // TC-040-014: 長いテキストが省略表示される
    // =========================================================================
    /// TC-040-014: 長い定型文テキストが省略表示されることを確認
    ///
    /// 【テスト目的】: テキストオーバーフロー処理確認
    /// 【テスト内容】: テキストオーバーフロー処理
    /// 【期待される動作】: 長いテキストが...で省略される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: UI品質
    /// 優先度: P2 低
    testWidgets('TC-040-014: 長い定型文テキストが省略表示される', (tester) async {
      // 【テストデータ準備】: 100文字の長いテキスト
      final longContent = 'あ' * 100;
      final phrase = createTestPhrase(id: '1', content: longContent);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // 幅を制限
              child: PhraseListItem(
                phrase: phrase,
              ),
            ),
          ),
        ),
      );

      // 【結果検証】: Textウィジェットがoverflow設定を持っていることを確認
      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.overflow,
          equals(TextOverflow.ellipsis)); // 【確認内容】: 省略設定 🟡
    });
  });

  group('PhraseListItem - サイズ・アクセシビリティテスト', () {
    // =========================================================================
    // TC-040-015: アイテムの最小高さが44px以上
    // =========================================================================
    /// TC-040-015: PhraseListItemの最小高さが44px以上であることを確認
    ///
    /// 【テスト目的】: サイズ要件確認
    /// 【テスト内容】: アクセシビリティ要件
    /// 【期待される動作】: アイテム高さが44px以上
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-5001, AC-008
    /// 優先度: P0 必須
    testWidgets('TC-040-015: PhraseListItemの最小高さが44px以上', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'あ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
            ),
          ),
        ),
      );

      // 【結果検証】: 最小高さを確認
      final itemSize = tester.getSize(find.byType(PhraseListItem));
      expect(itemSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget)); // 【確認内容】: 44px以上 🔵
    });

    // =========================================================================
    // TC-040-016: アイテムの推奨高さ60px
    // =========================================================================
    /// TC-040-016: PhraseListItemの推奨高さが60pxであることを確認
    ///
    /// 【テスト目的】: 推奨サイズ確認
    /// 【テスト内容】: 推奨サイズ
    /// 【期待される動作】: アイテム高さが60px程度
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: NFR-202
    /// 優先度: P2 低
    testWidgets('TC-040-016: PhraseListItemの推奨高さが60px', (tester) async {
      final phrase = createTestPhrase(id: '1', content: '推奨サイズテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
            ),
          ),
        ),
      );

      // 【結果検証】: 推奨高さを確認
      final itemSize = tester.getSize(find.byType(PhraseListItem));
      expect(
          itemSize.height,
          greaterThanOrEqualTo(
              AppSizes.recommendedTapTarget)); // 【確認内容】: 60px以上 🟡
    });
  });

  group('PhraseListItem - 境界値テスト', () {
    // =========================================================================
    // TC-040-033: 定型文テキストが1文字の場合
    // =========================================================================
    /// TC-040-033: 定型文テキストが最短（1文字）の場合を確認
    ///
    /// 【テスト目的】: 最短テキストの確認
    /// 【テスト内容】: 1文字でも正しく表示
    /// 【期待される動作】: 「あ」が正しく表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: UI品質
    /// 優先度: P2 低
    testWidgets('TC-040-033: 定型文テキストが最短（1文字）の場合', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'あ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
            ),
          ),
        ),
      );

      // 【結果検証】: 1文字が表示されることを確認
      expect(find.text('あ'), findsOneWidget); // 【確認内容】: 1文字表示 🟡
    });

    // =========================================================================
    // TC-040-034: 定型文テキストが500文字（上限値）の場合
    // =========================================================================
    /// TC-040-034: 定型文テキストが500文字（上限値）の場合を確認
    ///
    /// 【テスト目的】: 上限テキストの確認
    /// 【テスト内容】: 上限テキストでも正しく省略表示
    /// 【期待される動作】: テキストが省略表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: EDGE-102
    /// 優先度: P2 低
    testWidgets('TC-040-034: 定型文テキストが500文字（上限値）の場合', (tester) async {
      // 【テストデータ準備】: 500文字のテキスト
      final longContent = 'あ' * 500;
      final phrase = createTestPhrase(id: '1', content: longContent);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: PhraseListItem(
                phrase: phrase,
              ),
            ),
          ),
        ),
      );

      // 【結果検証】: ウィジェットがエラーなく表示されることを確認
      expect(
          find.byType(PhraseListItem), findsOneWidget); // 【確認内容】: 500文字でも表示 🟡
    });
  });

  group('PhraseListItem - 入力欄へボタンテスト', () {
    /// 【REQ-102対応】: 定型文タップ=即時読み上げのみだったところに、
    /// 入力欄へ入れて編集する動線として「入力欄へ」ボタンを追加した。
    testWidgets('「入力欄へ」ラベルが表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: '入力欄へテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
            ),
          ),
        ),
      );

      expect(find.text('入力欄へ'), findsOneWidget);
    });
  });

  group('PhraseListItem - お気に入り切り替えテスト', () {
    // =========================================================================
    // TC-040-035: お気に入り切り替えコールバックが発火する
    // =========================================================================
    /// TC-040-035: お気に入りアイコンタップでonFavoriteToggleが発火することを確認
    ///
    /// 【テスト目的】: お気に入り切り替え確認
    /// 【テスト内容】: お気に入り切り替え機能
    /// 【期待される動作】: お気に入りアイコンタップでコールバック発火
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: REQ-105
    /// 優先度: P1 重要
    testWidgets('TC-040-035: お気に入りアイコンタップでonFavoriteToggleが発火する',
        (tester) async {
      bool favoriteToggled = false;
      final phrase =
          createTestPhrase(id: '1', content: 'お気に入りテスト', isFavorite: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              onFavoriteToggle: () => favoriteToggled = true,
            ),
          ),
        ),
      );

      // 【実際の処理実行】: お気に入りアイコンをタップ
      // お気に入りでない場合はstar_borderアイコン
      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      // 【結果検証】: コールバックが呼び出されたことを確認
      expect(favoriteToggled, isTrue); // 【確認内容】: お気に入り切り替えコールバック 🟡
    });
  });
}
