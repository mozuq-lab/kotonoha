/// 全画面共通の帯（音量 0・保存できない・読み上げ失敗・オフライン）が、
/// VoiceOver / TalkBack で読める項目として semantics tree にあること
///
/// 物理 iPad の VoiceOver で「音量が0です」の帯に触れても、読める項目が無いときの
/// 音がするだけで何も読まれなかった（2026-10-17）。原因: 帯はシェル
/// （`AppShell`）の中で、画面を載せる入れ子の Navigator と並んでいる。
/// Navigator の各ページの後ろには `ModalBarrier` があり、その `BlockSemantics` は
/// 「同じ semantics の区切りの中で、先に描かれたもの」を tree から外す。
/// 入れ子の Navigator が区切りになっていなかったので、先に描かれる帯がすべて
/// 外れていた（台帳 L-173・L-178 の「Web の semantics tree に出ない」も同じ原因）。
///
/// 本番と同じ router（`KotonohaApp`）で確かめる。`MaterialApp(home: …)` の
/// 1 本の Navigator では帯が入れ子の Navigator と並ばず、偽の緑になる。
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_failure_banner.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_flutter_tts.dart';
import '../../mocks/mock_volume_controller.dart';

void main() {
  late MockFlutterTts tts;
  late MockVolumeController volume;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
    registerFallbackValue(() {});
  });

  setUp(() {
    tts = MockFlutterTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    stubSpeakThatStarts(tts);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    volume = MockVolumeController();
    when(() => volume.getVolume()).thenAnswer((_) async => 0.0);
    when(() => volume.getMute()).thenAnswer((_) async => true);
  });

  /// 本番と同じ router でアプリを起動する
  /// [storageReady]: 保存できる状態にして、保存できない帯を出さない
  /// （テストの環境には Hive が無いので、既定では保存できない帯が出る）
  Future<ProviderContainer> startApp(
    WidgetTester tester, {
    bool storageReady = true,
  }) async {
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});
    final container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts))),
      volumeServiceProvider
          .overrideWithValue(VolumeService(volumeController: volume)),
      if (storageReady)
        persistenceStateProvider.overrideWithValue(const PersistenceReady()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KotonohaApp(),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// 画面の左上を原点にした、物理ピクセルでの位置
  Rect globalRect(SemanticsNode node) {
    var rect = node.rect;
    for (SemanticsNode? n = node; n != null; n = n.parent) {
      final transform = n.transform;
      if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
    }
    return rect;
  }

  /// [label] をそのまま読む項目が、根から辿れる tree に 1 つだけあり、
  /// 隠れておらず、画面の中に大きさを持って置かれている
  SemanticsNode expectReadable(WidgetTester tester, String label) {
    final nodes = find.semantics.byLabel(label).evaluate().toList();
    expect(nodes, hasLength(1),
        reason: '「$label」を読む項目が無い（VoiceOver が何も読まない）か、二重にある');
    final node = nodes.single;
    expect(node.label, label, reason: '他の文と連結されて読まれる');
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isHidden, isFalse);
    final rect = globalRect(node);
    final screen = Offset.zero & tester.view.physicalSize;
    expect(rect.isEmpty, isFalse, reason: '大きさが無いと触れられない');
    expect(screen.intersect(rect), rect, reason: '画面の外にはみ出している: $rect');
    return node;
  }

  testWidgets('音量 0 の帯と、その「閉じる」ボタン', (tester) async {
    final handle = tester.ensureSemantics();
    await startApp(tester);
    await tester.tap(find.text('はい'));
    await tester.pumpAndSettle();
    expect(find.text('音量が0です'), findsOneWidget);

    expectReadable(tester, '警告: 音量が0です');
    final close = expectReadable(tester, '閉じる');
    final data = close.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    // 「閉じる」を支援技術から押すと帯が消える
    tester.semantics.tap(find.semantics.byLabel('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('音量が0です'), findsNothing);
    handle.dispose();
  });

  testWidgets('保存できない帯', (tester) async {
    final handle = tester.ensureSemantics();
    await startApp(tester, storageReady: false);
    // 文言は保存できない領域で変わるので、帯に描かれた文をそのまま読むことを見る
    final shown = tester
        .widget<Text>(find.descendant(
          of: find.byType(PersistenceBanner),
          matching: find.byType(Text),
        ))
        .data!;
    expect(shown, contains('保存できません'));

    expectReadable(tester, shown);
    handle.dispose();
  });

  testWidgets('読み上げ失敗の帯', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => tts.setLanguage(any()))
        .thenAnswer((_) async => throw Exception('no voice'));
    await startApp(tester);

    expectReadable(tester, TtsFailureBanner.startupMessage);
    handle.dispose();
  });

  testWidgets('オフラインの帯', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await startApp(tester);
    await container.read(networkProvider.notifier).setOffline();
    await tester.pumpAndSettle();

    expectReadable(tester, 'オフライン状態です。基本機能のみ利用可能です。');
    handle.dispose();
  });

  testWidgets('帯が出ていても、画面の項目は読める項目のまま', (tester) async {
    final handle = tester.ensureSemantics();
    await startApp(tester, storageReady: false);

    // ホームの AppBar の題（画面の名前として読まれる）
    expectReadable(tester, 'kotonoha');
    handle.dispose();
  });
}
