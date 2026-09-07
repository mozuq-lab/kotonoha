/// EmergencyAudioService テスト
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

    // 1.1 基本再生テスト
    group('基本再生テスト', () {
      /// 緊急音が再生される
      test('TC-047-001: 緊急音が再生される', () async {
        // Act
        await service.startEmergencySound();

        // Assert
        verify(() => mockPlayer.play(any())).called(1);
      });

      /// 緊急音がループ再生される
      test('TC-047-002: 緊急音がループ再生される', () async {
        // Act
        await service.startEmergencySound();

        // Assert
        verify(() => mockPlayer.setReleaseMode(ReleaseMode.loop)).called(1);
      });

      /// 緊急音が最大音量で再生される
      test('TC-047-003: 緊急音が最大音量で再生される', () async {
        // Act
        await service.startEmergencySound();

        // Assert
        verify(() => mockPlayer.setVolume(1.0)).called(1);
      });

      /// 緊急音ファイルがアセットから読み込まれる
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
            equals('audio/emergency_alarm.m4a'));
      });

      /// 緊急音が停止できる
      test('TC-047-005: 緊急音が停止できる', () async {
        // Arrange - 再生中状態にする
        await service.startEmergencySound();

        // Act
        await service.stopEmergencySound();

        // Assert
        verify(() => mockPlayer.stop()).called(1);
      });
    });

    // 1.2 AudioPlayerモック検証テスト
    group('AudioPlayerモック検証テスト', () {
      /// AudioPlayerがモック化できる
      test('TC-047-006: AudioPlayerがモック化できる', () async {
        // Assert - モックが注入されていることを確認
        expect(mockPlayer, isA<MockAudioPlayer>());

        // Act
        await service.startEmergencySound();

        // Assert - モックのメソッドが呼び出される
        verify(() => mockPlayer.play(any())).called(1);
      });

      /// 再生開始時にAudioPlayerが正しく初期化される
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

      /// 停止時にAudioPlayerのstopが呼ばれる
      test('TC-047-008: 停止時にAudioPlayerのstopが呼ばれる', () async {
        // Arrange
        await service.startEmergencySound();

        // Act
        await service.stopEmergencySound();

        // Assert
        verify(() => mockPlayer.stop()).called(1);
      });

      /// リソース解放時にAudioPlayerがdisposeされる
      test('TC-047-009: リソース解放時にAudioPlayerがdisposeされる', () async {
        // Act
        await service.dispose();

        // Assert
        verify(() => mockPlayer.dispose()).called(1);
      });
    });

    // 1.3 エラーハンドリングテスト
    group('エラーハンドリングテスト', () {
      /// 音声ファイル読み込み失敗時に例外をキャッチ
      test('TC-047-010: 音声ファイル読み込み失敗時に例外をキャッチ', () async {
        // Arrange - playが例外をスローするように設定
        when(() => mockPlayer.play(any()))
            .thenThrow(Exception('Failed to load audio file'));

        // Act & Assert - 例外がスローされることを検証
        expect(
          () => service.startEmergencySound(),
          throwsA(isA<Exception>()),
        );
      });

      /// 音声ファイル読み込み失敗時にコールバックが呼ばれる
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

      /// 再生中に停止失敗しても例外をスロー
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

    // 状態管理テスト
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
