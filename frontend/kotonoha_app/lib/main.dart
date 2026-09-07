/// Main entry point for kotonoha app
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';

/// アプリケーションのエントリーポイント
/// Hive初期化を実行してからFlutterアプリを起動する。
/// 実装要件
/// ProviderScopeでKotonohaAppをラップ
/// Hive初期化の維持
/// Hive初期化がBox個別の復旧（hive_init.dart）を経ても失敗した場合
/// 最終フォールバックとしてrunAppへ到達させ、文字盤・TTS等の基本機能を維持する
void main() async {
  // Flutter初期化: async main関数でawaitを使用するために必要
  WidgetsFlutterBinding.ensureInitialized();

  // Hive初期化: TypeAdapter登録とボックスオープン
  // 最終フォールバック: hive_init.dart側で各Boxのオープンは個別に復旧を試みるが
  // Hive.initFlutter自体の失敗など、万一initHive全体が例外を送出した場合でも
  // アプリがrunAppへ到達できるようにtry/catchで保護する。
  // Hiveが利用不可でもrepository_providersのnullフォールバックにより
  // 文字盤・TTS等の基本機能はインメモリ動作で継続できる。
  try {
    await initHive();
  } catch (error, stackTrace) {
    debugPrint('[main] Hive初期化に失敗しました。インメモリ動作で起動を継続します: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // アプリ起動: ProviderScopeでKotonohaAppをラップして起動
  runApp(
    const ProviderScope(
      child: KotonohaApp(),
    ),
  );
}
