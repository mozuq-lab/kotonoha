/// AppShell 緊急時音量警告配線テスト（EDGE-203）
///
/// 緊急状態（alertActive）に遷移した際、VolumeServiceでOS音量をチェックし、
/// 音量が0（マナーモード等で音が鳴らない可能性がある）場合に
/// EmergencyAlertScreen へ warningMessage が渡されることを検証する。
///
/// 関連要件:
/// - EDGE-203: マナーモード・音量0時に緊急音が聞こえない場合の視覚的警告
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';

import '../../mocks/mock_emergency_audio_service.dart';
import '../../mocks/mock_volume_controller.dart';

void main() {
  group('AppShell 緊急時音量警告配線テスト（EDGE-203）', () {
    late MockEmergencyAudioService mockAudioService;
    late MockVolumeController mockVolumeController;
    late ProviderContainer container;

    setUp(() {
      mockAudioService = MockEmergencyAudioService();
      mockVolumeController = MockVolumeController();

      when(() => mockAudioService.startEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.stopEmergencySound())
          .thenAnswer((_) async {});
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestApp() {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(
            child: Scaffold(body: Text('test child')),
          ),
        ),
      );
    }

    testWidgets('EDGE-203: OS音量が0の場合、EmergencyAlertScreenにwarningMessageが渡される',
        (WidgetTester tester) async {
      // Arrange: 音量0（ミュート相当）を返すVolumeServiceを注入
      when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.0);
      when(() => mockVolumeController.getMute()).thenAnswer((_) async => true);

      container = ProviderContainer(
        overrides: [
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
          volumeServiceProvider.overrideWithValue(
            VolumeService(volumeController: mockVolumeController),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 初期状態では緊急アラート画面は表示されない
      expect(find.byType(EmergencyAlertScreen), findsNothing);

      // Act: 緊急状態を開始する
      await container.read(emergencyStateProvider.notifier).startEmergency();
      await tester.pumpAndSettle();

      // Assert: 緊急アラート画面が表示され、警告メッセージも表示される
      final alertScreen = tester
          .widget<EmergencyAlertScreen>(find.byType(EmergencyAlertScreen));
      expect(
        alertScreen.warningMessage,
        isNotNull,
        reason: '音量0の場合、warningMessageが設定される必要がある',
      );
      expect(
        find.text(alertScreen.warningMessage!),
        findsOneWidget,
        reason: '警告メッセージがEmergencyAlertScreen上に表示される必要がある',
      );
    });

    testWidgets(
        'EDGE-203: OS音量が正常な場合、EmergencyAlertScreenにwarningMessageが渡されない',
        (WidgetTester tester) async {
      // Arrange: 通常音量（0.5）を返すVolumeServiceを注入
      when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.5);
      when(() => mockVolumeController.getMute()).thenAnswer((_) async => false);

      container = ProviderContainer(
        overrides: [
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
          volumeServiceProvider.overrideWithValue(
            VolumeService(volumeController: mockVolumeController),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Act: 緊急状態を開始する
      await container.read(emergencyStateProvider.notifier).startEmergency();
      await tester.pumpAndSettle();

      // Assert: 緊急アラート画面は表示されるが、警告メッセージはなし
      final alertScreen = tester
          .widget<EmergencyAlertScreen>(find.byType(EmergencyAlertScreen));
      expect(
        alertScreen.warningMessage,
        isNull,
        reason: '音量が正常な場合、warningMessageはnullのままである必要がある',
      );
    });

    testWidgets('EDGE-203: リセット後に再度緊急を発生させると警告状態が再評価される',
        (WidgetTester tester) async {
      // Arrange: 最初は音量0、リセット後は音量正常に切り替わるシナリオ
      var currentVolume = 0.0;
      when(() => mockVolumeController.getVolume())
          .thenAnswer((_) async => currentVolume);
      when(() => mockVolumeController.getMute())
          .thenAnswer((_) async => currentVolume == 0.0);

      container = ProviderContainer(
        overrides: [
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
          volumeServiceProvider.overrideWithValue(
            VolumeService(volumeController: mockVolumeController),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 1回目: 音量0のため警告あり
      await container.read(emergencyStateProvider.notifier).startEmergency();
      await tester.pumpAndSettle();

      var alertScreen = tester
          .widget<EmergencyAlertScreen>(find.byType(EmergencyAlertScreen));
      expect(alertScreen.warningMessage, isNotNull);

      // リセット
      await container.read(emergencyStateProvider.notifier).resetEmergency();
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyAlertScreen), findsNothing);

      // 音量を正常値に変更してから再度緊急発生
      currentVolume = 1.0;
      await container.read(emergencyStateProvider.notifier).startEmergency();
      await tester.pumpAndSettle();

      alertScreen = tester
          .widget<EmergencyAlertScreen>(find.byType(EmergencyAlertScreen));
      expect(
        alertScreen.warningMessage,
        isNull,
        reason: '音量が回復していれば再発生時には警告が表示されない',
      );
    });
  });
}
