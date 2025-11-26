// 【Provider定義】: ネットワーク状態管理プロバイダー
// 【実装内容】: ネットワーク接続状態の監視、AI変換可否判定を提供
// 【設計根拠】: REQ-1001, REQ-1002, REQ-1003（オフライン対応）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/network_state.dart';

/// 【Notifier定義】: ネットワーク状態管理Notifier
/// 【実装内容】: ネットワーク接続状態の管理、AI変換可否の判定を提供
/// 🔵 信頼性レベル: 青信号 - REQ-1001〜1003に基づく
class NetworkNotifier extends StateNotifier<NetworkState> {
  NetworkNotifier() : super(NetworkState.checking);

  /// 【メソッド定義】: オンライン状態を設定
  /// 【実装内容】: ネットワーク接続が確認された時に呼び出す
  /// 🔵 信頼性レベル: 青信号 - REQ-1001
  Future<void> setOnline() async {
    state = NetworkState.online;
  }

  /// 【メソッド定義】: オフライン状態を設定
  /// 【実装内容】: ネットワーク切断が検知された時に呼び出す
  /// 🔵 信頼性レベル: 青信号 - REQ-1001
  Future<void> setOffline() async {
    state = NetworkState.offline;
  }

  /// 【メソッド定義】: 接続チェック中状態を設定
  /// 【実装内容】: ネットワーク接続を確認中に呼び出す
  /// 🟡 信頼性レベル: 黄信号 - 妥当な推測
  Future<void> setChecking() async {
    state = NetworkState.checking;
  }

  /// 【メソッド定義】: 接続チェック失敗をシミュレート
  /// 【実装内容】: 接続チェックが失敗した場合、オフライン状態に遷移
  /// 🟡 信頼性レベル: 黄信号 - テスト用
  Future<void> simulateConnectionCheckFailure() async {
    state = NetworkState.offline;
  }

  /// 【ゲッター定義】: AI変換機能が利用可能かどうか
  /// 【実装内容】: オンライン時のみtrue、オフライン・チェック中はfalse
  /// 🔵 信頼性レベル: 青信号 - REQ-1001（オフライン時AI変換無効化）
  bool get isAIConversionAvailable {
    return state == NetworkState.online;
  }

  /// 【メソッド定義】: ネットワーク接続状態をチェックする
  /// 【実装内容】: 実際のネットワーク接続を確認し、状態を更新
  /// 🟡 信頼性レベル: 黄信号 - 将来的にconnectivity_plusを使用
  Future<void> checkConnectivity() async {
    // 将来的にはconnectivity_plusパッケージを使用して実装
    // 現在はメモリ内での管理のみ
    // TASK-0058で詳細実装
  }
}

/// 【Provider定義】: NetworkNotifierのProvider
/// 🔵 信頼性レベル: 青信号 - Riverpodパターンに基づく
final networkProvider =
    StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  return NetworkNotifier();
});
