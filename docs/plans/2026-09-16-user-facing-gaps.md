# 利用者に効く未達 3 件（L-73・L-74/L-103・L-104）の実装計画

破棄条件: 3 タスクの PR がすべて main にマージされたら、この計画書は最後の PR で削除する。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 台帳の「利用者に効く未達」3 件を、赤を先に見るテスト付きで直す（1000 文字上限の警告／フォント設定の全画面追従／下書き・チュートリアル保存失敗の報告）。

**Architecture:** 3 タスクは互いに独立で、それぞれ main から切ったブランチ・別 PR にする（1 PR は 400 行 / 12 ファイルまで）。Task 1 は入力バッファの派生状態を 1 つ足して小さな告知ウィジェットを入力欄の下に置く。Task 2 はテーマ（`ThemeData.textTheme`）にフォント設定の倍率を掛け、テーマ由来の文字をすべて追従させる（文字盤やボタンのように既に明示サイズを持つ箇所は二重に拡大されない）。Task 3 は設定の保存失敗と同じ報告経路（`settingsWriteFailureProvider`）に下書きとチュートリアル完了フラグの書き込み結果を流し、バナーの名前対応を足す。

**Tech Stack:** Flutter 3.38.1（`fvm`）、flutter_riverpod 3.1（`Notifier` / `ref.mounted`）、shared_preferences（失敗注入は `SharedPreferencesStorePlatform.instance`）、flutter_test。

**Spec:** `docs/spec/kotonoha-requirements.md` の EDGE-101（1000 文字超で警告し 1000 文字で制限）、REQ-802（文字盤・定型文一覧・ボタンラベルのフォントサイズが設定に追従）、REQ-2007（変更が即座に全テキストへ反映）、NFR-302（クラッシュ復旧時に最後の入力状態を復元）。台帳 `docs/ledger.md` の L-73・L-74・L-103・L-104。決定は ADR-005（永続化の失敗は利用者に伝える）。

## Global Constraints

- 1 変更（PR）は 400 行 / 12 ファイルまで。触るファイルを PR 本文に列挙し、AGENTS.md の索引 5 行（ADR-002/005/007/009/010）ごとに yes/no を書く
- 修正の前にテストを書き、赤を見る。赤と緑の出力を報告に貼る（AGENTS.md 規律 5）。完全一致アサーションを書かない。モックは外部 SDK 境界（`SharedPreferencesStorePlatform`）にだけ置き、自分の関数を patch しない
- Flutter: null safety、`const` コンストラクタ、ウィジェットに `key`、flutter_lints 準拠。`fvm flutter analyze --no-fatal-infos` は exit 0（info は main と同数の 82 件が既存）、`fvm dart format --output=none --set-exit-if-changed .` は差分なし
- 検証コマンドは `frontend/kotonoha_app` で `fvm flutter test <対象ファイル>`。`fvm flutter test` の後は `git checkout HEAD -- pubspec.lock` してからコミットする（lock が別 SDK 版で解決されているため。コミット出力は全部読む。pre-commit が「files were modified by this hook」で止めたら lock を戻して再コミット）
- コミットは `fix:` ＋ 日本語 1 行、末尾に `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- 文言は利用者（発話が困難な人と支援者）向けに短く。数字は 1 つの真実から取る（1000 は `InputBufferNotifier.maxLength`、フォント値は `AppSizes.fontSizeSmall/Medium/Large` = 16/20/24）
- 永続化の経路を変える Task 3 は PR で独立監査（AGENTS.md 規律 9）を通す。コントローラが手配する

---

### Task 1: 入力欄が 1000 文字に達したことを利用者に伝える（L-73、EDGE-101）

**Files:**
- Modify: `frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart`（`inputBufferProvider` の直後に派生 provider を足す）
- Create: `frontend/kotonoha_app/lib/features/character_board/presentation/widgets/input_limit_notice.dart`
- Modify: `frontend/kotonoha_app/lib/features/character_board/presentation/home_screen.dart`（`_buildInputArea` の `child:` 以下）
- Test: `frontend/kotonoha_app/test/features/character_board/providers/input_buffer_provider_test.dart`（group を 1 つ追加）
- Test: `frontend/kotonoha_app/test/features/character_board/presentation/widgets/input_limit_notice_test.dart`（新規）

**Interfaces:**
- Produces: `final inputLimitReachedProvider = Provider<bool>`（バッファ長が `InputBufferNotifier.maxLength` 以上なら true）／`class InputLimitNotice extends ConsumerWidget`（`static const String message`）

- [ ] **Step 1: 派生 provider のテストを書く（赤）**

`input_buffer_provider_test.dart` の末尾の group の後に追加:

```dart
  group('上限到達の派生状態（L-73、EDGE-101）', () {
    test('999 文字では上限に達していない', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(inputBufferProvider.notifier).setText('あ' * 999);
      expect(container.read(inputLimitReachedProvider), isFalse);
    });

    test('1000 文字で上限に達し、さらに追加しても 1000 文字のまま', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あ' * InputBufferNotifier.maxLength);
      notifier.addCharacter('い');
      expect(container.read(inputBufferProvider).length,
          InputBufferNotifier.maxLength);
      expect(container.read(inputLimitReachedProvider), isTrue);
    });

    test('上限を超える setText は 1000 文字に切り詰められ、上限到達になる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(inputBufferProvider.notifier).setText('あ' * 1200);
      expect(container.read(inputBufferProvider).length,
          InputBufferNotifier.maxLength);
      expect(container.read(inputLimitReachedProvider), isTrue);
    });

    test('1 文字消すと上限到達が解ける', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(inputBufferProvider.notifier);
      notifier.setText('あ' * InputBufferNotifier.maxLength);
      notifier.deleteLastCharacter();
      expect(container.read(inputLimitReachedProvider), isFalse);
    });
  });
