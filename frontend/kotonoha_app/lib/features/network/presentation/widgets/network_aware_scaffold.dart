/// ネットワーク状態対応Scaffold
///
/// TASK-0077: オフライン時UI表示・AI変換無効化
///
/// 信頼性レベル: 青信号（要件定義書ベース）
/// 関連要件:
/// - REQ-1002: オフライン状態表示
/// - EDGE-001: ネットワーク復帰時の通知
/// - NFR-203: ユーザー操作を妨げない通知
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/themes/theme_colors.dart';

import 'offline_banner.dart';
import 'online_recovery_notification.dart';

/// ネットワーク状態に応じたUIを自動的に表示するScaffold
///
/// オフライン時はバナーを表示し、オンライン復帰時は通知を表示する。
/// 既存のScaffoldを置き換えるだけで使用可能。
///
/// 関連要件:
/// - REQ-1002: オフライン状態表示
/// - EDGE-001: ネットワーク復帰時の通知
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

/// AI変換ボタンがオフライン時に押された場合のダイアログを表示
///
/// REQ-1003: オフライン時のフォールバック動作
/// 信頼性レベル: 青信号
///
/// AA対応: アイコン色を Colors.grey[700](#616161) に固定していたため、
/// 背景を自前で持たずテーマの surface に載るこのダイアログでは
/// ダークテーマ (#1E1E1E) に対し 2.69:1 と非テキスト基準(3:1)未達だった。
/// 他の警告アイコンと同じ warningIconColor() を再利用する
/// （ライト 5.44:1 / ダーク 9.63:1 / 高コントラスト 5.93:1）。
Future<void> showOfflineAIConversionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.wifi_off, color: warningIconColor(context)),
          const SizedBox(width: 8),
          const Text('オフライン'),
        ],
      ),
      content: const Text(
        'AI変換機能はインターネット接続が必要です。\n'
        '接続を確認してから再度お試しください。\n\n'
        '定型文や履歴からの読み上げは引き続きご利用いただけます。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
