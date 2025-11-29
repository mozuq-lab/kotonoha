/// Connectivity Service
///
/// TASK-0076: ネットワーク状態管理Provider
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - REQ-1001: オフライン時AI変換無効化
/// - REQ-1002: オフライン状態表示
/// - REQ-3004: ネットワーク状態の正確な検知
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ネットワーク接続状態を監視するサービス
///
/// connectivity_plusパッケージをラップし、テスト可能なインターフェースを提供する。
class ConnectivityService {
  /// Connectivityインスタンス
  final Connectivity _connectivity;

  /// コンストラクタ
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// 現在の接続状態を確認する
  ///
  /// Returns: ConnectivityResult のリスト
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  /// 接続状態変更ストリームを取得する
  ///
  /// ネットワーク接続状態が変更されるたびにイベントを発行する。
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

/// ConnectivityService プロバイダー
///
/// テスト時にモックに置き換え可能。
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
