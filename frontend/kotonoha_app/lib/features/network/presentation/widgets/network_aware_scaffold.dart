/// ネットワーク状態対応Scaffold
/// オフライン状態表示
/// ネットワーク復帰時の通知
/// ユーザー操作を妨げない通知
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_banner.dart';
import 'online_recovery_notification.dart';

/// ネットワーク状態に応じたUIを自動的に表示するScaffold
/// オフライン時はバナーを表示し、オンライン復帰時は通知を表示する。
/// 既存のScaffoldを置き換えるだけで使用可能。
/// オフライン状態表示
/// ネットワーク復帰時の通知
class NetworkAwareScaffold extends ConsumerWidget {
  /// AppBar
  final PreferredSizeWidget? appBar;

  /// Scaffoldのbody
  final Widget body;

  /// FloatingActionButton
  final Widget? floatingActionButton;

  /// FloatingActionButtonの位置
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// BottomNavigationBar
  final Widget? bottomNavigationBar;

  /// Drawer
  final Widget? drawer;

  /// EndDrawer
  final Widget? endDrawer;

  /// 背景色
  final Color? backgroundColor;

  /// オフラインバナーを表示するかどうか
  final bool showOfflineBanner;

  /// オンライン復帰通知を表示するかどうか
  final bool showOnlineRecoveryNotification;

  /// コンストラクタ
  const NetworkAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.showOfflineBanner = true,
    this.showOnlineRecoveryNotification = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget content = body;

    // オフラインバナーを追加
    if (showOfflineBanner) {
      content = Column(
        children: [
          const OfflineBanner(),
          Expanded(child: content),
        ],
      );
    }

    // オンライン復帰通知を追加
    if (showOnlineRecoveryNotification) {
      content = OnlineRecoveryNotification(child: content);
    }

    return Scaffold(
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
    );
  }
}
