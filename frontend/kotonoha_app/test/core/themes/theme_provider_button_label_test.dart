/// ボタンラベルの文字サイズがフォント設定に追従する（タスクレビュー反映）
/// 「中」では基準値（実測値）そのままで 1px も変えない。
/// 基準値（このテストで実測・記録した値）:
/// ElevatedButton: 20.0（テーマの ElevatedButtonThemeData.style.textStyle が明示）
/// TextButton / OutlinedButton / FilledButton: 14.0（テーマに textStyle の明示が無く、
/// Material のレンダリング既定値で描かれている）
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

/// 設定を固定して返す Notifier（SharedPreferences を読まない）
/// テーマ倍率テスト（theme_provider_font_size_test.dart）と同じもの
class _FixedSettings extends SettingsNotifier {
  _FixedSettings(this._settings);
  final AppSettings _settings;

  @override
  Future<AppSettings> build() async => _settings;
}

/// 設定を後から書き換えられる Notifier（`_FixedSettings` は初期値の固定のみ）。
/// `AnimatedTheme`（既定 200ms）のアニメーション途中の値を観測するには、
/// 描画済みの container の設定を実行時に差し替える必要がある
/// （`ProviderScope.overrides` を作り直しても既存 container には反映されない。
/// round 2 の報告で実測済み）。
class _MutableSettings extends SettingsNotifier {
  _MutableSettings(this._initial);
  final AppSettings _initial;

  @override
  Future<AppSettings> build() async => _initial;

  /// テスト用: SharedPreferences へは保存せず、state だけを書き換える。
  void setFontSizeForTest(FontSize size) {
    final current = state.asData?.value ?? _initial;
    state = AsyncValue.data(current.copyWith(fontSize: size));
  }
}

