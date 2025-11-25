/// TTSサービス
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// OS標準TTSエンジンとの連携を提供
library;

import 'package:flutter_tts/flutter_tts.dart';
import '../models/tts_speed.dart';
import '../models/tts_state.dart';

/// TTSサービス
///
/// OS標準のText-to-Speech（TTS）エンジンを使用して、
/// テキストを音声で読み上げる機能を提供する。
///
/// REQ-401: システムは入力欄のテキストをOS標準TTSで読み上げる機能を提供しなければならない
/// REQ-403: システムは読み上げ中の停止・中断機能を提供しなければならない
/// REQ-404: システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない
class TTSService {
  /// コンストラクタ
  ///
  /// [tts] FlutterTtsインスタンス（テスト時はモックを注入）
  TTSService({required this.tts});

  /// FlutterTtsインスタンス
  final FlutterTts tts;

  /// 現在の状態
  TTSState state = TTSState.idle;

  /// 現在の読み上げ速度
  TTSSpeed currentSpeed = TTSSpeed.normal;

  /// エラーメッセージ
  String? errorMessage;

  /// 初期化フラグ
  bool _isInitialized = false;

  /// TTS初期化
  ///
  /// flutter_ttsの初期化、言語設定、デフォルト速度設定を行う。
  ///
  /// 参照: requirements.md（119-126行目）
  ///
  /// Returns:
  /// - true: 初期化成功
  /// - false: 初期化失敗
  Future<bool> initialize() async {
    try {
      await tts.setLanguage('ja-JP');
      await tts.setSpeechRate(1.0);
      _isInitialized = true;
      return true;
    } catch (e) {
      errorMessage = 'TTS初期化に失敗しました';
      _isInitialized = false;
      return false;
    }
  }

  /// テキストを読み上げ
  ///
  /// 指定されたテキストをOS標準TTSエンジンで読み上げる。
  ///
  /// 制約:
  /// - 空文字列の場合は何もしない
  /// - 読み上げ中に再度呼び出された場合は前の読み上げを停止してから新規読み上げ
  ///
  /// 参照: requirements.md（128-139行目）
  ///
  /// [text] 読み上げるテキスト
  Future<void> speak(String text) async {
    // 空文字列チェック
    if (text.isEmpty) return;

    // 初期化チェック（防御的プログラミング）
    if (!_isInitialized) {
      state = TTSState.error;
      errorMessage = 'TTSが初期化されていません';
      return;
    }

    // 読み上げ中の場合は停止してから新規読み上げ
    if (state == TTSState.speaking) {
      await stop();
    }

    try {
      state = TTSState.speaking;
      await tts.speak(text);
    } catch (e) {
      state = TTSState.error;
      errorMessage = '読み上げに失敗しました';
    }
  }

  /// 読み上げを停止
  ///
  /// 現在の読み上げを即座に停止する。
  ///
  /// 参照: requirements.md（141-145行目）
  Future<void> stop() async {
    await tts.stop();
    state = TTSState.stopped;
  }

  /// 読み上げ速度を設定
  ///
  /// 読み上げ速度を変更する。
  ///
  /// 参照: requirements.md（148-158行目）
  ///
  /// [speed] 読み上げ速度（slow/normal/fast）
  Future<void> setSpeed(TTSSpeed speed) async {
    await tts.setSpeechRate(speed.value);
    currentSpeed = speed;
  }

  /// 読み上げ完了コールバック
  ///
  /// 読み上げが完了した際に呼ばれる。
  /// 状態をcompletedに変更し、少し待ってからidleに戻す。
  ///
  /// 参照: requirements.md（168-176行目）
  Future<void> onComplete() async {
    state = TTSState.completed;
    // 少し待ってからidleに戻る（非同期で実行）
    Future.delayed(const Duration(milliseconds: 100), () {
      state = TTSState.idle;
    });
  }

  /// リソース解放
  ///
  /// FlutterTtsのリソースを解放する。
  Future<void> dispose() async {
    await tts.stop();
  }
}
