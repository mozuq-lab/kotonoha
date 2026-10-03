/// CharacterBoardWidget fit-to-height ウィジェットテスト
/// スマホレイアウト修正（fix/improvement-p0-p2）
/// 対象: lib/features/character_board/presentation/widgets/character_board_widget.dart
/// 可視高さが乏しい場合でも、セルの実高さが44px未満に縮小されないこと
/// （下回る場合はGridView標準のスクロールに委ねる）を検証する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';

void main() {
  group('CharacterBoardWidget fit-to-heightテスト', () {
    testWidgets(
      '可視高さが乏しい場合でもセルの実高さは44px未満に縮小されない',
      (tester) async {
        // 幅700px・高さ200pxという、高さ基準では1セルあたり30px程度しか
        // 割り当てられない極端に低い領域に配置する
        // （5行 × 高さ200pxの領域では、単純な高さ按分だと44pxを下回る）。
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 700,
                height: 200,
                child: CharacterBoardWidget(onCharacterTap: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // GridViewが内部スクロールで吸収するため、レイアウト例外は発生しない
        expect(tester.takeException(), isNull);

        final buttonSize = tester.getSize(
          find.byType(CharacterButton).first,
        );

        // 高さ基準の理論値(約30px)まで縮小されず、44px下限で底上げされている
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
        );
        // 幅より高さが小さい（正方形固定ではなく、高さ方向のみ押し縮められて
        // いること）を確認し、fit-to-height処理が実際に働いていることを示す
        expect(buttonSize.height, lessThan(buttonSize.width));
      },
    );

    testWidgets(
      '可視高さが十分な場合は空いた高さを使ってキーを縦に伸ばす（幅の1.75倍まで）',
      (tester) async {
        // タブレットの縦持ちのように高さが余る場合、正方形のままだと文字盤の
        // 下が空く。縦に伸ばして空いた高さを使う。ただし幅の1.75倍を超えない。
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: CharacterBoardWidget(onCharacterTap: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final buttonSize = tester.getSize(
          find.byType(CharacterButton).first,
        );

        expect(buttonSize.height, greaterThan(buttonSize.width * 1.2),
            reason: '高さが余っているのにキーが伸びていない');
        expect(
            buttonSize.height, lessThanOrEqualTo(buttonSize.width * 1.75 + 0.5),
            reason: 'キーが幅の1.75倍より縦長になっている');
      },
    );

    // 高さで決まる大きさ（縦に余裕が無い）で比べる。行数の少ない文字種だけ
    // キーが伸びると、ここで大きく食い違う
    testWidgets('文字種を切り替えてもキーの大きさは変わらない', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 400,
              child: CharacterBoardWidget(onCharacterTap: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final basic = tester.getSize(find.byType(CharacterButton).first);

      await tester.tap(find.text('半濁音'));
      await tester.pumpAndSettle();
      final handakuon = tester.getSize(find.byType(CharacterButton).first);

      expect(handakuon, basic);
    });

    testWidgets('大きなキーでは文字もキーに合わせて大きくなる', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<double> glyphSize(double width, double height) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                height: height,
                child: CharacterBoardWidget(onCharacterTap: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 描かれた文字の高さ（FittedBox で縮められた分も反映される）
        return tester.getRect(find.text('あ')).height;
      }

      // 電話の縦持ち相当の小さなキー
      final small = await glyphSize(360, 500);
      // タブレット相当の大きなキー
      final large = await glyphSize(1000, 900);
      expect(large, greaterThan(small * 1.5), reason: 'キーが大きくなっても文字が大きくならない');
    });
  });
}
