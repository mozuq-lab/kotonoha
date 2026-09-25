/// 利用シナリオの結合テスト（`docs/now.md` の「形」の定義）
///
/// 初めて使う人が、要件の MVP（文字盤・読み上げ・定型文・履歴・お気に入り・
/// 設定）を説明なしに一通り使えることを、本物のアプリで確かめる。
/// iOS シミュレータ（iPad）と Android エミュレータで走らせる。
///
/// 1 本の長いテストにしない理由: 最初の失敗で止まると、その先の
/// 足りないものが見えない。利用の区切りごとに分け、それぞれ本物のアプリを
/// 起動するところから始める。
///
/// 読み上げの確かめ方: 押す前から TTS の状態（`ttsProvider`）の移り変わりを
/// 記録し、speaking を一度でも通ったかを見る。読み上げボタンの「停止」は、
/// `pumpAndSettle` が読み上げの終わりまで待ってしまうと消えているので使わない。
@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/persistence/recreated_areas_provider.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(KotonohaApp)));

/// 読み上げの状態の移り変わりを記録し始める（押す前に呼ぶ）
List<TTSState> _recordSpeech(WidgetTester tester) {
  final seen = <TTSState>[];
  final sub = _container(tester)
      .listen<TTSServiceState>(ttsProvider, (_, next) => seen.add(next.state));
  addTearDown(() {
    try {
      sub.close();
    } catch (_) {
      // 起動し直した後は、元の container が破棄済みのことがある
    }
  });
  return seen;
}

