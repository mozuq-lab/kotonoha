/// 誤操作防止ダイアログが、どれも同じ並びの契約を満たすこと（台帳 L-130・L-131）
///
/// 契約そのものと、なぜそれが要るのかは `confirmation_dialog_contract.dart` に書いた。
/// ここでは「取り消し ＋ 取り消せない実行」の二択を出す**すべての**ダイアログに
/// それを当てる。新しくこの形のダイアログを足したら、この一覧にも足すこと。
///
/// **どのケースも本番の入口から開く。** テストの中で `ConfirmationDialog` を
/// 組み直すと、呼び出し元が素の `AlertDialog` に戻されても緑のまま通る
/// （台帳 L-135。`send_to_input_button.dart` を戻して 2230 本が全部緑になった）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:kotonoha_app/shared/widgets/send_to_input_button.dart';

import 'confirmation_dialog_contract.dart';

class _Favorites extends FavoriteNotifier {
  _Favorites(this._state);
  final FavoriteState _state;
  @override
  FavoriteState build() => _state;
}

/// 入力欄に文が入っている状態（空だと確認ダイアログは出ず、そのまま置き換わる）
class _FilledBuffer extends InputBufferNotifier {
  @override
  String build() => '入力中の文';
}

class _Histories extends HistoryNotifier {
  _Histories(this._state);
  final HistoryState _state;
  @override
  HistoryState build() => _state;
}

PresetPhrase _phrase() => PresetPhrase(
      id: 'p1',
      content: 'テスト',
      category: 'daily',
      displayOrder: 0,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

/// タップで開く入口をひとつだけ置いた画面（本番のウィジェットをそのまま置く）
Widget _screenWith(Widget entry) => Scaffold(body: Center(child: entry));

/// ダイアログ自体が公開ウィジェットのもの。本番の `showDialog` と同じ形で開く
Widget _opener(Widget Function(BuildContext context) dialog) => Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: dialog,
          ),
          child: const Text('開く'),
        ),
      ),
    );

Future<void> _tapText(WidgetTester tester, String text) =>
    tester.tap(find.text(text));

Future<void> _tapIcon(WidgetTester tester, IconData icon) =>
    tester.tap(find.byIcon(icon));

