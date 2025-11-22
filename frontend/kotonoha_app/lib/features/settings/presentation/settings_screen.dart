/// Settings screen widget
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';

/// 設定画面ウィジェット
///
/// アプリケーションの設定を管理する画面。
/// 現在はスケルトン実装で、後続タスクで設定機能を実装予定。
///
/// 実装要件:
/// - FR-003: ルートパス「/settings」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
class SettingsScreen extends StatelessWidget {
  /// 設定画面を作成する。
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: const Center(
        child: Text('設定画面'),
      ),
    );
  }
}
