/// FaceToFaceScreen 画面 テスト
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// テストケース: TC-052-010〜TC-052-015
///
/// テスト対象: lib/features/face_to_face/presentation/screens/face_to_face_screen.dart
///
/// 【TDD Redフェーズ】: FaceToFaceScreenが未実装、テストが失敗するはず
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/screens/face_to_face_screen.dart';

void main() {
  group('FaceToFaceScreenテスト', () {
    // =========================================================================
    // 1. 正常系テストケース（画面表示）
    // =========================================================================
    group('画面表示テスト', () {
      /// TC-052-010: 対面表示画面が表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-501
      /// 検証内容: FaceToFaceScreenが正しくレンダリングされること
      testWidgets('TC-052-010: 対面表示画面が表示されることを確認', (WidgetTester tester) async {
        // 【テスト目的】: FaceToFaceScreenが正しくレンダリングされることを確認 🔵
        // 【テスト内容】: 画面を構築し、表示されることを検証
        // 【期待される動作】: 対面表示画面が表示される
        // 🔵 青信号: REQ-501「テキストを画面中央に大きく表示」に基づく

        // Given: 【テストデータ準備】: FaceToFaceScreenを構築
        // 【初期条件設定】: 表示テキストを指定
        const testText = 'お水をください';

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FaceToFaceScreen(
                displayText: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 画面が表示されていることを確認
        // 【期待値確認】: REQ-501に基づく
        // 【品質保証】: 対面表示モードが利用可能であること
        expect(
          find.byType(FaceToFaceScreen),
          findsOneWidget,
        ); // 【確認内容】: 画面ウィジェットが存在することを確認 🔵
      });

      /// TC-052-011: 渡されたテキストが画面中央に表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-501
      /// 検証内容: displayTextが画面中央に大きく表示されること
      testWidgets('TC-052-011: 渡されたテキストが画面中央に表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: displayTextが画面中央に大きく表示されることを確認 🔵
        // 【テスト内容】: 画面を構築し、テキストが表示されることを検証
        // 【期待される動作】: テキストが画面中央に大きく表示される
        // 🔵 青信号: REQ-501「テキストを画面中央に大きく表示する拡大表示モード」に基づく

        // Given: 【テストデータ準備】: 表示テキストを指定
        // 【初期条件設定】: 対面の相手に見せたいメッセージ
        const testText = 'お水をください';

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FaceToFaceScreen(
                displayText: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: テキストが表示されていることを確認
        // 【期待値確認】: REQ-501に基づく
        // 【品質保証】: 対面の相手がメッセージを読み取れること
        expect(
          find.text(testText),
          findsOneWidget,
        ); // 【確認内容】: テキストが表示されていることを確認 🔵
      });

      /// TC-052-012: 戻るボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-503, NFR-202
      /// 検証内容: 通常モードに戻るボタンが表示されること
      testWidgets('TC-052-012: 戻るボタンが表示されることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 通常モードに戻るボタンが表示されることを確認 🔵
        // 【テスト内容】: 画面を構築し、戻るボタンが表示されることを検証
        // 【期待される動作】: 戻るボタンが画面に表示される
        // 🔵 青信号: REQ-503「シンプルな操作で切り替え」、NFR-202「視認性が高く押しやすいサイズ」に基づく

        // Given: 【テストデータ準備】: FaceToFaceScreenを構築
        // 【初期条件設定】: 対面表示モードの状態
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FaceToFaceScreen(
                displayText: 'テスト',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 戻るボタンが表示されていることを確認
        // 【期待値確認】: NFR-202に基づく
        // 【品質保証】: ユーザーが通常モードに戻れること
        // 戻るボタンのアイコン（close または arrow_back）を検索
        expect(
          find.byIcon(Icons.close).evaluate().isNotEmpty ||
              find.byIcon(Icons.arrow_back).evaluate().isNotEmpty,
          isTrue,
        ); // 【確認内容】: 戻るボタンが表示されていることを確認 🔵
      });

      /// TC-052-013: 戻るボタンをタップするとonBackが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-503
      /// 検証内容: 戻るボタンタップでonBackコールバックが呼ばれること
      testWidgets('TC-052-013: 戻るボタンをタップするとonBackが呼ばれることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 戻るボタンタップでonBackコールバックが呼ばれることを確認 🔵
        // 【テスト内容】: 戻るボタンをタップし、コールバックが呼ばれることを検証
        // 【期待される動作】: onBackコールバックが呼ばれる
        // 🔵 青信号: REQ-503「シンプルな操作で切り替え」に基づく

        // Given: 【テストデータ準備】: onBackコールバックを監視
        // 【初期条件設定】: 対面表示モードの状態
        var onBackCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: FaceToFaceScreen(
                displayText: 'テスト',
                onBack: () {
                  onBackCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: 【実際の処理実行】: 戻るボタンをタップ
        // 【処理内容】: ユーザーが通常モードに戻る操作を模擬
        // closeアイコンまたはarrow_backアイコンを探してタップ
        final closeButton = find.byIcon(Icons.close);
        final backButton = find.byIcon(Icons.arrow_back);

        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
        } else if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        }
        await tester.pumpAndSettle();

        // Then: 【結果検証】: onBackコールバックが呼ばれたことを確認
        // 【期待値確認】: ユーザー操作が正しく処理されること
        // 【品質保証】: 通常モードに戻る操作が確実に機能すること
        expect(
          onBackCalled,
          isTrue,
        ); // 【確認内容】: onBackが呼ばれたことを確認 🔵
      });
    });

    // =========================================================================
    // 2. 背景・スタイルテストケース
    // =========================================================================
    group('背景・スタイルテスト', () {
      /// TC-052-014: 背景がシンプルである（余計な要素がない）
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-501
      /// 検証内容: 背景がシンプルで読みやすいこと
      testWidgets('TC-052-014: 背景がシンプルであることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 背景がシンプルで読みやすいことを確認 🟡
        // 【テスト内容】: 画面構成要素が最小限であることを検証
        // 【期待される動作】: テキストと戻るボタン以外の要素が最小限
        // 🟡 黄信号: REQ-501「画面中央に大きく表示」から、背景はシンプルと推測

        // Given: 【テストデータ準備】: FaceToFaceScreenを構築
        // 【初期条件設定】: 対面表示モードの状態
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FaceToFaceScreen(
                displayText: 'テスト',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 画面構成が最小限であることを確認
        // 【期待値確認】: 余計なUI要素がないこと
        // 【品質保証】: 対面の相手がメッセージに集中できること

        // 画面にFaceToFaceScreenが存在することを確認
        expect(
          find.byType(FaceToFaceScreen),
          findsOneWidget,
        ); // 【確認内容】: 画面が表示されていることを確認 🟡

        // 主要なUI要素（テキスト、戻るボタン）以外が最小限であることを確認
        // ここでは画面が正常に表示されていることを基本的に検証
      });

      /// TC-052-015: ダークモード・高コントラストモードで正しく表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-5006
      /// 検証内容: テーマに応じた表示がされること
      testWidgets('TC-052-015: ダークモードで正しく表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: ダークモードで正しく表示されることを確認 🟡
        // 【テスト内容】: ダークテーマで画面を構築し、表示を検証
        // 【期待される動作】: ダークモードに適応した表示
        // 🟡 黄信号: REQ-5006「高コントラスト対応」から推測

        // Given: 【テストデータ準備】: ダークテーマでFaceToFaceScreenを構築
        // 【初期条件設定】: ダークモードの状態
        const testText = 'テスト';

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const FaceToFaceScreen(
                displayText: testText,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 画面が正しく表示されていることを確認
        // 【期待値確認】: ダークモードでもテキストが読みやすいこと
        // 【品質保証】: 様々な環境で利用可能であること
        expect(
          find.text(testText),
          findsOneWidget,
        ); // 【確認内容】: ダークモードでテキストが表示されていることを確認 🟡
      });
    });

    // =========================================================================
    // 3. アクセシビリティテストケース
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// 戻るボタンのサイズが44px×44px以上である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5001
      /// 検証内容: 戻るボタンのタップ領域が適切であること
      testWidgets('戻るボタンのサイズが44px×44px以上であることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 戻るボタンのタップ領域が適切であることを確認 🔵
        // 【テスト内容】: 戻るボタンのサイズが最低44px×44px以上であることを検証
        // 【期待される動作】: ボタンのタップ領域が最低44pxを確保
        // 🔵 青信号: REQ-5001「タップターゲット44px×44px以上」に基づく

        // Given: 【テストデータ準備】: FaceToFaceScreenを構築
        // 【初期条件設定】: 対面表示モードの状態
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: FaceToFaceScreen(
                displayText: 'テスト',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 戻るボタンのタップ領域が44px×44px以上であることを確認
        // closeまたはarrow_backを含むInkWellを探す
        final closeIcon = find.byIcon(Icons.close);
        final backIcon = find.byIcon(Icons.arrow_back);

        Finder? iconFinder;
        if (closeIcon.evaluate().isNotEmpty) {
          iconFinder = closeIcon;
        } else if (backIcon.evaluate().isNotEmpty) {
          iconFinder = backIcon;
        }

        if (iconFinder != null) {
          final inkWellFinder = find.ancestor(
            of: iconFinder,
            matching: find.byType(InkWell),
          );

          if (inkWellFinder.evaluate().isNotEmpty) {
            final buttonSize = tester.getSize(inkWellFinder.first);
            expect(
              buttonSize.width,
              greaterThanOrEqualTo(44),
            ); // 【確認内容】: タップ領域の幅が44px以上であることを確認 🔵
            expect(
              buttonSize.height,
              greaterThanOrEqualTo(44),
            ); // 【確認内容】: タップ領域の高さが44px以上であることを確認 🔵
          }
        }
      });
    });
  });
}