void main() {
  // --- ダイアログ自体が公開ウィジェット ---

  expectMeetsContract(
    '全消去の確認',
    home: () => _screenWith(const ClearAllButton(enabled: true)),
    open: (tester) => _tapIcon(tester, Icons.delete_outline),
    cancelLabel: 'いいえ',
    confirmLabel: 'はい',
  );

  expectMeetsContract(
    '定型文の削除',
    home: () => _opener((_) => PhraseDeleteDialog(phrase: _phrase())),
    open: (tester) => _tapText(tester, '開く'),
    cancelLabel: 'キャンセル',
    confirmLabel: '削除',
  );

  // 本文がフォームなので `ConfirmationDialog` には入らない。
  // 並びだけ `ConfirmationDialogLayout` から取っている（台帳 L-130）
  expectMeetsContract(
    '定型文の追加',
    home: () => _opener((_) => const PhraseAddDialog()),
    open: (tester) => _tapText(tester, '開く'),
    cancelLabel: 'キャンセル',
    confirmLabel: '保存',
  );

  expectMeetsContract(
    '定型文の編集',
    home: () => _opener((_) => PhraseEditDialog(phrase: _phrase())),
    open: (tester) => _tapText(tester, '開く'),
    cancelLabel: 'キャンセル',
    confirmLabel: '保存',
  );

  // 緊急呼び出しだけは `ConfirmationDialog` を使わず自前で組む（色・連続タップ
  // 防止・補足行・固定箱のため）。並びは同じ `ConfirmationDialogLayout` から
  // 取っているが、「取っているつもり」で済ませず契約そのものを当てる
  expectMeetsContract(
    '緊急呼び出しの確認',
    home: () => _screenWith(
      EmergencyButtonWithConfirmation(onEmergencyConfirmed: () {}),
    ),
    open: (tester) => tester.tap(find.byType(EmergencyButtonWithConfirmation)),
    cancelLabel: EmergencyConfirmationDialog.cancelLabel,
    confirmLabel: EmergencyConfirmationDialog.confirmLabel,
  );

  // --- 画面の中で `ConfirmationDialog` を組んでいるもの（画面ごと pump する） ---

  final favorite = Favorite(
    id: 'f1',
    content: 'こんにちは',
    createdAt: DateTime(2026, 9, 1),
    displayOrder: 0,
  );
  Widget favoriteScope(Widget app) => ProviderScope(
        overrides: [
          favoriteProvider.overrideWith(
            () => _Favorites(FavoriteState(favorites: [favorite])),
          ),
        ],
        child: app,
      );

  expectMeetsContract(
    'お気に入りの削除（個別）',
    home: FavoritesScreen.new,
    open: (tester) => _tapIcon(tester, Icons.delete),
    cancelLabel: 'キャンセル',
    confirmLabel: '削除',
    scope: favoriteScope,
  );

  expectMeetsContract(
    'お気に入りの削除（全件）',
    home: FavoritesScreen.new,
    open: (tester) => _tapIcon(tester, Icons.delete_sweep),
    cancelLabel: 'キャンセル',
    confirmLabel: '削除',
    scope: favoriteScope,
  );

  expectMeetsContract(
    '履歴の削除（全件）',
    home: HistoryScreen.new,
    open: (tester) => _tapIcon(tester, Icons.delete_sweep),
    cancelLabel: 'キャンセル',
    confirmLabel: '削除',
    scope: (app) => ProviderScope(
      overrides: [
        historyProvider.overrideWith(
          () => _Histories(
            HistoryState(
              histories: [
                History(
                  id: 'h1',
                  content: 'こんにちは',
                  createdAt: DateTime(2026, 9, 1),
                  type: HistoryType.manualInput,
                ),
              ],
            ),
          ),
        ),
      ],
      child: app,
    ),
  );

  expectMeetsContract(
    '入力欄の置き換え',
    home: () => _screenWith(const SendToInputButton(text: '置き換える文')),
    open: (tester) => _tapText(tester, '入力欄へ'),
    cancelLabel: 'キャンセル',
    confirmLabel: '置き換える',
    scope: (app) => ProviderScope(
      overrides: [inputBufferProvider.overrideWith(_FilledBuffer.new)],
      child: app,
    ),
  );

  // 「取り消せない実行だけを塗って見分けられるようにする」という決定に
  // 観測点を置く。レビューで、`colorScheme.error` をリテラルの赤に変えても、
  // `destructive` を `primary` に変えても 769 本が緑のままだと分かったため
  // （どちらも比率だけ見る既存テストを通ってしまう）。
  // 色そのものは決定（`light_theme.dart` の「緊急色との分離 1.83:1」）なので、
  // テーマの役割色と一致することを見る。面とのコントラストは台帳 L-132。
  for (final (themeName, theme) in [
    ('ライト', lightTheme),
    ('ダーク', darkTheme),
    ('高コントラスト', highContrastTheme),
  ]) {
    for (final (kindName, kind, expected) in [
      ('destructive', ConfirmKind.destructive, (ColorScheme c) => c.error),
      ('normal', ConfirmKind.normal, (ColorScheme c) => c.primary),
    ]) {
      testWidgets('$themeName: $kindName の実行ボタンはテーマの役割色で塗る', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ConfirmationDialog(
                      title: '確認',
                      message: '消しますか？',
                      cancelLabel: 'いいえ',
                      confirmLabel: 'はい',
                      kind: kind,
                      onCancel: () {},
                      onConfirm: () {},
                    ),
                  ),
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'はい'),
        );
        final background = button.style!.backgroundColor!.resolve({});
        expect(background, expected(theme.colorScheme));
        // 取り消しと同じ見た目にならないこと（見分けがつかないと意味がない）
        final cancel = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'いいえ'),
        );
        expect(cancel.style?.backgroundColor?.resolve({}), isNot(background));
      });
    }
  }
}