/// 記録し始めてから、読み上げ中を一度でも通ったか（最大 6 秒待つ）
Future<void> _expectSpoke(
    WidgetTester tester, List<TTSState> seen, String what) async {
  for (var i = 0; i < 60 && !seen.contains(TTSState.speaking); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(seen, contains(TTSState.speaking),
      reason: '$whatで読み上げが始まらない（状態の移り変わり: $seen）');
  await tester.pumpAndSettle();
}

/// 端末に残った設定（SharedPreferences）を消さずに、アプリを起動し直す
/// `restartApp` は `pumpApp` 経由で SharedPreferences を作り直すので、
/// 設定が残るかを確かめるときには使えない。
Future<void> _relaunchKeepingSettings(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  final outcomes = await initHive();
  await tester.pumpWidget(ProviderScope(
    overrides: [corruptionOutcomesProvider.overrideWithValue(outcomes)],
    child: const KotonohaApp(),
  ));
  await tester.pumpAndSettle();
}

/// 文字盤で 1 文字ずつ打つ。電話の画面では文字盤の一部の行しか描画されない
/// （GridView.builder）ので、利用者と同じく文字盤をなぞって目的の文字を出す。
Future<void> _type(WidgetTester tester, String text) async {
  final grid = find.descendant(
    of: find.byType(CharacterBoardWidget),
    matching: find.byType(GridView),
  );
  for (final ch in text.split('')) {
    final key = find.byKey(ValueKey('character_button_$ch'));
    for (final dy in [-150.0, 150.0]) {
      for (var i = 0; i < 12 && key.evaluate().isEmpty; i++) {
        await tester.dragFrom(tester.getRect(grid).center, Offset(0, dy));
        await tester.pumpAndSettle();
      }
    }
    expect(key, findsOneWidget, reason: '文字盤をなぞっても「$ch」に届かない');
    await tester.ensureVisible(key);
    await tester.pumpAndSettle();
    await tester.tap(key);
    await tester.pump();
  }
}

/// 前の読み上げが終わるまで待つ（最大 10 秒）。続けて押す操作を、
/// 前の読み上げの途中の割り込みにしないため。
Future<void> _waitQuiet(WidgetTester tester) async {
  for (var i = 0;
      i < 100 &&
          _container(tester).read(ttsProvider).state == TTSState.speaking;
      i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openFromHome(WidgetTester tester, String tooltip) async {
  final target = find.byTooltip(tooltip);
  expect(target, findsOneWidget, reason: 'ホームに「$tooltip」の入口が無い');
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  initializeE2ETestBinding();

  testWidgets('1. 初回起動: チュートリアルを最後まで進めるとホームに出て、次の起動では出ない', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester, completeTutorial: false);

    expect(find.text('ようこそ、ことのはへ'), findsOneWidget, reason: '初回起動でチュートリアルが出ない');
    for (final title in ['文字盤で入力', '定型文を使う', '読み上げ機能', '準備完了']) {
      await tapButton(tester, '次へ');
      expect(find.text(title), findsOneWidget, reason: 'チュートリアルの「$title」に進めない');
    }
    await tapButton(tester, 'はじめる');
    expect(find.text('準備完了'), findsNothing, reason: '「はじめる」でチュートリアルが閉じない');
    expect(find.text('kotonoha'), findsOneWidget);

    await _relaunchKeepingSettings(tester);
    expect(find.text('ようこそ、ことのはへ'), findsNothing, reason: '完了したチュートリアルが再び出る');
  });

  testWidgets('2. 文字盤で打って読み上げ、履歴に残り、お気に入りにして使える', (tester) async {
    await pumpApp(tester);

    await _type(tester, 'こんにちは');
    expect(find.text('こんにちは'), findsWidgets, reason: '打った文が入力欄に出ない');

    final spoken = _recordSpeech(tester);
    await tester.tap(find.text('読み上げ'));
    await _expectSpoke(tester, spoken, '読み上げボタン');

    // 入力欄を空にする（確認つき）
    await tester.tap(find.bySemanticsLabel('全消去'));
    await tester.pumpAndSettle();
    expect(find.text('入力内容をすべて消去しますか？'), findsOneWidget, reason: '全消去の確認が出ない');
    await tapDialogButton(tester, 'はい');
    expect(find.text('入力してください...'), findsOneWidget, reason: '全消去で入力欄が空にならない');

    // 履歴に残っていて、お気に入りにできる
    await _openFromHome(tester, '履歴');
    expect(find.text('こんにちは'), findsOneWidget, reason: '読み上げた文が履歴に無い');
    await tester.tap(find.byTooltip('お気に入りに追加'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('お気に入り登録済み'), findsOneWidget,
        reason: '履歴からお気に入りにできない');
    await _back(tester);

    // お気に入りから読み上げる
    await _openFromHome(tester, 'お気に入り');
    expect(find.text('こんにちは'), findsOneWidget, reason: 'お気に入りに出ない');
    final again = _recordSpeech(tester);
    await tester.tap(find.text('こんにちは'));
    await _expectSpoke(tester, again, 'お気に入りのタップ');
    await _back(tester);
    expect(find.text('kotonoha'), findsOneWidget);
  });

  testWidgets('3. 定型文をタップすると読み上げて履歴に残り、追加した定型文は再起動後も残る', (tester) async {
    await pumpApp(tester);

    await _openFromHome(tester, '定型文');
    await scrollIntoView(tester, find.text('おはようございます'));
    final spoken = _recordSpeech(tester);
    await tester.tap(find.text('おはようございます'));
    await _expectSpoke(tester, spoken, '定型文のタップ');

    await tester.tap(find.byTooltip('定型文を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'シナリオで足した文');
    await tester.pump();
    await tapDialogButton(tester, '保存');
    await scrollIntoView(tester, find.text('シナリオで足した文'));
    expect(find.text('シナリオで足した文'), findsOneWidget, reason: '追加した定型文が一覧に出ない');
    await _back(tester);

    await _openFromHome(tester, '履歴');
    expect(find.text('おはようございます'), findsOneWidget, reason: 'タップした定型文が履歴に無い');
    await _back(tester);

    await restartApp(tester);
    await _openFromHome(tester, '定型文');
    await scrollIntoView(tester, find.text('シナリオで足した文'));
    expect(find.text('シナリオで足した文'), findsOneWidget, reason: '追加した定型文が再起動で消える');
  });

  testWidgets('4. 大ボタンと状態ボタンは押すとすぐ読み上げ、履歴に残る', (tester) async {
    await pumpApp(tester);

    final quick = _recordSpeech(tester);
    await tester.tap(find.text('いいえ'));
    await _expectSpoke(tester, quick, '「いいえ」');

    await _waitQuiet(tester);
    final status = _recordSpeech(tester);
    await tester.tap(find.text('痛い'));
    await _expectSpoke(tester, status, '「痛い」');

    await _openFromHome(tester, '履歴');
    expect(find.text('いいえ'), findsOneWidget, reason: '「いいえ」が履歴に無い');
    expect(find.text('痛い'), findsOneWidget, reason: '「痛い」が履歴に無い');
  });

  testWidgets('5. 設定（文字の大きさ・テーマ・読み上げ速度）を変えると、再起動後も残る', (tester) async {
    await pumpApp(tester);
    await _openFromHome(tester, '設定');

    await scrollAndTap(tester, find.text('大'));
    await scrollAndTap(tester, find.text('ダーク'));
    await scrollAndTap(tester, find.text('遅い'));

    var settings =
        await _container(tester).read(settingsNotifierProvider.future);
    expect(settings.fontSize, FontSize.large, reason: '文字の大きさが変わらない');
    expect(settings.theme, AppTheme.dark, reason: 'テーマが変わらない');
    expect(settings.ttsSpeed, TTSSpeed.slow, reason: '読み上げ速度が変わらない');

    await _relaunchKeepingSettings(tester);
    settings = await _container(tester).read(settingsNotifierProvider.future);
    expect(settings.fontSize, FontSize.large, reason: '文字の大きさが再起動で戻る');
    expect(settings.theme, AppTheme.dark, reason: 'テーマが再起動で戻る');
    expect(settings.ttsSpeed, TTSSpeed.slow, reason: '読み上げ速度が再起動で戻る');
  });

  testWidgets('6. 履歴とお気に入りは再起動後も残り、入力中の文も戻る', (tester) async {
    await pumpApp(tester);

    // 「ず」は「す」に濁点を付けて打つ
    await _type(tester, 'みす');
    await _type(tester, '゛');
    expect(find.text('みず'), findsWidgets, reason: '濁点で「ず」にならない');
    final spoken = _recordSpeech(tester);
    await tester.tap(find.text('読み上げ'));
    await _expectSpoke(tester, spoken, '読み上げボタン');
    await _openFromHome(tester, '履歴');
    await tester.tap(find.byTooltip('お気に入りに追加'));
    await tester.pumpAndSettle();
    await _back(tester);

    // 読み上げずに打ちかけた文
    await tester.tap(find.bySemanticsLabel('全消去'));
    await tester.pumpAndSettle();
    await tapDialogButton(tester, 'はい');
    await _type(tester, 'さむい');
    // 入力中の文は 400ms 後に保存される
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await _relaunchKeepingSettings(tester);
    expect(find.text('さむい'), findsWidgets, reason: '打ちかけの文が再起動で戻らない');
    await _openFromHome(tester, '履歴');
    expect(find.text('みず'), findsOneWidget, reason: '履歴が再起動で消える');
    await _back(tester);
    await _openFromHome(tester, 'お気に入り');
    expect(find.text('みず'), findsOneWidget, reason: 'お気に入りが再起動で消える');
  });
}
