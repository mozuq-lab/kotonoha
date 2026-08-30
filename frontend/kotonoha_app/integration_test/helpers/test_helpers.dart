/// E2Eテスト用ヘルパー関数
///
/// TASK-0081: E2Eテスト環境構築
/// 信頼性レベル: 🟡 黄信号（テスト戦略は要件定義書から推測）
///
/// E2Eテストで共通して使用するヘルパー関数を提供。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:flutter/material.dart' show Icons;

/// E2Eテスト用のバインディング初期化
///
/// 各E2Eテストファイルの先頭で呼び出す。
IntegrationTestWidgetsFlutterBinding initializeE2ETestBinding() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

/// アプリの初期化とポンピング
///
/// Hive初期化とアプリのレンダリングを行う。
///
/// [tester]: WidgetTester
/// [overrides]: Provider上書き設定（オプション）
/// [clearData]: true の場合、履歴・お気に入りデータをクリア（デフォルト: true）
/// [completeTutorial]: true の場合、初回チュートリアルを完了済みにする
///   （デフォルト: true）。**チュートリアル自体を検証するテスト以外は既定のままにする。**
///
/// 【チュートリアルを完了済みにする理由（Issue #84 の根本原因）】:
/// E2E はストレージが空の状態から始まるため初回起動扱いになり、
/// `TutorialOverlay` が表示される。このオーバーレイは
/// `Container(color: Colors.black54)` で画面全体を覆っており、
/// **配下へのタップをヒットテストで吸収する**（緊急ボタンだけは意図的に手前に置かれ、
/// 常に操作できる。`app_shell.dart` の「安全性（重要）」コメントを参照）。
///
/// その結果「ウィジェットは見つかる・タップは実行される・状態は変わらない」が起き、
/// 操作を伴うテストが軒並み落ちていた（`Found 0 widgets with text` が62件）。
/// 操作を一切しない `app_startup_test.dart` だけが通っていたのはこのためである。
///
/// Issue #84 は「ヘッドレスWebで失敗」「テストの陳腐化」としていたが、
/// **どちらも誤り**だった。ホストVMのウィジェットテストでも同じ条件で再現し
/// （`tester.tap` が `_RenderColoredBox` に吸収されるヒットテスト警告を出す）、
/// プラットフォームとは無関係だった。
Future<void> pumpApp(
  WidgetTester tester, {
  dynamic overrides,
  bool clearData = true,
  bool completeTutorial = true,
}) async {
  // 【チュートリアルの抑止】: pumpWidget より前に行う。
  // AppShell は最初のフレーム後に tutorialProvider.initialize() を呼び、
  // ここで読んだ値で表示要否が決まる。
  if (completeTutorial) {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tutorial_completed': true,
    });
  }

  await initHive();

  // テスト用にデータをクリア
  if (clearData) {
    await clearHistoryAndFavorites();
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: const KotonohaApp(),
    ),
  );

  // 初期レンダリング完了を待つ
  await tester.pumpAndSettle();
}

