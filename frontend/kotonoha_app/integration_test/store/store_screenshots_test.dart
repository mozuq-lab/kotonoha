/// ストア用のスクリーンショットを撮る（台帳 L-107）
///
/// 本物のアプリを操作して、ホーム・対面表示・定型文・履歴・お気に入り・設定を撮る。
/// 画面の内容は利用者の操作で作る（履歴は読み上げた文だけが残る）。
/// 画像は `test_driver/screenshot_driver.dart` が `build/screenshots/` に書く。
///
/// ```bash
/// fvm flutter drive -d <device_id> \
///   --driver=test_driver/screenshot_driver.dart \
///   --target=integration_test/store/store_screenshots_test.dart
/// ```
/// Android では `--flavor production` も付ける。
///
/// `integration_test/*_test.dart` の走査（CI の Web 実行）には入らない。
@Tags(['e2e'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';

import '../helpers/test_helpers.dart';

/// 読み上げが終わるまで待つ（最大 10 秒）。「停止」が写らないように。
Future<void> _waitQuiet(WidgetTester tester) async {
  final container =
      ProviderScope.containerOf(tester.element(find.byType(KotonohaApp)));
  for (var i = 0;
      i < 100 && container.read(ttsProvider).state == TTSState.speaking;
      i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String tooltip) async {
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
  final binding = initializeE2ETestBinding();

  testWidgets('ストア用のスクリーンショット', (tester) async {
    // ストアの画像に DEBUG の帯を写さない（flutter drive はシミュレータでは debug ビルドになる）
    WidgetsApp.debugAllowBannerOverride = false;
    addTearDown(() => WidgetsApp.debugAllowBannerOverride = true);
    await pumpApp(tester);
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android は Flutter の描画面を画像にできる形へ切り替えてから撮る
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }

    Future<void> shoot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    // 履歴に残す文を、文字盤と定型文から読み上げておく
    await typeOnCharacterBoard(tester, 'あつい');
    await tapAndExpectSpeech(tester, find.text('読み上げ'));
    await _waitQuiet(tester);
    await tester.tap(find.byType(ClearAllButton));
    await tester.pumpAndSettle();
    await tapDialogButton(tester, 'はい');

    await _open(tester, '定型文');
    await scrollIntoView(tester, find.text('おはようございます'));
    await tapAndExpectSpeech(tester, find.text('おはようございます'));
    await _waitQuiet(tester);
    await _back(tester);

    // ホーム: 文字盤で打った文
    await typeOnCharacterBoard(tester, 'すこしやすみたい');
    await tapAndExpectSpeech(tester, find.text('読み上げ'));
    await _waitQuiet(tester);
    await shoot('01_home');

    await _open(tester, '対面表示');
    await shoot('02_face_to_face');
    await tester.tap(find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '対面表示モードを終了'));
    await tester.pumpAndSettle();

    await _open(tester, '定型文');
    await shoot('03_preset_phrases');
    await _back(tester);

    await _open(tester, '履歴');
    await shoot('04_history');
    await _back(tester);

    await _open(tester, 'お気に入り');
    await shoot('05_favorites');
    await _back(tester);

    await _open(tester, '設定');
    await shoot('06_settings');
  });
}
