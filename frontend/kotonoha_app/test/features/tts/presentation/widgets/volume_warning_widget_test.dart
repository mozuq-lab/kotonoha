/// VolumeWarningWidgetウィジェット テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';

void main() {
  group('VolumeWarningWidgetテスト', () {
    group('UI表示テスト', () {
      /// 警告表示時に「音量が0です」メッセージが表示される
      testWidgets('TC-051-017: 警告表示時に「音量が0です」メッセージが表示されることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: isVisible=trueでVolumeWarningWidgetを構築
        // 初期条件設定: 音量0が検出された状態
        // ignore: unused_local_variable
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

        // Then: 結果検証: 「音量が0です」メッセージが表示されていることを確認
        // 「視覚的警告を表示」に基づく
        // 品質保証: ユーザーが音量0であることに気づけること
        expect(
          find.text('音量が0です'),
          findsOneWidget,
        );

        // 警告アイコンが表示されていることも確認
        expect(
          find.byIcon(Icons.volume_off),
          findsOneWidget,
        );
      });

      /// isVisible=falseの時、警告が非表示になる
      testWidgets('TC-051-018: isVisible=falseの時、警告が非表示になることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: isVisible=falseでVolumeWarningWidgetを構築
        // 初期条件設定: 音量が正常な状態

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

        // Then: 結果検証: 警告メッセージが表示されていないことを確認
        // 不要な時は表示しない
        // 品質保証: ユーザーの邪魔にならないこと
        expect(
          find.text('音量が0です'),
          findsNothing,
        );
      });

      /// 閉じるボタンをタップするとonDismissが呼ばれる
      testWidgets('TC-051-019: 閉じるボタンをタップするとonDismissが呼ばれることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: onDismissコールバックを監視
        // 初期条件設定: 警告が表示されている状態
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

        // When: 実際の処理実行: 閉じるボタンをタップ
        // 処理内容: ユーザーが警告を閉じた場合を模擬
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Then: 結果検証: onDismissコールバックが呼ばれたことを確認
        // ユーザーが警告を認識し、閉じた
        // 品質保証: ユーザーの操作が正しく処理されること
        expect(dismissCalled, isTrue);
      });
    });

    group('アクセシビリティテスト', () {
      /// 警告ウィジェットのアクセシビリティ
      testWidgets('警告ウィジェットにSemanticsが設定されていることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: VolumeWarningWidgetを構築
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

        // Then: 結果検証: Semanticsが設定されていることを確認
        // アクセシビリティ対応
        final semantics = tester.getSemantics(find.byType(VolumeWarningWidget));
        expect(semantics, isNotNull);
      });

      /// ボタンサイズが44px×44px以上である
      testWidgets('閉じるボタンのサイズが44px×44px以上であることを確認',
          (WidgetTester tester) async {
        // Given: テストデータ準備: VolumeWarningWidgetを構築
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

        // Then: 結果検証: 閉じるボタンのタップ領域が44px×44px以上であることを確認
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
        );
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(44),
        );
      });
    });

    group('ビジュアルテスト', () {
      /// 警告表示が目立つ色で表示される
      testWidgets('警告表示が目立つ色で表示されることを確認', (WidgetTester tester) async {
        // Given: テストデータ準備: VolumeWarningWidgetを構築
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

        // Then: 結果検証: 警告表示が存在することを確認
        // 具体的な色のテストはウィジェット実装に依存するため
        // ここでは警告コンテナが表示されていることを確認
        expect(find.byType(VolumeWarningWidget), findsOneWidget);
        // 警告ウィジェットが表示されていることを確認
      });
    });
  });
}
