/// オフラインダイアログのコントラスト比回帰テスト
///
/// テスト対象:
/// lib/features/network/presentation/widgets/network_aware_scaffold.dart の
/// `showOfflineAIConversionDialog()`
/// テスト目的: 3テーマ（ライト／ダーク／高コントラスト）すべてで
/// WCAG 2.1 AA を満たし続けることを保証する。
///
/// 背景（実障害）: このダイアログは背景色を自前で持たずテーマの surface に
/// 載るのに、アイコン色を `Colors.grey[700]`(#616161) に固定していたため、
/// ダークテーマの背景 (#1E1E1E) に対し 2.69:1 と非テキスト基準(3:1)未達だった。
///
/// 方針: アプリ内の警告アイコン共通の `warningIconColor()`
/// （lib/core/themes/theme_colors.dart）を再利用し、テーマの明暗に応じた色を使う。
///
/// 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/network_aware_scaffold.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

void main() {
  group('オフライン時のAI変換ダイアログ', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマでアイコンが 3:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showOfflineAIConversionDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

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
        final icon = resolvedIconColor(tester, find.byIcon(Icons.wifi_off));

        expectOpaque(background, '${entry.key}テーマのダイアログ背景');
        expectOpaque(icon, '${entry.key}テーマのオフラインアイコン');

        final ratio = contrastRatio(icon, background);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason: '${entry.key}テーマのオフラインアイコンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
        );
      });

      testWidgets('${entry.key}テーマで本文が 4.5:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showOfflineAIConversionDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

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
        final body = resolvedTextColor(
          tester,
          find.textContaining('AI変換機能はインターネット接続が必要です。'),
        );

        expectOpaque(body, '${entry.key}テーマの本文色');

        final ratio = contrastRatio(body, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの本文のコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });

      // この回帰テストの理由: アイコンと本文は測っていたが、ユーザーが必ず押す
      // 唯一の操作要素である「OK」は colorScheme.primary の既定のままAA未達だった
      // （ライト 2.87:1 / ダーク 3.62:1）。操作要素こそ最初に検証する。
      testWidgets('${entry.key}テーマでOKボタンの文字が 4.5:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showOfflineAIConversionDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

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
        final text = resolvedTextColor(tester, find.text('OK'));

        expectOpaque(background, '${entry.key}テーマのダイアログ背景');
        expectOpaque(text, '${entry.key}テーマのOKボタン文字');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのOKボタンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });
}
