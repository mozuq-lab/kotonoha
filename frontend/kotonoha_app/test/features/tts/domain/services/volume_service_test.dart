/// VolumeService テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/tts/domain/services/volume_service.dart';
import '../../../../mocks/mock_volume_controller.dart';

void main() {
  group('VolumeService', () {
    late MockVolumeController mockVolumeController;
    late VolumeService service;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue(0.0);
    });

    setUp(() {
      // テスト前準備: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 環境初期化: モックを作成し、デフォルト動作を設定
      mockVolumeController = MockVolumeController();

      // モックのデフォルト動作を設定
      when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.5);
      when(() => mockVolumeController.getMute()).thenAnswer((_) async => false);

      service = VolumeService(volumeController: mockVolumeController);
    });

    group('正常系テストケース', () {
      /// VolumeServiceが正常に初期化される
      test('TC-051-001: VolumeServiceが正常に初期化される', () async {
        // When: 実際の処理実行: サービスインスタンスを確認
        // Then: 結果検証: インスタンスが正常に作成されていることを確認
        expect(service, isNotNull);
        expect(service.isInitialized, isTrue);
      });

      /// 音量50%の場合、isVolumeZeroがfalseを返す
      test('TC-051-002: 音量50%の場合、isVolumeZeroがfalseを返す', () async {
        // Given: テストデータ準備: 音量0.5を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.5);

        // When: 実際の処理実行: isVolumeZeroを確認
        final result = await service.isVolumeZero();

        // Then: 結果検証: falseが返されることを確認
        expect(result, isFalse);
      });

      /// 音量0%の場合、isVolumeZeroがtrueを返す
      test('TC-051-003: 音量0%の場合、isVolumeZeroがtrueを返す', () async {
        // Given: テストデータ準備: 音量0.0を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.0);

        // When: 実際の処理実行: isVolumeZeroを確認
        final result = await service.isVolumeZero();

        // Then: 結果検証: trueが返されることを確認
        expect(result, isTrue);
      });

      /// getCurrentVolumeで現在の音量を取得できる
      test('TC-051-004: getCurrentVolumeで現在の音量を取得できる', () async {
        // Given: テストデータ準備: 音量0.75を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.75);

        // When: 実際の処理実行: getCurrentVolumeを呼び出す
        final result = await service.getCurrentVolume();

        // Then: 結果検証: 0.75が返されることを確認
        expect(result, 0.75);
      });
    });

    group('異常系テストケース', () {
      /// 音量取得に失敗した場合、例外がスローされる
      test('TC-051-009: 音量取得に失敗した場合、例外がスローされる', () async {
        // Given: テストデータ準備: getVolumeが例外をスローするように設定
        when(() => mockVolumeController.getVolume())
            .thenThrow(Exception('音量取得に失敗'));

        // When/Then: 実際の処理実行・結果検証: 例外がスローされることを確認
        expect(
          () => service.getCurrentVolume(),
          throwsA(isA<VolumeServiceException>()),
        );
      });

      /// Web環境では音量取得が無効化される
      test('TC-051-010: Web環境では音量取得が無効化される', () async {
        // Given: テストデータ準備: Web環境をシミュレート
        final webService = VolumeService(
          volumeController: mockVolumeController,
          isSupported: false,
        );

        // When: 実際の処理実行: isVolumeZeroを呼び出す
        final result = await webService.isVolumeZero();

        // Then: 結果検証: falseが返されることを確認
        expect(result, isFalse);
      });
    });

    group('境界値テストケース', () {
      /// 音量0.0の場合、isVolumeZeroがtrueを返す（境界値）
      test('TC-051-011: 音量0.0の場合、isVolumeZeroがtrueを返す（境界値）', () async {
        // Given: テストデータ準備: 音量0.0を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.0);

        // When: 実際の処理実行: isVolumeZeroを呼び出す
        final result = await service.isVolumeZero();

        // Then: 結果検証: trueが返されることを確認
        expect(result, isTrue);
      });

      /// 音量0.01の場合、isVolumeZeroがfalseを返す（境界値）
      test('TC-051-012: 音量0.01の場合、isVolumeZeroがfalseを返す（境界値）', () async {
        // Given: テストデータ準備: 音量0.01を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.01);

        // When: 実際の処理実行: isVolumeZeroを呼び出す
        final result = await service.isVolumeZero();

        // Then: 結果検証: falseが返されることを確認
        expect(result, isFalse);
      });

      /// 音量1.0の場合、isVolumeZeroがfalseを返す（境界値）
      test('TC-051-013: 音量1.0の場合、isVolumeZeroがfalseを返す（境界値）', () async {
        // Given: テストデータ準備: 音量1.0を返すように設定
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 1.0);

        // When: 実際の処理実行: isVolumeZeroを呼び出す
        final result = await service.isVolumeZero();

        // Then: 結果検証: falseが返されることを確認
        expect(result, isFalse);
      });

      /// 音量チェックが100ms以内に完了する（パフォーマンス）
      test('TC-051-014: 音量チェックが100ms以内に完了する（パフォーマンス）', () async {
        // Given: テストデータ準備: モックは即座に応答
        when(() => mockVolumeController.getVolume())
            .thenAnswer((_) async => 0.5);

        // When: 実際の処理実行: isVolumeZeroを呼び出し、実行時間を計測
        final stopwatch = Stopwatch()..start();
        await service.isVolumeZero();
        stopwatch.stop();

        // Then: 結果検証: 100ms以内に完了することを確認
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
        );
      });
    });
  });
}
