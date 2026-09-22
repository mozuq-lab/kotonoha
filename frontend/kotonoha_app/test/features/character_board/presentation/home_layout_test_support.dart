/// 低い画面・オフライン時のHome表示テストの共通土台（台帳 L-155・L-156）
/// ファイル目的: 実AppShell・フォント設定「大」・OSの文字拡大・オフラインで
/// Homeを立ち上げ、矩形と段落を最も外側から測るための道具を1箇所に置く。
/// 使う側は home_screen_low_screen_board_test.dart（L-155: 文字盤のキー）。
/// 複製すると片方だけ弱いまま取り残されるため、ここにまとめる。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 文字盤の先頭2行（あ行・か行）
const List<String> boardKeys = [
  'あ',
  'い',
  'う',
  'え',
  'お',
  'か',
  'き',
  'く',
  'け',
  'こ'
];

/// 文字盤のキー。矩形はInkWell＝GridViewのタイルで測る。
Finder boardCell(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InkWell));

/// [outer] が [inner] を包んでいるか
bool encloses(Rect outer, Rect inner, {double tolerance = .01}) =>
    outer.inflate(tolerance).contains(inner.topLeft) &&
    outer.inflate(tolerance).contains(inner.bottomRight);

/// 既知の横オーバーフロー（台帳 L-156）だけに当たる matcher。
/// 告知の折り返しを入れるまでは幅320でバナーのRowが右へはみ出すので
/// 文字盤側のテストはこれを許すしかないが、**許すのはこれだけ**にする。
/// 負の制約（NOT NORMALIZED）・縦のオーバーフロー・その他の framework
/// 例外は赤にする。
final Matcher isKnownHorizontalOverflow = predicate<Object?>(
  (exception) =>
      exception is FlutterError &&
      exception.toString().contains('RenderFlex overflowed') &&
      exception.toString().contains('on the right'),
  '既知の横オーバーフロー（RenderFlex overflowed … on the right）',
);

/// [harness] の直前の pump で出た例外が、既知の横オーバーフローだけで
/// あることを見る（1 件も出ていなければ当然緑）。
void expectOnlyKnownOverflow(HomeLayoutHarness harness, {String? reason}) {
  expect(harness.pumpErrors, everyElement(isKnownHorizontalOverflow),
      reason: reason ?? '既知の横overflow以外の例外が出ている: ${harness.pumpErrors}');
}

/// 実AppShellでHomeを立ち上げる土台。テストの main() で [install] を呼ぶ。
class HomeLayoutHarness {
  HomeLayoutHarness._(this._binding);

  static const List<String> _channels = ['connectivity', 'connectivity_status'];

  final TestWidgetsFlutterBinding _binding;
  late Directory _directory;

  /// providerを直接読み書きして状態を作るためのコンテナ
  late ProviderContainer container;

  /// 直前の [pumpOffline] で出た framework 例外（畳まずに全部）
  /// `takeException()` は複数の例外を「Multiple exceptions (N)」1本に
  /// 畳んでしまい、1件ずつの判定ができない。SDK境界の
  /// `FlutterError.onError` を pump の間だけ差し替えて集める。
  final List<Object> pumpErrors = [];

  /// setUp/tearDownを張って土台を返す。差し替えるのはSDK境界
  /// （connectivityのMethodChannel・SharedPreferences・実Hive）だけ。
  static HomeLayoutHarness install() {
    final harness =
        HomeLayoutHarness._(TestWidgetsFlutterBinding.ensureInitialized());
    setUp(harness._setUp);
    tearDown(harness._tearDown);
    return harness;
  }

  Future<void> _setUp() async {
    SharedPreferences.setMockInitialValues({
      'fontSize': 'large',
      'tutorial_completed': true,
    });
    _directory = await Directory.systemTemp.createTemp('home_low_screen_');
    Hive.init(_directory.path);
    registerPersistedTypeAdapters();
    await openPersistedBoxes(hivePath: _directory.path);
    container = ProviderContainer();
    for (final name in _channels) {
      _binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('dev.fluttercommunity.plus/$name'),
        (call) async => call.method == 'check' ? ['wifi'] : null,
      );
    }
  }

  Future<void> _tearDown() async {
    container.dispose();
    await Hive.close();
    await _directory.delete(recursive: true);
    for (final name in _channels) {
      _binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel('dev.fluttercommunity.plus/$name'), null);
    }
  }

  /// 実AppShellを[size]で立ち上げ、入力を抱えたままオフラインにする。
  /// [scale]はOSの文字拡大倍率。出た例外は [pumpErrors] に全部入り
  /// 戻り値はその先頭（1件も無ければnull）。取り出さないと後続の観測と
  /// 関係のない理由でテストが落ちるため、ここで必ず取り出す。
  /// [extraChrome] はAppShellの外側に積む帯の高さ。告知を折り返すと
  /// オフラインバナーが56→96pxに増えるので、その差をこの土台だけで
  /// 作るために使う（折り返しを入れる側にも実バナー込みの同じテストがある）。
  Future<Object?> pumpOffline(WidgetTester tester, Size size,
      {double scale = 2, double extraChrome = 0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    pumpErrors.clear();
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => pumpErrors.add(details.exception);
    try {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) => MaterialApp(
            theme: ref.watch(currentThemeProvider),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: extraChrome > 0
                ? Column(children: [
                    SizedBox(height: extraChrome),
                    const Expanded(child: AppShell(child: HomeScreen())),
                  ])
                : const AppShell(child: HomeScreen()),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      container.read(inputBufferProvider.notifier).setText('あ' * 999);
      await container.read(networkProvider.notifier).setOffline();
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = previousOnError;
    }
    // 差し替えの網から漏れた分（binding が先に受けたもの）も拾う。
    final pending = tester.takeException();
    if (pending != null) pumpErrors.add(pending);
    return pumpErrors.isEmpty ? null : pumpErrors.first;
  }
}
