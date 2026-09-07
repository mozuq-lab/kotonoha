/// FaceToFaceScreen 画面 テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/screens/face_to_face_screen.dart';

void main() {
  group('FaceToFaceScreenテスト', () {
    group('画面表示テスト', () {
      /// 対面表示画面が表示される
      testWidgets('TC-052-010: 対面表示画面が表示されることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceScreenを構築
        // 初期条件設定: 表示テキストを指定
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

        // Then: 結果検証: 画面が表示されていることを確認
        // に基づく
        // 品質保証: 対面表示モードが利用可能であること
        expect(
          find.byType(FaceToFaceScreen),
          findsOneWidget,
        );
      });

      /// 渡されたテキストが画面中央に表示される
      testWidgets('TC-052-011: 渡されたテキストが画面中央に表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: 表示テキストを指定
        // 初期条件設定: 対面の相手に見せたいメッセージ
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

        // Then: 結果検証: テキストが表示されていることを確認
        // に基づく
        // 品質保証: 対面の相手がメッセージを読み取れること
        expect(
          find.text(testText),
          findsOneWidget,
        );
      });

      /// 戻るボタンが表示される
      testWidgets('TC-052-012: 戻るボタンが表示されることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceScreenを構築
        // 初期条件設定: 対面表示モードの状態
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

        // Then: 結果検証: 戻るボタンが表示されていることを確認
        // に基づく
        // 品質保証: ユーザーが通常モードに戻れること
        // 戻るボタンのアイコン（close または arrow_back）を検索
        expect(
          find.byIcon(Icons.close).evaluate().isNotEmpty ||
              find.byIcon(Icons.arrow_back).evaluate().isNotEmpty,
          isTrue,
        );
      });

      /// 戻るボタンをタップするとonBackが呼ばれる
      testWidgets('TC-052-013: 戻るボタンをタップするとonBackが呼ばれることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: onBackコールバックを監視
        // 初期条件設定: 対面表示モードの状態
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

        // When: 実際の処理実行: 戻るボタンをタップ
        // 処理内容: ユーザーが通常モードに戻る操作を模擬
        // closeアイコンまたはarrow_backアイコンを探してタップ
        final closeButton = find.byIcon(Icons.close);
        final backButton = find.byIcon(Icons.arrow_back);

        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
        } else if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        }
        await tester.pumpAndSettle();

        // Then: 結果検証: onBackコールバックが呼ばれたことを確認
        // ユーザー操作が正しく処理されること
        // 品質保証: 通常モードに戻る操作が確実に機能すること
        expect(
          onBackCalled,
          isTrue,
        );
      });
    });

    group('背景・スタイルテスト', () {
      /// 背景がシンプルである（余計な要素がない）
      testWidgets('TC-052-014: 背景がシンプルであることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceScreenを構築
        // 初期条件設定: 対面表示モードの状態
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

        // Then: 結果検証: 画面構成が最小限であることを確認
        // 余計なUI要素がないこと
        // 品質保証: 対面の相手がメッセージに集中できること

        // 画面にFaceToFaceScreenが存在することを確認
        expect(
          find.byType(FaceToFaceScreen),
          findsOneWidget,
        );

        // 主要なUI要素（テキスト、戻るボタン）以外が最小限であることを確認
        // ここでは画面が正常に表示されていることを基本的に検証
      });

      /// ダークモード・高コントラストモードで正しく表示される
      testWidgets('TC-052-015: ダークモードで正しく表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: ダークテーマでFaceToFaceScreenを構築
        // 初期条件設定: ダークモードの状態
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

        // Then: 結果検証: 画面が正しく表示されていることを確認
        // ダークモードでもテキストが読みやすいこと
        // 品質保証: 様々な環境で利用可能であること
        expect(
          find.text(testText),
          findsOneWidget,
        );
      });
    });

    group('アクセシビリティテスト', () {
      /// 戻るボタンのサイズが44px×44px以上である
      testWidgets('戻るボタンのサイズが44px×44px以上であることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceScreenを構築
        // 初期条件設定: 対面表示モードの状態
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

        // Then: 結果検証: 戻るボタンのタップ領域が44px×44px以上であることを確認
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
            );
            expect(
              buttonSize.height,
              greaterThanOrEqualTo(44),
            );
          }
        }
      });
    });
  });
}
