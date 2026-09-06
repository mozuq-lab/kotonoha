/// オフラインバナーウィジェット
///
/// TASK-0077: オフライン時UI表示・AI変換無効化
///
/// 信頼性レベル: 青信号（要件定義書ベース）
/// 関連要件:
/// - REQ-1002: オフライン状態表示
/// - NFR-203: ユーザー操作を妨げない通知
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/network_state.dart';
import '../../providers/network_provider.dart';

/// オフライン時に画面上部に表示されるバナー
///
/// オフライン状態の時のみ表示され、基本機能のみ利用可能である
/// ことをユーザーに通知する。
///
/// 関連要件:
/// - REQ-1002: オフライン状態表示
/// - REQ-1003: オフライン時も基本機能は動作
class OfflineBanner extends ConsumerWidget {
  /// コンストラクタ
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);

    // オンラインまたはチェック中は表示しない
    if (networkState != NetworkState.offline) {
      return const SizedBox.shrink();
    }

    // Material で包む理由: このバナーは AppShell に置かれ、各画面の
    // Scaffold より外側にある。Material 祖先が無い位置の Text は
    // WidgetsApp の既定スタイル（赤文字＋黄色の二重下線）を継承するため、
    // style を部分指定しただけでは下線が残る。
    // Phase 3 WP-1 で実機（Chrome）の目視から発見した既存不具合。
    return Semantics(
      label: 'オフライン状態です。基本機能のみ利用可能です。',
      // excludeSemantics: 付けないと label と子 Text のラベルが
      // 同一ノードに連結され、読み上げが重複する。
      excludeSemantics: true,
      child: Material(
        color: Colors.grey[300],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 18,
                // AA対応: grey[900] on grey[300] でコントラスト比 約12:1。
                // 旧 grey[700] on grey[300] は約4.0:1でAA不足だった。
                color: Colors.grey[900],
              ),
              const SizedBox(width: 8),
              Text(
                'オフライン - 基本機能のみ利用可能',
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