```

- [ ] **Step 2: 赤を見る**

Run: `cd frontend/kotonoha_app && fvm flutter test test/features/character_board/providers/input_buffer_provider_test.dart`
Expected: コンパイルエラー `Undefined name 'inputLimitReachedProvider'`（provider が未定義）

- [ ] **Step 3: 派生 provider を足す**

`input_buffer_provider.dart` の `inputBufferProvider` 定義の直後:

```dart
/// 入力バッファが上限（[InputBufferNotifier.maxLength]）に達しているか
/// 上限で黙って捨てるのではなく、利用者に伝えるための派生状態（EDGE-101、台帳 L-73）。
final inputLimitReachedProvider = Provider<bool>(
  (ref) => ref.watch(inputBufferProvider).length >= InputBufferNotifier.maxLength,
);
```

- [ ] **Step 4: 緑を見る**

Run: 同上
Expected: 新しい 4 本を含め全部 pass

- [ ] **Step 5: 告知ウィジェットのテストを書く（赤）**

`test/features/character_board/presentation/widgets/input_limit_notice_test.dart`（新規）:

```dart
/// 入力上限の告知（L-73、EDGE-101）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: InputLimitNotice())),
      ),
    );
    return container;
  }

  testWidgets('上限に達していなければ何も描かない', (tester) async {
    final container = await pump(tester);
    container.read(inputBufferProvider.notifier).setText('あ' * 999);
    await tester.pump();
    expect(find.textContaining('文字に達しました'), findsNothing);
  });

  testWidgets('上限に達したら、達したことと入力できないことを描く', (tester) async {
    final container = await pump(tester);
    container
        .read(inputBufferProvider.notifier)
        .setText('あ' * InputBufferNotifier.maxLength);
    await tester.pump();
    expect(find.textContaining('1000 文字に達しました'), findsOneWidget);
    expect(find.textContaining('これ以上は入力できません'), findsOneWidget);
  });

  testWidgets('1 文字消すと告知が消える', (tester) async {
    final container = await pump(tester);
    final notifier = container.read(inputBufferProvider.notifier);
    notifier.setText('あ' * InputBufferNotifier.maxLength);
    await tester.pump();
    notifier.deleteLastCharacter();
    await tester.pump();
    expect(find.textContaining('文字に達しました'), findsNothing);
  });
}
```

- [ ] **Step 6: 赤を見る**

Run: `fvm flutter test test/features/character_board/presentation/widgets/input_limit_notice_test.dart`
Expected: コンパイルエラー（`input_limit_notice.dart` が無い）

- [ ] **Step 7: ウィジェットを作る**

`lib/features/character_board/presentation/widgets/input_limit_notice.dart`:

```dart
/// 入力欄が上限に達したことを伝える告知（EDGE-101、台帳 L-73）
///
/// 上限で超過分を黙って捨てるのではなく、達したことと、これ以上入力できないことを
/// 入力欄の直下に出す。上限を下回れば消える。読み上げは liveRegion で自動通知する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

