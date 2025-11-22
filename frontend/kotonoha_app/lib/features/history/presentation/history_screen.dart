/// History screen widget
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';

/// 履歴画面ウィジェット
///
/// 過去の入力履歴を表示・管理する画面。
/// 現在はスケルトン実装で、後続タスクで履歴機能を実装予定。
///
/// 実装要件:
/// - FR-003: ルートパス「/history」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
class HistoryScreen extends StatelessWidget {
  /// 履歴画面を作成する。
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
      ),
      body: const Center(
        child: Text('履歴画面'),
      ),
    );
  }
}
