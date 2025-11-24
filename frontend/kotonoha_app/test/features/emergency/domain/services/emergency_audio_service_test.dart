/// EmergencyAudioService テスト
///
/// TASK-0047: 緊急音・画面赤表示実装
/// テストケース: TC-047-001〜TC-047-012
///
/// テスト対象: lib/features/emergency/domain/services/emergency_audio_service.dart
///
/// 【TDD Greenフェーズ】: サービスクラスが実装済み、テストが通るはず
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/emergency/domain/services/emergency_audio_service.dart';
import '../../../../mocks/mock_audio_player.dart';

void main() {
  group('EmergencyAudioService', () {
    late MockAudioPlayer mockPlayer;
    late EmergencyAudioService service;

    setUpAll(() {
      // Mocktailのフォールバック値を登録
      registerFallbackValue(AssetSource('test'));
      registerFallbackValue(ReleaseMode.loop);
    });

    setUp(() {
      mockPlayer = MockAudioPlayer();
      // モックのデフォルト動作を設定
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});
      when(() => mockPlayer.stop()).thenAnswer((_) async {});
      when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
      when(() => mockPlayer.setReleaseMode(any())).thenAnswer((_) async {});
      when(() => mockPlayer.dispose()).thenAnswer((_) async {});

      service = EmergencyAudioService(player: mockPlayer);
    });

    // =========================================================================
    // 1.1 基本再生テスト
    // =========================================================================
    group('基本再生テスト', () {
      /// TC-047-001: 緊急音が再生される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-001, REQ-303
      /// 検証内容: startEmergencySound()呼び出しでAudioPlayerのplay()が呼ばれる
      test('TC-047-001: 緊急音が再生される', () async {
        // Act
        await service.startEmergencySound();

        // Assert
        verify(() => mockPlayer.play(any())).called(1);
      });

      /// TC-047-002: 緊急音がループ再生される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-002
      /// 検証内容: setReleaseMode(ReleaseMode.loop)が呼ばれる
      test('TC-047-002: 緊急音がループ再生される', () async {
        // Act
        await service.startEmergencySound();

        // Assert
        verify(() => mockPlayer.setReleaseMode(ReleaseMode.loop)).called(1);
      });

      /// TC-047-003: 緊急音が最大音量で再生される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-003
      /// 検証内容: setVolume(1.0)が呼ばれる
      test('TC-047-003: 緊急音が最大音量で再生される', () async {
        // Act
        await service.startEmergencySound();

        // Assert
        verify(() => mockPlayer.setVolume(1.0)).called(1);
      });

      /// TC-047-004: 緊急音ファイルがアセットから読み込まれる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-204
      /// 検証内容: AssetSource('audio/emergency_alarm.mp3')が使用される
      test('TC-047-004: 緊急音ファイルがアセットから読み込まれる', () async {
        // Arrange - 特定のアセットパスを検証するためにキャプチャ
        Source? capturedSource;
        when(() => mockPlayer.play(any())).thenAnswer((invocation) async {
          capturedSource = invocation.positionalArguments[0] as Source;
        });

        // Act
        await service.startEmergencySound();

        // Assert
        expect(capturedSource, isA<AssetSource>());
        expect((capturedSource as AssetSource).path,
            equals('audio/emergency_alarm.mp3'));
      });

      /// TC-047-005: 緊急音が停止できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: FR-007
      /// 検証内容: stopEmergencySound()呼び出しでAudioPlayerのstop()が呼ばれる
      test('TC-047-005: 緊急音が停止できる', () async {
        // Arrange - 再生中状態にする
        await service.startEmergencySound();

        // Act
        await service.stopEmergencySound();

        // Assert
        verify(() => mockPlayer.stop()).called(1);
      });
    });

    // =========================================================================
    // 1.2 AudioPlayerモック検証テスト
    // =========================================================================
    group('AudioPlayerモック検証テスト', () {
      /// TC-047-006: AudioPlayerがモック化できる
      ///
      /// 優先度: P0（必須）
      /// 検証内容: モックが正しく注入される
      test('TC-047-006: AudioPlayerがモック化できる', () async {
        // Assert - モックが注入されていることを確認
        expect(mockPlayer, isA<MockAudioPlayer>());

        // Act
        await service.startEmergencySound();

        // Assert - モックのメソッドが呼び出される
        verify(() => mockPlayer.play(any())).called(1);
      });

      /// TC-047-007: 再生開始時にAudioPlayerが正しく初期化される
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: setReleaseMode → setVolume → play の順で呼び出される
      test('TC-047-007: 再生開始時にAudioPlayerが正しく初期化される', () async {
        // Act
        await service.startEmergencySound();

        // Assert - 呼び出し順序を検証
        verifyInOrder([
          () => mockPlayer.setReleaseMode(ReleaseMode.loop),
          () => mockPlayer.setVolume(1.0),
          () => mockPlayer.play(any()),
        ]);
      });

      /// TC-047-008: 停止時にAudioPlayerのstopが呼ばれる
      ///
      /// 優先度: P0（必須）
      /// 検証内容: stopEmergencySound()でstop()が1回呼ばれる
      test('TC-047-008: 停止時にAudioPlayerのstopが呼ばれる', () async {
        // Arrange
        await service.startEmergencySound();

        // Act
        await service.stopEmergencySound();

        // Assert
        verify(() => mockPlayer.stop()).called(1);
      });

      /// TC-047-009: リソース解放時にAudioPlayerがdisposeされる
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: dispose()でAudioPlayerのdispose()が呼ばれる
      test('TC-047-009: リソース解放時にAudioPlayerがdisposeされる', () async {
        // Act
        await service.dispose();

        // Assert
        verify(() => mockPlayer.dispose()).called(1);
      });
    });

    // =========================================================================
    // 1.3 エラーハンドリングテスト
    // =========================================================================
    group('エラーハンドリングテスト', () {
      /// TC-047-010: 音声ファイル読み込み失敗時に例外をキャッチ
      ///
      /// 優先度: P1（高優先度）
      /// 検証内容: play()が例外をスローしてもエラーがキャッチされる
      test('TC-047-010: 音声ファイル読み込み失敗時に例外をキャッチ', () async {
        // Arrange - play()が例外をスローするように設定
        when(() => mockPlayer.play(any()))
            .thenThrow(Exception('Failed to load audio file'));

        // Act & Assert - 例外がスローされることを検証
        expect(
          () => service.startEmergencySound(),
          throwsA(isA<Exception>()),
        );
      });

      /// TC-047-011: 音声ファイル読み込み失敗時にコールバックが呼ばれる
      ///
      /// 優先度: P2（中優先度）
      /// 検証内容: エラー発生時にonErrorコールバックが呼ばれる
      test('TC-047-011: 音声ファイル読み込み失敗時にコールバックが呼ばれる', () async {
        // Arrange
        Object? capturedError;
        service.onError = (error) => capturedError = error;

        when(() => mockPlayer.play(any()))
            .thenThrow(Exception('Audio load failed'));

        // Act
        try {
          await service.startEmergencySound();
        } catch (_) {
          // エラーをキャッチ
        }

        // Assert - onErrorコールバックが呼ばれることを検証
        expect(capturedError, isA<Exception>());
      });

      /// TC-047-012: 再生中に停止失敗しても例外をスロー
      ///
      /// 優先度: P2（中優先度）
      /// 検証内容: stop()が例外をスローしても適切に処理される
      test('TC-047-012: 再生中に停止失敗しても例外をスロー', () async {
        // Arrange
        await service.startEmergencySound();
        when(() => mockPlayer.stop()).thenThrow(Exception('Stop failed'));

        // Act & Assert
        expect(
          () => service.stopEmergencySound(),
          throwsA(isA<Exception>()),
        );
      });
    });

    // =========================================================================
    // 状態管理テスト
    // =========================================================================
    group('状態管理テスト', () {
      /// 再生中状態の追跡
      test('再生開始後はisPlayingがtrueになる', () async {
        // Arrange
        expect(service.isPlaying, isFalse);

        // Act
        await service.startEmergencySound();

        // Assert
        expect(service.isPlaying, isTrue);
      });

      /// 停止後は再生状態がfalseになる
      test('停止後はisPlayingがfalseになる', () async {
        // Arrange
        await service.startEmergencySound();

        // Act
        await service.stopEmergencySound();

        // Assert
        expect(service.isPlaying, isFalse);
      });
    });
  });
}