/// 上限到達の告知
class InputLimitNotice extends ConsumerWidget {
  /// 告知を作る
  const InputLimitNotice({super.key});

  /// 告知文（数字は [InputBufferNotifier.maxLength] から取る）
  static const String message =
      '${InputBufferNotifier.maxLength} 文字に達しました。これ以上は入力できません';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reached = ref.watch(inputLimitReachedProvider);
    if (!reached) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.paddingXSmall),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
```

`AppSizes` のインポートパスは `home_screen.dart` の import を見て合わせる（`paddingXSmall` は既存の定数）。

- [ ] **Step 8: 緑を見る**

Run: 同上
Expected: 3 本 pass

- [ ] **Step 9: 入力欄に組み込む**

`home_screen.dart` の `_buildInputArea` で、`Container` の `child: Semantics(liveRegion: true, child: SingleChildScrollView(...))` を次に置き換える（既存の `Semantics` と `SingleChildScrollView` と `Text` はそのまま `Flexible` の中へ移す）:

```dart
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  // （既存のまま）
                ),
              ),
            ),
          ),
          const InputLimitNotice(),
        ],
      ),
```

import に `package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart` を足す。

- [ ] **Step 10: 画面での配線をテストで確かめる**

`test/features/character_board/presentation/home_screen_wiring_test.dart` の既存の pump 手順（同ファイルの他のテストが使っているヘルパー）を使い、テストを 1 本足す:

```dart
  testWidgets('入力欄が 1000 文字に達すると、入力欄の下に告知が出る（L-73）', (tester) async {
    // 既存ヘルパーで HomeScreen を pump し、container を得る
    // （このファイルの他のテストと同じ手順を使う）
    container
        .read(inputBufferProvider.notifier)
        .setText('あ' * InputBufferNotifier.maxLength);
    await tester.pump();
    expect(find.text(InputLimitNotice.message), findsOneWidget);
  });
```

既存ヘルパーが `container` を返さない形なら、そのファイルの流儀に合わせて `ProviderScope` の `overrides` 経由で同じことをする。HomeScreen の pump が重くて安定しない場合は、その旨を DONE_WITH_CONCERNS で報告し、Step 5〜8 のウィジェットテストを配線の証拠とする。

- [ ] **Step 11: 全部を回して、format と analyze を確かめる**

Run: `fvm flutter test test/features/character_board && fvm flutter analyze --no-fatal-infos && fvm dart format --output=none --set-exit-if-changed lib/features/character_board test/features/character_board`
Expected: すべて pass / exit 0 / 差分なし

- [ ] **Step 12: コミット**

```bash
cd /Volumes/external/dev/kotonoha && git checkout HEAD -- frontend/kotonoha_app/pubspec.lock
git add frontend/kotonoha_app/lib/features/character_board frontend/kotonoha_app/test/features/character_board
git commit -m "fix: 入力欄が 1000 文字に達したことを利用者に伝える（EDGE-101、台帳 L-73）

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: フォントサイズ設定をテーマ由来の全テキストに追従させる（L-74・L-103、REQ-802・REQ-2007）

**Files:**
- Modify: `frontend/kotonoha_app/lib/features/settings/models/font_size.dart`（enum の後に extension を足す）
- Modify: `frontend/kotonoha_app/lib/core/themes/theme_provider.dart`（`currentThemeProvider`）
- Modify: `frontend/kotonoha_app/lib/core/widgets/persistence_banner.dart:142`（`fontSize: 14` の固定をやめる）
- Test: `frontend/kotonoha_app/test/core/themes/theme_provider_font_size_test.dart`（新規）
- Test: `frontend/kotonoha_app/test/features/preset_phrase/presentation/widgets/phrase_list_item_test.dart`（テストを 1 本追加）
- Test: `frontend/kotonoha_app/test/core/widgets/persistence_banner_test.dart`（テストを 1 本追加）

**Interfaces:**
- Produces: `extension FontSizeScale on FontSize { double get scaleFactor; }`（small 0.8 / medium 1.0 / large 1.2 ＝ `AppSizes.fontSizeSmall/Medium/Large ÷ AppSizes.fontSizeMedium`）
- Consumes: `settingsNotifierProvider`（`AsyncNotifierProvider<SettingsNotifier, AppSettings>`。`AppSettings.fontSize`）

