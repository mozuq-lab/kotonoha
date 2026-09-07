/// 緊急機能のコントラスト比回帰テスト
/// テスト対象
/// lib/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart
/// lib/features/emergency/presentation/screens/emergency_alert_screen.dart
/// WCAG 2.1 AA を満たし続けることを保証する。
/// 背景（実障害）: 緊急系の背景色は `getEmergencyColor` でテーマごとに
/// 変わるのに、前景は `Colors.white` 固定・説明文は `Colors.grey` 固定だった。
/// 確認ダイアログの説明文 Colors.grey(#9E9E9E): ライト 2.46:1 / 高コントラスト 2.68:1
/// 「はい」ボタンの白文字: ダーク(#EF5350) 3.49:1 / 高コントラスト(#FF0000) 4.00:1
/// 緊急画面の白文字・白アイコン: 同上
/// 緊急ボタン本体の白アイコン: 同上
/// 設計判断: 緊急表示の赤は「目立たせる」ための色であり暗くしない。
/// 背景色の輝度から黒・白のうちコントラスト比が高い方を選ぶ
/// （[bestContrastingTextColor]）ことで、赤を保ったまま基準を満たす。
/// 重要: 色は宣言値ではなく**解決済みの描画色**から読む。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

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

/// ボタンが実際に描画している背景色を取り出す
/// `ElevatedButton.styleFrom(backgroundColor:)` の宣言値ではなく
/// ButtonStyleButton が生成する Material の色を読む。背景の指定が
/// 外れてテーマ既定へフォールバックした場合もその実色で判定できる。
Color _buttonBackground(WidgetTester tester, Finder buttonFinder) {
  final material = tester.widget<Material>(
    find.descendant(of: buttonFinder, matching: find.byType(Material)).first,
  );
  return material.color!;
}

Future<void> _pumpConfirmationDialog(
    WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => EmergencyConfirmationDialog(
                onConfirm: () {},
                onCancel: () {},
              ),
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

Future<void> _pumpAlertScreen(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: EmergencyAlertScreen(onReset: () {}),
    ),
  );
  await tester.pumpAndSettle();
}

/// 緊急ボタンのアイコンは非テキスト要素だが、**4.5:1（テキスト基準）** で判定する。
/// 理由: このボタンは app_shell 経由で全画面に常時表示される、本アプリで
/// 最も重要な操作であり、アイコンが唯一のラベルでもある。緊急「画面」の警告
/// アイコンを同じ考え方で 5.25〜6.02:1 まで引き上げた以上、緊急「ボタン」を
/// 非テキストの最低ライン(3:1)に留める理由がない。
const double _emergencyIconMinRatio = 4.5;

void main() {
  group('緊急呼び出しボタン（常時表示）', () {
    for (final entry in _themes.entries) {
      testWidgets(
          '${entry.key}テーマでアイコンが '
          '$_emergencyIconMinRatio:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Scaffold(
              body: Center(
                child: EmergencyButtonWithConfirmation(
                  onEmergencyConfirmed: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 円形ボタンの実描画背景（Ink の decoration）を読む
        final decoration =
            tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;
        final background = decoration.color!;
        final icon = resolvedIconColor(
          tester,
          find.byIcon(Icons.notifications_active),
        );

        expectOpaque(background, '${entry.key}テーマの緊急ボタン背景');
        expectOpaque(icon, '${entry.key}テーマの緊急ボタンアイコン');

        final ratio = contrastRatio(icon, background);
        expect(
          ratio,
          greaterThanOrEqualTo(_emergencyIconMinRatio),
          reason: '${entry.key}テーマの緊急ボタンアイコンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で '
              '$_emergencyIconMinRatio:1 未達',
        );
      });
    }
  });

  group('緊急呼び出し確認ダイアログ', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで説明文が 4.5:1 以上', (tester) async {
        await _pumpConfirmationDialog(tester, entry.value);

        final background = _dialogBackground(tester);
        final text = resolvedTextColor(
          tester,
          find.text('周囲に緊急音が鳴り、画面が赤くなります。'),
        );

        expectOpaque(background, '${entry.key}テーマのダイアログ背景');
        expectOpaque(text, '${entry.key}テーマの説明文');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの説明文のコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });

      for (final label in const ['はい', 'いいえ']) {
        testWidgets('${entry.key}テーマで「$label」ボタンの文字が 4.5:1 以上', (tester) async {
          await _pumpConfirmationDialog(tester, entry.value);

          final buttonFinder = find.widgetWithText(ElevatedButton, label);
          final background = _buttonBackground(tester, buttonFinder);
          final text = resolvedTextColor(tester, find.text(label));

          expectOpaque(background, '${entry.key}テーマの「$label」ボタン背景');
          expectOpaque(text, '${entry.key}テーマの「$label」ボタン文字');

          final ratio = contrastRatio(text, background);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}テーマの「$label」ボタンのコントラスト比が '
                '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
          );
        });
      }
    }
  });

  group('緊急画面', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで緊急メッセージが 4.5:1 以上', (tester) async {
        await _pumpAlertScreen(tester, entry.value);

        final background = tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(EmergencyAlertScreen),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        final text = resolvedTextColor(tester, find.text('緊急呼び出し中'));

        expectOpaque(background, '${entry.key}テーマの緊急画面背景');
        expectOpaque(text, '${entry.key}テーマの緊急メッセージ');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの緊急メッセージのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });

      testWidgets('${entry.key}テーマで警告アイコンが 3:1 以上', (tester) async {
        await _pumpAlertScreen(tester, entry.value);

        final background = tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(EmergencyAlertScreen),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        final icon = resolvedIconColor(tester, find.byIcon(Icons.warning));

        expectOpaque(icon, '${entry.key}テーマの警告アイコン');

        final ratio = contrastRatio(icon, background);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason: '${entry.key}テーマの警告アイコンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
        );
      });

      testWidgets('${entry.key}テーマでリセットボタンが基準を満たす', (tester) async {
        await _pumpAlertScreen(tester, entry.value);

        final screenBackground = tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(EmergencyAlertScreen),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        final buttonFinder = find.widgetWithText(ElevatedButton, 'リセット');
        final buttonBackground = _buttonBackground(tester, buttonFinder);
        final text = resolvedTextColor(tester, find.text('リセット'));

        expectOpaque(buttonBackground, '${entry.key}テーマのリセットボタン背景');
        expectOpaque(text, '${entry.key}テーマのリセットボタン文字');

        final textRatio = contrastRatio(text, buttonBackground);
        expect(
          textRatio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのリセットボタン文字のコントラスト比が '
              '${textRatio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );

        // ボタン面と全面赤の境界は非テキスト（WCAG 1.4.11）
        final surfaceRatio = contrastRatio(buttonBackground, screenBackground);
        expect(
          surfaceRatio,
          greaterThanOrEqualTo(3.0),
          reason: '${entry.key}テーマのリセットボタンと背景の境界が '
              '${surfaceRatio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
        );
      });
    }
  });
}
