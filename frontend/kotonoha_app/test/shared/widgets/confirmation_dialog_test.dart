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
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/favorites/presentation/favorites_screen.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/presentation/history_screen.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/preset_phrase_screen.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
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

class _Online extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.online;
}

/// AI 変換にまだ同意していない状態（`AppSettings` の既定）
class _NotYetAccepted extends SettingsNotifier {
  @override
  Future<AppSettings> build() async => const AppSettings();
}

class _Phrases extends PresetPhraseNotifier {
  _Phrases(this._state);
  final PresetPhraseState _state;
  @override
  PresetPhraseState build() => _state;
}

/// 実プラグイン（FlutterTts）を触らせないためのスタブ
class _StubTts extends TTSNotifier {
  @override
  TTSServiceState build() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );
  @override
  Future<void> speak(String text) async {}
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

  // 定型文の 3 つは `PresetPhraseScreen` から開く。ここをテストの中で
  // 組み直すと、画面側が素の `AlertDialog` に戻されても気づけない（L-135）。
  // 一覧に 1 件だけ置く（✏️ と 🗑 は行数ぶん並ぶので、複数あると掴めない）
  Widget phraseScope(Widget app) => ProviderScope(
        overrides: [
          presetPhraseNotifierProvider.overrideWith(
            () => _Phrases(PresetPhraseState(phrases: [_phrase()])),
          ),
          ttsProvider.overrideWith(_StubTts.new),
        ],
        child: app,
      );

  expectMeetsContract(
    '定型文の削除',
    home: PresetPhraseScreen.new,
    open: (tester) => _tapIcon(tester, Icons.delete_outline),
    cancelLabel: 'キャンセル',
    confirmLabel: '削除',
    scope: phraseScope,
  );

  // 本文がフォームなので `ConfirmationDialog` には入らない。
  // 並びだけ `ConfirmationDialogLayout.build` から取っている（台帳 L-130）
  expectMeetsContract(
    '定型文の追加',
    // 本文がフォーム。キーボードが出た状態でも当てる（`scrollable` が効く場面）
    withKeyboard: true,
    home: PresetPhraseScreen.new,
    open: (tester) => _tapIcon(tester, Icons.add),
    cancelLabel: 'キャンセル',
    confirmLabel: '保存',
    scope: phraseScope,
  );

  expectMeetsContract(
    '定型文の編集',
    // 本文がフォーム。キーボードが出た状態でも当てる（`scrollable` が効く場面）
    withKeyboard: true,
    home: PresetPhraseScreen.new,
    open: (tester) => _tapIcon(tester, Icons.edit),
    cancelLabel: 'キャンセル',
    confirmLabel: '保存',
    scope: phraseScope,
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

  // --- 「取り消せない実行だけを塗って見分けられるようにする」という決定 ---
  //
  // レビューで 2 つの穴が見つかった（2026-09-20）。
  //   1. `style` を見ると、テーマ側で塗られている場合に null が返る。
  //      取り消しボタンを実行とまったく同じ赤に塗っても気づかなかった
  //   2. テストの中で `kind:` を明示して組むと、**本番の呼び出し元が
  //      どちらを受け取るか**を見ていない。`kind` の既定を `normal` に
  //      変えても全テストが緑のままだった
  // そこで、本番の入口から開いて**描画された色**を見る。
  for (final (themeName, theme) in [
    ('ライト', lightTheme),
    ('ダーク', darkTheme),
    ('高コントラスト', highContrastTheme),
  ]) {
    testWidgets('$themeName: 全消去の「はい」は error 色で塗られ、「いいえ」と区別できる',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Center(child: ClearAllButton(enabled: true)),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      final confirm = renderedButtonColor(tester, 'はい');
      final cancel = renderedButtonColor(tester, 'いいえ');

      // 取り消せない実行はテーマの error 色。`kind` の既定が変わるとここが落ちる
      expect(confirm, theme.colorScheme.error,
          reason: '$themeName: 実行ボタンが error 色で塗られていない');
      // 取り消しと同じ見た目では、そもそも見分けがつかない
      expect(cancel, isNot(confirm),
          reason: '$themeName: 取り消しと実行が同じ色（いいえ=$cancel はい=$confirm）');
    });
  }

  // `ConfirmKind.normal` を使う本番の経路は AI 変換の同意だけ。
  // `HomeScreen` は永久に動くアニメーションを持つので `pumpAndSettle` が
  // 返らない。フレームを決め打ちで進める（`settle` の差し替え口）
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  expectMeetsContract(
    'AI変換の利用確認',
    home: HomeScreen.new,
    open: (tester) => tester.tap(find.widgetWithText(ElevatedButton, 'AI変換')),
    cancelLabel: '同意しない',
    confirmLabel: '同意して利用',
    settle: pumpFrames,
    scope: (app) => ProviderScope(
      overrides: [
        inputBufferProvider.overrideWith(_FilledBuffer.new),
        networkProvider.overrideWith(_Online.new),
        settingsNotifierProvider.overrideWith(_NotYetAccepted.new),
        ttsProvider.overrideWith(_StubTts.new),
      ],
      child: app,
    ),
  );

  // AI 同意も 3 テーマで、取り消しとの区別まで見る（destructive と同じ扱い）
  for (final (themeName, theme) in [
    ('ライト', lightTheme),
    ('ダーク', darkTheme),
    ('高コントラスト', highContrastTheme),
  ]) {
    testWidgets('$themeName: AI変換の同意は primary 色で、「同意しない」と区別できる',
        (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inputBufferProvider.overrideWith(_FilledBuffer.new),
            networkProvider.overrideWith(_Online.new),
            settingsNotifierProvider.overrideWith(_NotYetAccepted.new),
            ttsProvider.overrideWith(_StubTts.new),
          ],
          child: MaterialApp(theme: theme, home: const HomeScreen()),
        ),
      );
      await pumpFrames(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'AI変換'));
      await pumpFrames(tester);

      final confirm = renderedButtonColor(tester, '同意して利用');
      final cancel = renderedButtonColor(tester, '同意しない');

      // データを消す操作ではないので error ではなく primary
      expect(confirm, theme.colorScheme.primary,
          reason: '$themeName: 同意ボタンが primary 色で塗られていない');
      // 取り消しと同じ見た目では、そもそも見分けがつかない
      expect(cancel, isNot(confirm),
          reason: '$themeName: 同意しないと同意して利用が同じ色'
              '（同意しない=$cancel 同意して利用=$confirm）');
      // destructive と同じ色では、重さの差が伝わらない
      expect(theme.colorScheme.primary, isNot(theme.colorScheme.error),
          reason: '$themeName: primary と error が同じ色');
    });
  }
}