**設計の要点:** 文字盤・入力欄・ボタンは既に `FontSize` から明示サイズを引いている（`home_screen.dart:805` 等の 3 つの switch）。テーマの `textTheme` に倍率を掛けると、`Theme.of(context).textTheme.bodyLarge` のようにテーマ由来のスタイルを使う定型文一覧・履歴・お気に入り・ダイアログ・ボタンラベルが追従し、明示サイズを持つ箇所は `copyWith(fontSize:)` が勝つので二重に拡大されない。

- [ ] **Step 1: テーマの倍率テストを書く（赤）**

`test/core/themes/theme_provider_font_size_test.dart`（新規）:

```dart
/// フォントサイズ設定がテーマの textTheme に反映される（REQ-802・REQ-2007、台帳 L-74）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

/// 設定を固定して返す Notifier（SharedPreferences を読まない）
class _FixedSettings extends SettingsNotifier {
  _FixedSettings(this._settings);
  final AppSettings _settings;

  @override
  Future<AppSettings> build() async => _settings;
}

void main() {
  Future<double> bodyLargeSizeFor(FontSize size) async {
    final container = ProviderContainer(
      overrides: [
        settingsNotifierProvider.overrideWith(
          () => _FixedSettings(AppSettings(fontSize: size)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsNotifierProvider.future);
    return container.read(currentThemeProvider).textTheme.bodyLarge!.fontSize!;
  }

  final base = lightTheme.textTheme.bodyLarge!.fontSize!;

  test('中（既定）ではテーマの文字サイズは変わらない', () async {
    expect(await bodyLargeSizeFor(FontSize.medium), closeTo(base, 0.01));
  });

  test('大では 1.2 倍になる（AppSizes.fontSizeLarge / fontSizeMedium）', () async {
    expect(await bodyLargeSizeFor(FontSize.large), closeTo(base * 1.2, 0.01));
  });

  test('小では 0.8 倍になる', () async {
    expect(await bodyLargeSizeFor(FontSize.small), closeTo(base * 0.8, 0.01));
  });
}
```

`SettingsNotifier` のクラス名・`AppSettings` のコンストラクタ引数名は `settings_provider.dart` と `app_settings.dart` で確かめる。`SettingsNotifier` が継承できない形（`final class` 等）なら、`SharedPreferences.setMockInitialValues({'fontSize': 'large'})` で同じ 3 本を書く（キー名は `settings_provider.dart` の `setFontSize` が書く名前から取り、読み込んだ `settings.fontSize` が期待値であることも先に `expect` する）。

- [ ] **Step 2: 赤を見る**

Run: `fvm flutter test test/core/themes/theme_provider_font_size_test.dart`
Expected: 「大」「小」の 2 本が fail（今のテーマは設定を見ないので `base` のまま）。「中」は pass

- [ ] **Step 3: extension とテーマの倍率を実装する**

`font_size.dart` の enum の後:

```dart
/// フォントサイズ設定をテーマの倍率に写す
/// 文字盤やボタンが使う明示サイズ（[AppSizes.fontSizeSmall] 等）と同じ比にする。
extension FontSizeScale on FontSize {
  /// テーマの textTheme に掛ける倍率（中 = 1.0）
  double get scaleFactor => switch (this) {
        FontSize.small => AppSizes.fontSizeSmall / AppSizes.fontSizeMedium,
        FontSize.medium => 1.0,
        FontSize.large => AppSizes.fontSizeLarge / AppSizes.fontSizeMedium,
      };
}
```

（`AppSizes` を import する。`home_screen.dart` と同じパス）

`theme_provider.dart` の `data:` 分岐を、テーマを選んだ後に倍率を掛ける形にする:

```dart
    data: (settings) {
      final base = switch (settings.theme) {
        AppTheme.light => lightTheme,
        AppTheme.dark => darkTheme,
        AppTheme.highContrast => highContrastTheme,
      };
      return _scaled(base, settings.fontSize.scaleFactor);
    },
```

ファイル末尾に:

