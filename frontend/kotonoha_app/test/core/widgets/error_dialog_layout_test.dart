/// エラーダイアログが、狭い画面と大きな文字であふれないこと（台帳 L-133）
///
/// これらは「取り消し ＋ 取り消せない実行」ではないので L-130 の契約の対象外だが、
/// **あふれるとボタンが切れて押せなくなる**のは同じ害。エラーの出口が押せないと、
/// 利用者は再試行も取り消しもできなくなる。
///
/// 見つかった形（2026-09-20 実測、修正前）:
///   - title が `Row` で `Expanded` が無いため、見出しが折り返せず右へあふれる。
///     **倍率 1.0・幅 320 でも 56px あふれる**
///   - actions は間隔の指定が無く、縦積みになると 0px で接する
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/widgets/error_dialog.dart';

/// ボタンとボタンの下限。`app_shell.dart` と同じ「16px 以上」
const double minGap = 16.0;

/// 変換行列を通った double の比較に許す誤差
const double epsilon = 0.01;

const widths = [320.0, 360.0, 375.0, 768.0];
const scales = [1.0, 1.3, 2.0, 2.4];

Finder buttonOf(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

/// 2 つの矩形の離れ具合。重なっていれば 0。
/// 片方の軸だけで離れていればその値、斜めなら大きいほうの軸の値を返す
/// （真の最短距離の**下界**なので、`>=` の判定に対して安全側）
double separation(Rect a, Rect b) {
  final horizontal = math.max(a.left - b.right, b.left - a.right);
  final vertical = math.max(a.top - b.bottom, b.top - a.bottom);
  return math.max(0.0, math.max(horizontal, vertical));
}

void expectDoesNotOverflow(
  String name, {
  required Future<void> Function(BuildContext context) open,
  required List<String> labels,
}) {
  for (final width in widths) {
    for (final scale in scales) {
      testWidgets('$name: 幅 $width・文字倍率 $scale であふれない', (tester) async {
        final screen = Size(width, 640);
        tester.view.physicalSize = screen;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => open(context),
                    child: const Text('開く'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        // 1. あふれない（見出しも本文も画面の外へ出ない）
        expect(tester.takeException(), isNull,
            reason: '$name が幅 $width・倍率 $scale であふれた');

        final rects = <String, Rect>{
          for (final label in labels) label: tester.getRect(buttonOf(label)),
        };

        // 2. どのボタンも画面の中にあって押せる
        for (final MapEntry(key: label, value: rect) in rects.entries) {
          expect(buttonOf(label).hitTestable(), findsWidgets,
              reason: '$name: 「$label」が押せない');
          // `hitTestable()` はボタン**中央の 1 点**しか見ないので、端が欠けても
          // 中央が押せれば通る。四辺すべてが画面の中にあることを別に見る
          expect(rect.left, greaterThanOrEqualTo(-epsilon),
              reason: '$name: 「$label」が画面の左に出ている（$rect）');
          expect(rect.right, lessThanOrEqualTo(width + epsilon),
              reason: '$name: 「$label」が画面の右に出ている（$rect）');
          expect(rect.top, greaterThanOrEqualTo(-epsilon),
              reason: '$name: 「$label」が画面の上に出ている（$rect）');
          expect(rect.bottom, lessThanOrEqualTo(screen.height + epsilon),
              reason: '$name: 「$label」が画面の下に出ている（$rect）');
        }

        // 3. どのボタンどうしも 16px 以上離れている。
        // 「隣り合う」を順番で決めない（横並びでもボタンの高さが違えば `top` は
        // ずれるので、上下で並べ替えると別の組を隣と見なす）。
        // 離れていない組が 1 つでもあれば誤タップの経路になるので、総当たりで見る
        final entries = rects.entries.toList();
        for (var i = 0; i < entries.length; i++) {
          for (var j = i + 1; j < entries.length; j++) {
            final gap = separation(entries[i].value, entries[j].value);
            expect(gap, greaterThanOrEqualTo(minGap - epsilon),
                reason: '$name: 「${entries[i].key}」と「${entries[j].key}」が'
                    '近すぎる（$gap）');
          }
        }
      });
    }
  }
}

void main() {
  expectDoesNotOverflow(
    'AI変換エラー',
    open: (context) => showAIConversionErrorDialog(
      context: context,
      originalText: '変換のもとになった文',
      onRetry: () {},
      onUseOriginal: () {},
    ),
    labels: ['キャンセル', '再試行', '元のテキストを使用'],
  );

  expectDoesNotOverflow(
    '読み上げエラー',
    open: (context) => showTTSErrorDialog(context: context, onRetry: () {}),
    labels: ['再試行', 'OK'],
  );
}
