/// ネットワーク状態管理プロバイダー
///
/// TASK-0057: Riverpod Provider 構造設計
/// TASK-0076: ネットワーク状態管理Provider（connectivity_plus統合）
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件:
/// - REQ-1001: オフライン時AI変換無効化
/// - REQ-1002: オフライン状態表示
/// - REQ-1003: オフライン時基本機能動作
/// - REQ-3004: ネットワーク状態の正確な検知
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/network_state.dart';
import '../domain/services/connectivity_service.dart';

/// ネットワーク状態管理Notifier
///
/// connectivity_plusを使用してネットワーク接続状態を監視し、
/// AI変換機能の利用可否を判定する。
class NetworkNotifier extends Notifier<NetworkState> {
  /// 接続状態変更リスナーのサブスクリプション
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 初期状態
  @override
  NetworkState build() => NetworkState.checking;

  /// ConnectivityServiceを取得
  ConnectivityService? get _connectivityService =>
      ref.read(connectivityServiceProvider);

  /// connectivity_plusを使用して初期化する
  ///
  /// 現在の接続状態を確認し、状態を更新する。
  Future<void> initializeWithConnectivity() async {
    final service = _connectivityService;
    if (service == null) {
      // ConnectivityServiceがない場合は状態変更なし
      return;
    }

    try {
      final results = await service.checkConnectivity();
      _updateStateFromResults(results);
    } catch (e) {
      // エラー時はオフライン扱い
      state = NetworkState.offline;
    }
  }

  /// 接続状態変更のリスナーを開始する
  ///
  /// ネットワーク接続状態が変更されるたびに状態を更新する。
  Future<void> startListening() async {
    final service = _connectivityService;
    if (service == null) {
      return;
    }

    _subscription = service.onConnectivityChanged.listen(
      _updateStateFromResults,
      onError: (_) {
        state = NetworkState.offline;
      },
    );
  }

  /// 接続状態変更のリスナーを停止する
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// ConnectivityResultリストから状態を更新する
  void _updateStateFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none)) {
      state = NetworkState.offline;
    } else {
      state = NetworkState.online;
    }
  }

  /// オンライン状態を設定（手動設定用）
  ///
  /// テストやシミュレーション用。
  Future<void> setOnline() async {
    state = NetworkState.online;
  }

  /// オフライン状態を設定（手動設定用）
  ///
  /// テストやシミュレーション用。
  Future<void> setOffline() async {
    state = NetworkState.offline;
  }

  /// 接続チェック中状態を設定
  Future<void> setChecking() async {
    state = NetworkState.checking;
  }

  /// 接続チェック失敗をシミュレート（テスト用）
  Future<void> simulateConnectionCheckFailure() async {
    state = NetworkState.offline;
  }

  /// ネットワーク接続状態をチェックする
  ///
  /// connectivity_plusを使用して現在の接続状態を確認する。
  Future<void> checkConnectivity() async {
    if (_connectivityService != null) {
      await initializeWithConnectivity();
    }
  }

  /// AI変換機能が利用可能かどうか
  ///
  /// オンライン時のみtrue、オフライン・チェック中はfalse。
  bool get isAIConversionAvailable {
    return state == NetworkState.online;
  }

  /// リソースをクリーンアップ
  void cleanup() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// NetworkNotifierのProvider
///
/// ConnectivityServiceを注入してテスト可能にする。
final networkProvider = NotifierProvider<NetworkNotifier, NetworkState>(
  NetworkNotifier.new,
);
