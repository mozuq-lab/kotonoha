/// オンライン復帰通知ウィジェット
///
/// TASK-0077: オフライン時UI表示・AI変換無効化
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - EDGE-001: ネットワーク復帰時の通知
/// - NFR-203: ユーザー操作を妨げない通知
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/network_state.dart';
import '../../providers/network_provider.dart';

/// オンライン復帰時に表示される通知ウィジェット
///
/// オフライン→オンラインに状態が変化した時、一時的に
/// 「オンラインに戻りました。AI変換が利用可能です」を表示する。
///
/// 関連要件:
/// - EDGE-001: ネットワーク復帰時の通知
class OnlineRecoveryNotification extends ConsumerStatefulWidget {
  /// 子ウィジェット
  final Widget child;

  /// 通知表示時間（デフォルト3秒）
  final Duration displayDuration;

  /// コンストラクタ
  const OnlineRecoveryNotification({
    super.key,
    required this.child,
    this.displayDuration = const Duration(seconds: 3),
  });

  @override
  ConsumerState<OnlineRecoveryNotification> createState() =>
      _OnlineRecoveryNotificationState();
}

class _OnlineRecoveryNotificationState
    extends ConsumerState<OnlineRecoveryNotification> {
  /// 通知表示フラグ
  bool _showNotification = false;

  /// 非表示タイマー
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ネットワーク状態を監視
    ref.listen<NetworkState>(
      networkProvider,
      (previous, next) {
        // オフラインからオンラインに復帰した場合に通知を表示
        if (previous == NetworkState.offline && next == NetworkState.online) {
          _showRecoveryNotification();
        }
      },
    );

    return Column(
      children: [
        // オンライン復帰通知
        if (_showNotification)
          Semantics(
            label: 'オンラインに戻りました。AI変換が利用可能です。',
            child: Container(
              width: double.infinity,
              // 【AA対応】: green[900] on green[100] でコントラスト比 約5.9:1。
              // 旧 green[800] on green[300] は約3.0:1でAA不足だった。
              color: Colors.green[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi,
                    size: 18,
                    color: Colors.green[900],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'オンラインに戻りました。AI変換が利用可能です',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 子ウィジェット
        Expanded(child: widget.child),
      ],
    );
  }

  /// 復帰通知を表示し、一定時間後に非表示にする
  void _showRecoveryNotification() {
    if (!mounted) return;

    // 既存のタイマーをキャンセル
    _hideTimer?.cancel();

    setState(() {
      _showNotification = true;
    });

    // 一定時間後に非表示
    _hideTimer = Timer(widget.displayDuration, () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }
}