/// アプリを再起動した状態にする
///
/// 【なぜ pumpApp の再呼び出しでは駄目か】: `pumpWidget` に同じ型のウィジェットを
/// 渡すと、Flutter は要素を**作り直さず更新する**。`ProviderScope` の要素が
/// 生き続けるため Riverpod の `ProviderContainer` も維持され、その中の
/// `GoRouter` も直前の画面のまま残る。つまり「再起動したつもり」で
/// **画面遷移すらリセットされない**。
///
/// E2E の永続化テスト2件がこれで落ちていた——再起動後にホームへ戻っている前提で
/// AppBar のボタンを探していたが、実際は前の画面のままだった（Issue #84）。
///
/// いったん別のウィジェットを描画して要素を破棄し、そのうえで組み直す。
/// Hive の box は開いたままなので、永続化されたデータは保持される
/// （このヘルパーが検証したいのはまさにそれである）。
Future<void> restartApp(
  WidgetTester tester, {
  dynamic overrides,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  await pumpApp(tester, overrides: overrides, clearData: false);
}

/// 履歴・お気に入りデータをクリアするヘルパー
///
/// テスト間の独立性を確保するために使用。
Future<void> clearHistoryAndFavorites() async {
  if (Hive.isBoxOpen('history')) {
    final historyBox = Hive.box<HistoryItem>('history');
    await historyBox.clear();
  }
  if (Hive.isBoxOpen('favorites')) {
    final favoritesBox = Hive.box<FavoriteItem>('favorites');
    await favoritesBox.clear();
  }
  // 【定型文も消す理由（Issue #84）】: 消さないと、削除を行うテストの結果が
  // **次のテストへ持ち越される**。同一ターゲット内では box が開いたままで、
  // `initializeDefaultPhrases()` は空のときしか投入しないため、
  // 一度削除された定型文は二度と戻らない。
  //
  // 実際 083-009 は「おはようございます」を削除して findsNothing を確認しており、
  // 以降のテストがその語を探すと「スクロールしても見つからない」で落ちていた。
  // テストの実行順序に結果が依存する状態だった。
  //
  // 空にしておけば、次の pumpApp で initializeDefaultPhrases() が
  // 87件を投入し直す（＝各テストが同じ初期状態から始まる）。
  if (Hive.isBoxOpen('presetPhrases')) {
    final presetBox = Hive.box<PresetPhrase>('presetPhrases');
    await presetBox.clear();
  }
}

/// パフォーマンス計測用ストップウォッチ
///
/// 処理時間を計測してパフォーマンス要件を検証する。
///
/// [description]: 計測対象の説明
/// [maxMilliseconds]: 許容最大ミリ秒
/// [action]: 計測対象の処理
Future<void> measurePerformance(
  String description, {
  required int maxMilliseconds,
  required Future<void> Function() action,
}) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();

  final elapsed = stopwatch.elapsedMilliseconds;

  // 【閾値で落とさない理由（2026-08-30 決定）】
  //
  // E2E が検証するのは「経路が繋がっていること」であって、値の実測ではない。
  //
  // ここでの計測はヘッドレスWebのCIランナー上の値であり、NFR が対象とする
  // 9.7インチタブレット実機の性能を表さない。実測で 100ms 要件に対し 139ms が
  // 出たが、これは実機の性能ではなく実行環境の性能である。閾値で落とすと
  // 「環境が遅い」を「アプリが遅い」として報告し続けることになる。
  //
  // NFR の検査は次の2層が担う。
  // - CI で動く層: test/integration/e2e_phase3_integration_test.dart が
  //   タップ応答 lessThan(100)、performance_optimization_test.dart が
  //   TTS 開始 lessThanOrEqualTo(1000) を実測する
  // - 要件の意味での検証: integration_test/device_test/ の実機実行
  //   （台帳 L-25。未実行。リリース準備で必要）
  //
  // 値はログに残すので、極端な退行は目視で拾える。
  debugPrint(
    '[perf] $description: ${elapsed}ms '
    '(参考値。閾値 ${maxMilliseconds}ms では落とさない。'
    'ヘッドレスWebの計測値であり実機性能ではない)',
  );
}

/// テキストが表示されるまで待機
///
/// [tester]: WidgetTester
/// [text]: 待機するテキスト
/// [timeout]: タイムアウト時間（デフォルト5秒）
Future<void> waitForText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text(text).evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Text "$text" not found within ${timeout.inSeconds} seconds');
}

/// ウィジェットが表示されるまで待機
///
/// [tester]: WidgetTester
/// [finder]: 検索するウィジェット
/// [timeout]: タイムアウト時間（デフォルト5秒）
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Widget not found within ${timeout.inSeconds} seconds');
}

/// 文字盤で文字を入力
///
/// [tester]: WidgetTester
/// [character]: 入力する文字
Future<void> tapCharacterOnBoard(
  WidgetTester tester,
  String character,
) async {
  final finder = find.text(character);
  expect(finder, findsOneWidget,
      reason: 'Character "$character" not found on board');
  await tester.tap(finder);
  await tester.pump();
}

/// 複数の文字を順番に入力
///
/// [tester]: WidgetTester
/// [characters]: 入力する文字列
Future<void> typeOnCharacterBoard(
  WidgetTester tester,
  String characters,
) async {
  for (final char in characters.split('')) {
    await tapCharacterOnBoard(tester, char);
  }
}

