/// Main entry point for kotonoha app
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';

/// アプリケーションのエントリーポイント
///
/// Hive初期化を実行してからFlutterアプリを起動する。
///
/// 実装要件:
/// - FR-007: ProviderScopeでKotonohaAppをラップ
/// - Hive初期化の維持（TASK-0014）
void main() async {
  // Flutter初期化: async main関数でawaitを使用するために必要
  WidgetsFlutterBinding.ensureInitialized();

  // Hive初期化: TypeAdapter登録とボックスオープン
  await initHive();

  // アプリ起動: ProviderScopeでKotonohaAppをラップして起動
  runApp(
    const ProviderScope(
      child: KotonohaApp(),
    ),
  );
}
