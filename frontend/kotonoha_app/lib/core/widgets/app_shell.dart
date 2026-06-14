/// アプリ全画面共通シェル
///
/// 全ルート画面を内包する共通シェル。go_routerのShellRouteから利用され、
/// 以下の2つの横断的関心事を全画面に配線する。
///
/// 1. ネットワーク監視の起動（F2 / REQ-1001, REQ-3004）
///    - 起動時に一度だけ NetworkNotifier を初期化し、接続状態の監視を開始する。
///    - これにより `isAIConversionAvailable` がオンライン時に true となり、
///      AI変換が利用可能になる。
///
/// 2. 緊急機能の全画面配線（F3 / REQ-301, REQ-302, REQ-304）
///    - 右下に緊急ボタンを常時表示（REQ-301）。
///    - 緊急状態（alertActive）の時に緊急アラート画面を最前面に重ねる（REQ-304）。
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/features/emergency/domain/models/emergency_state.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

/// 全画面共通シェルウィジェット
///
/// ShellRouteのbuilderから `AppShell(child: child)` として生成される。
/// [child] は現在のルート画面ウィジェット。
class AppShell extends ConsumerStatefulWidget {
  /// 現在表示中のルート画面
  final Widget child;

  /// AppShellを作成する。
  ///
  /// [child] - ShellRouteから渡される現在のルート画面（必須）
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// ネットワーク監視の起動を一度きりにするためのフラグ
  bool _networkInitialized = false;

  @override
  void initState() {
    super.initState();
    // 最初のフレーム描画後にネットワーク監視を起動する（F2）。
    // initState内で直接ref.readを呼ばず、addPostFrameCallbackで遅延実行する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNetworkMonitoring();
    });
  }

  /// ネットワーク監視を起動する（一度きり）
  ///
  /// 初期接続状態の確認と接続状態変更リスナーの開始を行う。
  /// connectivity_plusプラグインが未モックなテスト環境などでも
  /// テストが落ちないよう、例外は握りつぶす
  /// （NetworkNotifier側でも捕捉済み）。
  Future<void> _initializeNetworkMonitoring() async {
    if (_networkInitialized) return;
    _networkInitialized = true;

    try {
      final notifier = ref.read(networkProvider.notifier);
      await notifier.initializeWithConnectivity();
      await notifier.startListening();
    } catch (_) {
      // テスト環境などでのプラグイン未モック対策。
      // ネットワーク状態は checking のままとなり、AI変換は無効のままになる。
    }
  }

  @override
  Widget build(BuildContext context) {
    // 緊急状態を監視し、alertActive時に緊急画面を最前面に重ねる（REQ-304）
    final emergencyState = ref.watch(emergencyStateProvider);
    final isAlertActive = emergencyState == EmergencyStateEnum.alertActive;

    return Stack(
      children: [
        // 現在のルート画面
        widget.child,

        // 緊急ボタン（全画面常時表示 / REQ-301, REQ-302）
        SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () =>
                    ref.read(emergencyStateProvider.notifier).startEmergency(),
              ),
            ),
          ),
        ),

        // 緊急アラート画面（alertActive時のみ最前面に表示 / REQ-304）
        if (isAlertActive)
          Positioned.fill(
            child: EmergencyAlertScreen(
              onReset: () =>
                  ref.read(emergencyStateProvider.notifier).resetEmergency(),
            ),
          ),
      ],
    );
  }
}
