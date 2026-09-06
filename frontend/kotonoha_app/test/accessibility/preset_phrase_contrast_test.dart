/// 定型文まわりのコントラスト比回帰テスト
///
/// テスト対象:
/// - lib/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart
/// - lib/features/preset_phrase/presentation/widgets/phrase_form_content.dart
/// テスト目的: 3テーマ（ライト／ダーク／高コントラスト）すべてで
/// WCAG 2.1 AA を満たし続けることを保証する。
///
/// 背景（実障害）: いずれも `Colors.red`(#F44336) を固定で使っていた。
/// - 削除ボタン: 赤背景 + 白文字で 3.68:1（全テーマ共通）
/// - 文字数超過カウンター: 赤文字をテーマの surface に載せており
///   ライト 3.38:1 / 高コントラスト 3.68:1
///
/// 方針: 赤を自前で持たず `colorScheme.error` を使う。エラー色は
/// テーマごとに背景（surface）との組み合わせでAAを満たすよう定義されており、
/// ボタン背景として使う場合の文字色は背景輝度から選ぶ。
///
/// 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

/// ダイアログの実描画背景色を取り出す
Color _dialogBackground(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
            of: find.byType(AlertDialog), matching: find.byType(Material))
        .first,
  );
  return material.color!;
}

/// ダイアログ内に任意のコンテンツを載せて表示する
Future<void> _pumpDialog(
  WidgetTester tester,
  ThemeData theme,
  Widget Function(BuildContext context) builder,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: builder,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('定型文の削除確認ダイアログ', () {
    final phrase = PresetPhrase(
      id: '1',
      content: 'テスト定型文',
      category: 'daily',
      displayOrder: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで削除ボタンの文字が 4.5:1 以上', (tester) async {
        await _pumpDialog(
          tester,
          entry.value,
          (_) => PhraseDeleteDialog(phrase: phrase),
        );

        final buttonFinder = find.widgetWithText(ElevatedButton, '削除');
        final background = tester
            .widget<Material>(
              find
                  .descendant(of: buttonFinder, matching: find.byType(Material))
                  .first,
            )
            .color!;
        final text = resolvedTextColor(tester, find.text('削除'));

        expectOpaque(background, '${entry.key}テーマの削除ボタン背景');
        expectOpaque(text, '${entry.key}テーマの削除ボタン文字');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの削除ボタンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });

      // この回帰テストの理由: 同じダイアログに並ぶ「削除」だけを直し、
      // 「キャンセル」は colorScheme.primary の既定のままでAA未達だった
      // （ライト 2.87:1 / ダーク 3.62:1）。破壊的操作とその取り消しは対で検証する。
      testWidgets('${entry.key}テーマでキャンセルボタンの文字が 4.5:1 以上', (tester) async {
        await _pumpDialog(
          tester,
          entry.value,
          (_) => PhraseDeleteDialog(phrase: phrase),
        );

        final background = tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(AlertDialog),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        final text = resolvedTextColor(tester, find.text('キャンセル'));

        expectOpaque(background, '${entry.key}テーマのダイアログ背景');
        expectOpaque(text, '${entry.key}テーマのキャンセルボタン文字');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのキャンセルボタンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });

  group('定型文フォームの文字数カウンター（上限到達時）', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマでカウンターが 4.5:1 以上', (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await _pumpDialog(
          tester,
          entry.value,
          (_) => AlertDialog(
            content: SingleChildScrollView(
              child: PhraseFormContent(
                controller: controller,
                selectedCategory: 'daily',
                onCategoryChanged: (_) {},
                currentLength: PresetPhraseValidator.maxLength,
              ),
            ),
          ),
        );

        final background = _dialogBackground(tester);
        final counterFinder = find.text(
          '${PresetPhraseValidator.maxLength}/${PresetPhraseValidator.maxLength}',
        );
        expect(counterFinder, findsOneWidget,
            reason: '文字数カウンターを特定できない（構造変更の可能性）');
        final text = resolvedTextColor(tester, counterFinder);

        expectOpaque(background, '${entry.key}テーマのダイアログ背景');
        expectOpaque(text, '${entry.key}テーマのカウンター文字');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのカウンターのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });
}
