/// PhraseListWidget ウィジェットテスト
///
/// TASK-0040: 定型文一覧UI実装
/// テストケース: TC-040-001〜TC-040-010, TC-040-024〜TC-040-032
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_list_widget.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_widget.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // ==========================================================================
  // テストデータ準備
  // ==========================================================================

  /// 【テストデータ準備】: テスト用の定型文データを生成するヘルパー関数
  /// 【初期条件設定】: 各テストで一貫したテストデータを使用するため
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    int displayOrder = 0,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      displayOrder: displayOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 【テストデータ準備】: 複数件の定型文データを生成
  List<PresetPhrase> createTestPhrases(int count, {String? category}) {
    return List.generate(
      count,
      (i) => createTestPhrase(
        id: 'test_$i',
        content: 'テスト定型文$i',
        category: category ??
            (i % 3 == 0 ? 'daily' : (i % 3 == 1 ? 'health' : 'other')),
      ),
    );
  }

  // 【設計変更】: Phase 3 / WP-2 / Stage 3b - PresetPhrase.isFavorite を削除した。
  // どの定型文がお気に入りかは favoriteProvider だけが知っているので、
  // 各テストは favoritePresetIds を明示的に渡す（フィクスチャからは導出しない）。

  group('PhraseListWidget - 正常系テスト', () {
    // =========================================================================
    // TC-040-001: 定型文一覧が正しく表示される
    // =========================================================================
    /// TC-040-001: PhraseListWidgetが定型文リストを正しく表示することを確認
    ///
    /// 【テスト目的】: 基本的な一覧表示機能の確認
    /// 【テスト内容】: 複数の定型文が渡された場合に、すべて表示されること
    /// 【期待される動作】: 3件の定型文がすべて画面上に表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-101
    /// 優先度: P0 必須
    testWidgets('TC-040-001: 定型文一覧が正しく表示される', (tester) async {
      // 【テストデータ準備】: 3カテゴリの定型文データを用意
      final phrases = [
        createTestPhrase(id: '1', content: 'おはようございます', category: 'daily'),
        createTestPhrase(id: '2', content: '体調が悪いです', category: 'health'),
        createTestPhrase(id: '3', content: 'お願いします', category: 'other'),
      ];

      // 【実際の処理実行】: PhraseListWidgetをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: すべての定型文が表示されることを確認
      expect(
          find.text('おはようございます'), findsOneWidget); // 【確認内容】: 日常カテゴリの定型文が表示 🔵
      expect(find.text('体調が悪いです'), findsOneWidget); // 【確認内容】: 体調カテゴリの定型文が表示 🔵
      expect(find.text('お願いします'), findsOneWidget); // 【確認内容】: その他カテゴリの定型文が表示 🔵
    });

    // =========================================================================
    // TC-040-002: お気に入り定型文がリスト上部に表示される
    // =========================================================================
    /// TC-040-002: お気に入りフラグ付きの定型文が通常の定型文より上に表示されることを確認
    ///
    /// 【テスト目的】: お気に入り優先表示の確認
    /// 【テスト内容】: お気に入りと通常の定型文が混在した場合の表示順序
    /// 【期待される動作】: お気に入りセクションがカテゴリセクションより先に表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-105
    /// 優先度: P0 必須
    testWidgets('TC-040-002: お気に入り定型文がリスト上部に優先表示される', (tester) async {
      // 【テストデータ準備】: お気に入り2件 + 通常1件
      final phrases = [
        createTestPhrase(id: '1', content: '通常定型文', category: 'daily'),
        createTestPhrase(id: '2', content: 'お気に入り定型文1', category: 'daily'),
        createTestPhrase(id: '3', content: 'お気に入り定型文2', category: 'health'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{'2', '3'},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: お気に入りセクションが表示されることを確認
      expect(
          find.text('お気に入り'), findsOneWidget); // 【確認内容】: お気に入りセクションヘッダーが表示 🔵

      // 【結果検証】: お気に入り定型文が表示されることを確認
      expect(find.text('お気に入り定型文1'), findsOneWidget); // 【確認内容】: お気に入り1が表示 🔵
      expect(find.text('お気に入り定型文2'), findsOneWidget); // 【確認内容】: お気に入り2が表示 🔵

      // 【結果検証】: 「優先表示」＝画面上で上にあること。存在確認だけでは
      // セクションの並びが入れ替わっても気づけないため、位置を比較する。
      // 【比較の仕方】: 座標の絶対値は固定せず、2つのdyの大小関係だけを見る 🔵
      expect(
        tester.getTopLeft(find.text('お気に入り')).dy,
        lessThan(tester.getTopLeft(find.text('日常')).dy),
        reason: 'REQ-105: お気に入りセクションはカテゴリセクションより上に出る',
      );
      expect(
        tester.getTopLeft(find.text('お気に入り定型文1')).dy,
        lessThan(tester.getTopLeft(find.text('通常定型文')).dy),
        reason: 'REQ-105: お気に入り定型文は通常の定型文より上に出る',
      );
    });

    // =========================================================================
    // TC-040-003: カテゴリ別に定型文が分類表示される
    // =========================================================================
    /// TC-040-003: 「日常」「体調」「その他」のカテゴリごとにグループ化表示されることを確認
    ///
    /// 【テスト目的】: カテゴリ分類機能の確認
    /// 【テスト内容】: 各カテゴリのセクションヘッダーと定型文が表示されること
    /// 【期待される動作】: 3つのカテゴリセクションが正しい順序で表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-003: 定型文がカテゴリ別に分類表示される', (tester) async {
      // 【テストデータ準備】: 各カテゴリに1件ずつ
      final phrases = [
        createTestPhrase(id: '1', content: '日常の挨拶', category: 'daily'),
        createTestPhrase(id: '2', content: '体調の報告', category: 'health'),
        createTestPhrase(id: '3', content: 'その他の連絡', category: 'other'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: カテゴリヘッダーが表示されることを確認
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: 日常カテゴリヘッダー 🔵
      expect(find.text('体調'), findsOneWidget); // 【確認内容】: 体調カテゴリヘッダー 🔵
      expect(find.text('その他'), findsOneWidget); // 【確認内容】: その他カテゴリヘッダー 🔵
    });

    // =========================================================================
    // TC-040-004: 定型文タップでコールバックが発火する
    // =========================================================================
    /// TC-040-004: 定型文アイテムのタップイベントハンドリングを確認
    ///
    /// 【テスト目的】: タップインタラクションの確認
    /// 【テスト内容】: 定型文タップ時にonPhraseSelectedが呼び出されること
    /// 【期待される動作】: コールバックが1回呼び出され、正しい定型文が渡される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-004
    /// 優先度: P0 必須
    testWidgets('TC-040-004: 定型文タップでonPhraseSelectedコールバックが発火する',
        (tester) async {
      // 【テストデータ準備】: コールバック検証用変数
      PresetPhrase? selectedPhrase;
      int callCount = 0;

      final testPhrase = createTestPhrase(id: '1', content: 'タップテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: [testPhrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (p) {
                selectedPhrase = p;
                callCount++;
              },
            ),
          ),
        ),
      );

      // 【実際の処理実行】: 定型文をタップ
      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      // 【結果検証】: コールバックが正しく呼び出されたことを確認
      expect(callCount, equals(1)); // 【確認内容】: コールバックが1回呼び出された 🔵
      expect(selectedPhrase?.id, equals('1')); // 【確認内容】: 正しい定型文が渡された 🔵
      expect(
          selectedPhrase?.content, equals('タップテスト')); // 【確認内容】: contentが一致 🔵
    });

    // =========================================================================
    // TC-040-005: スクロール可能なリスト表示
    // =========================================================================
    /// TC-040-005: ListView.builderによるスクロール可能なリスト実装を確認
    ///
    /// 【テスト目的】: スクロール機能の確認
    /// 【テスト内容】: 定型文が多数ある場合にスクロール可能であること
    /// 【期待される動作】: スクロール後に下部の定型文が表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: NFR-004
    /// 優先度: P1 重要
    testWidgets('TC-040-005: 定型文リストがスクロール可能であること', (tester) async {
      // 【テストデータ準備】: スクロールが必要な件数
      final phrases = createTestPhrases(20);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: ListViewが使用されていることを確認
      expect(
          find.byType(ListView), findsOneWidget); // 【確認内容】: ListViewが使用されている 🟡
    });
  });

  group('PhraseListWidget - 空状態・エッジケーステスト', () {
    // =========================================================================
    // TC-040-006: 定型文0件で空状態メッセージ表示
    // =========================================================================
    /// TC-040-006: 空リスト時の表示を確認
    ///
    /// 【テスト目的】: 空状態の適切な表示確認
    /// 【テスト内容】: 定型文が0件の場合にPhraseEmptyStateが表示されること
    /// 【期待される動作】: 「定型文がありません」メッセージが表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-005, EDGE-104
    /// 優先度: P0 必須
    testWidgets('TC-040-006: 定型文が0件の場合「定型文がありません」と表示される', (tester) async {
      // 【テストデータ準備】: 空リスト
      final phrases = <PresetPhrase>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: 空状態メッセージが表示されることを確認
      expect(find.text('定型文がありません'), findsOneWidget); // 【確認内容】: 空状態メッセージ 🔵
    });

    // =========================================================================
    // TC-040-007: 空カテゴリは非表示になる
    // =========================================================================
    /// TC-040-007: 空カテゴリのセクション非表示を確認
    ///
    /// 【テスト目的】: 空カテゴリの非表示確認
    /// 【テスト内容】: 定型文が0件のカテゴリセクションは表示されないこと
    /// 【期待される動作】: 「日常」のみ表示、「体調」「その他」は非表示
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-006, EDGE-204
    /// 優先度: P1 重要
    testWidgets('TC-040-007: 定型文がないカテゴリは非表示になる', (tester) async {
      // 【テストデータ準備】: 日常カテゴリのみ
      final phrases = [
        createTestPhrase(id: '1', content: '日常1', category: 'daily'),
        createTestPhrase(id: '2', content: '日常2', category: 'daily'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: 日常カテゴリのみ表示されることを確認
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: 日常カテゴリは表示 🔵
      expect(find.text('体調'), findsNothing); // 【確認内容】: 体調カテゴリは非表示 🔵
      expect(find.text('その他'), findsNothing); // 【確認内容】: その他カテゴリは非表示 🔵
    });

    // =========================================================================
    // TC-040-008: お気に入りのみ存在する場合の表示
    // =========================================================================
    /// TC-040-008: お気に入りセクションのみの表示を確認
    ///
    /// 【テスト目的】: お気に入りのみ表示の確認
    /// 【テスト内容】: お気に入りのみでカテゴリセクションが空の場合
    /// 【期待される動作】: お気に入りセクションのみ表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: REQ-105
    /// 優先度: P2 低
    testWidgets('TC-040-008: お気に入りのみ存在する場合の正常表示', (tester) async {
      // 【テストデータ準備】: お気に入りのみ（通常カテゴリなし状態をシミュレート）
      final phrases = [
        createTestPhrase(id: '1', content: 'お気に入り1'),
        createTestPhrase(id: '2', content: 'お気に入り2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{'1', '2'},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: お気に入りセクションが表示されることを確認
      expect(find.text('お気に入り'), findsOneWidget); // 【確認内容】: お気に入りセクション 🟡
      expect(find.text('お気に入り1'), findsOneWidget); // 【確認内容】: お気に入り1表示 🟡
      expect(find.text('お気に入り2'), findsOneWidget); // 【確認内容】: お気に入り2表示 🟡
    });
  });

  group('PhraseListWidget - サイズ・アクセシビリティテスト', () {
    // =========================================================================
    // TC-040-009: リストアイテムのタップターゲットが44px以上
    // =========================================================================
    /// TC-040-009: アクセシビリティ要件のタップターゲットサイズを確認
    ///
    /// 【テスト目的】: アクセシビリティ要件の確認
    /// 【テスト内容】: 各アイテムの高さが44px以上であること
    /// 【期待される動作】: タップターゲットが44px以上
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-5001, AC-008
    /// 優先度: P0 必須
    testWidgets('TC-040-009: リストアイテムのタップターゲットサイズが44px以上', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'サイズテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: [phrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: PhraseListItemの高さを確認
      final itemFinder = find.byType(PhraseListItem);
      expect(itemFinder, findsOneWidget);

      final itemBox = tester.getSize(itemFinder);
      expect(itemBox.height, greaterThanOrEqualTo(44.0)); // 【確認内容】: 高さ44px以上 🔵
    });

    // =========================================================================
    // TC-040-010: Semanticsラベルが設定されている
    // =========================================================================
    /// TC-040-010: スクリーンリーダー対応を確認
    ///
    /// 【テスト目的】: スクリーンリーダー対応確認
    /// 【テスト内容】: 各アイテムにSemanticsラベルが付与されること
    /// 【期待される動作】: Semanticsラベルに定型文の内容が含まれる
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: アクセシビリティ
    /// 優先度: P1 重要
    testWidgets('TC-040-010: 定型文アイテムにSemanticsラベルが設定されている', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'おはようございます');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: [phrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: Semanticsウィジェットが設定されていることを確認
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'おはようございます',
      );
      expect(semanticsFinder, findsOneWidget); // 【確認内容】: Semanticsラベル 🟡
    });
  });

  group('PhraseListWidget - テーマ対応テスト', () {
    // =========================================================================
    // TC-040-024: ライトテーマで正しく表示される
    // =========================================================================
    /// TC-040-024: ライトテーマでの表示を確認
    ///
    /// 【テスト目的】: テーマ適用確認
    /// 【テスト内容】: ライトテーマの配色で表示されること
    /// 【期待される動作】: ライトテーマの配色が適用される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-803, AC-009
    /// 優先度: P1 重要
    testWidgets('TC-040-024: ライトテーマで正しく表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'ライトテーマテスト');

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: PhraseListWidget(
              phrases: [phrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: ウィジェットがエラーなく描画されることを確認
      expect(find.byType(PhraseListWidget),
          findsOneWidget); // 【確認内容】: ライトテーマで描画 🔵
      expect(find.text('ライトテーマテスト'), findsOneWidget); // 【確認内容】: テキスト表示 🔵
    });

    // =========================================================================
    // TC-040-025: ダークテーマで正しく表示される
    // =========================================================================
    /// TC-040-025: ダークテーマでの表示を確認
    ///
    /// 【テスト目的】: テーマ適用確認
    /// 【テスト内容】: ダークテーマの配色で表示されること
    /// 【期待される動作】: ダークテーマの配色が適用される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-803, AC-009
    /// 優先度: P1 重要
    testWidgets('TC-040-025: ダークテーマで正しく表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'ダークテーマテスト');

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: PhraseListWidget(
              phrases: [phrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: ウィジェットがエラーなく描画されることを確認
      expect(find.byType(PhraseListWidget),
          findsOneWidget); // 【確認内容】: ダークテーマで描画 🔵
      expect(find.text('ダークテーマテスト'), findsOneWidget); // 【確認内容】: テキスト表示 🔵
    });

    // =========================================================================
    // TC-040-026: 高コントラストテーマで正しく表示される
    // =========================================================================
    /// TC-040-026: 高コントラストテーマでの表示を確認
    ///
    /// 【テスト目的】: テーマ適用確認
    /// 【テスト内容】: 高コントラストの配色で表示されること
    /// 【期待される動作】: 高コントラストの配色が適用される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-803, AC-009
    /// 優先度: P1 重要
    testWidgets('TC-040-026: 高コントラストテーマで正しく表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: '高コントラストテスト');

      await tester.pumpWidget(
        MaterialApp(
          theme: highContrastTheme,
          home: Scaffold(
            body: PhraseListWidget(
              phrases: [phrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: ウィジェットがエラーなく描画されることを確認
      expect(find.byType(PhraseListWidget),
          findsOneWidget); // 【確認内容】: 高コントラストで描画 🔵
      expect(find.text('高コントラストテスト'), findsOneWidget); // 【確認内容】: テキスト表示 🔵
    });
  });

  group('PhraseListWidget - 統合・境界値テスト', () {
    // =========================================================================
    // TC-040-029: お気に入りセクションとカテゴリセクションの両方が表示される
    // =========================================================================
    /// TC-040-029: 複合表示の統合を確認
    ///
    /// 【テスト目的】: 統合動作確認
    /// 【テスト内容】: お気に入り→日常→体調→その他の順で表示されること
    /// 【期待される動作】: 正しい順序で全セクションが表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-105, REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-029: お気に入りとカテゴリの両方が正しい順序で表示される', (tester) async {
      final phrases = [
        createTestPhrase(id: '1', content: 'お気に入り1', category: 'daily'),
        createTestPhrase(id: '2', content: 'お気に入り2', category: 'health'),
        createTestPhrase(id: '3', content: '日常1', category: 'daily'),
        createTestPhrase(id: '4', content: '体調1', category: 'health'),
        createTestPhrase(id: '5', content: 'その他1', category: 'other'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{'1', '2'},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: 全セクションが表示されることを確認
      expect(find.text('お気に入り'), findsOneWidget); // 【確認内容】: お気に入りセクション 🔵
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: 日常セクション 🔵
      expect(find.text('体調'), findsOneWidget); // 【確認内容】: 体調セクション 🔵
      expect(find.text('その他'), findsOneWidget); // 【確認内容】: その他セクション 🔵
    });

    // =========================================================================
    // TC-040-031: 定型文1件のみの表示
    // =========================================================================
    /// TC-040-031: 最小有効データの確認
    ///
    /// 【テスト目的】: 最小データの確認
    /// 【テスト内容】: 1件でも正しく表示されること
    /// 【期待される動作】: 1件の定型文が正しく表示される
    ///
    /// 信頼性レベル: 🟡 黄信号
    /// 関連要件: REQ-101
    /// 優先度: P1 重要
    testWidgets('TC-040-031: 定型文が1件のみの場合の表示', (tester) async {
      final phrases = [
        createTestPhrase(id: '1', content: '唯一の定型文', category: 'daily'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListWidget(
              phrases: phrases,
              favoritePresetIds: const <String>{},
              onPhraseSelected: (_) {},
            ),
          ),
        ),
      );

      // 【結果検証】: 1件の定型文が表示されることを確認
      expect(find.text('唯一の定型文'), findsOneWidget); // 【確認内容】: 1件表示 🟡
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: カテゴリも表示 🟡
    });
  });
}