void main() {
  // ButtonStyle の実効フォントサイズはテーマの ThemeData だけでは測れない
  // （M3 の既定値との合成は実際の描画時に解決される）ため、
  // 実際にボタンを描画して RenderParagraph で測る。
  Future<void> pumpButtons(WidgetTester tester, FontSize size) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith(
            () => _FixedSettings(AppSettings(fontSize: size)),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: ref.watch(currentThemeProvider),
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('保存')),
                  TextButton(onPressed: () {}, child: const Text('キャンセル')),
                  OutlinedButton(onPressed: () {}, child: const Text('枠線')),
                  FilledButton(onPressed: () {}, child: const Text('塗り')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double sizeOf(WidgetTester tester, String text) => tester
      .renderObject<RenderParagraph>(find.text(text))
      .text
      .style!
      .fontSize!;

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

  const elevatedBase = 20.0;
  const textOutlinedFilledBase = 14.0;

  group('「中」（既定）ではボタンラベルの実効サイズが 1px も変わらない', () {
    testWidgets('ElevatedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, '保存'), elevatedBase);
    });

    testWidgets('TextButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, 'キャンセル'), textOutlinedFilledBase);
    });

    testWidgets('OutlinedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, '枠線'), textOutlinedFilledBase);
    });

    testWidgets('FilledButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, '塗り'), textOutlinedFilledBase);
    });
  });

  group('「大」ではボタンラベルが基準値 × 1.2 になる', () {
    testWidgets('ElevatedButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(sizeOf(tester, '保存'), closeTo(elevatedBase * 1.2, 0.01));
    });

    testWidgets('TextButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(
        sizeOf(tester, 'キャンセル'),
        closeTo(textOutlinedFilledBase * 1.2, 0.01),
      );
    });

    testWidgets('OutlinedButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(
        sizeOf(tester, '枠線'),
        closeTo(textOutlinedFilledBase * 1.2, 0.01),
      );
    });

    testWidgets('FilledButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(
        sizeOf(tester, '塗り'),
        closeTo(textOutlinedFilledBase * 1.2, 0.01),
      );
    });
  });

  group('「大」でも fontSize 以外（fontWeight・letterSpacing・fontFamily）は変わらない（再レビュー反映）',
      () {
    // なぜ: サイズだけを見るテストは、テーマの既定スタイル（太さ・字間・
    // フォントファミリー等）を丸ごと素の TextStyle(fontSize:...) に
    // 置き換えてしまう実装のバグを検出できない（fontSize さえ合っていれば
    // 通ってしまう）。
    //
    // 「中」の基準値は独立した pump で実測した値（下記の一覧参照。
    // 同一テスト内で `pumpButtons` を 2 回呼んで「中→大」を比較する方法は
    // 採らない: `ProviderScope.overrides` は既存の container に対して
    // ホットスワップされず、2 回目の pump も 1 回目の設定のまま描画され続ける
    // ため、常に「変化なし」を観測してしまい、テストとして機能しない
    // （実際にこの罠で 4 本とも偽の green になることを確認した）。
    //
    // 中の基準値（実測、TextButton/OutlinedButton/FilledButton で共通）:
    //   fontWeight: FontWeight.w500, letterSpacing: 0.1, fontFamily: 'Roboto'
    //   （Material 3 既定 = `Theme.of(context).textTheme.labelLarge`。
    //   実体は `Typography.englishLike2021.labelLarge`。round 2 の報告参照）
    const defaultLabelFontWeight = FontWeight.w500;
    const defaultLabelLetterSpacing = 0.1;
    const defaultLabelFontFamily = 'Roboto';

    testWidgets('ElevatedButton は「大」でもテーマの太字のまま', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, '保存');
      expect(style.fontWeight, FontWeight.bold);
    });

    testWidgets('TextButton は「大」でも太さ・字間・フォントファミリーが変わらない', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, 'キャンセル');
      expect(style.fontWeight, defaultLabelFontWeight);
      expect(style.letterSpacing, defaultLabelLetterSpacing);
      expect(style.fontFamily, defaultLabelFontFamily);
    });

    testWidgets('OutlinedButton は「大」でも太さ・字間・フォントファミリーが変わらない', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, '枠線');
      expect(style.fontWeight, defaultLabelFontWeight);
      expect(style.letterSpacing, defaultLabelLetterSpacing);
      expect(style.fontFamily, defaultLabelFontFamily);
    });

    testWidgets('FilledButton は「大」でも太さ・字間・フォントファミリーが変わらない', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, '塗り');
      expect(style.fontWeight, defaultLabelFontWeight);
      expect(style.letterSpacing, defaultLabelLetterSpacing);
      expect(style.fontFamily, defaultLabelFontFamily);
    });
  });

  group('「中」でも Material 既定の太さ・字間・フォントファミリーである（基準値の裏付け）', () {
    testWidgets('TextButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, 'キャンセル');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0.1);
      expect(style.fontFamily, 'Roboto');
    });

    testWidgets('OutlinedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, '枠線');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0.1);
      expect(style.fontFamily, 'Roboto');
    });

    testWidgets('FilledButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, '塗り');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0.1);
      expect(style.fontFamily, 'Roboto');
    });

    testWidgets('ElevatedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, '保存');
      expect(style.fontWeight, FontWeight.bold);
    });
  });

  group('フォント設定「大」→「中」への切替でボタンラベルが止まらず追従する（P0、リスクレビュー反映）', () {
    // なぜ: `_scaled` が factor == 1.0 で早期リターンしていたとき、
    // TextButton/OutlinedButton/FilledButton の `textStyle` は「中」でだけ
    // null になり、「大」「小」では非 null になる非対称があった。
    // `MaterialApp` は既定で `theme:` を `AnimatedTheme`（200ms）に渡しており、
    // `ButtonStyle.lerp` は `textStyle` を `WidgetStateProperty.lerp` 経由で
    // `TextStyle.lerp` に渡す。片方が null だと `TextStyle.lerp` は
    // `t < 0.5` で旧値のまま・`t >= 0.5` で null へジャンプするステップ関数
    // （`text_style.dart`）。「大→小」のように両側とも非 null な遷移では
    // 素直な線形補間になり、この問題は出ない。
    //
    // 実測した挙動（10ms 刻み、`大→中`、修正前）:
    //   t=0〜200ms: 16.8（開始値のまま完全に静止。AnimatedTheme 自体の
    //     200ms の間ずっと動かない）
    //   t=210〜390ms: 16.66→14.14（AnimatedTheme が収束した後、
    //     ButtonStyleButton 自身の 200ms アニメーションが今度は動き出す）
    //   t=400ms: 14.0（ようやく収束）
    // つまり「200ms 止まってから遅れて動き出す」という段差が実際に見える
    // （リスクレビューが指摘した「一瞬固まってから遅れて追従する」不具合の
    // 実測波形）。250ms 時点では 16.1（目標 14.0 まで残り 2.1）。
    //
    // 修正後（`_scaled` が「中」でも常に非 null な textStyle を与える）は
    // 段差が無くなり、t=100ms の時点で既に目標へ向けて動き出している
    // （実測: t=100ms で 16.523、開始値 16.8 から明確に変化）。
    // ただし「いつ 14.0 ちょうどに収束するか」は修正の有無を判別しない
    // （ButtonStyleButton 自身の 200ms 分の追従アニメーションが
    // AnimatedTheme の 200ms の後に続くため、修正前後どちらも実測で
    // t=400ms に収束していた）。判別点は「最初の 100ms で動き出すか」。
    testWidgets('大→中に切り替えたとき、最初の 100ms で静止せず目標へ向けて動き出す', (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsNotifierProvider.overrideWith(
            () => _MutableSettings(const AppSettings(fontSize: FontSize.large)),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: ref.watch(currentThemeProvider),
              home: Scaffold(
                body: TextButton(
                  onPressed: () {},
                  child: const Text('キャンセル'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double fontSizeNow() => tester
          .renderObject<RenderParagraph>(find.text('キャンセル'))
          .text
          .style!
          .fontSize!;
      expect(fontSizeNow(), closeTo(textOutlinedFilledBase * 1.2, 0.01));

      // 大 → 中へ切り替える（保存はしない、state のみ変更）
      (container.read(settingsNotifierProvider.notifier) as _MutableSettings)
          .setFontSizeForTest(FontSize.medium);
      await tester.pump();

      // 10ms 刻みで 100ms 進める（リスクレビューと同じ測定方法）。
      // 修正前はこの時点でもまだ 16.8（開始値）のまま完全に静止している
      // （実測）。修正後は目標（14.0）へ向けてすでに動き出している。
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        fontSizeNow(),
        lessThan(16.7),
        reason: '100ms 経っても開始値付近で静止している（一瞬固まる不具合）',
      );

      // さらに 400ms（合計 500ms）進めれば、最終的に目標値へ収束する
      // （実測: 修正前後とも t=400ms 時点で 14.0 に収束するため、
      // ここは「修正で壊れていないこと」の確認であり、上の 100ms 判定が
      // 本題の赤/緑を分ける）。
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(fontSizeNow(), closeTo(textOutlinedFilledBase, 0.01));
    });
  });

  group('「中」でもボタン 3 種の textStyle が非 null（P0/Important、リスクレビュー反映）', () {
    // なぜ: 早期リターンを消しても、`_defaultButtonLabelStyle` は Material 既定と
    // 同値になるよう導出されているため、既存のサイズ・太さ・字間のテストは
    // 早期リターンの有無を区別できない（リスクレビューで mutation 実測済み）。
    // 「中」でも textStyle 自体が非 null であることを直接見る。
    testWidgets('TextButton/OutlinedButton/FilledButton', (tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsNotifierProvider.overrideWith(
            () => _FixedSettings(const AppSettings(fontSize: FontSize.medium)),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      final theme = container.read(currentThemeProvider);

      for (final style in [
        theme.textButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.filledButtonTheme.style,
      ]) {
        final resolved = style?.textStyle?.resolve(const <WidgetState>{});
        expect(resolved, isNotNull);
        expect(resolved!.fontSize, closeTo(textOutlinedFilledBase, 0.01));
      }
    });
  });
}
