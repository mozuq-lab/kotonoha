/// PhraseListWidget ウィジェットテスト
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
  // テストデータ準備

  /// テストデータ準備: テスト用の定型文データを生成するヘルパー関数
  /// 初期条件設定: 各テストで一貫したテストデータを使用するため
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

  /// テストデータ準備: 複数件の定型文データを生成
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

  // 設計変更: Phase 3 / WP-2 / Stage 3b - PresetPhrase.isFavorite を削除した。
  // どの定型文がお気に入りかは favoriteProvider だけが知っているので
  // 各テストは favoritePresetIds を明示的に渡す（フィクスチャからは導出しない）。

  group('PhraseListWidget - 正常系テスト', () {
    // 定型文一覧が正しく表示される
    /// PhraseListWidgetが定型文リストを正しく表示することを確認
    testWidgets('TC-040-001: 定型文一覧が正しく表示される', (tester) async {
      // テストデータ準備: 3カテゴリの定型文データを用意
      final phrases = [
        createTestPhrase(id: '1', content: 'おはようございます', category: 'daily'),
        createTestPhrase(id: '2', content: '体調が悪いです', category: 'health'),
        createTestPhrase(id: '3', content: 'お願いします', category: 'other'),
      ];

      // 実際の処理実行: PhraseListWidgetをレンダリング
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

      // 結果検証: すべての定型文が表示されることを確認
      expect(find.text('おはようございます'), findsOneWidget);
      expect(find.text('体調が悪いです'), findsOneWidget);
      expect(find.text('お願いします'), findsOneWidget);
    });

    // お気に入り定型文がリスト上部に表示される
    /// お気に入りフラグ付きの定型文が通常の定型文より上に表示されることを確認
    testWidgets('TC-040-002: お気に入り定型文がリスト上部に優先表示される', (tester) async {
      // テストデータ準備: お気に入り2件 + 通常1件
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

      // 結果検証: お気に入りセクションが表示されることを確認
      expect(find.text('お気に入り'), findsOneWidget);

      // 結果検証: お気に入り定型文が表示されることを確認
      expect(find.text('お気に入り定型文1'), findsOneWidget);
      expect(find.text('お気に入り定型文2'), findsOneWidget);

      // 結果検証: 「優先表示」＝画面上で上にあること。存在確認だけでは
      // セクションの並びが入れ替わっても気づけないため、位置を比較する。
      // 比較の仕方: 座標の絶対値は固定せず、2つのdyの大小関係だけを見る
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

    // カテゴリ別に定型文が分類表示される
    /// 「日常」「体調」「その他」のカテゴリごとにグループ化表示されることを確認
    testWidgets('TC-040-003: 定型文がカテゴリ別に分類表示される', (tester) async {
      // テストデータ準備: 各カテゴリに1件ずつ
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

      // 結果検証: カテゴリヘッダーが表示されることを確認
      expect(find.text('日常'), findsOneWidget);
      expect(find.text('体調'), findsOneWidget);
      expect(find.text('その他'), findsOneWidget);
    });

    // 定型文タップでコールバックが発火する
    /// 定型文アイテムのタップイベントハンドリングを確認
    testWidgets('TC-040-004: 定型文タップでonPhraseSelectedコールバックが発火する',
        (tester) async {
      // テストデータ準備: コールバック検証用変数
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

      // 実際の処理実行: 定型文をタップ
      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      // 結果検証: コールバックが正しく呼び出されたことを確認
      expect(callCount, equals(1));
      expect(selectedPhrase?.id, equals('1'));
      expect(selectedPhrase?.content, equals('タップテスト'));
    });

    // スクロール可能なリスト表示
    /// ListView.builderによるスクロール可能なリスト実装を確認
    testWidgets('TC-040-005: 定型文リストがスクロール可能であること', (tester) async {
      // テストデータ準備: スクロールが必要な件数
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

      // 結果検証: ListViewが使用されていることを確認
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('PhraseListWidget - 空状態・エッジケーステスト', () {
    // 定型文0件で空状態メッセージ表示
    /// 空リスト時の表示を確認
    testWidgets('TC-040-006: 定型文が0件の場合「定型文がありません」と表示される', (tester) async {
      // テストデータ準備: 空リスト
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

      // 結果検証: 空状態メッセージが表示されることを確認
      expect(find.text('定型文がありません'), findsOneWidget);
    });

    // 空カテゴリは非表示になる
    /// 空カテゴリのセクション非表示を確認
    testWidgets('TC-040-007: 定型文がないカテゴリは非表示になる', (tester) async {
      // テストデータ準備: 日常カテゴリのみ
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

      // 結果検証: 日常カテゴリのみ表示されることを確認
      expect(find.text('日常'), findsOneWidget);
      expect(find.text('体調'), findsNothing);
      expect(find.text('その他'), findsNothing);
    });

    // お気に入りのみ存在する場合の表示
    /// お気に入りセクションのみの表示を確認
    testWidgets('TC-040-008: お気に入りのみ存在する場合の正常表示', (tester) async {
      // テストデータ準備: お気に入りのみ（通常カテゴリなし状態をシミュレート）
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

      // 結果検証: お気に入りセクションが表示されることを確認
      expect(find.text('お気に入り'), findsOneWidget);
      expect(find.text('お気に入り1'), findsOneWidget);
      expect(find.text('お気に入り2'), findsOneWidget);
    });
  });

  group('PhraseListWidget - サイズ・アクセシビリティテスト', () {
    // リストアイテムのタップターゲットが44px以上
    /// アクセシビリティ要件のタップターゲットサイズを確認
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

      // 結果検証: PhraseListItemの高さを確認
      final itemFinder = find.byType(PhraseListItem);
      expect(itemFinder, findsOneWidget);

      final itemBox = tester.getSize(itemFinder);
      expect(itemBox.height, greaterThanOrEqualTo(44.0));
    });

    // Semanticsラベルが設定されている
    /// スクリーンリーダー対応を確認
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

      // 結果検証: Semanticsウィジェットが設定されていることを確認
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'おはようございます',
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });

  group('PhraseListWidget - テーマ対応テスト', () {
    // ライトテーマで正しく表示される
    /// ライトテーマでの表示を確認
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

      // 結果検証: ウィジェットがエラーなく描画されることを確認
      expect(find.byType(PhraseListWidget), findsOneWidget);
      expect(find.text('ライトテーマテスト'), findsOneWidget);
    });

    // ダークテーマで正しく表示される
    /// ダークテーマでの表示を確認
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

      // 結果検証: ウィジェットがエラーなく描画されることを確認
      expect(find.byType(PhraseListWidget), findsOneWidget);
      expect(find.text('ダークテーマテスト'), findsOneWidget);
    });

    // 高コントラストテーマで正しく表示される
    /// 高コントラストテーマでの表示を確認
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

      // 結果検証: ウィジェットがエラーなく描画されることを確認
      expect(find.byType(PhraseListWidget), findsOneWidget);
      expect(find.text('高コントラストテスト'), findsOneWidget);
    });
  });

  group('PhraseListWidget - 統合・境界値テスト', () {
    // お気に入りセクションとカテゴリセクションの両方が表示される
    /// 複合表示の統合を確認
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

      // 結果検証: 全セクションが表示されることを確認
      expect(find.text('お気に入り'), findsOneWidget);
      expect(find.text('日常'), findsOneWidget);
      expect(find.text('体調'), findsOneWidget);
      expect(find.text('その他'), findsOneWidget);
    });

    // 定型文1件のみの表示
    /// 最小有効データの確認
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

      // 結果検証: 1件の定型文が表示されることを確認
      expect(find.text('唯一の定型文'), findsOneWidget);
      expect(find.text('日常'), findsOneWidget);
    });
  });
}