```dart
/// テーマ由来の文字サイズにフォント設定の倍率を掛ける（REQ-802・REQ-2007、台帳 L-74）
/// 明示サイズ（`copyWith(fontSize:)`）を持つ箇所は影響を受けない。
ThemeData _scaled(ThemeData base, double factor) {
  if (factor == 1.0) return base;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontSizeFactor: factor),
    primaryTextTheme: base.primaryTextTheme.apply(fontSizeFactor: factor),
  );
}
```

- [ ] **Step 4: 緑を見る**

Run: 同上
Expected: 3 本 pass

- [ ] **Step 5: 定型文一覧が追従することを描画で確かめる（赤 → 緑は Step 3 で済むので、ここは追従の証拠）**

`phrase_list_item_test.dart` に 1 本追加（既存テストの `PhraseListItem` の作り方と `createTestPhrase` ヘルパーの使い方に合わせる。`_FixedSettings` は Step 1 と同じものをこのファイルにも定義する）:

```dart
  testWidgets('本文の文字サイズがフォント設定「大」に追従する（REQ-802、L-74）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith(
            () => _FixedSettings(const AppSettings(fontSize: FontSize.large)),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: ref.watch(currentThemeProvider),
            home: Scaffold(
              body: PhraseListItem(
                // 既存テストと同じ引数
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(find.text('こんにちは'));
    expect(
      paragraph.text.style!.fontSize,
      closeTo(lightTheme.textTheme.bodyLarge!.fontSize! * 1.2, 0.01),
    );
  });
```

観測点は描画された `RenderParagraph` のスタイル（最も外側）。`Text` ウィジェットの `style` を見ない。

- [ ] **Step 6: バナーの文字を固定 14 からテーマ由来にする**

`persistence_banner.dart:142` の `style: TextStyle(color: colors.foreground, fontSize: 14)` を次に:

```dart
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.foreground),
```

（`bodyMedium` の既定は 14 なので「中」では見た目が変わらない）

`persistence_banner_test.dart` に 1 本追加（既存の「設定の保存失敗」group の pump 手順に、`settingsNotifierProvider` の `_FixedSettings(large)` override と `theme: ref.watch(currentThemeProvider)` を足す）:

```dart
    testWidgets('バナーの文字がフォント設定「大」に追従する（L-103）', (tester) async {
      // 既存の pump に上の override を足して、失敗状態のバナーを出す
      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('保存できません'),
      );
      expect(paragraph.text.style!.fontSize, closeTo(14 * 1.2, 0.01));
    });
```

- [ ] **Step 7: 全部を回して、format と analyze を確かめる**

Run: `fvm flutter test test/core/themes test/core/widgets/persistence_banner_test.dart test/features/preset_phrase test/features/settings && fvm flutter analyze --no-fatal-infos && fvm dart format --output=none --set-exit-if-changed lib test`
Expected: すべて pass / exit 0 / 差分なし。既存テストが「中」以外の倍率で落ちたら、そのテストが固定している数値が仕様か偶然かを報告する（勝手に数値を書き換えない）

- [ ] **Step 8: コミット**

