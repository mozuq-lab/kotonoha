/// Main entry point for kotonoha app
///
/// TASK-0015: go_routerナビゲーション設定・ルーティング実装
/// TASK-0059: Hive初期化失敗時もアプリ起動を継続させる最終フォールバック
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/app.dart';
import 'package:kotonoha_app/core/persistence/favorite_migration.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';

/// アプリケーションのエントリーポイント
///
/// Hive初期化を実行してからFlutterアプリを起動する。
///
/// 実装要件:
/// - FR-007: ProviderScopeでKotonohaAppをラップ
/// - Hive初期化の維持（TASK-0014）
/// - NFR-301: Hive初期化がBox個別の復旧（hive_init.dart）を経ても失敗した場合、
///   最終フォールバックとしてrunAppへ到達させ、文字盤・TTS等の基本機能を維持する
void main() async {
  // Flutter初期化: async main関数でawaitを使用するために必要
  WidgetsFlutterBinding.ensureInitialized();

  // Hive初期化: TypeAdapter登録とボックスオープン
  //
  // 【最終フォールバック】: hive_init.dart側で各Boxのオープンは個別に復旧を試みるが、
  // Hive.initFlutter()自体の失敗など、万一initHive()全体が例外を送出した場合でも
  // アプリがrunAppへ到達できるようにtry/catchで保護する。
  // Hiveが利用不可でもrepository_providersのnullフォールバックにより
  // 文字盤・TTS等の基本機能はインメモリ動作で継続できる（NFR-301）。
  try {
    await initHive();

    // 定型文お気に入りの移行: PresetPhrase.isFavorite → FavoriteItem
    //
    // 【順序の制約】: initHive()（box オープン）より後、runApp() より前。
    // provider がまだ無い時点なので、移行関数は box を直接触る。
    // Stage 3b で PresetPhrase.isFavorite（Hive field 3）を削除すると
    // ディスク上のフラグは読めなくなるため、この移行を含むビルドが
    // Stage 3b より前に配布されている必要がある。
    //
    // 【失敗の扱い】: 移行自体も内部で例外を飲んで正常に返すが、
    // 万一送出されても initHive() と同じ扱いで runApp へ到達させる（NFR-301）。
    await migratePresetPhraseFavorites();
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
