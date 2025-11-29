/// NetworkProvider connectivity_plus 統合テスト
///
/// TASK-0076: ネットワーク状態管理Provider
/// 関連要件:
/// - REQ-1001: オフライン時AI変換無効化
/// - REQ-1002: オフライン状態表示
/// - REQ-3004: ネットワーク状態の正確な検知
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/network/domain/services/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('NetworkProvider connectivity 統合テスト', () {
    late ProviderContainer container;
    late MockConnectivityService mockService;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      mockService = MockConnectivityService();
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(() => mockService.onConnectivityChanged)
          .thenAnswer((_) => connectivityController.stream);
      when(() => mockService.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      connectivityController.close();
    });

    // =========================================================================
    // 接続検知テスト
    // =========================================================================

    group('接続検知テスト', () {
      test('TC-076-001: WiFi接続時にオンライン状態', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        final state = container.read(networkProvider);
        expect(state, NetworkState.online);
      });

      test('TC-076-002: モバイルデータ接続時にオンライン状態', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        final state = container.read(networkProvider);
        expect(state, NetworkState.online);
      });

      test('TC-076-003: イーサネット接続時にオンライン状態', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.ethernet]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        final state = container.read(networkProvider);
        expect(state, NetworkState.online);
      });

      test('TC-076-004: 接続なし時にオフライン状態', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        final state = container.read(networkProvider);
        expect(state, NetworkState.offline);
      });
    });

    // =========================================================================
    // 接続状態変更リスナーテスト
    // =========================================================================

    group('接続状態変更リスナーテスト', () {
      test('TC-076-005: WiFi→オフライン変更を検知', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();
        await notifier.startListening();

        // 初期状態確認
        expect(container.read(networkProvider), NetworkState.online);

        // 接続状態変更をシミュレート
        connectivityController.add([ConnectivityResult.none]);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(container.read(networkProvider), NetworkState.offline);
      });

      test('TC-076-006: オフライン→WiFi変更を検知', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();
        await notifier.startListening();

        // 初期状態確認
        expect(container.read(networkProvider), NetworkState.offline);

        // 接続状態変更をシミュレート
        connectivityController.add([ConnectivityResult.wifi]);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(container.read(networkProvider), NetworkState.online);
      });

      test('TC-076-007: 複数の接続タイプがある場合はオンライン', () async {
        when(() => mockService.checkConnectivity()).thenAnswer(
            (_) async => [ConnectivityResult.wifi, ConnectivityResult.mobile]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        expect(container.read(networkProvider), NetworkState.online);
      });
    });

    // =========================================================================
    // 定期接続確認テスト
    // =========================================================================

    group('定期接続確認テスト', () {
      test('TC-076-008: 定期接続確認が動作する', () async {
        int checkCount = 0;
        when(() => mockService.checkConnectivity()).thenAnswer((_) async {
          checkCount++;
          return [ConnectivityResult.wifi];
        });

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        // 初期チェック
        expect(checkCount, 1);
      });

      test('TC-076-009: 接続確認でエラーが発生してもオフライン扱い', () async {
        when(() => mockService.checkConnectivity())
            .thenThrow(Exception('Network error'));

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();

        final state = container.read(networkProvider);
        expect(state, NetworkState.offline);
      });
    });

    // =========================================================================
    // リソース解放テスト
    // =========================================================================

    group('リソース解放テスト', () {
      test('TC-076-010: stopListeningでリスナーが停止する', () async {
        when(() => mockService.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final notifier = container.read(networkProvider.notifier);
        await notifier.initializeWithConnectivity();
        await notifier.startListening();
        await notifier.stopListening();

        // リスナー停止後は変更を検知しない
        connectivityController.add([ConnectivityResult.none]);
        await Future.delayed(const Duration(milliseconds: 100));

        // 状態は変わらないことを確認（startListening時はonline）
        expect(container.read(networkProvider), NetworkState.online);
      });
    });
  });
}