```bash
cd /Volumes/external/dev/kotonoha && git checkout HEAD -- frontend/kotonoha_app/pubspec.lock
git add frontend/kotonoha_app/lib/features/settings/models/font_size.dart frontend/kotonoha_app/lib/core/themes/theme_provider.dart frontend/kotonoha_app/lib/core/widgets/persistence_banner.dart frontend/kotonoha_app/test/core/themes frontend/kotonoha_app/test/features/preset_phrase/presentation/widgets/phrase_list_item_test.dart frontend/kotonoha_app/test/core/widgets/persistence_banner_test.dart
git commit -m "fix: フォントサイズ設定をテーマ由来の全テキストに追従させる（REQ-802・REQ-2007、台帳 L-74・L-103）

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: 下書きとチュートリアル完了フラグの保存失敗を利用者に伝える（L-104、NFR-302、ADR-005）

**Files:**
- Modify: `frontend/kotonoha_app/lib/core/persistence/settings_write_failure_provider.dart`（定数 1 つと関数 1 つを足す）
- Modify: `frontend/kotonoha_app/lib/features/app_state/providers/app_session_provider.dart:112-150`（`saveDraftText` / `saveLastRoute` / `onAppPaused`）
- Modify: `frontend/kotonoha_app/lib/features/help/providers/tutorial_provider.dart:60-64`（`completeTutorial`）
- Modify: `frontend/kotonoha_app/lib/core/widgets/persistence_banner.dart:98-101`（`if (settingsFailed) '設定'` の箇所）
- Test: `frontend/kotonoha_app/test/features/app_state/providers/app_session_write_failure_test.dart`（新規）
- Test: `frontend/kotonoha_app/test/features/help/providers/tutorial_write_failure_test.dart`（新規）
- Test: `frontend/kotonoha_app/test/core/widgets/persistence_banner_test.dart`（group を 1 つ追加）

**Interfaces:**
- Produces: `const String draftTextWriteKey = 'draft_text';`／`List<String> prefFailureNames(Set<String> failedKeys)`（`draftTextWriteKey` を含めば「入力中の文」、それ以外のキーを含めば「設定」。この順）
- Consumes: `SettingsWriteFailureNotifier.record({required String key, required bool succeeded})`（既存）／`settings_provider.dart:140-156` の `_persist` の形（`try/catch` → `ref.mounted` → `record`）

**設計の要点:** 下書き（`draft_text`）は NFR-302 の対象で、失敗を黙って落とすのが最悪。報告経路は設定と同じ `settingsWriteFailureProvider`（キー単位）に流し、バナーの名前だけ「入力中の文」に写す。`last_route` と `session_timestamp` はセッションの記録で利用者のデータではないので報告しないが、未処理の非同期エラーにはしない（`try/catch` で握る）。

- [ ] **Step 1: 名前の対応のテストを書く（赤）**

`persistence_banner_test.dart` に group を追加（既存の「設定（SharedPreferences）の保存失敗の告知」group が `settingsWriteFailureProvider` を override している手順をそのまま使う）:

```dart
  group('下書きの保存失敗の告知（NFR-302、L-104）', () {
    testWidgets('下書きの保存が失敗していると「入力中の文を保存できません」と出る', (tester) async {
      // 既存 group と同じ pump で、失敗キーを {draftTextWriteKey} にする
      expect(find.textContaining('入力中の文を保存できません'), findsOneWidget);
      expect(find.textContaining('設定を保存できません'), findsNothing);
    });

    testWidgets('下書きと設定の両方が失敗していると「入力中の文、設定を保存できません」と出る', (tester) async {
      // 失敗キーを {draftTextWriteKey, 'fontSize'} にする
      expect(find.textContaining('入力中の文、設定を保存できません'), findsOneWidget);
    });
  });
```

- [ ] **Step 2: 赤を見る**

Run: `fvm flutter test test/core/widgets/persistence_banner_test.dart`
Expected: コンパイルエラー（`draftTextWriteKey` 未定義）

- [ ] **Step 3: 定数と名前対応を足し、バナーに配線する**

`settings_write_failure_provider.dart` の provider 定義の後:

```dart
/// 入力中の文（下書き）の SharedPreferences キー。`app_session_provider.dart` と共有する
const String draftTextWriteKey = 'draft_text';

/// 失敗しているキーを利用者向けの名前に写す（順序固定: 入力中の文 → 設定）
/// 下書きは利用者のデータ（NFR-302）、それ以外のキーは設定として 1 語にまとめる。
List<String> prefFailureNames(Set<String> failedKeys) => [
      if (failedKeys.contains(draftTextWriteKey)) '入力中の文',
      if (failedKeys.any((key) => key != draftTextWriteKey)) '設定',
    ];
```

`persistence_banner.dart` の `final settingsFailed = ref.watch(settingsWriteFailureProvider).isNotEmpty;` を `final failedPrefKeys = ref.watch(settingsWriteFailureProvider);` に、`if (settingsFailed) '設定',` を `...prefFailureNames(failedPrefKeys),` に置き換える（ほかに `settingsFailed` を使う箇所があれば `failedPrefKeys.isNotEmpty` に）。

- [ ] **Step 4: 緑を見る**

Run: 同上
Expected: 新しい 2 本を含め全部 pass（既存の「設定」のテストも pass のまま）

- [ ] **Step 5: 下書きの保存失敗が記録されるテストを書く（赤）**

`test/features/app_state/providers/app_session_write_failure_test.dart`（新規。`_ThrowingStore` / `_FalseStore` と `setUp` / `tearDown` の `SharedPreferencesStorePlatform.instance` の差し替え・戻し方は `test/features/settings/providers/settings_write_failure_test.dart` からそのまま写す）:

```dart
/// 下書き（入力中の文）の保存失敗を利用者へ伝える（NFR-302、ADR-005、台帳 L-104）
///
/// 失敗の注入は shared_preferences の外部 SDK 境界（SharedPreferencesStorePlatform）で行う。
library;

