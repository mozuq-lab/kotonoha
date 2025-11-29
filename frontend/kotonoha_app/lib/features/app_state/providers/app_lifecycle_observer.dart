/// アプリライフサイクル監視
///
/// TASK-0079: アプリ状態復元・クラッシュリカバリ実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - EDGE-201: バックグラウンド復帰時の状態復元
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_session_provider.dart';

/// アプリライフサイクル監視ウィジェット
///
/// アプリがバックグラウンドに移行/復帰した時に
/// セッション状態の保存/復元を行う。
///
/// 関連要件:
/// - EDGE-201: バックグラウンド復帰時の状態復元
class AppLifecycleObserver extends ConsumerStatefulWidget {
  /// 子ウィジェット
  final Widget child;

  /// コンストラクタ
  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appSessionProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final notifier = ref.read(appSessionProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        // バックグラウンドに移行
        notifier.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // フォアグラウンドに復帰
        notifier.onAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 他の状態は特に処理なし
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