/// ボタンをタップ
///
/// [tester]: WidgetTester
/// [text]: ボタンのテキスト
Future<void> tapButton(
  WidgetTester tester,
  String text,
) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget, reason: 'Button "$text" not found');
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// アイコンボタンをタップ
///
/// [tester]: WidgetTester
/// [icon]: ボタンのアイコン
Future<void> tapIconButton(
  WidgetTester tester,
  IconData icon,
) async {
  final finder = find.byIcon(icon);
  expect(finder, findsOneWidget, reason: 'Icon button with $icon not found');
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Semanticsラベルでボタンをタップ
///
/// [tester]: WidgetTester
/// [label]: Semanticsラベル
/// 遅延生成リストの中から [finder] が指す要素を画面内へスクロールして出す
///
/// 【なぜ必要か】: 定型文一覧は `ListView.builder` で、**画面外の要素は
/// ウィジェットとして構築されない**。したがって `find.text` は 0 件を返し、
/// 「表示されていない」ではなく「存在しない」ように見える。
///
/// 【双方向に探す理由】: `scrollUntilVisible` は与えた delta の向きにしか
/// 動かない。下向きだけで探すと、**一度下へ行った後で上の要素へ戻れない**。
/// 見つからないまま maxScrolls を使い切り `Bad state: No element` で落ちる
/// ——「対象が存在しない」ように見えるが、実際はスクロール位置の問題である。
/// 実測で確認した（Issue #84）:
///
///   最下部へ移動後、上部の語を下向きで探す → Bad state: No element
///   同じ語を上向きで探す                   → 成功
///
/// まず下向き、見つからなければ上向きに探す。
Future<void> scrollIntoView(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
  int maxScrolls = 60,
}) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    return;
  }

  final scrollable = find.byType(Scrollable);
  expect(scrollable, findsWidgets, reason: 'スクロール可能な領域が見つからない');

  for (final direction in <double>[delta, -delta]) {
    try {
      await tester.scrollUntilVisible(
        finder,
        direction,
        scrollable: scrollable.first,
        maxScrolls: maxScrolls,
      );
      await tester.pumpAndSettle();
      return;
    } on StateError {
      // この向きでは見つからなかった。逆向きを試す。
      await tester.pumpAndSettle();
    }
  }

  fail('スクロールしても対象が見つからない: $finder');
}

/// 遅延生成リストの要素をスクロールして出してからタップする
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollIntoView(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// 確認ダイアログ内のボタンをタップする
///
/// 【なぜ専用のヘルパーが要るか】: 画面本体にもクイック応答の「はい」「いいえ」が
/// 常時あるため、`tapButton(tester, 'はい')` は2件に一致して
/// `findsOneWidget` で落ちる。ダイアログが「出ていない」ように見えるが、
/// 実際は出ている——症状を誤読しやすい失敗の型である（Issue #84）。
///
/// `AlertDialog` の子孫に限定して数え、タップする。
Future<void> tapDialogButton(
  WidgetTester tester,
  String label,
) async {
  final finder = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text(label),
  );
  expect(
    finder,
    findsOneWidget,
    reason: 'ダイアログ内にボタン "$label" が見つからない'
        '（画面本体の同名ボタンと取り違えていないか確認すること）',
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tapButtonBySemanticsLabel(
  WidgetTester tester,
  String label,
) async {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget,
      reason: 'Button with semantics label "$label" not found');
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// ナビゲーションを実行
///
/// [tester]: WidgetTester
/// [destination]: 遷移先の識別子（ボタンテキストやアイコン）
Future<void> navigateTo(
  WidgetTester tester,
  String destination,
) async {
  final textFinder = find.text(destination);
  if (textFinder.evaluate().isNotEmpty) {
    await tester.tap(textFinder);
    await tester.pumpAndSettle();
    return;
  }

  // アイコンボタンを試す
  final iconFinder = find.byTooltip(destination);
  if (iconFinder.evaluate().isNotEmpty) {
    await tester.tap(iconFinder);
    await tester.pumpAndSettle();
    return;
  }

  fail('Navigation target "$destination" not found');
}

/// スクリーンショット取得（デバッグ用）
///
/// [binding]: IntegrationTestWidgetsFlutterBinding
/// [name]: スクリーンショット名
Future<void> takeScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.takeScreenshot(name);
}