// import は settings_write_failure_test.dart と同じ ＋ app_session_provider

void main() {
  // setUp / tearDown: settings_write_failure_test.dart と同じ

  test('書き込みが例外で失敗すると、下書きのキーが失敗として記録される', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSessionProvider.notifier).saveDraftText('あ');

    expect(container.read(settingsWriteFailureProvider), contains(draftTextWriteKey));
    expect(container.read(appSessionProvider).draftText, 'あ');
  });

  test('書き込みが false で失敗しても同じく記録される', () async {
    SharedPreferencesStorePlatform.instance = _FalseStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSessionProvider.notifier).saveDraftText('あ');

    expect(container.read(settingsWriteFailureProvider), contains(draftTextWriteKey));
  });

  test('成功すると失敗の記録が消える', () async {
    SharedPreferencesStorePlatform.instance = _FalseStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appSessionProvider.notifier);
    await notifier.saveDraftText('あ');
    expect(container.read(settingsWriteFailureProvider), contains(draftTextWriteKey));

    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    await notifier.saveDraftText('い');

    expect(container.read(settingsWriteFailureProvider), isNot(contains(draftTextWriteKey)));
  });

  test('last_route の保存失敗は未処理エラーにならず、報告もしない', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(appSessionProvider.notifier).saveLastRoute('/settings'),
      completes,
    );
    expect(container.read(settingsWriteFailureProvider), isEmpty);
  });
}
```

`SharedPreferences` はインスタンスをキャッシュするので、store を差し替えた後は `settings_write_failure_test.dart` がしているのと同じ手順（`SharedPreferences.resetStatic()` 等）でキャッシュを落とす。成功→失敗の順ではなく失敗→成功の順で 1 テストに書くのは、キャッシュを落とす手順が 1 回で済むため。

- [ ] **Step 6: 赤を見る**

Run: `fvm flutter test test/features/app_state/providers/app_session_write_failure_test.dart`
Expected: 1 本目・2 本目が fail（今は記録されない。1 本目は例外が未処理で test error になる）

- [ ] **Step 7: `app_session_provider.dart` を直す**

`_SessionKeys.draftText` の値を共有定数から取る（2 つ目の真実を作らない）:

```dart
  static const String draftText = draftTextWriteKey;
```

（`package:kotonoha_app/core/persistence/settings_write_failure_provider.dart` を import）

`saveDraftText` / `saveLastRoute` / `onAppPaused` を、書き込みの成否を握るヘルパー経由にする:

```dart
  /// 入力中のテキストを保存
  /// クラッシュ時のデータ保持。失敗は利用者に報告する（NFR-302、台帳 L-104）。
  Future<void> saveDraftText(String text) async {
    state = state.copyWith(draftText: text);
    await _persist(
      _SessionKeys.draftText,
      (prefs) => text.isEmpty
          ? prefs.remove(_SessionKeys.draftText)
          : prefs.setString(_SessionKeys.draftText, text),
    );
  }

  /// 最後に表示したルートを保存（セッションの記録。失敗は報告しない）
  Future<void> saveLastRoute(String route) async {
    state = state.copyWith(lastRoute: route);
    await _persist(
      _SessionKeys.lastRoute,
      (prefs) => prefs.setString(_SessionKeys.lastRoute, route),
      report: false,
    );
  }

  /// アプリがバックグラウンドに移行した時の処理
  Future<void> onAppPaused() async {
    if (state.draftText.isNotEmpty) {
      await _persist(
        _SessionKeys.draftText,
        (prefs) => prefs.setString(_SessionKeys.draftText, state.draftText),
      );
    }
    final lastRoute = state.lastRoute;
    if (lastRoute != null) {
      await _persist(
        _SessionKeys.lastRoute,
        (prefs) => prefs.setString(_SessionKeys.lastRoute, lastRoute),
        report: false,
      );
    }
    await _persist(
      _SessionKeys.sessionTimestamp,
      (prefs) => prefs.setString(
        _SessionKeys.sessionTimestamp,
        DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      report: false,
    );
  }

  /// SharedPreferences への書き込みを行い、成否を報告する
  /// [report] が false のキーは、失敗しても未処理エラーにしないだけで報告しない
  /// （セッションの記録であって利用者のデータではない）。
  Future<void> _persist(
    String key,
    Future<bool> Function(SharedPreferences prefs) write, {
    bool report = true,
  }) async {
    var succeeded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      succeeded = await write(prefs);
    } catch (_) {
      succeeded = false;
    }
    if (!report || !ref.mounted) return;
    ref
        .read(settingsWriteFailureProvider.notifier)
        .record(key: key, succeeded: succeeded);
  }
