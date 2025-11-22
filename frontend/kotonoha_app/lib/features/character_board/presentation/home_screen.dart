/// Home screen widget (Character Board)
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';

/// ホーム画面（文字盤画面）ウィジェット
///
/// アプリケーションのメイン画面。文字盤入力機能を提供する。
/// 現在はスケルトン実装で、後続タスクで文字盤機能を実装予定。
///
/// 実装要件:
/// - FR-002: 初期ルート「/」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
class HomeScreen extends StatelessWidget {
  /// ホーム画面を作成する。
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('kotonoha'),
      ),
      body: const Center(
        child: Text('ホーム画面'),
      ),
    );
  }
}
