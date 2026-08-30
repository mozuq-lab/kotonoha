/// AppShell 上のバナー文字にデバッグ用装飾が残っていないかの検証
///
/// 【背景】: AppShell のバナーは各画面の Scaffold より外側にあり、
/// Material 祖先を持たない。この位置の Text は WidgetsApp の既定スタイル
/// （赤文字＋黄色の二重下線）を継承するため、`style` を部分指定しただけでは
/// `decoration` が残り、利用者に下線付きの文字が見える。
/// Phase 3 WP-1 で実機（Chrome）の目視から発見した。
///
/// 【なぜ AppShell 経由で描くか】: バナー単体を `Scaffold` の中に置いて
/// 描くと Material 祖先ができてしまい、この不具合は再現しない。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

/// オフライン状態に固定する
class _OfflineNetworkNotifier extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.offline;
}

/// テストから状態を切り替えられるネットワーク通知
class _ControllableNetworkNotifier extends NetworkNotifier {
  @override
  NetworkState build() => NetworkState.offline;

  /// 状態を差し替える
  void setState(NetworkState next) => state = next;
}

/// [finder] が指すテキストに実際に適用される装飾を返す
TextDecoration _effectiveDecoration(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  final style =
      DefaultTextStyle.of(tester.element(finder)).style.merge(text.style);
  return style.decoration ?? TextDecoration.none;
}

void main() {
  testWidgets('オフラインバナーの文字に下線が付かない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceStateProvider.overrideWithValue(const PersistenceReady()),
          networkProvider.overrideWith(_OfflineNetworkNotifier.new),
        ],
        child: const MaterialApp(
          home: AppShell(child: Scaffold(body: Text('画面本体'))),
        ),
      ),
    );
    await tester.pump();

    expect(
      _effectiveDecoration(tester, find.textContaining('オフライン')),
      TextDecoration.none,
    );
  });

  testWidgets('オンライン復帰通知の文字に下線が付かない', (tester) async {
    // 【なぜ3本目も見るか】: AppShell の Column に載るバナーは
    // PersistenceBanner / OfflineBanner / OnlineRecoveryNotification の3本。
    // どれも Scaffold の外側にあり、同じ条件で下線を継承する。
    final container = ProviderContainer(
      overrides: [
        persistenceStateProvider.overrideWithValue(const PersistenceReady()),
        networkProvider.overrideWith(_ControllableNetworkNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(child: Scaffold(body: Text('画面本体'))),
        ),
      ),
    );
    await tester.pump();

    (container.read(networkProvider.notifier) as _ControllableNetworkNotifier)
        .setState(NetworkState.online);
    await tester.pump();

    expect(
      _effectiveDecoration(tester, find.textContaining('オンラインに戻りました')),
      TextDecoration.none,
    );

    // 表示タイマーを流し切ってから終わる
    await tester.pump(const Duration(seconds: 10));
  });
}
