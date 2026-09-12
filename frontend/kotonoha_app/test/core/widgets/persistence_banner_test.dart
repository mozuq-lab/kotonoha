/// 永続化バナーのテスト（ADR-005 / Phase 3 WP-1）
/// 何を守るテストか: 「保存できたように見えて消える」を防ぐ。
/// 利用者は発話で確認・訂正できず、データは端末内にしか無い。
/// 検証は描画されたウィジェットで行い、状態クラスの戻り値では行わない。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';

/// WCAG 2.1 の相対輝度
double _relativeLuminance(Color color) {
  double channel(double v) {
    final c = v / 255.0;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(color.r * 255) +
      0.7152 * channel(color.g * 255) +
      0.0722 * channel(color.b * 255);
}

/// WCAG 2.1 のコントラスト比
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

Future<void> _pumpBanner(
  WidgetTester tester,
  PersistenceState state, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [persistenceStateProvider.overrideWithValue(state)],
      child: MaterialApp(
        theme: theme ?? lightTheme,
        home: const Scaffold(body: PersistenceBanner()),
      ),
    ),
  );
}

void main() {
  group('PersistenceBanner の表示', () {
    testWidgets('Ready のときは何も表示せず、高さを取らない', (tester) async {
      await _pumpBanner(tester, const PersistenceReady());

      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(PersistenceBanner)).height, 0);
    });

    testWidgets('Unavailable のとき、保存されないことを利用者に伝える', (tester) async {
      await _pumpBanner(tester, const PersistenceUnavailable());

      expect(find.textContaining('保存できません'), findsOneWidget);
      expect(find.textContaining('消えます'), findsOneWidget);
    });

    testWidgets('RecoverableFailure のとき、保存できない領域の名前を出す', (tester) async {
      await _pumpBanner(
        tester,
        const PersistenceRecoverableFailure({PersistedArea.presetPhrases}),
      );

      expect(find.textContaining('定型文'), findsOneWidget);
    });

    testWidgets('RecoverableFailure で保存できている領域の名前は出さない', (tester) async {
      await _pumpBanner(
        tester,
        const PersistenceRecoverableFailure({PersistedArea.presetPhrases}),
      );

      expect(find.textContaining('履歴'), findsNothing);
      expect(find.textContaining('お気に入り'), findsNothing);
    });

    testWidgets('Unavailable でも「入力内容が消える」とは言わない', (tester) async {
      // なぜ: 下書き（入力バッファ）は Hive ではなく SharedPreferences に
      // 保存され、AppLifecycleObserver が復元する。Hive が全滅しても入力内容は
      // 残るため、「入力内容は消えます」は誤報である。
      // 1文字に分単位かかる利用者に「急げ・アプリを閉じるな」という誤った行動を
      // 強いることになり、この製品では実害が大きい。
      await _pumpBanner(tester, const PersistenceUnavailable());

      expect(find.textContaining('入力内容'), findsNothing);
    });

    testWidgets('Unavailable では実際に失われる領域の名前を出す', (tester) async {
      await _pumpBanner(tester, const PersistenceUnavailable());

      for (final area in PersistedArea.values) {
        expect(
          find.textContaining(area.label),
          findsOneWidget,
          reason: '${area.label} が失われることを利用者に伝えていない',
        );
      }
    });

    testWidgets('failedAreas が空でも警告が消えない（フェイルセーフ）', (tester) async {
      // なぜ: ADR-005 は「保存されないことは必ず伝える」と定めている。
      // resolvePersistenceState は空集合の RecoverableFailure を作らないが
      // コンストラクタは公開されており、型が空集合を禁じてもいない。
      // failure 状態で無音になる経路は、到達可能性に関わらず塞ぐ。
      // 沈黙は、文言が多少不自然であることより悪い。
      await _pumpBanner(
        tester,
        const PersistenceRecoverableFailure(<PersistedArea>{}),
      );

      expect(find.textContaining('保存できません'), findsOneWidget);
      expect(
        tester.getSize(find.byType(PersistenceBanner)).height,
        greaterThan(0),
      );
    });

    testWidgets('保存できない警告が読み上げで二重にならない', (tester) async {
      // なぜ: Semantics(label:) の子に同じ文言の Text を置くと
      // ラベルが連結されて同一ノードに2回入り、読み上げが二重になる。
      final handle = tester.ensureSemantics();
      await _pumpBanner(tester, const PersistenceUnavailable());

      final node = tester.getSemantics(find.byType(PersistenceBanner));
      expect('保存できません'.allMatches(node.label).length, 1);

      // SemanticsHandle はテスト終了前に破棄する必要がある
      handle.dispose();
    });

    testWidgets('保存できない状態にはスクリーンリーダー向けのラベルが付く', (tester) async {
      await _pumpBanner(tester, const PersistenceUnavailable());

      final semantics = tester.getSemantics(find.byType(PersistenceBanner));
      expect(semantics.label, contains('保存'));
    });
  });

  group('描画された背景が状態ごとの配色になっている', () {
    // なぜ関数の戻り値では足りないか: 配色関数だけを測っても
    // その色が実際にバナーへ塗られているかは分からない。Material の color を
    // 落としても・2状態の配色を入れ替えても、関数を測るテストは緑のまま通る
    // （レビューの mutation 実験で両方とも生き残った）。
    // 検証は最も外側の境界＝描画されたウィジェットで行う。
    Color bannerBackground(WidgetTester tester, String text) {
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.textContaining(text),
              matching: find.byType(Material),
            )
            .first,
      );
      return material.color!;
    }

    testWidgets('Unavailable の背景が Unavailable 用の配色である', (tester) async {
      await _pumpBanner(tester, const PersistenceUnavailable());

      expect(
        bannerBackground(tester, '保存できません'),
        unavailableBannerColors(lightTheme.colorScheme).background,
      );
    });

    testWidgets('RecoverableFailure の背景が Recoverable 用の配色である', (tester) async {
      await _pumpBanner(
        tester,
        const PersistenceRecoverableFailure({PersistedArea.presetPhrases}),
      );

      expect(
        bannerBackground(tester, '保存できません'),
        recoverableBannerColors().background,
      );
    });

    testWidgets('2状態が同じ背景色で描かれることはない', (tester) async {
      await _pumpBanner(tester, const PersistenceUnavailable());
      final unavailable = bannerBackground(tester, '保存できません');

      await _pumpBanner(
        tester,
        const PersistenceRecoverableFailure({PersistedArea.presetPhrases}),
      );
      final recoverable = bannerBackground(tester, '保存できません');

      expect(unavailable, isNot(equals(recoverable)));
    });
  });

  group('コントラスト比（WCAG 2.1 AA / REQ-5006）', () {
    // なぜ測るか: 色の妥当性をコメントで主張すると、テーマを足したときに
    // 主張だけが残る。実際に計算して確かめる。
    // 範囲の正確な記述: Unavailable は colorScheme.error/onError なので
    // テーマごとに値が変わり、3テーマそれぞれを測っている。
    // RecoverableFailure は AppColors の固定色でテーマに依存しないため
    // ループしても同じ1組を測り直しているだけである（当初この節に
    // 「3テーマ × 2状態を測る」と書いていたが、後者については事実と違った）。
    final themes = <String, ThemeData>{
      'light': lightTheme,
      'dark': darkTheme,
      'highContrast': highContrastTheme,
    };

    for (final entry in themes.entries) {
      test('${entry.key}: Unavailable の前景と背景が 4.5:1 以上', () {
        final colors = unavailableBannerColors(entry.value.colorScheme);
        expect(
          _contrastRatio(colors.foreground, colors.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key}: RecoverableFailure の前景と背景が 4.5:1 以上', () {
        final colors = recoverableBannerColors();
        expect(
          _contrastRatio(colors.foreground, colors.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key}: 2状態の背景色は区別できる', () {
        expect(
          unavailableBannerColors(entry.value.colorScheme).background,
          isNot(equals(recoverableBannerColors().background)),
        );
      });
    }
  });
  group('PersistenceRecreated（破損で退避して作り直した）の告知', () {
    testWidgets('空の状態で開始したことと、元のデータを退避したことを領域名つきで伝える', (tester) async {
      await _pumpBanner(
        tester,
        const PersistenceRecreated(
            {PersistedArea.history, PersistedArea.presetPhrases}),
      );
      expect(find.textContaining('空の状態で開始'), findsOneWidget);
      expect(find.textContaining('退避'), findsOneWidget);
      expect(find.textContaining('履歴'), findsOneWidget);
      expect(find.textContaining('定型文'), findsOneWidget);
      expect(find.textContaining('お気に入り'), findsNothing,
          reason: '作り直していない領域の名前は出さない');
    });

    testWidgets('告知は「閉じる」で消え、高さを取らなくなる', (tester) async {
      await _pumpBanner(
        tester,
        const PersistenceRecreated({PersistedArea.favorites}),
      );
      expect(find.text('閉じる'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pump();
      expect(find.textContaining('空の状態で開始'), findsNothing);
      expect(tester.getSize(find.byType(PersistenceBanner)).height, 0);
    });
  });
}
