/// NetworkProvider テスト
///
/// TASK-0057: Riverpod Provider 構造設計
/// TC-057-025 〜 TC-057-033
///
/// 関連要件:
/// - REQ-1001: オフライン時AI変換無効化
/// - REQ-1002: オフライン状態表示
/// - REQ-1003: オフライン時基本機能動作
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';

void main() {
  group('NetworkProvider テスト', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // 正常系テスト
    // =========================================================================

    group('正常系テスト', () {
      test('TC-057-025: オンライン状態を検知できる', () async {
        // Arrange
        final notifier = container.read(networkProvider.notifier);

        // Act - オンライン状態をシミュレート
        await notifier.setOnline();

        // Assert
        final state = container.read(networkProvider);
        expect(state, NetworkState.online);
      });

      test('TC-057-026: オフライン状態を検知できる', () async {
        // Arrange
        final notifier = container.read(networkProvider.notifier);

        // Act - オフライン状態をシミュレート
        await notifier.setOffline();

        // Assert
        final state = container.read(networkProvider);
        expect(state, NetworkState.offline);
      });

      test('TC-057-027: オンラインでAI変換が有効', () async {
        // Arrange
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOnline();

        // Act
        final isAvailable = notifier.isAIConversionAvailable;

        // Assert
        expect(isAvailable, true);
      });

      test('TC-057-028: オフラインでAI変換が無効', () async {
        // Arrange
        final notifier = container.read(networkProvider.notifier);
        await notifier.setOffline();

        // Act
        final isAvailable = notifier.isAIConversionAvailable;

        // Assert
        expect(isAvailable, false);
      });

      test('TC-057-029: ネットワーク状態変更時に通知される', () async {
        // Arrange
        final notifier = container.read(networkProvider.notifier);
        final states = <NetworkState>[];

        // 状態変更をリッスン
        container.listen<NetworkState>(
          networkProvider,
          (previous, next) {
            states.add(next);
          },
          fireImmediately: false,
        );

        // Act
        await notifier.setOnline();
        await notifier.setOffline();
        await notifier.setOnline();

        // Assert
        expect(states.length, 3);
        expect(states[0], NetworkState.online);
        expect(states[1], NetworkState.offline);
        expect(states[2], NetworkState.online);
      });
    });

    // =========================================================================
    // デフォルト値テスト
    // =========================================================================

    group('デフォルト値テスト', () {
      test('TC-057-030: 初期状態はchecking', () {
        // Assert
        final state = container.read(networkProvider);
        expect(state, NetworkState.checking);
      });
    });

    // =========================================================================
    // 異常系テスト
    // =========================================================================

    group('異常系テスト', () {
      test('TC-057-031: 接続チェック失敗時はoffline扱い', () async {
        // Arrange
        final notifier = container.read(networkProvider.notifier);

        // Act - 接続チェック失敗をシミュレート
        await notifier.simulateConnectionCheckFailure();

        // Assert
        final state = container.read(networkProvider);
        expect(state, NetworkState.offline);
      });

      test('TC-057-032: オフラインでも基本機能は動作', () async {
        // Arrange
        final networkNotifier = container.read(networkProvider.notifier);
        await networkNotifier.setOffline();

        // Act & Assert - ネットワーク状態に関係なくProviderが存在することを確認
        final networkState = container.read(networkProvider);
        expect(networkState, NetworkState.offline);

        // 基本機能（inputBuffer等）の動作はTASK-0058で詳細テスト
        // ここではNetworkProviderが正常にoffline状態を保持することを確認
      });

      test('TC-057-033: オフラインでも定型文は動作', () async {
        // Arrange
        final networkNotifier = container.read(networkProvider.notifier);
        await networkNotifier.setOffline();

        // Act & Assert - ネットワーク状態に関係なくProviderが存在することを確認
        final networkState = container.read(networkProvider);
        expect(networkState, NetworkState.offline);

        // 定型文機能の動作はTASK-0058で詳細テスト
        // ここではNetworkProviderが正常にoffline状態を保持することを確認
      });
    });
  });
}
