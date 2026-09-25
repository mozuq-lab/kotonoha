/// アプリ全画面共通シェル。
/// ネットワーク監視、保存・読み上げ・接続状態の通知、初回チュートリアルを
/// 現在のルート画面に配線する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/help/presentation/widgets/tutorial_overlay.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/online_recovery_notification.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_failure_banner.dart';

/// 全画面共通シェルウィジェット。
/// ShellRouteのbuilderから生成される。
class AppShell extends ConsumerStatefulWidget {
  /// 現在表示中のルート画面。
  final Widget child;

  /// AppShellを作成する。
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _networkInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNetworkMonitoring();
      _initializeTutorial();
    });
  }

  Future<void> _initializeNetworkMonitoring() async {
    if (_networkInitialized) return;
    _networkInitialized = true;

    try {
      final notifier = ref.read(networkProvider.notifier);
      await notifier.initializeWithConnectivity();
      await notifier.startListening();
    } catch (_) {
      // テスト環境などでプラグインが使えない場合は checking のままにする。
    }
  }

  Future<void> _initializeTutorial() async {
    try {
      await ref.read(tutorialProvider.notifier).initialize();
    } catch (_) {
      // SharedPreferencesが使えない場合もアプリ本体の表示を継続する。
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorialState = ref.watch(tutorialProvider);
    final screenContent = OnlineRecoveryNotification(
      child: Column(
        children: [
          const PersistenceBanner(),
          const TtsFailureBanner(),
          const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
    );

    return tutorialState.shouldShowTutorial
        ? TutorialOverlay(
            onComplete: () {
              ref.read(tutorialProvider.notifier).completeTutorial();
            },
            child: screenContent,
          )
        : screenContent;
  }
}
