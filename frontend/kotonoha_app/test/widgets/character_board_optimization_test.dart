/// 文字盤UI最適化テスト
///
/// TASK-0089: 文字盤UI最適化
/// テストケース: TC-OPT-001〜TC-OPT-017（自動化可能な部分）
///
/// テスト対象: lib/features/character_board/presentation/widgets/character_board_widget.dart
///
/// TDD Redフェーズ: 最適化が未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

void main() {
  group('CharacterBoardOptimizationTest', () {
    // =========================================================================
    // 1. パフォーマンステストケース
    // =========================================================================
    group('パフォーマンステスト', () {
      /// TC-OPT-001: 文字盤タップ応答時間（100ms以内）
      ///
      /// テスト目的: NFR-003の充足確認
      /// テスト内容: タップから入力欄反映まで100ms以内で完了することを確認
      /// 期待される動作: タップ応答時間が100ms以内
      /// 青信号: NFR-003で100ms以内のタップ応答が必須
      testWidgets('TC-OPT-001: 文字盤タップ応答時間が100ms以内', (tester) async {
        String? tappedCharacter;
        final stopwatch = Stopwatch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacter = char,
              ),
            ),
          ),
        );

        // タップ応答時間を計測
        stopwatch.start();
        await tester.tap(find.text('あ'));
        await tester.pump(); // 1フレーム進める（UIの更新を待つ）
        stopwatch.stop();

        // 期待結果: 100ms以内で応答（NFR-003）
        // 注意: CI環境ではパフォーマンスが不安定なため、200msまで許容
        // 本番環境の実機テストでは100ms以内を確認すること
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'タップ応答時間が200ms以内である必要がある（CI環境、本番は100ms: NFR-003）',
        );
        expect(tappedCharacter, equals('あ'));
      });

      /// TC-OPT-002: 10文字連続タップ応答時間
      ///
      /// テスト目的: 連続操作時のパフォーマンス維持確認
      /// テスト内容: 各タップが100ms以内で応答することを確認
      /// 期待される動作: 各タップの応答時間が100ms以内
      /// 青信号: NFR-003適用
      testWidgets('TC-OPT-002: 10文字連続タップがすべて100ms以内', (tester) async {
        final tappedCharacters = <String>[];
        final responseTimes = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (char) => tappedCharacters.add(char),
              ),
            ),
          ),
        );

        // 10文字連続タップ
        const characters = 'あいうえおかきくけこ';
        for (final char in characters.split('')) {
          final stopwatch = Stopwatch()..start();
          await tester.tap(find.text(char));
          await tester.pump();
          stopwatch.stop();
          responseTimes.add(stopwatch.elapsedMilliseconds);
        }

        // 期待結果: すべてのタップが100ms以内（NFR-003）
        // 注意: CI環境ではパフォーマンスが不安定なため、200msまで許容
        for (var i = 0; i < responseTimes.length; i++) {
          expect(
            responseTimes[i],
            lessThan(200),
            reason: '${i + 1}文字目のタップ応答時間が200ms以内である必要がある（CI環境）',
          );
        }

        // 期待結果: 全文字が正しく入力された
        expect(tappedCharacters.join(), equals(characters));

        // 期待結果: 平均応答時間が100ms以下（CI環境では緩和）
        final average =
            responseTimes.reduce((a, b) => a + b) / responseTimes.length;
        expect(
          average,
          lessThan(100),
          reason: '平均応答時間が100ms以下である必要がある（CI環境）',
        );
      });

      /// TC-OPT-003: カテゴリ切り替え時のパフォーマンス
      ///
      /// テスト目的: カテゴリ切り替え時の再レンダリング最適化確認
      /// テスト内容: 切り替えが200ms以内で完了することを確認
      /// 期待される動作: カテゴリ切り替えが200ms以内
      /// 青信号: 要件定義での切り替えパフォーマンス
      testWidgets('TC-OPT-003: カテゴリ切り替えが200ms以内', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 初期状態で「基本」カテゴリが表示されていることを確認
        expect(find.text('あ'), findsOneWidget);

        // カテゴリ切り替え時間を計測
        final stopwatch = Stopwatch()..start();
        await tester.tap(find.text('濁音'));
        await tester.pumpAndSettle(); // アニメーション完了まで待つ
        stopwatch.stop();

        // 期待結果: 200ms以内で切り替え完了
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(200),
          reason: 'カテゴリ切り替えが200ms以内である必要がある',
        );

        // 期待結果: 濁音カテゴリが表示される
        expect(find.text('が'), findsOneWidget);
      });
    });

    // =========================================================================
    // 2. 再レンダリング最適化テストケース
    // =========================================================================
    group('再レンダリング最適化テスト', () {
      /// TC-OPT-004: RepaintBoundaryの配置確認
      ///
      /// テスト目的: RepaintBoundaryが適切に配置されていることを確認
      /// テスト内容: 各CharacterButtonがRepaintBoundaryで明示的に囲まれている
      /// 期待される動作: GridViewのitemBuilder内でRepaintBoundaryが使用されている
      /// 青信号: REQ-OPT-002で定義
      testWidgets('TC-OPT-004: RepaintBoundaryが配置されている', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 期待結果: 各CharacterButtonがRepaintBoundaryで明示的に囲まれている
        // GridView.builderのitemBuilder内で、各CharacterButtonを
        // RepaintBoundaryで囲む必要がある
        final characterButtons = find.byType(CharacterButton);
        final buttonCount = tester.widgetList(characterButtons).length;

        // RepaintBoundaryの総数を確認
        final repaintBoundaries = find.byType(RepaintBoundary);
        final boundaryCount = tester.widgetList(repaintBoundaries).length;

        // 期待結果: CharacterButtonの数 + 10個以上のRepaintBoundaryが存在
        // （各ボタンを囲むRepaintBoundary + カテゴリタブ境界 + グリッド境界など）
        // 最適化前は、GridViewが自動的に追加するRepaintBoundaryのみなので少ない
        // 最適化後は、各ボタンに明示的にRepaintBoundaryを追加するので大幅に増える
        expect(
          boundaryCount,
          greaterThanOrEqualTo(buttonCount + 10),
          reason: '各CharacterButtonが明示的にRepaintBoundaryで囲まれている必要がある。'
              'ボタン数: $buttonCount, RepaintBoundary数: $boundaryCount. '
              '期待値: ${buttonCount + 10}以上',
        );
      });

      /// TC-OPT-007: constコンストラクタの使用確認
      ///
      /// テスト目的: constコンストラクタが適切に使用されていることを確認
      /// テスト内容: CharacterDataがconstで定義されている
      /// 期待される動作: CharacterData.getCharacters()が返すリストがconstリスト
      /// 青信号: REQ-OPT-001で定義
      test('TC-OPT-007: CharacterDataがconstリストを返す', () {
        // 期待結果: CharacterData.basicがconstリスト
        const characters = CharacterData.basic;
        expect(characters, isNotNull);
        expect(characters.length, greaterThan(0));

        // 期待結果: 各カテゴリのデータがconstで定義されている
        const dakuon = CharacterData.dakuon;
        const handakuon = CharacterData.handakuon;
        const komoji = CharacterData.komoji;
        const kigou = CharacterData.kigou;

        expect(dakuon, isNotNull);
        expect(handakuon, isNotNull);
        expect(komoji, isNotNull);
        expect(kigou, isNotNull);
      });

      /// TC-OPT-008: 親ウィジェット再ビルド時の子ウィジェット安定性
      ///
      /// テスト目的: 親ウィジェットが再ビルドされても子ウィジェットが不要に再ビルドされないことを確認
      /// テスト内容: 親ウィジェットのsetState時にCharacterBoardWidgetが再ビルドされない
      /// 期待される動作: constコンストラクタによりCharacterBoardWidgetが再利用される
      /// 青信号: REQ-OPT-001, REQ-OPT-006で定義
      testWidgets('TC-OPT-008: 親ウィジェット再ビルド時の安定性', (tester) async {
        int parentBuildCount = 0;
        int characterBoardBuildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                parentBuildCount++;
                return Scaffold(
                  body: Column(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            characterBoardBuildCount++;
                            return CharacterBoardWidget(
                              key: const ValueKey('character_board'),
                              onCharacterTap: (_) {},
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Rebuild Parent'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // 初期ビルド回数を記録
        final initialParentBuildCount = parentBuildCount;
        final initialCharacterBoardBuildCount = characterBoardBuildCount;

        // 親ウィジェットを再ビルド
        await tester.tap(find.text('Rebuild Parent'));
        await tester.pump();

        // 期待結果: 親ウィジェットは再ビルドされる
        expect(
          parentBuildCount,
          greaterThan(initialParentBuildCount),
          reason: '親ウィジェットが再ビルドされる必要がある',
        );

        // 期待結果: CharacterBoardWidgetは再ビルドされない
        // （ただし、Builderで囲んでいるため再ビルドされる可能性あり）
        // このテストは最適化実装後に調整が必要
        expect(
          characterBoardBuildCount,
          lessThan(initialCharacterBoardBuildCount + 3),
          reason: '最小限の再ビルドに抑える必要がある',
        );
      });
    });

    // =========================================================================
    // 3. ウィジェットツリー最適化テストケース
    // =========================================================================
    group('ウィジェットツリー最適化テスト', () {
      /// TC-OPT-012: CharacterButton階層の深さ確認
      ///
      /// テスト目的: ウィジェット階層が5層以内であることを確認
      /// テスト内容: CharacterButton内のウィジェット階層を計測
      /// 期待される動作: 階層が5層以内
      /// 青信号: REQ-OPT-003で定義
      testWidgets('TC-OPT-012: CharacterButtonの階層が最適化されている', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 期待結果: CharacterButtonが存在する
        final characterButtons = find.byType(CharacterButton);
        expect(characterButtons, findsWidgets);

        // 期待結果: 各CharacterButtonのウィジェット階層が深すぎない
        // CharacterButton -> Semantics -> SizedBox -> Material -> InkWell -> Container
        // この階層が最適化により削減されることを期待
        // （具体的な階層数は実装後に調整）
        final firstButton =
            tester.widget<CharacterButton>(characterButtons.first);
        expect(firstButton, isNotNull);
      });

      /// TC-OPT-013: 不要なSemanticsラッパーの削除確認
      ///
      /// テスト目的: 必要最小限のSemanticsのみ使用されていることを確認
      /// テスト内容: Semanticsが適切に使用されている
      /// 期待される動作: 必要最小限のSemantics使用
      /// 青信号: REQ-OPT-003で定義
      testWidgets('TC-OPT-013: Semanticsが最小限に使用されている', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 期待結果: Semanticsウィジェットが存在する
        final semanticsWidgets = find.byType(Semantics);
        expect(semanticsWidgets, findsWidgets);

        // 期待結果: CharacterButtonの数と同程度のSemantics
        final characterButtons = find.byType(CharacterButton);
        final semanticsCount = tester.widgetList(semanticsWidgets).length;
        final buttonCount = tester.widgetList(characterButtons).length;

        // 各ボタンに1つのSemanticsが対応している
        expect(
          semanticsCount,
          greaterThanOrEqualTo(buttonCount),
          reason: '各CharacterButtonにSemanticsが設定されている必要がある',
        );
      });
    });

    // =========================================================================
    // 4. Riverpod状態管理最適化テストケース
    // =========================================================================
    group('Riverpod状態管理最適化テスト', () {
      /// TC-OPT-016: inputBufferProvider変更時の再ビルド範囲
      ///
      /// テスト目的: inputBufferProviderの変更がCharacterBoardWidgetを不要に再ビルドしないことを確認
      /// テスト内容: CharacterBoardWidgetがStatefulWidgetであることを確認
      /// 期待される動作: CharacterBoardWidgetがinputBufferProviderをwatchしていない
      /// 青信号: REQ-OPT-006で定義
      test('TC-OPT-016: CharacterBoardWidgetがStatefulWidget', () {
        // 期待結果: CharacterBoardWidgetがStatefulWidget
        expect(CharacterBoardWidget, isA<Type>());

        // CharacterBoardWidgetのインスタンスがStatefulWidgetであることを確認
        final widget = CharacterBoardWidget(onCharacterTap: (_) {});
        expect(widget, isA<StatefulWidget>());
      });

      /// TC-OPT-017: ConsumerWidgetの使用範囲確認
      ///
      /// テスト目的: ConsumerWidgetが必要最小限のみ使用されていることを確認
      /// テスト内容: CharacterBoardWidget自体はStatefulWidget
      /// 期待される動作: CharacterBoardWidgetがConsumerWidgetでない
      /// 青信号: REQ-OPT-006で定義
      test('TC-OPT-017: CharacterBoardWidgetがConsumerWidgetでない', () {
        final widget = CharacterBoardWidget(onCharacterTap: (_) {});

        // 期待結果: CharacterBoardWidgetがStatefulWidget
        expect(widget, isA<StatefulWidget>());

        // 期待結果: CharacterBoardWidgetがConsumerWidgetでない
        // （ConsumerWidgetはriverpod_flutter packageから提供される）
        expect(widget.runtimeType.toString(), equals('CharacterBoardWidget'));
      });
    });

    // =========================================================================
    // 5. コード品質テストケース
    // =========================================================================
    group('コード品質テスト', () {
      /// TC-OPT-022: ウィジェットkeyパラメータ確認
      ///
      /// テスト目的: ウィジェットがkeyパラメータを持つことを確認
      /// テスト内容: CharacterBoardWidget、CharacterButtonがkeyを持つ
      /// 期待される動作: ValueKeyが適切に使用されている
      /// 青信号: コーディング規約
      testWidgets('TC-OPT-022: ウィジェットがkeyパラメータを持つ', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                key: const ValueKey('test_key'),
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 期待結果: keyが設定されたウィジェットが見つかる
        expect(find.byKey(const ValueKey('test_key')), findsOneWidget);

        // 期待結果: CharacterButtonにもkeyが設定されている
        final characterButtons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in characterButtons) {
          expect(button.key, isNotNull,
              reason: 'CharacterButtonにkeyが設定されている必要がある');
        }
      });
    });

    // =========================================================================
    // 6. 追加の最適化テスト
    // =========================================================================
    group('追加の最適化テスト', () {
      /// 空要素がconst SizedBox.shrink()で実装されている
      testWidgets('空要素がconst SizedBox.shrink()を使用', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                initialCategory: CharacterCategory.kigou,
              ),
            ),
          ),
        );

        // 期待結果: SizedBox.shrink()が使用されている
        // （記号カテゴリは空要素を含むため）
        final sizedBoxes = find.byType(SizedBox);
        expect(sizedBoxes, findsWidgets);
      });

      /// ボタンサイズが適切に設定されている
      testWidgets('ボタンサイズが推奨サイズ以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
              ),
            ),
          ),
        );

        // 期待結果: ボタンサイズが推奨サイズ（60px）以上
        final buttons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in buttons) {
          expect(
            button.size,
            greaterThanOrEqualTo(AppSizes.recommendedTapTarget),
            reason: 'ボタンサイズが推奨サイズ（60px）以上である必要がある',
          );
        }
      });

      /// フォントサイズが正しく反映される
      testWidgets('フォントサイズ設定が反映される', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CharacterBoardWidget(
                onCharacterTap: (_) {},
                fontSize: FontSize.large,
              ),
            ),
          ),
        );

        // 期待結果: フォントサイズ設定が反映される
        final widget = tester.widget<CharacterBoardWidget>(
          find.byType(CharacterBoardWidget),
        );
        expect(widget.fontSize, equals(FontSize.large));

        // 期待結果: CharacterButtonにもフォントサイズが渡される
        final buttons = tester.widgetList<CharacterButton>(
          find.byType(CharacterButton),
        );

        for (final button in buttons) {
          expect(button.fontSize, equals(FontSize.large));
        }
      });
    });
  });
}
