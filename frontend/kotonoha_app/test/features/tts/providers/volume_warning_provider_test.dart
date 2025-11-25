/// VolumeWarningProvider テスト
///
/// TASK-0051: OS音量0の警告表示
/// テストケース: TC-051-005〜TC-051-008（状態管理・警告表示制御）
///
/// テスト対象: lib/features/tts/providers/volume_warning_provider.dart
///
/// 【TDD Redフェーズ】: Providerが未実装、テストが失敗するはず
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
      // 【テスト前準備】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【環境初期化】: ProviderContainerとモックを作成
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
      // 【テスト後処理】: ProviderContainerを破棄し、メモリリークを防ぐ
      container.dispose();
    });

    // =========================================================================
    // 状態管理テストケース
    // =========================================================================
    group('状態管理テストケース', () {
      /// TC-051-005: 初期状態でshowWarningはfalse
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: 初期状態でshowWarningがfalseであることを確認
      test('TC-051-005: 初期状態でshowWarningはfalse', () {
        // 【テスト目的】: 初期状態でshowWarningがfalseであることを確認 🔵
        // 【テスト内容】: Provider作成直後のshowWarning状態を確認
        // 【期待される動作】: showWarning = false
        // 🔵 青信号: volume-warning-requirements.md「VolumeWarningProvider」セクションに基づく

        // When: 【実際の処理実行】: volumeWarningProviderの状態を読み取る
        final state = container.read(volumeWarningProvider);

        // Then: 【結果検証】: showWarningがfalseであることを確認
        expect(state.showWarning, isFalse); // 【確認内容】: 初期状態でshowWarningがfalseであることを確認 🔵
      });

      /// TC-051-006: 音量0でcheckVolumeを呼ぶとshowWarningがtrueになる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: 音量0の状態でcheckVolumeを呼び出すと、showWarningがtrueになることを確認
      test('TC-051-006: 音量0でcheckVolumeを呼ぶとshowWarningがtrueになる', () async {
        // 【テスト目的】: 音量0の状態でcheckVolumeを呼び出すと、showWarningがtrueになることを確認 🔵
        // 【テスト内容】: 音量0.0でcheckVolumeBeforeSpeakを呼び出し、showWarningがtrueになることを確認
        // 【期待される動作】: showWarning = true
        // 🔵 青信号: volume-warning-requirements.md「データフロー」セクションに基づく

        // Given: 【テストデータ準備】: 音量0.0を返すように設定
        when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.0);

        // When: 【実際の処理実行】: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        await notifier.checkVolumeBeforeSpeak();

        // Then: 【結果検証】: showWarningがtrueになることを確認
        expect(
          container.read(volumeWarningProvider).showWarning,
          isTrue,
        ); // 【確認内容】: 音量0でshowWarningがtrueになることを確認 🔵
      });

      /// TC-051-007: 音量50%でcheckVolumeを呼んでもshowWarningはfalseのまま
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: 音量が0より大きい状態でcheckVolumeを呼び出しても、showWarningがfalseのままであることを確認
      test('TC-051-007: 音量50%でcheckVolumeを呼んでもshowWarningはfalseのまま', () async {
        // 【テスト目的】: 音量が0より大きい状態ではshowWarningがfalseのままであることを確認 🔵
        // 【テスト内容】: 音量0.5でcheckVolumeBeforeSpeakを呼び出し、showWarningがfalseのままであることを確認
        // 【期待される動作】: showWarning = false
        // 🔵 青信号: volume-warning-requirements.md「データフロー」セクションに基づく

        // Given: 【テストデータ準備】: 音量0.5を返すように設定（デフォルト）
        // すでにsetUp()で設定済み

        // When: 【実際の処理実行】: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        await notifier.checkVolumeBeforeSpeak();

        // Then: 【結果検証】: showWarningがfalseのままであることを確認
        expect(
          container.read(volumeWarningProvider).showWarning,
          isFalse,
        ); // 【確認内容】: 音量50%でshowWarningがfalseのままであることを確認 🔵
      });

      /// TC-051-008: dismissWarningを呼ぶとshowWarningがfalseになる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: 警告表示中にdismissWarningを呼び出すと、showWarningがfalseになることを確認
      test('TC-051-008: dismissWarningを呼ぶとshowWarningがfalseになる', () async {
        // 【テスト目的】: 警告表示中にdismissWarningを呼び出すと、showWarningがfalseになることを確認 🔵
        // 【テスト内容】: showWarning=trueの状態からdismissWarningを呼び出し、falseになることを確認
        // 【期待される動作】: showWarning = false
        // 🔵 青信号: volume-warning-requirements.md「VolumeWarningWidget」セクションに基づく

        // Given: 【テストデータ準備】: 警告が表示されている状態を作る
        when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.0);
        final notifier = container.read(volumeWarningProvider.notifier);
        await notifier.checkVolumeBeforeSpeak();

        // 警告が表示されていることを確認
        expect(container.read(volumeWarningProvider).showWarning, isTrue);

        // When: 【実際の処理実行】: dismissWarningを呼び出す
        notifier.dismissWarning();

        // Then: 【結果検証】: showWarningがfalseになることを確認
        expect(
          container.read(volumeWarningProvider).showWarning,
          isFalse,
        ); // 【確認内容】: dismissWarningでshowWarningがfalseになることを確認 🔵
      });
    });

    // =========================================================================
    // 統合テストケース
    // =========================================================================
    group('統合テストケース', () {
      /// TC-051-015: TTS読み上げ前に音量チェックが実行される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: checkVolumeBeforeSpeakがtrueを返す場合（音量0）、読み上げを続行するかどうかを返す
      test('TC-051-015: TTS読み上げ前に音量チェックが実行される', () async {
        // 【テスト目的】: checkVolumeBeforeSpeakの戻り値で読み上げ続行を判断できることを確認 🔵
        // 【テスト内容】: 音量0でcheckVolumeBeforeSpeakを呼び出し、falseが返されることを確認
        // 【期待される動作】: shouldProceed = false（警告表示のため読み上げを待機）
        // 🔵 青信号: volume-warning-requirements.md「データフロー」セクションに基づく

        // Given: 【テストデータ準備】: 音量0.0を返すように設定
        when(() => mockVolumeController.getVolume()).thenAnswer((_) async => 0.0);

        // When: 【実際の処理実行】: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        final shouldProceed = await notifier.checkVolumeBeforeSpeak();

        // Then: 【結果検証】: falseが返されることを確認
        expect(shouldProceed, isFalse); // 【確認内容】: 音量0でfalseが返されることを確認 🔵
        expect(
          container.read(volumeWarningProvider).showWarning,
          isTrue,
        ); // 【確認内容】: 警告が表示されることを確認 🔵
      });

      /// TC-051-016: 音量正常時は読み上げが即座に開始される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: EDGE-202
      /// 検証内容: checkVolumeBeforeSpeakがtrueを返す場合（音量>0）、読み上げを続行
      test('TC-051-016: 音量正常時は読み上げが即座に開始される', () async {
        // 【テスト目的】: 音量が正常な場合、checkVolumeBeforeSpeakがtrueを返すことを確認 🔵
        // 【テスト内容】: 音量0.5でcheckVolumeBeforeSpeakを呼び出し、trueが返されることを確認
        // 【期待される動作】: shouldProceed = true（読み上げ続行）
        // 🔵 青信号: volume-warning-requirements.md「データフロー」セクションに基づく

        // Given: 【テストデータ準備】: 音量0.5を返すように設定（デフォルト）
        // すでにsetUp()で設定済み

        // When: 【実際の処理実行】: checkVolumeBeforeSpeakを呼び出す
        final notifier = container.read(volumeWarningProvider.notifier);
        final shouldProceed = await notifier.checkVolumeBeforeSpeak();

        // Then: 【結果検証】: trueが返されることを確認
        expect(shouldProceed, isTrue); // 【確認内容】: 音量正常でtrueが返されることを確認 🔵
        expect(
          container.read(volumeWarningProvider).showWarning,
          isFalse,
        ); // 【確認内容】: 警告が表示されないことを確認 🔵
      });
    });
  });
}
