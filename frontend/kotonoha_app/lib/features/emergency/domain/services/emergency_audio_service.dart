/// 緊急音再生サービス
///
/// TASK-0047: 緊急音・画面赤表示実装
/// 関連要件: REQ-303（緊急音発生）、FR-001〜FR-003
/// 信頼性レベル: 青信号（要件定義書ベース）
///
/// 緊急ボタン押下時に緊急音を再生するサービス。
/// audioplayersパッケージを使用してループ再生・最大音量で再生。
///
/// ## 設計概要
///
/// このサービスは以下の責務を持つ:
/// - 緊急音の再生開始（ループ再生、最大音量）
/// - 緊急音の停止
/// - リソースの解放
///
/// ## 依存性注入
///
/// テスト容易性のため、AudioPlayerをコンストラクタで注入可能。
/// ```dart
/// // 本番環境
/// final service = EmergencyAudioService();
///
/// // テスト環境
/// final mockPlayer = MockAudioPlayer();
/// final service = EmergencyAudioService(player: mockPlayer);
/// ```
library;

import 'package:audioplayers/audioplayers.dart';

// =============================================================================
// 定数定義
// =============================================================================

/// 緊急音再生に関する定数
abstract class _EmergencyAudioConstants {
  /// 緊急音ファイルのパス（assetsフォルダからの相対パス）
  static const String audioPath = 'audio/emergency_alarm.mp3';

  /// 最大音量
  static const double maxVolume = 1.0;
}

/// 緊急音再生サービスのインターフェース
///
/// テスト時にモック化するためのインターフェース定義。
abstract class EmergencyAudioServiceInterface {
  /// 緊急音の再生を開始（ループ再生）
  Future<void> startEmergencySound();

  /// 緊急音の再生を停止
  Future<void> stopEmergencySound();

  /// リソースを解放
  Future<void> dispose();

  /// 再生中かどうか
  bool get isPlaying;

  /// エラーコールバック
  set onError(void Function(Object error)? callback);
}

/// 緊急音再生サービス
///
/// audioplayers パッケージを使用して緊急音を再生する。
///
/// 機能:
/// - ループ再生（ReleaseMode.loop）
/// - 最大音量（volume: 1.0）
/// - アセットからの音声ファイル読み込み
///
/// 使用例:
/// ```dart
/// final service = EmergencyAudioService();
/// await service.startEmergencySound();
/// // ... 緊急状態 ...
/// await service.stopEmergencySound();
/// await service.dispose();
/// ```
class EmergencyAudioService implements EmergencyAudioServiceInterface {
  // ---------------------------------------------------------------------------
  // フィールド
  // ---------------------------------------------------------------------------

  /// AudioPlayer インスタンス
  final AudioPlayer _player;

  /// 再生中フラグ
  bool _isPlaying = false;

  /// エラーコールバック
  void Function(Object error)? _onError;

  // ---------------------------------------------------------------------------
  // コンストラクタ
  // ---------------------------------------------------------------------------

  /// EmergencyAudioService を作成する
  ///
  /// [player] - テスト用にAudioPlayerを注入可能。
  ///            nullの場合は新しいインスタンスを作成。
  EmergencyAudioService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  // ---------------------------------------------------------------------------
  // ゲッター・セッター
  // ---------------------------------------------------------------------------

  @override
  bool get isPlaying => _isPlaying;

  @override
  set onError(void Function(Object error)? callback) {
    _onError = callback;
  }

  // ---------------------------------------------------------------------------
  // 公開メソッド
  // ---------------------------------------------------------------------------

  /// 緊急音の再生を開始
  ///
  /// ループ再生・最大音量で緊急音を再生する。
  /// 既に再生中の場合は何もしない。
  ///
  /// 例外発生時:
  /// - onErrorコールバックを呼び出す
  /// - エラーをログに記録
  /// - 例外を再スローしない（UIは継続動作）
  @override
  Future<void> startEmergencySound() async {
    if (_isPlaying) return;

    try {
      // ループ再生モードを設定
      await _player.setReleaseMode(ReleaseMode.loop);

      // 最大音量を設定
      await _player.setVolume(_EmergencyAudioConstants.maxVolume);

      // アセットから緊急音を再生
      await _player.play(AssetSource(_EmergencyAudioConstants.audioPath));

      _isPlaying = true;
    } catch (e) {
      _onError?.call(e);
      // エラー時も状態を更新しない（再試行可能）
      rethrow;
    }
  }

  /// 緊急音の再生を停止
  ///
  /// 現在再生中の緊急音を停止する。
  /// 再生中でない場合は何もしない。
  @override
  Future<void> stopEmergencySound() async {
    if (!_isPlaying) return;

    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      _onError?.call(e);
      _isPlaying = false; // エラー時も停止状態に
      rethrow;
    }
  }

  /// リソースを解放
  ///
  /// AudioPlayer のリソースを解放する。
  /// サービスが不要になった時に呼び出す。
  @override
  Future<void> dispose() async {
    _isPlaying = false;
    await _player.dispose();
  }
}
