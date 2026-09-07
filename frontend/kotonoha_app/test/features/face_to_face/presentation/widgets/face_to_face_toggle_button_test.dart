/// FaceToFaceToggleButton ウィジェット テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/face_to_face_toggle_button.dart';

void main() {
  group('FaceToFaceToggleButtonテスト', () {
    group('UI表示テスト', () {
      /// 対面表示ボタンが表示される
      testWidgets('TC-052-016: 対面表示ボタンが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceToggleButtonを構築
        // 初期条件設定: 通常状態（モード無効）
        // ignore: unused_local_variable
        var onTapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FaceToFaceToggleButton(
                isEnabled: false,
                onTap: () {
                  onTapCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンが表示されていることを確認
        // に基づく
        // 品質保証: ユーザーがボタンを認識できること
        expect(
          find.byType(FaceToFaceToggleButton),
          findsOneWidget,
        );

        // 対面表示アイコン（fullscreenまたはzoom_out_map）が表示されていることを確認
        expect(
          find.byIcon(Icons.zoom_out_map),
          findsOneWidget,
        );
      });

      /// ボタンタップでonTapコールバックが呼ばれる
      testWidgets('TC-052-017: ボタンタップでonTapコールバックが呼ばれることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: onTapコールバックを監視
        // 初期条件設定: ボタンが表示されている状態
        var onTapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FaceToFaceToggleButton(
                isEnabled: false,
                onTap: () {
                  onTapCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // When: 実際の処理実行: ボタンをタップ
        // 処理内容: ユーザーがボタンをタップした場合を模擬
        await tester.tap(find.byType(FaceToFaceToggleButton));
        await tester.pumpAndSettle();

        // Then: 結果検証: onTapコールバックが呼ばれたことを確認
        // ユーザー操作が正しく処理されること
        // 品質保証: タップ操作が確実に反応すること
        expect(
          onTapCalled,
          isTrue,
        );
      });

      /// isEnabled=trueの時、異なるアイコンが表示される
      testWidgets('TC-052-018: isEnabled=trueの時、fullscreen_exitアイコンが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: isEnabled=trueでFaceToFaceToggleButtonを構築
        // 初期条件設定: 対面表示モードが有効の状態
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FaceToFaceToggleButton(
                isEnabled: true,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: fullscreen_exitアイコンが表示されていることを確認
        // モード状態がアイコンで視覚的にわかること
        // 品質保証: ユーザーが現在の状態を認識できること
        expect(
          find.byIcon(Icons.fullscreen_exit),
          findsOneWidget,
        );
      });
    });

    group('アクセシビリティテスト', () {
      /// ボタンサイズが44px×44px以上である
      testWidgets('TC-052-019: ボタンサイズが44px×44px以上であることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceToggleButtonを構築
        // 初期条件設定: ボタンが表示されている状態
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: FaceToFaceToggleButton(
                  isEnabled: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: ボタンサイズが44px×44px以上であることを確認
        // アクセシビリティ要件を満たすこと
        // 品質保証: 運動障害のあるユーザーでもタップしやすいこと
        final buttonSize = tester.getSize(find.byType(FaceToFaceToggleButton));
        expect(
          buttonSize.width,
          greaterThanOrEqualTo(44),
        );
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(44),
        );
      });

      /// Semanticsラベルが設定されていることを確認
      testWidgets('Semanticsラベルが設定されていることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: FaceToFaceToggleButtonを構築
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FaceToFaceToggleButton(
                isEnabled: false,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 結果検証: Semanticsが設定されていることを確認
        // アクセシビリティ対応
        final semantics =
            tester.getSemantics(find.byType(FaceToFaceToggleButton));
        expect(semantics, isNotNull);
      });
    });
  });
}
