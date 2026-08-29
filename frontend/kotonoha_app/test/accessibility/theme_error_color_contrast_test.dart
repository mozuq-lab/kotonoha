/// テーマのエラー色のコントラスト比回帰テスト
///
/// 【テスト対象】: lib/core/themes/{light,dark,high_contrast}_theme.dart の
/// `colorScheme.error` / `colorScheme.onError`
/// 【テスト目的】: エラー色は2通りの使われ方をするため、その両方で
/// WCAG 2.1 AA を満たし続けることを保証する。
///
/// 1. 前景として: `TextField.errorText` やエラーアイコンなど、
///    テーマの surface 上に `error` 色そのものを描画する使い方
/// 2. 背景として: 削除ボタンなど、`error` を背景に `onError` を載せる使い方
///
/// 【背景（実障害）】:
/// - ダークテーマは error に #D32F2F（ライト用の濃い赤）を流用していたため、
///   surface(#1E1E1E) 上で 3.35:1、onError(黒)との組み合わせで 4.22:1 と
///   どちらの使い方でもAA未達だった
/// - 高コントラストテーマは error に純赤 #FF0000 を使い、白背景・白文字の
///   いずれに対しても 4.00:1 しかなかった（コード上のコメントは 5.25:1 と
///   誤記されていた）
///
/// 【緊急色との分離】: エラー色（破壊的操作・エラー表示）と緊急色は
/// 意味が違うため、同一画面に並んでも見分けられる必要がある。
/// home_screen の ClearAllButton（error 背景の塗りボタン）と app_shell の
/// EmergencyButtonWithConfirmation（緊急色の塗りボタン）は同時に描画される。
/// 以前はライト・ダークとも両者が完全に同一色だった。
/// ただし「輝度比でどれだけ離すか」は数値で固定できない（下記の長いコメント参照）。
/// 実際の識別は色以外の手段（ラベル・形状・枠線）が担う。
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

import '../support/contrast_helpers.dart';

final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

// 【輝度比による「分離」の閾値を置いていない理由】
//
// 以前ここには `_minRoleSeparation = 1.4` という定数があった。しかしこの値は
// 「現状の実測（ライト1.83 / ダーク2.04 / 高コントラスト1.47）のうち最小のものが
// 通る値」として逆算したもので、狙っていた不具合（高コントラストで2つの赤が
// 見分けられない）を原理的に検出できなかった。閾値が現状値に追従する限り、
// テストは常に緑になる。
//
// では原理的な閾値（WCAG 1.4.11 非テキストの 3:1）へ引き上げればよいかというと、
// **数学的に成立しない**。エラー色には次の3つが同時に課される:
//   (a) 面の上の文字として 4.5:1 以上
//   (b) onError を載せた背景として 4.5:1 以上
//   (c) 緊急色との輝度比 3:1 以上
// 全色空間を探索した結果、(a)(b)(c) を同時に満たす色は
//   ライト・高コントラスト: #140000 付近（黒と区別が付かない暗い赤）
//   ダーク:                 #FCEAE8 付近（白と区別が付かない淡いピンク）
// しか存在しない。とくにダークは、緊急色 emergencyDark(#EF5350, 輝度0.2512) に対し
// 3:1 を満たす輝度が 0.0504 以下か 0.8535 以上である一方、暗い面(#1E1E1E)の上で
// 4.5:1 を満たすには 0.2334 以上が必要で、下側の枝は最初から両立しない。
// つまり「どちらも赤に見えて、どちらもAAを満たし、輝度でも十分離れている」は
// 同時に成立しない要求である。
//
// したがってこのテストは輝度比で分離を主張しない。代わりに
//   1. 2色が同一値でないこと
//   2. それぞれが自分のAA義務を満たすこと（後続のグループ）
//   3. **色以外の識別手段が存在すること**（WCAG 1.4.1「色だけに依存しない」）
// を固定する。3 が実際の安全弁であり、輝度比の数字ではない。

