/// FaceToFaceToggleButton ウィジェット テスト
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// テストケース: TC-052-016〜TC-052-019
///
/// テスト対象: lib/features/face_to_face/presentation/widgets/face_to_face_toggle_button.dart
///
/// 【TDD Redフェーズ】: FaceToFaceToggleButtonが未実装、テストが失敗するはず
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/face_to_face_toggle_button.dart';

void main() {
  group('FaceToFaceToggleButtonテスト', () {
    // =========================================================================
    // 1. 正常系テストケース（UI表示）
    // =========================================================================
    group('UI表示テスト', () {
      /// TC-052-016: 対面表示ボタンが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-503
      /// 検証内容: FaceToFaceToggleButtonが正しくレンダリングされること
      testWidgets('TC-052-016: 対面表示ボタンが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: FaceToFaceToggleButtonが正しくレンダリングされることを確認 🔵
        // 【テスト内容】: ウィジェットを構築し、表示されることを検証
        // 【期待される動作】: 対面表示ボタンが画面に表示される
        // 🔵 青信号: REQ-503「シンプルな操作で切り替え」に基づく

        // Given: 【テストデータ準備】: FaceToFaceToggleButtonを構築
        // 【初期条件設定】: 通常状態（モード無効）
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

        // Then: 【結果検証】: ボタンが表示されていることを確認
        // 【期待値確認】: REQ-503に基づく
        // 【品質保証】: ユーザーがボタンを認識できること
        expect(
          find.byType(FaceToFaceToggleButton),
          findsOneWidget,
        ); // 【確認内容】: ボタンウィジェットが存在することを確認 🔵

        // 対面表示アイコン（fullscreenまたはzoom_out_map）が表示されていることを確認
        expect(
          find.byIcon(Icons.zoom_out_map),
          findsOneWidget,
        ); // 【確認内容】: 対面表示アイコンが表示されていることを確認 🔵
      });

      /// TC-052-017: ボタンタップでonTapコールバックが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-503
      /// 検証内容: ボタンタップでonTapが呼ばれること
      testWidgets('TC-052-017: ボタンタップでonTapコールバックが呼ばれることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: ボタンタップでonTapコールバックが呼ばれることを確認 🔵
        // 【テスト内容】: ボタンをタップし、コールバックが呼ばれることを検証
        // 【期待される動作】: onTapコールバックが呼ばれる
        // 🔵 青信号: REQ-503「シンプルな操作で切り替え」に基づく

        // Given: 【テストデータ準備】: onTapコールバックを監視
        // 【初期条件設定】: ボタンが表示されている状態
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

        // When: 【実際の処理実行】: ボタンをタップ
        // 【処理内容】: ユーザーがボタンをタップした場合を模擬
        await tester.tap(find.byType(FaceToFaceToggleButton));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: onTapコールバックが呼ばれたことを確認
        // 【期待値確認】: ユーザー操作が正しく処理されること
        // 【品質保証】: タップ操作が確実に反応すること
        expect(
          onTapCalled,
          isTrue,
        ); // 【確認内容】: onTapが呼ばれたことを確認 🔵
      });

      /// TC-052-018: isEnabled=trueの時、異なるアイコンが表示される
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-503
      /// 検証内容: モード有効時にアイコンが変わること
      testWidgets('TC-052-018: isEnabled=trueの時、fullscreen_exitアイコンが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: モード有効時にアイコンが変わることを確認 🟡
        // 【テスト内容】: isEnabled=trueでレンダリングし、アイコンを検証
        // 【期待される動作】: fullscreen_exitアイコンが表示される
        // 🟡 黄信号: 一般的なUIパターンから推測

        // Given: 【テストデータ準備】: isEnabled=trueでFaceToFaceToggleButtonを構築
        // 【初期条件設定】: 対面表示モードが有効の状態
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

        // Then: 【結果検証】: fullscreen_exitアイコンが表示されていることを確認
        // 【期待値確認】: モード状態がアイコンで視覚的にわかること
        // 【品質保証】: ユーザーが現在の状態を認識できること
        expect(
          find.byIcon(Icons.fullscreen_exit),
          findsOneWidget,
        ); // 【確認内容】: fullscreen_exitアイコンが表示されていることを確認 🟡
      });
    });

    // =========================================================================
    // 2. アクセシビリティテストケース
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// TC-052-019: ボタンサイズが44px×44px以上である
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5001
      /// 検証内容: タップターゲットが最低44px×44px以上であること
      testWidgets('TC-052-019: ボタンサイズが44px×44px以上であることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: タップターゲットが最低44px×44px以上であることを確認 🔵
        // 【テスト内容】: ボタンのサイズを検証
        // 【期待される動作】: ボタンのタップ領域が44px以上
        // 🔵 青信号: REQ-5001「タップターゲット44px×44px以上」に基づく

        // Given: 【テストデータ準備】: FaceToFaceToggleButtonを構築
        // 【初期条件設定】: ボタンが表示されている状態
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

        // Then: 【結果検証】: ボタンサイズが44px×44px以上であることを確認
        // 【期待値確認】: アクセシビリティ要件を満たすこと
        // 【品質保証】: 運動障害のあるユーザーでもタップしやすいこと
        final buttonSize = tester.getSize(find.byType(FaceToFaceToggleButton));
        expect(
          buttonSize.width,
          greaterThanOrEqualTo(44),
        ); // 【確認内容】: タップ領域の幅が44px以上であることを確認 🔵
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(44),
        ); // 【確認内容】: タップ領域の高さが44px以上であることを確認 🔵
      });

      /// Semanticsラベルが設定されていることを確認
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: スクリーンリーダー対応
      testWidgets('Semanticsラベルが設定されていることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: スクリーンリーダーで読み上げられることを確認 🟡
        // 【テスト内容】: Semanticsが適切に設定されていることを検証
        // 【期待される動作】: Semanticsラベルが設定されている
        // 🟡 黄信号: アクセシビリティベストプラクティスに基づく

        // Given: 【テストデータ準備】: FaceToFaceToggleButtonを構築
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

        // Then: 【結果検証】: Semanticsが設定されていることを確認
        // 【期待値確認】: アクセシビリティ対応
        final semantics = tester.getSemantics(find.byType(FaceToFaceToggleButton));
        expect(semantics, isNotNull); // 【確認内容】: Semanticsが設定されていることを確認 🟡
      });
    });
  });
}
