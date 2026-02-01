/// TTSプロバイダー
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// Riverpod StateNotifierを使用したTTS状態管理
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../domain/models/tts_speed.dart';
import '../domain/models/tts_state.dart';
import '../domain/services/tts_service.dart';

/// TTSサービスの状態
///
/// Riverpod StateNotifierで管理する状態クラス
class TTSServiceState {
  /// コンストラクタ
  const TTSServiceState({
    required this.state,
    required this.currentSpeed,
    this.errorMessage,
  });

  /// 読み上げ状態
  final TTSState state;

  /// 現在の読み上げ速度
  final TTSSpeed currentSpeed;

  /// エラーメッセージ
  final String? errorMessage;

  /// 初期状態を作成
  ///
  /// 状態: idle
  /// 速度: normal
  /// エラーメッセージ: null
  factory TTSServiceState.initial() => const TTSServiceState(
        state: TTSState.idle,
        currentSpeed: TTSSpeed.normal,
      );

  /// 状態のコピーを作成
  ///
  /// 指定されたフィールドのみを更新した新しい状態を返す。
  TTSServiceState copyWith({
    TTSState? state,
    TTSSpeed? currentSpeed,
    String? errorMessage,
  }) {
    return TTSServiceState(
      state: state ?? this.state,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// TTSNotifierのNotifierProvider
///
/// TTS機能の状態管理を行うプロバイダー。
/// UIからはこのプロバイダーを通してTTS機能を利用する。
final ttsProvider = NotifierProvider<TTSNotifier, TTSServiceState>(
  TTSNotifier.new,
);

/// TTSNotifier
///
/// TTS機能の状態管理を行うNotifier。
///
/// 機能:
/// - TTS初期化
/// - テキスト読み上げ
/// - 読み上げ停止
/// - 読み上げ速度設定
class TTSNotifier extends Notifier<TTSServiceState> {
  /// テスト用のTTSServiceオーバーライド
  ///
  /// テスト時は以下のようにオーバーライドする:
  /// ```dart
  /// ttsProvider.overrideWith(() => TTSNotifier(serviceOverride: mockService))
  /// ```
  TTSNotifier({this.serviceOverride});

  /// テスト用のサービスオーバーライド
  final TTSService? serviceOverride;

  @override
  TTSServiceState build() {
    _service = serviceOverride ??
        TTSService(
          tts: FlutterTts(),
          onStateChanged: _onServiceStateChanged,
        );
    // バックグラウンドでTTS初期化を開始（TASK-0090: TTS最適化）
    // build()完了後に非同期で初期化を実行することで、
    // 最初のspeak()呼び出し時の遅延を削減
    Future.microtask(() => _service.initialize());
    return TTSServiceState.initial();
  }

  /// TTSServiceインスタンス
  late final TTSService _service;

  /// TTSServiceの状態変更時に呼ばれるコールバック
  void _onServiceStateChanged() {
    state = state.copyWith(
      state: _service.state,
      errorMessage: _service.errorMessage,
    );
  }

  /// TTS初期化
  ///
  /// OS標準TTSエンジンを初期化する。
  ///
  /// 参照: requirements.md（119-126行目）
  Future<void> initialize() async {
    final success = await _service.initialize();
    if (!success) {
      state = state.copyWith(
        state: TTSState.error,
        errorMessage: _service.errorMessage,
      );
    }
  }

  /// テキストを読み上げ
  ///
  /// 指定されたテキストをOS標準TTSエンジンで読み上げる。
  ///
  /// 参照: requirements.md（128-139行目）
  ///
  /// [text] 読み上げるテキスト
  Future<void> speak(String text) async {
    await _service.speak(text);
    state = state.copyWith(
      state: _service.state,
      errorMessage: _service.errorMessage,
    );
  }

  /// 読み上げを停止
  ///
  /// 現在の読み上げを即座に停止する。
  ///
  /// 参照: requirements.md（141-145行目）
  Future<void> stop() async {
    await _service.stop();
    state = state.copyWith(state: _service.state);
  }

  /// 読み上げ速度を設定
  ///
  /// 読み上げ速度を変更する。
  ///
  /// 参照: requirements.md（148-158行目）
  ///
  /// [speed] 読み上げ速度（slow/normal/fast）
  Future<void> setSpeed(TTSSpeed speed) async {
    await _service.setSpeed(speed);
    state = state.copyWith(currentSpeed: speed);
  }
}
