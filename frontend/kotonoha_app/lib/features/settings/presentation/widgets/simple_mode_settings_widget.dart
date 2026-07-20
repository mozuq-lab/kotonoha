/// シンプルモード設定ウィジェット
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
///
/// 信頼性レベル: 🟡 黄信号（要件定義書にない新規機能のため妥当な推測）
///
/// シンプルモードのON/OFFを切り替えるスイッチ。
/// ONにすると、ホーム画面が文字盤なしの大ボタン画面に切り替わる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';

/// シンプルモード設定ウィジェット
///
/// 疲労時・症状進行時など、文字盤操作が難しい場面向けに、
/// クイック応答・状態ボタン・お気に入りのみの大ボタン画面へ
/// 切り替えるための設定スイッチ。
class SimpleModeSettingsWidget extends ConsumerWidget {
  /// コンストラクタ
  const SimpleModeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
      data: (settings) {
        return Semantics(
          toggled: settings.simpleMode,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('シンプルモード'),
            subtitle: const Text(
              '文字盤を使わず、クイック応答・状態ボタン・お気に入りだけの'
              '大ボタン画面に切り替えます。疲れているときにおすすめです。',
            ),
            value: settings.simpleMode,
            // 【AA対応】: SwitchListTileのタップ領域は行全体のため
            // 44px以上のタップターゲットは自動的に確保される。
            onChanged: (enabled) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setSimpleMode(enabled);
            },
          ),
        );
      },
    );
  }
}