```

- [ ] **Step 8: 緑を見る**

Run: 同上 ＋ `fvm flutter test test/features/app_state`
Expected: 新しい 4 本と既存（`app_lifecycle_observer_draft_test.dart`）が pass

- [ ] **Step 9: チュートリアル完了フラグのテストを書く（赤）**

`test/features/help/providers/tutorial_write_failure_test.dart`（新規。store と setUp/tearDown は Step 5 と同じ）:

```dart
  test('完了フラグの書き込みが失敗しても、状態は完了になり、失敗が記録される', () async {
    SharedPreferencesStorePlatform.instance = _ThrowingStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(tutorialProvider.notifier).completeTutorial();

    expect(container.read(tutorialProvider).isCompleted, isTrue);
    expect(container.read(settingsWriteFailureProvider), isNotEmpty);
  });

  test('成功すると失敗は記録されない', () async {
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(tutorialProvider.notifier).completeTutorial();

    expect(container.read(settingsWriteFailureProvider), isEmpty);
  });
```

- [ ] **Step 10: 赤を見る**

Run: `fvm flutter test test/features/help/providers/tutorial_write_failure_test.dart`
Expected: 1 本目が fail（例外が未処理）

- [ ] **Step 11: `tutorial_provider.dart` の `completeTutorial` を直す**

```dart
  /// チュートリアルを完了としてマーク
  /// shared_preferences にフラグを保存する。保存に失敗しても画面は先へ進め、
  /// 失敗は設定と同じ経路で利用者に伝える（ADR-005、台帳 L-104）。
  Future<void> completeTutorial() async {
    var succeeded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      succeeded = await prefs.setBool(_tutorialCompletedKey, true);
    } catch (_) {
      succeeded = false;
    }
    if (!ref.mounted) return;
    state = state.copyWith(isCompleted: true);
    ref
        .read(settingsWriteFailureProvider.notifier)
        .record(key: _tutorialCompletedKey, succeeded: succeeded);
  }
```

- [ ] **Step 12: 緑を見る**

Run: 同上 ＋ `fvm flutter test test/features/help`
Expected: すべて pass

- [ ] **Step 13: 全部を回して、format と analyze を確かめる**

Run: `fvm flutter test test/core/widgets test/core/persistence test/features/app_state test/features/help test/features/settings && fvm flutter analyze --no-fatal-infos && fvm dart format --output=none --set-exit-if-changed lib test`
Expected: すべて pass / exit 0 / 差分なし

- [ ] **Step 14: 台帳と計画書を更新してコミット**

`docs/ledger.md` の L-73・L-74・L-103・L-104 を `[x]` にし、行末に `。解消（2026-09-16、PR #NNN）` を足す（PR 番号はコントローラが埋める）。この計画書 `docs/plans/2026-09-16-user-facing-gaps.md` は破棄条件どおり削除する。

```bash
cd /Volumes/external/dev/kotonoha && git checkout HEAD -- frontend/kotonoha_app/pubspec.lock
git add frontend/kotonoha_app/lib/core/persistence/settings_write_failure_provider.dart frontend/kotonoha_app/lib/core/widgets/persistence_banner.dart frontend/kotonoha_app/lib/features/app_state/providers/app_session_provider.dart frontend/kotonoha_app/lib/features/help/providers/tutorial_provider.dart frontend/kotonoha_app/test/features/app_state/providers frontend/kotonoha_app/test/features/help/providers/tutorial_write_failure_test.dart frontend/kotonoha_app/test/core/widgets/persistence_banner_test.dart docs/ledger.md
git commit -m "fix: 下書きとチュートリアル完了フラグの保存失敗を利用者に伝える（NFR-302、ADR-005、台帳 L-104）

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