void main() {
  group('エラー色と緊急色の分離', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで両者が同一色でない', (tester) async {
        late Color errorColor;
        late Color emergencyColor;
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                errorColor = Theme.of(context).colorScheme.error;
                emergencyColor =
                    EmergencyConfirmationDialog.getEmergencyColor(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          errorColor,
          isNot(equals(emergencyColor)),
          reason: '${entry.key}テーマでエラー色と緊急色が完全に同一（$errorColor）。'
              '破壊的操作のボタンと緊急ボタンが同じ画面に並ぶため区別できない',
        );
      });
    }
  });

  group('色以外の識別手段', () {
    // 【このテストが実際の安全弁である理由】: 上記のとおり、エラー色と緊急色を
    // 輝度で十分に離すことはAA要件と両立しない。WCAG 1.4.1 が求めるとおり、
    // 色だけに依存しない識別手段が要る。ClearAllButton と
    // EmergencyButtonWithConfirmation はどちらも同じ画面に常時並ぶため、
    // 両者が異なるアクセシブルラベルを持つことを固定する。
    // 【定数比較ではなく実描画を見る理由】: 一度は
    // `clearAllButtonSemanticsLabel != emergencyButtonSemanticsLabel` という
    // 定数同士の比較で済ませていたが、それはウィジェットがその定数を実際に
    // 使っていることを何も保証しない。実際、全消去ボタンの label を
    // 緊急ボタンと同一の文字列リテラルに書き換えても全テストが緑のまま通った。
    // 輝度比の逆算閾値を「原理的に検出できない」と批判して置き換えたものが、
    // 同じく検出できないテストになっていた。実際に描画してセマンティクスを読む。
    testWidgets('全消去ボタンと緊急ボタンが異なるラベルで描画される', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const ClearAllButton(),
                EmergencyButtonWithConfirmation(onEmergencyConfirmed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clearLabel = tester.getSemantics(find.byType(ClearAllButton)).label;
      final emergencyLabel = tester
          .getSemantics(find.byType(EmergencyButtonWithConfirmation))
          .label;

      expect(clearLabel, isNotEmpty, reason: '全消去ボタンにラベルが無い');
      expect(emergencyLabel, isNotEmpty, reason: '緊急ボタンにラベルが無い');
      expect(
        clearLabel,
        isNot(equals(emergencyLabel)),
        reason: '全消去ボタンと緊急ボタンのアクセシブルラベルが同一（$clearLabel）。'
            '2つの赤を輝度で見分けられない利用者にとって、ラベルが唯一の識別手段になる',
      );

      // addTearDown は終了時検証より後に走るため、明示的に破棄する
      handle.dispose();
    });
  });

  group('colorScheme.error を背景にした SnackBar', () {
    // history_screen / favorites_screen は backgroundColor に error だけを渡し、
    // 本文の色は SnackBar 既定（onInverseSurface）に任せている。
    // 「背景を固定しつつ前景をテーマ継承にする」形なので、error を変えると
    // 気付かないうちに破綻しうる。実際に使っている組み合わせで固定する。
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで本文が 4.5:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('読み上げに失敗しました'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final background = snackBar.backgroundColor!;
        final text = resolvedTextColor(tester, find.text('読み上げに失敗しました'));

        expectOpaque(background, '${entry.key}テーマのスナックバー背景');
        expectOpaque(text, '${entry.key}テーマのスナックバー本文色');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのスナックバー本文のコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });

  group('colorScheme.error', () {
    for (final entry in _themes.entries) {
      test('${entry.key}テーマ: surface上の文字色として 4.5:1 以上', () {
        final scheme = entry.value.colorScheme;

        expectOpaque(scheme.error, '${entry.key}テーマの error');
        expectOpaque(scheme.surface, '${entry.key}テーマの surface');

        final ratio = contrastRatio(scheme.error, scheme.surface);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの error を surface 上の文字に使うと '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });

      test('${entry.key}テーマ: 背景として onError と 4.5:1 以上', () {
        final scheme = entry.value.colorScheme;

        expectOpaque(scheme.onError, '${entry.key}テーマの onError');

        final ratio = contrastRatio(scheme.onError, scheme.error);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの error 背景 + onError 文字が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });
}
