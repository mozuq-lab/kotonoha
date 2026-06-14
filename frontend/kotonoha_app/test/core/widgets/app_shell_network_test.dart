/// AppShell ネットワーク監視起動テスト
///
/// F2: AppShellがマウント時にネットワーク監視
/// （initializeWithConnectivity / startListening）を起動することを検証する。
/// これにより networkProvider の状態が checking から実際の接続状態へ更新され、
/// isAIConversionAvailable がオンライン時に true となる。
///
/// 関連要件:
/// - REQ-1001: オフライン時AI変換無効化
/// - REQ-3004: ネットワーク状態の正確な検知
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/domain/services/connectivity_service.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

import '../../mocks/mock_emergency_audio_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('AppShell ネットワーク監視起動テスト', () {
    late MockConnectivityService mockService;
    late MockEmergencyAudioService mockAudioService;
    late StreamController<List<ConnectivityResult>> connectivityController;
    late ProviderContainer container;

    setUp(() {
      mockService = MockConnectivityService();
      mockAudioService = MockEmergencyAudioService();
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(() => mockService.onConnectivityChanged)
          .thenAnswer((_) => connectivityController.stream);
      when(() => mockService.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(() => mockAudioService.startEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.stopEmergencySound())
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(mockService),
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      connectivityController.close();
    });

    testWidgets('F2: マウント時にネットワーク監視が起動しオンライン状態になる',
        (WidgetTester tester) async {
      // 初期状態は checking
      expect(container.read(networkProvider), NetworkState.checking);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      // post-frame callback 実行とネットワーク初期化の非同期完了を待つ
      await tester.pumpAndSettle();

      // initializeWithConnectivity / startListening が呼ばれた結果、
      // checkConnectivity が実行され状態がオンラインへ更新される
      verify(() => mockService.checkConnectivity()).called(1);
      verify(() => mockService.onConnectivityChanged).called(greaterThan(0));
      expect(
        container.read(networkProvider),
        NetworkState.online,
        reason: 'ネットワーク監視起動後はオンライン状態になる必要がある',
      );
      expect(
        container.read(networkProvider.notifier).isAIConversionAvailable,
        isTrue,
        reason: 'オンライン時はAI変換が利用可能になる必要がある',
      );
    });

    testWidgets('F2: 接続状態変更ストリームの更新が状態へ反映される', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // リスナーが起動済みなので、オフラインイベントを流すと反映される
      connectivityController.add([ConnectivityResult.none]);
      await tester.pumpAndSettle();

      expect(
        container.read(networkProvider),
        NetworkState.offline,
        reason: 'startListening起動後は接続変更が状態へ反映される必要がある',
      );
    });
  });
}
