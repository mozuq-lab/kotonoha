/// 永続化の失敗が利用者に届くかの検証（ADR-005 / Phase 3 WP-1）
///
/// なぜ AppShell ごと描画するか: PersistenceBanner 単体を叩くテストは、
/// AppShell への配線が外れても緑のままになる。「保存できたように見えて消える」
/// を防げているかは、実際に画面へ出るかどうかでしか確かめられない。
/// 検証は最も外側の境界で行う（docs/verification-principles.md）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/core/widgets/persistence_banner.dart';

Future<void> _pumpShell(WidgetTester tester, PersistenceState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [persistenceStateProvider.overrideWithValue(state)],
      child: const MaterialApp(
        home: AppShell(child: Scaffold(body: Text('画面本体'))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('永続化の失敗が画面に出る（AppShell 経由）', () {
    testWidgets('保存できないとき、警告が画面に出る', (tester) async {
      await _pumpShell(tester, const PersistenceUnavailable());

      expect(find.textContaining('保存できません'), findsOneWidget);
    });

    testWidgets('一部だけ保存できないとき、対象の領域が画面に出る', (tester) async {
      await _pumpShell(
        tester,
        const PersistenceRecoverableFailure({PersistedArea.history}),
      );

      expect(find.textContaining('履歴'), findsOneWidget);
    });

    testWidgets('保存できているときは警告が出ず、画面本体を圧迫しない', (tester) async {
      await _pumpShell(tester, const PersistenceReady());

      expect(find.textContaining('保存できません'), findsNothing);
      expect(tester.getSize(find.byType(PersistenceBanner)).height, 0);
    });

    testWidgets('保存できない状態でも画面本体は表示され、操作を止めない（NFR-301）', (tester) async {
      await _pumpShell(tester, const PersistenceUnavailable());

      expect(find.text('画面本体'), findsOneWidget);
    });

    testWidgets('バナーの文字にデバッグ用の下線が付かない', (tester) async {
      // なぜ必要か: AppShell のバナーは各画面の Scaffold より外側にあり、
      // Material 祖先を持たない。この位置の Text は WidgetsApp の既定
      // スタイル（赤文字＋黄色の二重下線）を継承するため、style を
      // 部分指定するだけでは decoration が残る。実機（Chrome）で
      // 下線が出ているのを目視して分かった。
      await _pumpShell(tester, const PersistenceUnavailable());

      final text = tester.widget<Text>(find.textContaining('保存できません'));
      final effective = DefaultTextStyle.of(
        tester.element(find.textContaining('保存できません')),
      ).style.merge(text.style);

      expect(effective.decoration ?? TextDecoration.none, TextDecoration.none);
    });
  });
}
