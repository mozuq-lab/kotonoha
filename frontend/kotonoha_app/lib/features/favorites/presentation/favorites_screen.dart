/// Favorites screen widget
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';

/// お気に入り画面ウィジェット
///
/// 定型文のお気に入りを表示・管理する画面。
/// 現在はスケルトン実装で、後続タスクでお気に入り機能を実装予定。
///
/// 実装要件:
/// - FR-003: ルートパス「/favorites」でこの画面を表示
/// - FR-005: StatelessWidget、constコンストラクタ、keyパラメータ
class FavoritesScreen extends StatelessWidget {
  /// お気に入り画面を作成する。
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り'),
      ),
      body: const Center(
        child: Text('お気に入り画面'),
      ),
    );
  }
}
