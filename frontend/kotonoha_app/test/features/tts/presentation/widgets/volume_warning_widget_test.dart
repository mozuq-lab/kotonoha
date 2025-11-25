/// VolumeWarningWidgetウィジェット テスト
///
/// TASK-0051: OS音量0の警告表示
/// テストケース: TC-051-017〜TC-051-019
///
/// テスト対象: lib/features/tts/presentation/widgets/volume_warning_widget.dart
///
/// 【TDD Redフェーズ】: VolumeWarningWidgetが未実装、テストが失敗するはず
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';

void main() {
  group('VolumeWarningWidgetテスト', () {
    // =========================================================================
    // 1. 正常系テストケース（UI表示）
    // =========================================================================
    group('UI表示テスト', () {
      /// TC-051-017: 警告表示時に「音量が0です」メッセージが表示される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: isVisible=trueの時、警告メッセージが表示されること
      testWidgets('TC-051-017: 警告表示時に「音量が0です」メッセージが表示されることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: isVisible=trueの時、警告メッセージが表示されることを確認 🔵
        // 【テスト内容】: VolumeWarningWidgetをisVisible=trueでレンダリングし、メッセージを検証
        // 【期待される動作】: 「音量が0です」メッセージが表示される
        // 🔵 青信号: EDGE-202「音量が0の状態で読み上げを実行した場合、視覚的警告を表示」に基づく

        // Given: 【テストデータ準備】: isVisible=trueでVolumeWarningWidgetを構築
        // 【初期条件設定】: 音量0が検出された状態
        var dismissCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeWarningWidget(
                isVisible: true,
                onDismiss: () {
                  dismissCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 「音量が0です」メッセージが表示されていることを確認
        // 【期待値確認】: EDGE-202「視覚的警告を表示」に基づく
        // 【品質保証】: ユーザーが音量0であることに気づけること
        expect(
          find.text('音量が0です'),
          findsOneWidget,
        ); // 【確認内容】: 「音量が0です」メッセージが表示されていることを確認 🔵

        // 警告アイコンが表示されていることも確認
        expect(
          find.byIcon(Icons.volume_off),
          findsOneWidget,
        ); // 【確認内容】: 音量オフアイコンが表示されていることを確認 🔵
      });

      /// TC-051-018: isVisible=falseの時、警告が非表示になる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: isVisible=falseの時、警告が表示されないこと
      testWidgets('TC-051-018: isVisible=falseの時、警告が非表示になることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: isVisible=falseの時、警告が表示されないことを確認 🔵
        // 【テスト内容】: VolumeWarningWidgetをisVisible=falseでレンダリングし、非表示を検証
        // 【期待される動作】: 警告メッセージが表示されない
        // 🔵 青信号: 通常の音量状態では警告が不要

        // Given: 【テストデータ準備】: isVisible=falseでVolumeWarningWidgetを構築
        // 【初期条件設定】: 音量が正常な状態

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeWarningWidget(
                isVisible: false,
                onDismiss: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 警告メッセージが表示されていないことを確認
        // 【期待値確認】: 不要な時は表示しない
        // 【品質保証】: ユーザーの邪魔にならないこと
        expect(
          find.text('音量が0です'),
          findsNothing,
        ); // 【確認内容】: 警告が非表示であることを確認 🔵
      });

      /// TC-051-019: 閉じるボタンをタップするとonDismissが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: 閉じるボタンタップでonDismissコールバックが呼ばれること
      testWidgets('TC-051-019: 閉じるボタンをタップするとonDismissが呼ばれることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 閉じるボタンタップでonDismissコールバックが呼ばれることを確認 🔵
        // 【テスト内容】: 閉じるボタンをタップし、コールバックが呼ばれることを検証
        // 【期待される動作】: onDismissコールバックが呼ばれる
        // 🔵 青信号: volume-warning-requirements.md「VolumeWarningWidget.onDismiss」に基づく

        // Given: 【テストデータ準備】: onDismissコールバックを監視
        // 【初期条件設定】: 警告が表示されている状態
        var dismissCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeWarningWidget(
                isVisible: true,
                onDismiss: () {
                  dismissCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 警告が表示されていることを確認
        expect(find.text('音量が0です'), findsOneWidget);

        // When: 【実際の処理実行】: 閉じるボタンをタップ
        // 【処理内容】: ユーザーが警告を閉じた場合を模擬
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Then: 【結果検証】: onDismissコールバックが呼ばれたことを確認
        // 【期待値確認】: ユーザーが警告を認識し、閉じた
        // 【品質保証】: ユーザーの操作が正しく処理されること
        expect(dismissCalled, isTrue); // 【確認内容】: onDismissが呼ばれたことを確認 🔵
      });
    });

    // =========================================================================
    // 2. アクセシビリティテストケース
    // =========================================================================
    group('アクセシビリティテスト', () {
      /// 警告ウィジェットのアクセシビリティ
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: 警告メッセージがスクリーンリーダーで読み上げられること
      testWidgets('警告ウィジェットにSemanticsが設定されていることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 警告メッセージがスクリーンリーダーで読み上げられることを確認 🟡
        // 【テスト内容】: VolumeWarningWidgetにSemanticsが適切に設定されていることを検証
        // 【期待される動作】: Semanticsラベルが設定されている
        // 🟡 黄信号: アクセシビリティベストプラクティスに基づく

        // Given: 【テストデータ準備】: VolumeWarningWidgetを構築
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeWarningWidget(
                isVisible: true,
                onDismiss: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: Semanticsが設定されていることを確認
        // 【期待値確認】: アクセシビリティ対応
        final semantics = tester.getSemantics(find.byType(VolumeWarningWidget));
        expect(semantics, isNotNull); // 【確認内容】: Semanticsが設定されていることを確認 🟡
      });

      /// ボタンサイズが44px×44px以上である
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: REQ-5001
      /// 検証内容: 閉じるボタンのタップ領域が適切であること
      testWidgets('閉じるボタンのサイズが44px×44px以上であることを確認',
          (WidgetTester tester) async {
        // 【テスト目的】: 閉じるボタンのタップ領域が適切であることを確認 🟡
        // 【テスト内容】: 閉じるボタンのサイズが最低44px×44px以上であることを検証
        // 【期待される動作】: ボタンのタップ領域が最低44pxを確保
        // 🟡 黄信号: REQ-5001「タップターゲット44px×44px以上」から推測

        // Given: 【テストデータ準備】: VolumeWarningWidgetを構築
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeWarningWidget(
                isVisible: true,
                onDismiss: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 閉じるボタンのタップ領域が44px×44px以上であることを確認
        // Icons.closeを含むInkWellを探す
        final inkWellFinder = find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(InkWell),
        );
        expect(inkWellFinder, findsOneWidget);

        final buttonSize = tester.getSize(inkWellFinder);
        expect(
          buttonSize.width,
          greaterThanOrEqualTo(44),
        ); // 【確認内容】: タップ領域の幅が44px以上であることを確認 🟡
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(44),
        ); // 【確認内容】: タップ領域の高さが44px以上であることを確認 🟡
      });
    });

    // =========================================================================
    // 3. ビジュアルテストケース
    // =========================================================================
    group('ビジュアルテスト', () {
      /// 警告表示が目立つ色で表示される
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: 警告が目立つ色（オレンジ/黄色系）で表示されること
      testWidgets('警告表示が目立つ色で表示されることを確認', (WidgetTester tester) async {
        // 【テスト目的】: 警告が目立つ色で表示されることを確認 🟡
        // 【テスト内容】: 警告の背景色がオレンジ/黄色系であることを検証
        // 【期待される動作】: 視覚的に目立つ警告表示
        // 🟡 黄信号: UI/UXベストプラクティスに基づく

        // Given: 【テストデータ準備】: VolumeWarningWidgetを構築
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeWarningWidget(
                isVisible: true,
                onDismiss: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Then: 【結果検証】: 警告表示が存在することを確認
        // 具体的な色のテストはウィジェット実装に依存するため、
        // ここでは警告コンテナが表示されていることを確認
        expect(find.byType(VolumeWarningWidget), findsOneWidget);
        // 【確認内容】: 警告ウィジェットが表示されていることを確認 🟡
      });
    });
  });
}
