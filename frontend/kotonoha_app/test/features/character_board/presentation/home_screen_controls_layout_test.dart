import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/politeness_level_selector.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/status_buttons/presentation/widgets/status_button.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpHome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(inputBufferProvider.notifier).setText('おみず');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: lightTheme, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Rect _inputRect(WidgetTester tester) => tester.getRect(
      find
          .ancestor(
            of: find.text('おみず').first,
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

/// 左右端の比較（Expanded の等分で出る浮動小数点の端数を許す）
Matcher _at(double edge) => closeTo(edge, 0.5);

void main() {
  testWidgets('スマホでは状態ボタンを4列×2行で全部見せ、全行の左右端がそろう', (tester) async {
    await _pumpHome(tester, const Size(390, 844));

    final quick = find.byType(QuickResponseButton);
    final quickLeft = tester.getRect(quick.first).left;
    final quickRight = tester.getRect(quick.last).right;
    final status = find.byType(StatusButton);
    expect(status, findsNWidgets(8));
    final rects = [for (var i = 0; i < 8; i++) tester.getRect(status.at(i))];
    for (var i = 0; i < 8; i++) {
      expect(rects[i].height, 44, reason: '状態ボタン$i');
      expect(rects[i].top, rects[i < 4 ? 0 : 4].top, reason: '状態ボタン$i');
    }
    expect(rects[4].top, greaterThan(rects[0].bottom));
    expect(rects[0].left, _at(quickLeft));
    expect(rects[4].left, _at(quickLeft));
    expect(rects[3].right, _at(quickRight));
    expect(rects[7].right, _at(quickRight));

    final input = _inputRect(tester);
    expect(input.left, _at(quickLeft));
    expect(input.right, _at(quickRight));
    expect(input.top - rects[4].bottom, greaterThanOrEqualTo(8));

    final delete = tester.getRect(find.byType(DeleteButton));
    final clear = tester.getRect(find.byType(ClearAllButton));
    final ai = tester.getRect(find.byType(AIConversionButton));
    final speak = tester.getRect(find.byType(TTSButton));
    expect(delete.top - input.bottom, greaterThanOrEqualTo(8));
    for (final entry in {
      'delete': delete,
      'clear': clear,
      'ai': ai,
      'speak': speak,
    }.entries) {
      expect(entry.value.height, 48, reason: entry.key);
      expect(entry.value.top, delete.top, reason: entry.key);
    }
    expect(delete.left, _at(quickLeft));
    expect(speak.right, _at(quickRight));
    expect(ai.right, lessThan(speak.left));

    // 丁寧さの選択はホームに置かず、AI変換の結果画面で選ぶ。
    expect(find.byType(PolitenessLevelSelector), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('入力が空から2文字になるまで、文字盤が指の下で動かない', (tester) async {
    final container = await _pumpHome(tester, const Size(390, 844));
    // オンラインでないと文字数不足の案内の有無を見られない。
    await container.read(networkProvider.notifier).setOnline();
    final input = container.read(inputBufferProvider.notifier);
    final tops = <double>[];
    for (final text in ['', 'あ', 'ああ']) {
      input.setText(text);
      await tester.pumpAndSettle();
      tops.add(tester.getRect(find.byType(CharacterBoardWidget)).top);
    }
    expect(tops.toSet(), hasLength(1), reason: '文字盤の上端: $tops');
  });

  testWidgets('横持ちスマホの狭い左ペインでも、状態ボタンは1個44px以上', (tester) async {
    // 2ペインになる最小に近い幅（左ペインは約190px）。実機では緊急ボタンの
    // レール（右92px）が加わるため、568×320 の端末がこの幅になる。
    await _pumpHome(tester, const Size(480, 320));
    expect(
      tester.getRect(find.byType(CharacterBoardWidget)).left,
      greaterThan(200),
      reason: '2ペイン（右に文字盤）になっていない',
    );

    final status = find.byType(StatusButton);
    expect(status, findsNWidgets(8));
    for (var i = 0; i < 8; i++) {
      final rect = tester.getRect(status.at(i));
      expect(rect.width, greaterThanOrEqualTo(44), reason: '状態ボタン$i: $rect');
      expect(rect.height, greaterThanOrEqualTo(44), reason: '状態ボタン$i: $rect');
    }
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('幅${width.toInt()}で文字種の切り替え5つが切れずに並ぶ', (tester) async {
      await _pumpHome(tester, Size(width, 844));

      final chips = find.byType(ChoiceChip);
      expect(chips, findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        final rect = tester.getRect(chips.at(i));
        expect(rect.left, greaterThanOrEqualTo(0), reason: '文字種$i: $rect');
        expect(rect.right, lessThanOrEqualTo(width), reason: '文字種$i: $rect');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('タブレットでは状態ボタン8個を1行に並べ、操作ボタンは60px', (tester) async {
    await _pumpHome(tester, const Size(820, 1180));

    final quick = find.byType(QuickResponseButton);
    final quickLeft = tester.getRect(quick.first).left;
    final quickRight = tester.getRect(quick.last).right;
    final status = find.byType(StatusButton);
    final first = tester.getRect(status.first);
    final last = tester.getRect(status.last);
    expect(last.top, first.top);
    expect(first.height, 60);
    expect(first.left, _at(quickLeft));
    expect(last.right, _at(quickRight));

    final input = _inputRect(tester);
    expect(input.left, _at(quickLeft));
    expect(input.right, _at(quickRight));

    final delete = tester.getRect(find.byType(DeleteButton));
    final speak = tester.getRect(find.byType(TTSButton));
    for (final type in [
      DeleteButton,
      ClearAllButton,
      AIConversionButton,
      TTSButton,
    ]) {
      final rect = tester.getRect(find.byType(type));
      expect(rect.height, 60, reason: '$type');
      expect(rect.top, delete.top, reason: '$type');
    }
    expect(delete.left, _at(quickLeft));
    expect(speak.right, _at(quickRight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('結果画面で丁寧さを変えると、その丁寧さで変換し直して次回の既定にする', (tester) async {
    SharedPreferences.setMockInitialValues({'ai_privacy_consent': true});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final requestedLevels = <String>[];
    final politeReply = Completer<void>();
    // Dioの通信境界のみでローカルの固定応答を返す。アプリの変換処理は実物。
    // 「丁寧」の応答は、変換待ちの間の画面を見るため止めておく。
    container.read(aiConversionApiClientProvider).dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) async {
        final level = (options.data as Map)['politeness_level'] as String;
        requestedLevels.add(level);
        if (level == 'polite') await politeReply.future;
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'converted_text': '変換:$level',
            'original_text': 'おみず',
            'politeness_level': level,
            'processing_time_ms': 1,
          },
        ));
      }),
    );
    await container.read(networkProvider.notifier).setOnline();
    container.read(inputBufferProvider.notifier).setText('おみず');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: lightTheme, home: const HomeScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI変換'));
    await tester.pumpAndSettle();
    expect(requestedLevels, ['normal']);
    expect(find.text('変換:normal'), findsOneWidget);

    await tester.tap(find.text('丁寧'));
    for (var i = 0; i < 20 && requestedLevels.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 変換を待つ間もダイアログは1枚のまま進捗を出し、元の結果と
    // 「採用」「元の文を使う」は押せる（閉じ込めない）。
    expect(requestedLevels, ['normal', 'polite']);
    expect(find.byType(AIConversionResultDialog), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('変換:normal'), findsOneWidget);
    for (final label in ['採用', '元の文を使う']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      );
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNotNull,
          reason: label);
    }

    politeReply.complete();
    await tester.pumpAndSettle();

    expect(find.byType(AIConversionResultDialog), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('変換:polite'), findsOneWidget);
    expect(
      container.read(settingsNotifierProvider).value?.aiPoliteness,
      PolitenessLevel.polite,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ai_politeness'), 'polite');
    expect(tester.takeException(), isNull);
  });
}
