/// VolumeControllerモッククラス
///
/// TASK-0051: OS音量0の警告表示
/// volume_controllerパッケージのモック
///
/// テスト用にVolumeControllerの動作をシミュレートする。
library;

import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';

/// VolumeControllerのモック実装
///
/// 使用例:
/// ```dart
/// final mockVolumeController = MockVolumeController();
/// when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.5);
/// ```
class MockVolumeController extends Mock implements VolumeControllerInterface {}
