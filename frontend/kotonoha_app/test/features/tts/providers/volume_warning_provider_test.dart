/// VolumeWarningProvider テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import '../../../mocks/mock_volume_controller.dart';

void main() {
  group('VolumeWarningProvider', () {
    late ProviderContainer container;
    late MockVolumeController mockVolumeController;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue(0.0);
    });

    setUp(() {
      // テスト前準備: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 環境初期化: ProviderContainerとモックを作成
      mockVolumeController = MockVolumeController();

      // モックのデフォルト動作を設定（音量50%）
      when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.5);
      when(() => mockVolumeController.getMute()).thenAnswer((_) async => false);

      container = ProviderContainer(
        overrides: [
          // VolumeServiceのモックを注入
          volumeServiceProvider.overrideWithValue(
            VolumeService(volumeController: mockVolumeController),
          ),
        ],
      );
    });

    tearDown(() {
      // テスト後処理: ProviderContainerを破棄し、メモリリークを防ぐ
      container.dispose();
    });

    // 状態管理テストケース
    group('状態管理テストケース', () {
      /// 初期状態でshowWarningはfalse
      test('TC-051-005: 初期状態でshowWarningはfalse', () {
        // When: 実際の処理実行: volumeWarningProviderの状態を読み取る
        final state = container.read(volumeWarningProvider);

        // Then: 結果検証: showWarningがfalseであることを確認
        expect(state.showWarning, isFalse);
      });

      /// 音量0でcheckVolumeを呼ぶとshowWarningがtrueになる
      test('TC-051-006: 音量0でcheckVolumeを呼ぶとshowWarningがtrueになる', () async {
        // Given: テストデータ準備: 音量0.0を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.0);

        // When: 実際の処理実行: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        await notifier.checkVolumeBeforeSpeak();

        // Then: 結果検証: showWarningがtrueになることを確認
        expect(
          container.read(volumeWarningProvider).showWarning,
          isTrue,
        );
      });

      /// 音量50%でcheckVolumeを呼んでもshowWarningはfalseのまま
      test('TC-051-007: 音量50%でcheckVolumeを呼んでもshowWarningはfalseのまま', () async {
        // Given: テストデータ準備: 音量0.5を返すように設定（デフォルト）
        // すでにsetUpで設定済み

        // When: 実際の処理実行: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        await notifier.checkVolumeBeforeSpeak();

        // Then: 結果検証: showWarningがfalseのままであることを確認
        expect(
          container.read(volumeWarningProvider).showWarning,
          isFalse,
        );
      });

      /// dismissWarningを呼ぶとshowWarningがfalseになる
      test('TC-051-008: dismissWarningを呼ぶとshowWarningがfalseになる', () async {
        // Given: テストデータ準備: 警告が表示されている状態を作る
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.0);
        final notifier = container.read(volumeWarningProvider.notifier);
        await notifier.checkVolumeBeforeSpeak();

        // 警告が表示されていることを確認
        expect(container.read(volumeWarningProvider).showWarning, isTrue);

        // When: 実際の処理実行: dismissWarningを呼び出す
        notifier.dismissWarning();

        // Then: 結果検証: showWarningがfalseになることを確認
        expect(
          container.read(volumeWarningProvider).showWarning,
          isFalse,
        );
      });
    });

    // 統合テストケース
    group('統合テストケース', () {
      /// TTS読み上げ前に音量チェックが実行される
      test('TC-051-015: TTS読み上げ前に音量チェックが実行される', () async {
        // Given: テストデータ準備: 音量0.0を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.0);

        // When: 実際の処理実行: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        final shouldProceed = await notifier.checkVolumeBeforeSpeak();

        // Then: 結果検証: falseが返されることを確認
        expect(shouldProceed, isFalse);
        expect(
          container.read(volumeWarningProvider).showWarning,
          isTrue,
        );
      });

      /// 音量正常時は読み上げが即座に開始される
      test('TC-051-016: 音量正常時は読み上げが即座に開始される', () async {
        // Given: テストデータ準備: 音量0.5を返すように設定（デフォルト）
        // すでにsetUpで設定済み

        // When: 実際の処理実行: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        final shouldProceed = await notifier.checkVolumeBeforeSpeak();

        // Then: 結果検証: trueが返されることを確認
        expect(shouldProceed, isTrue);
        expect(
          container.read(volumeWarningProvider).showWarning,
          isFalse,
        );
      });
    });
  });
}
