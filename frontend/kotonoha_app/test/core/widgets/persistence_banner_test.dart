/// 永続化バナーのテスト（ADR-005 / Phase 3 WP-1）
///
/// 【何を守るテストか】: 「保存できたように見えて消える」を防ぐ。
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

    testWidgets('保存できない状態にはスクリーンリーダー向けのラベルが付く', (tester) async {
      await _pumpBanner(tester, const PersistenceUnavailable());

      final semantics = tester.getSemantics(find.byType(PersistenceBanner));
      expect(semantics.label, contains('保存'));
    });
  });

  group('コントラスト比（WCAG 2.1 AA / REQ-5006）', () {
    // 【なぜ測るか】: 色の妥当性をコメントで主張すると、テーマを足したときに
    // 主張だけが残る。3テーマ × 2状態を実際に測る。
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
}
