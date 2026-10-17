/// アプリ全画面共通シェル。
/// ネットワーク監視、保存・読み上げ・接続状態の通知、初回チュートリアルを
/// 現在のルート画面に配線する。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/widgets/persistence_banner.dart';
import 'package:kotonoha_app/features/help/presentation/widgets/tutorial_overlay.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/online_recovery_notification.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_failure_banner.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_banner.dart';

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
    final screenContent = _StatusBarArea(
      child: OnlineRecoveryNotification(
        child: Column(
          children: [
            // 音量 0 の警告は一番上に置く。ステータスバーの分の余白は
            // _StatusBarArea が引き受けるので、帯の側では持たない
            const VolumeWarningBanner(),
            const PersistenceBanner(),
            const TtsFailureBanner(),
            const OfflineBanner(),
            Expanded(child: widget.child),
          ],
        ),
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

/// ステータスバーの分の余白を、シェルが引き受ける
///
/// 帯（音量 0・保存できない・読み上げ失敗・オフライン・オンライン復帰）は各画面の
/// Scaffold より外に置くので、そのままでは画面の一番上、OS のステータスバーの
/// 裏に描かれ、文頭が時計・日付と重なって読めなかった（iPad で確かめた）。
/// シェルの一番上にステータスバーの高さの帯を画面の背景色で敷き、その下に
/// 帯と画面を置く。画面からは上の余白を外すので、AppBar の位置は今までと同じ
/// （全テーマで AppBar の背景色は画面の背景色と同じ。`app_visual_theme.dart`）。
/// ステータスバーの文字色は、今まで AppBar が決めていたのと同じく背景の明るさで決める。
class _StatusBarArea extends StatelessWidget {
  const _StatusBarArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final dark =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark;
    return Column(
      children: [
        AnnotatedRegion<SystemUiOverlayStyle>(
          // ステータスバーの項目だけを決める。SystemUiOverlayStyle.light / .dark を
          // そのまま使うと、Android のナビゲーションバーまで黒にする（AppBar も
          // ナビゲーションバーの項目には触れない）
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          ),
          child: ColoredBox(
            color: background,
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.paddingOf(context).top,
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
