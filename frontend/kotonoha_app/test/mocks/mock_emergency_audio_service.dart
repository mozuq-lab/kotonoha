/// EmergencyAudioServiceモッククラス
///
/// TASK-0047: 緊急音・画面赤表示実装
/// 緊急音再生サービスのモック
///
/// テスト用にEmergencyAudioServiceの動作をシミュレートする。
library;

import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/emergency/domain/services/emergency_audio_service.dart';

/// EmergencyAudioServiceのモッククラス
///
/// 緊急音の再生・停止をシミュレートする。
///
/// 使用例:
/// ```dart
/// final mockService = MockEmergencyAudioService();
/// when(() => mockService.startEmergencySound()).thenAnswer((_) async {});
/// when(() => mockService.stopEmergencySound()).thenAnswer((_) async {});
/// ```
class MockEmergencyAudioService extends Mock
    implements EmergencyAudioServiceInterface {}
