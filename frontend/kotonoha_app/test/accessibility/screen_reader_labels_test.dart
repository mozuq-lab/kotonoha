/// VoiceOver / TalkBack が、画面の項目を 1 回ずつ、意図した読み方で読むこと
///
/// 物理 iPad の VoiceOver で確かめた不具合（2026-10-17）:
/// - 文字ボタンが「あ、あ、ボタン」と 2 回読まれた。ボタンに付けた名前に、
///   中に描いた文字が合流していた（ほかのボタンは、外の名前とボタン自身の名前が
///   別々の項目になり、同じ名前が 2 つ並んでいた）
/// - 「AI変換」が「あい変換」と読まれた
/// - 記号キー「ー」「、」「。」に触れても無音だった（VoiceOver は既定で句読点を読まない）
///
/// 見た目は変えず、読み上げ用の名前だけを直したことを semantics tree で見る。
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_loading.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_item_card.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/presentation/widgets/history_item_card.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/online_recovery_notification.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/simple_mode/presentation/simple_mode_view.dart';
import 'package:kotonoha_app/features/tts/domain/services/tts_service.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_flutter_tts.dart';
import '../mocks/mock_volume_controller.dart';

/// 読み上げの tree 全体で、二重に読まれる名前・「あい」と読まれる名前を集める
/// - 1 つの項目の中で同じ文が繰り返される（「あ」の中に「あ」が合流）
/// - 親と子が同じ名前を持つ（外の名前とボタン自身の名前が別の項目として並ぶ）
/// - 名前・ヒント・ツールチップに「AI」が残る（日本語の声で「あい」と読まれる）
/// - ボタンの名前が「ボタン」で終わる（VoiceOver が「…ボタン、ボタン」と読む）
List<String> readingProblems(WidgetTester tester) {
  final problems = <String>[];
  void walk(SemanticsNode node, String parentLabel) {
    final data = node.getSemanticsData();
    final label = data.label;
    final parts = label.split('\n');
    if (parts.length != parts.toSet().length) {
      problems.add('同じ文が 2 回: ${label.replaceAll('\n', '⏎')}');
    }
    if (label.isNotEmpty && label == parentLabel) {
      problems.add('親子で同じ名前: $label');
    }
    for (final text in [label, data.hint, data.tooltip]) {
      if (text.contains('AI')) problems.add('「AI」が残る: $text');
    }
    if (data.flagsCollection.isButton && label.endsWith('ボタン')) {
      problems.add('「ボタン」が 2 回: $label');
    }
    node.visitChildren((child) {
      walk(child, label);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!, '');
  return problems;
}

/// [label] とちょうど同じ名前のボタンが 1 つだけあり、支援技術から押せる
SemanticsNode expectSingleButton(String label, {bool tappable = true}) {
  final nodes = find.semantics.byLabel(label).evaluate().toList();
  expect(nodes, hasLength(1), reason: '「$label」を読む項目が 1 つでない');
  final node = nodes.single;
  expect(node.label, label, reason: '他の文と連結されて読まれる');
  final data = node.getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue, reason: '「$label」がボタンでない');
  expect(data.hasAction(SemanticsAction.tap), tappable,
      reason: '「$label」をダブルタップで押せるか');
  return node;
}

void main() {
  late MockFlutterTts tts;
  late MockVolumeController volume;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(0.0);
  });

  setUp(() {
    tts = MockFlutterTts();
    when(() => tts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => tts.setSpeechRate(any())).thenAnswer((_) async => 1);
    stubSpeakThatStarts(tts);
    when(() => tts.stop()).thenAnswer((_) async => 1);
    volume = MockVolumeController();
    when(() => volume.getVolume()).thenAnswer((_) async => 0.5);
    when(() => volume.getMute()).thenAnswer((_) async => false);
  });

  /// 本番と同じ router でアプリを起動する（タブレット横の大きさ）
  Future<ProviderContainer> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});
    final container = ProviderContainer(overrides: [
      ttsProvider.overrideWith(
          () => TTSNotifier(serviceOverride: TTSService(tts: tts))),
      volumeServiceProvider
          .overrideWithValue(VolumeService(volumeController: volume)),
      persistenceStateProvider.overrideWithValue(const PersistenceReady()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const KotonohaApp(),
    ));
    await container.read(networkProvider.notifier).setOnline();
    await tester.pumpAndSettle();
    return container;
  }

  group('ホーム', () {
    testWidgets('文字ボタン・大ボタン・操作ボタンは、名前を 1 回だけ読み、ダブルタップで押せる', (tester) async {
      final handle = tester.ensureSemantics();
      await startApp(tester);

      expectSingleButton('あ');
      expectSingleButton('濁点');
      expectSingleButton('空白');
      expectSingleButton('はい');
      expectSingleButton('いいえ');
      expectSingleButton('わからない');
      expectSingleButton('読み上げ');

      // 支援技術から押すと入力される（InkWell の押す動作が残っている）
      tester.semantics.tap(find.semantics.byLabel('あ'));
      await tester.pumpAndSettle();
      tester.semantics.tap(find.semantics.byLabel('い'));
      await tester.pumpAndSettle();
      expect(find.text('あい'), findsOneWidget);

      expectSingleButton('削除');
      expectSingleButton('全消去');
      // 「AI変換」の見た目は変えず、読み方だけ「エーアイ」にする
      expect(find.text('AI変換'), findsOneWidget);
      expectSingleButton('エーアイ変換');

      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('記号キー「ー」「、」「。」は語で読む', (tester) async {
      final handle = tester.ensureSemantics();
      await startApp(tester);
      await tester.tap(find.text('記号'));
      await tester.pumpAndSettle();

      expectSingleButton('長音');
      expectSingleButton('読点');
      expectSingleButton('句点');
      expectSingleButton('？');
      expectSingleButton('！');

      tester.semantics.tap(find.semantics.byLabel('長音'));
      await tester.pumpAndSettle();
      expect(find.text('ー'), findsNWidgets(2), reason: 'キーと入力欄の 2 か所');

      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('オフラインの知らせも、AI をエーアイと読み、二重に読まない', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await startApp(tester);
      await container.read(networkProvider.notifier).setOffline();
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel('オフライン状態です。エーアイ変換機能は利用できません。'),
        findsOne,
      );
      expectSingleButton('エーアイ変換', tappable: false);
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('設定とヘルプの見出しも、AI をエーアイと読む', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await startApp(tester);

      container.read(routerProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      expect(find.text('AI設定'), findsOneWidget);
      expect(find.semantics.byLabel('エーアイ設定'), findsOne);
      expect(readingProblems(tester), isEmpty);

      container.read(routerProvider).go(AppRoutes.help);
      await tester.pumpAndSettle();
      expect(find.text('AI変換'), findsOneWidget);
      // 見出しは説明文と 1 つの項目にまとまって読まれる
      expect(find.semantics.byLabel(RegExp('エーアイ変換')), findsOne);
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });
  });

  group('一覧と画面の部品', () {
    final favorite =
        Favorite(id: 'f1', content: 'みず', createdAt: DateTime(2026, 1, 1));

    Future<void> pumpPart(WidgetTester tester, Widget part) async {
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ListView(children: [part])),
        ),
      ));
      await tester.pump(const Duration(seconds: 4));
    }

    testWidgets('定型文の行は、文を 1 回だけ読み、押せる', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPart(
        tester,
        PhraseListItem(
          phrase: PresetPhrase(
            id: 'p1',
            content: 'おはよう',
            category: 'daily',
            displayOrder: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          isFavorite: false,
          onTap: () {},
          onFavoriteToggle: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      );
      expectSingleButton('おはよう');
      expectSingleButton('入力欄へ');
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('履歴の行は、種類・文・日時を 1 回だけ読み、AI をエーアイと読む', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPart(
        tester,
        HistoryItemCard(
          history: History(
            id: 'h1',
            content: 'こんにちは',
            createdAt: DateTime(2026, 10, 1, 9, 30),
            type: HistoryType.aiConverted,
          ),
          onTap: () {},
          onDelete: () {},
          onFavoriteTap: () {},
          onLongPress: () {},
        ),
      );
      final node = expectSingleButton('エーアイ変換、こんにちは、10/01 09:30');
      expect(
          node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue,
          reason: '長押しでお気に入りに追加するメニューが、支援技術から開けない');
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('お気に入りの行は、文と日時を 1 回だけ読む', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPart(
        tester,
        FavoriteItemCard(
          favorite: favorite,
          onTap: () {},
          onDelete: () {},
          onColorChange: () {},
        ),
      );
      expectSingleButton('お気に入り、みず、01/01 00:00');
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('ホームのお気に入りボタンは、文を 1 回だけ読む', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPart(
        tester,
        FavoriteShortcutButton(
          favorite: favorite,
          onPressed: () {},
          height: 60,
          fontSize: FontSize.medium,
        ),
      );
      expectSingleButton('みず');
      // ツールチップも同じ文なので、読ませるとボタンの外に「みず」の項目がもう 1 つできる
      final mentions = <String>[];
      void walk(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.label.contains('みず') || data.tooltip.contains('みず')) {
          mentions.add('label=${data.label} tooltip=${data.tooltip}');
        }
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
      expect(mentions, hasLength(1), reason: '$mentions');
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('シンプルモードのボタンは、名前を 1 回だけ読む', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPart(
        tester,
        SizedBox(
          height: 800,
          child: SimpleModeView(
            fontSize: FontSize.medium,
            favorites: [favorite],
            onQuickResponse: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      expectSingleButton('通常モードに戻る');
      expectSingleButton('はい');
      expectSingleButton('みず');
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('AI 変換中の表示は、AI をエーアイと読み、二重に読まない', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPart(tester, const AIConversionLoading());
      expect(find.text('AI変換中...'), findsOneWidget);
      expect(find.semantics.byLabel('エーアイ変換処理中。しばらくお待ちください。'), findsOne);
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });
  });

  group('知らせとダイアログ', () {
    testWidgets('オンライン復帰の帯は、AI をエーアイと読む', (tester) async {
      final handle = tester.ensureSemantics();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(networkProvider.notifier).setOffline();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: OnlineRecoveryNotification(
              displayDuration: const Duration(seconds: 10),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ));
      await container.read(networkProvider.notifier).setOnline();
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('オンラインに戻りました。エーアイ変換が利用可能です。'), findsOne);
      expect(readingProblems(tester), isEmpty);
      await tester.pump(const Duration(seconds: 11));
      handle.dispose();
    });

    testWidgets('確認ダイアログの見出しと本文は、AI をエーアイと読む', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ConfirmationDialog(
            title: 'AI変換の利用確認',
            message: '入力した文章がAIサービスへ送られます。',
            cancelLabel: '同意しない',
            confirmLabel: '同意して利用',
            kind: ConfirmKind.normal,
            onCancel: () {},
            onConfirm: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('AI変換の利用確認'), findsOneWidget);
      expect(find.semantics.byLabel('エーアイ変換の利用確認'), findsOne);
      expect(find.semantics.byLabel(RegExp('エーアイサービスへ送られます')), findsOne);
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('変換結果のダイアログは、AI をエーアイと読む', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => AIConversionResultDialog.show(
                  context: context,
                  originalText: 'みず',
                  convertedText: 'お水をください',
                  politenessLevel: PolitenessLevel.normal,
                  onAdopt: (_) {},
                  onRegenerate: () {},
                  onLevelChanged: (_) async => throw Exception('失敗'),
                ),
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      expect(find.text('AI変換結果'), findsOneWidget);
      expect(find.semantics.byLabel(RegExp('エーアイ変換結果')), findsWidgets);

      // 丁寧さを選び直して失敗したときの知らせも
      await tester.tap(find.text('丁寧'));
      await tester.pumpAndSettle();
      expect(find.textContaining('AI変換に失敗しました'), findsOneWidget);
      // 丁寧さのボタンも 1 回だけ読み、選んだものは選択中と分かる
      final selected = expectSingleButton('普通、選択中');
      expect(selected.getSemanticsData().flagsCollection.isSelected,
          Tristate.isTrue);
      expectSingleButton('丁寧');
      expect(readingProblems(tester), isEmpty);
      handle.dispose();
    });
  });
}
