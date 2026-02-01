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
Future<void> pumpApp(
  WidgetTester tester, {
  dynamic overrides,
  bool clearData = true,
}) async {
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
  debugPrint('$description: ${elapsed}ms (max: ${maxMilliseconds}ms)');

  expect(
    elapsed,
    lessThanOrEqualTo(maxMilliseconds),
    reason: '$description exceeded ${maxMilliseconds}ms (actual: ${elapsed}ms)',
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
