/// AI変換ローディング・タイマー テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_loading.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/politeness_level_selector.dart';

void main() {
  group('TASK-0068: AI変換ローディング・タイマーテスト', () {
    // ローディングメッセージ表示テスト
    group('ローディングメッセージ表示テスト', () {
      /// 3秒超過時にローディングメッセージが表示される
      testWidgets('TC-068-005: 3秒超過時にローディングメッセージが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ローディング状態のウィジェットを構築
        // 初期条件設定: AI変換処理開始直後
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AIConversionLoading(
                  extendedMessageDelaySeconds: 1, // テスト用に1秒に短縮
                ),
              ),
            ),
          ),
        );

        // 初期状態: メッセージ非表示
        expect(find.text('AI変換中...'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // When: 時間経過シミュレート: 1秒以上経過
        // 操作内容: タイマーを進めて経過をシミュレート
        await tester.pump(const Duration(seconds: 2));

        // Then: 結果検証: ローディングメッセージが表示されることを確認
        // 「3秒超過時のローディング表示」に基づく
        expect(find.text('AI変換中...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      /// 3秒ジャストでのローディングメッセージ表示
      testWidgets('TC-068-013: 処理開始から3秒ジャストでローディングメッセージが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: タイマー付きローディングウィジェットを構築
        // 初期条件設定: 開始時刻を記録
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AIConversionLoading(
                  extendedMessageDelaySeconds: 3, // 本番と同じ3秒
                ),
              ),
            ),
          ),
        );

        // 2秒時点: メッセージ非表示
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('AI変換中...'), findsNothing);

        // When: 時間経過シミュレート: ちょうど3秒経過（残り1秒）
        await tester.pump(const Duration(seconds: 1));

        // Then: 結果検証: 3秒ジャストでメッセージが表示されることを確認
        // 「3秒閾値」に基づく
        expect(find.text('AI変換中...'), findsOneWidget);
      });

      /// ローディングタイマーが正しく動作する
      testWidgets('TC-068-016: ローディングタイマーが正しく動作することを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: タイマーロジックのテスト用変数
        // 初期条件設定: タイマー開始
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AIConversionLoading(
                  extendedMessageDelaySeconds: 3,
                ),
              ),
            ),
          ),
        );

        // 初期状態
        expect(find.text('AI変換中...'), findsNothing);

        // 1秒経過
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('AI変換中...'), findsNothing);

        // 2秒経過
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('AI変換中...'), findsNothing);

        // 3秒経過
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('AI変換中...'), findsOneWidget);
      });
    });

    // 丁寧さレベル全パターンテスト
    group('丁寧さレベル選択テスト', () {
      /// 各丁寧さレベルが正しく選択・表示される
      testWidgets('TC-068-014: 全3種類の丁寧さレベルが選択可能なことを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 丁寧さレベル選択ウィジェットを構築
        // 初期条件設定: 初期選択は「普通」
        PolitenessLevel selectedLevel = PolitenessLevel.normal;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return PolitenessLevelSelector(
                    selectedLevel: selectedLevel,
                    onLevelChanged: (level) {
                      setState(() => selectedLevel = level);
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 初期状態: 「普通」が選択されている
        expect(selectedLevel, PolitenessLevel.normal);

        // When/Then 1: カジュアル選択
        await tester.tap(find.text('カジュアル'));
        await tester.pumpAndSettle();
        expect(selectedLevel, PolitenessLevel.casual);

        // When/Then 2: 丁寧選択
        await tester.tap(find.text('丁寧'));
        await tester.pumpAndSettle();
        expect(selectedLevel, PolitenessLevel.polite);

        // When/Then 3: 普通選択（戻る）
        await tester.tap(find.text('普通'));
        await tester.pumpAndSettle();
        expect(selectedLevel, PolitenessLevel.normal);
      });
    });

    // Dispose処理テスト
    group('リソース管理テスト', () {
      /// ウィジェットが正しくDisposeされる
      testWidgets('TC-068-017: ウィジェット破棄時にリソースがクリーンアップされることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ローディングウィジェットをマウント
        // 初期条件設定: ウィジェットがマウントされた状態
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AIConversionLoading(),
              ),
            ),
          ),
        );

        await tester.pump();

        // ウィジェットがマウントされていることを確認
        expect(find.byType(AIConversionLoading), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // When: ウィジェット破棄: 別のウィジェットに置き換えてアンマウント
        // 操作内容: ウィジェットを破棄
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(), // 空のウィジェット
            ),
          ),
        );

        await tester.pump();

        // Then: 結果検証: ウィジェットが正しく破棄されることを確認
        // メモリリークがないこと
        // 注: 実際のテストでは、タイマーがキャンセルされたことを確認
        expect(find.byType(AIConversionLoading), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });
}
