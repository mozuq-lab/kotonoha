/// TTSサービス
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// OS標準TTSエンジンとの連携を提供
///
/// 【機能概要】: OS標準のText-to-Speech（TTS）エンジンを使用した音声読み上げ機能
/// 【設計方針】:
/// - オフラインファースト: OS標準TTSを使用することでネットワーク不要
/// - パフォーマンス重視: 読み上げ開始まで1秒以内（NFR-001）
/// - エラー耐性: エラー時も基本機能は継続動作（NFR-301）
/// 【保守性】: flutter_ttsパッケージへの依存を一元管理
library;

import 'package:flutter_tts/flutter_tts.dart';
import '../models/tts_speed.dart';
import '../models/tts_state.dart';

/// TTSサービス
///
/// OS標準のText-to-Speech（TTS）エンジンを使用して、
/// テキストを音声で読み上げる機能を提供する。
///
/// 【主要機能】:
/// - TTS初期化（日本語、標準速度で設定）
/// - テキスト読み上げ（空文字チェック、読み上げ中の制御含む）
/// - 読み上げ停止・速度変更
/// - 状態管理（idle/speaking/stopped/completed/error）
///
/// 【要件対応】:
/// - REQ-401: システムは入力欄のテキストをOS標準TTSで読み上げる機能を提供しなければならない
/// - REQ-403: システムは読み上げ中の停止・中断機能を提供しなければならない
/// - REQ-404: システムは読み上げ速度を「遅い」「普通」「速い」の3段階から選択できなければならない
///
/// 【パフォーマンス要件】:
/// - NFR-001: TTS読み上げ開始までの時間を1秒以内
///
/// 【信頼性要件】:
/// - NFR-301: 重大なエラーでも基本機能（文字盤+読み上げ）は継続動作
///
/// 🔵 信頼性レベル: 高（要件定義書・設計文書ベース）
class TTSService {
  /// コンストラクタ
  ///
  /// 【パラメータ】:
  /// - [tts] FlutterTtsインスタンス（テスト時はモックを注入）
  /// - [onStateChanged] 状態変更時のコールバック（オプション）
  ///
  /// 【使用例】:
  /// ```dart
  /// // 本番環境
  /// final service = TTSService(tts: FlutterTts());
  ///
  /// // テスト環境
  /// final service = TTSService(tts: mockFlutterTts);
  /// ```
  TTSService({required this.tts, this.onStateChanged});

  /// FlutterTtsインスタンス
  ///
  /// 【役割】: OS標準TTSエンジンとの通信を担当
  /// 【依存性注入】: テスト時はモックを注入することでテスト可能性を確保
  final FlutterTts tts;

  /// 状態変更時のコールバック
  ///
  /// 【役割】: TTS状態が変更された際にNotifierに通知
  final void Function()? onStateChanged;

  /// 現在の状態
  ///
  /// 【状態遷移】:
  /// - idle: 初期状態、読み上げ可能
  /// - speaking: 読み上げ中
  /// - stopped: ユーザーが停止
  /// - completed: 読み上げ完了
  /// - error: エラー発生
  ///
  /// 【UI連携】: この状態に基づいてボタンの有効/無効を制御
  TTSState state = TTSState.idle;

  /// 現在の読み上げ速度
  ///
  /// 【デフォルト値】: TTSSpeed.normal（1.0倍速）
  /// 【変更方法】: setSpeed()メソッドを使用
  TTSSpeed currentSpeed = TTSSpeed.normal;

  /// エラーメッセージ
  ///
  /// 【設定タイミング】: エラー発生時のみ
  /// 【用途】: ユーザーへのエラー通知、デバッグログ
  /// 【例】: "TTS初期化に失敗しました", "読み上げに失敗しました"
  String? errorMessage;

  /// 初期化フラグ
  ///
  /// 【役割】: 初期化済みかどうかを追跡
  /// 【防御的プログラミング】: 初期化前のspeak()呼び出しを防止
  bool _isInitialized = false;

  /// TTS初期化
  ///
  /// flutter_ttsの初期化、言語設定、デフォルト速度設定を行う。
  ///
  /// 【処理内容】:
  /// 1. 言語を日本語（ja-JP）に設定
  /// 2. 読み上げ速度を標準（1.0）に設定
  /// 3. 初期化フラグを設定
  ///
  /// 【エラーハンドリング】:
  /// - 初期化失敗時: errorMessageを設定し、falseを返す
  /// - アプリはクラッシュせず、基本機能は継続（NFR-301）
  ///
  /// 【呼び出しタイミング】: アプリ起動時、最初の読み上げ前
  ///
  /// 参照: requirements.md（119-126行目）
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  ///
  /// Returns:
  /// - true: 初期化成功
  /// - false: 初期化失敗（エラーメッセージがerrorMessageに設定される）
  Future<bool> initialize() async {
    try {
      // 【言語設定】: 日本語（ja-JP）を設定
      await tts.setLanguage('ja-JP');

      // 【速度設定】: 標準速度（1.0倍速）を設定
      await tts.setSpeechRate(1.0);

      // 【完了コールバック登録】: 読み上げ完了時に状態をidleに戻す
      tts.setCompletionHandler(() {
        state = TTSState.idle;
        onStateChanged?.call();
      });

      // 【初期化完了】: フラグを設定し、読み上げ可能な状態にする
      _isInitialized = true;
      return true;
    } catch (e) {
      // 【エラー処理】: 初期化失敗時もアプリは継続動作（NFR-301）
      errorMessage = 'TTS初期化に失敗しました';
      _isInitialized = false;
      return false;
    }
  }

  /// テキストを読み上げ
  ///
  /// 指定されたテキストをOS標準TTSエンジンで読み上げる。
  ///
  /// 【処理フロー】:
  /// 1. 空文字列チェック（何もせず終了）
  /// 2. 初期化チェック（未初期化なら自動初期化）
  /// 3. 読み上げ中チェック（読み上げ中なら停止してから再開）
  /// 4. 状態をspeakingに変更
  /// 5. OS標準TTSで読み上げ開始
  ///
  /// 【制約】:
  /// - 空文字列の場合は何もしない（EDGE-3対応）
  /// - 読み上げ中に再度呼び出された場合は前の読み上げを停止してから新規読み上げ（EDGE-2対応）
  /// - 最大文字数: 1000文字（入力バッファの制限と同じ）
  ///
  /// 【エラーハンドリング】:
  /// - 初期化失敗時: state=error、エラーメッセージ設定
  /// - 読み上げ失敗時: state=error、エラーメッセージ設定、アプリは継続（NFR-301）
  ///
  /// 【パフォーマンス】:
  /// - NFR-001: 読み上げ開始まで1秒以内を目標
  ///
  /// 参照: requirements.md（128-139行目）
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  ///
  /// [text] 読み上げるテキスト（空文字列の場合は何もしない）
  Future<void> speak(String text) async {
    // 【入力検証】: 空文字列チェック（EDGE-3: 空文字列の読み上げ試行）
    if (text.isEmpty) return;

    // 【自動初期化】: 未初期化の場合は自動的に初期化を実行
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        // 初期化失敗時はエラー状態のまま終了
        return;
      }
    }

    // 【読み上げ中断処理】: EDGE-2対応 - 読み上げ中に新しいテキストを読み上げる場合
    if (state == TTSState.speaking) {
      // 【前の読み上げを停止】: 新しいテキストの読み上げを開始する前に現在の読み上げを停止
      await stop();
    }

    try {
      // 【状態更新】: 読み上げ中状態に遷移
      state = TTSState.speaking;

      // 【読み上げ開始】: OS標準TTSエンジンで読み上げ（1秒以内を目標）
      await tts.speak(text);
    } catch (e) {
      // 【エラー処理】: EDGE-004対応 - 読み上げエラー時も継続動作
      state = TTSState.error;
      errorMessage = '読み上げに失敗しました';
      // 【NFR-301準拠】: エラーでもアプリは継続、テキスト表示は維持
    }
  }

  /// 読み上げを停止
  ///
  /// 現在の読み上げを即座に停止する。
  ///
  /// 【処理内容】:
  /// 1. OS標準TTSエンジンに停止命令を送信
  /// 2. 状態をstoppedに変更
  ///
  /// 【冪等性】: 読み上げ中でない状態で呼ばれてもエラーにならない（安全な実装）
  ///
  /// 【パフォーマンス】: NFR-003準拠 - 即座に停止（100ms以内）
  ///
  /// 参照: requirements.md（141-145行目）、REQ-403
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  Future<void> stop() async {
    try {
      // 【停止処理】: OS標準TTSエンジンに停止命令を送信
      await tts.stop();

      // 【状態更新】: 停止状態に遷移
      state = TTSState.stopped;
    } catch (e) {
      // 【エラー処理】: NFR-301準拠 - エラー時も基本機能は継続動作
      // 停止エラーが発生しても、アプリはクラッシュしない
      state = TTSState.error;
      errorMessage = '読み上げ停止に失敗しました';
    }
  }

  /// 読み上げ速度を設定
  ///
  /// 読み上げ速度を変更する。
  ///
  /// 【設定可能な速度】:
  /// - TTSSpeed.slow: 0.7倍速
  /// - TTSSpeed.normal: 1.0倍速（デフォルト）
  /// - TTSSpeed.fast: 1.3倍速
  ///
  /// 【適用タイミング】: 次回の読み上げから新しい速度が適用される
  ///
  /// 参照: requirements.md（148-158行目）、REQ-404
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  ///
  /// [speed] 読み上げ速度（slow/normal/fast）
  Future<void> setSpeed(TTSSpeed speed) async {
    // 【速度変更】: OS標準TTSエンジンに新しい速度を設定
    await tts.setSpeechRate(speed.value);

    // 【状態保存】: 現在の速度を記録
    currentSpeed = speed;
  }

  /// 読み上げ完了コールバック
  ///
  /// 読み上げが完了した際に呼ばれる。
  /// 状態をcompletedに変更し、少し待ってからidleに戻す。
  ///
  /// 【処理フロー】:
  /// 1. 状態をcompletedに変更
  /// 2. 100ms待機（UI更新用の猶予時間）
  /// 3. 状態をidleに戻す（次の読み上げ受付可能）
  ///
  /// 【状態遷移】: speaking → completed → idle
  ///
  /// 参照: requirements.md（168-176行目）
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  Future<void> onComplete() async {
    // 【完了状態設定】: 読み上げ完了を通知
    state = TTSState.completed;

    // 【自動復帰】: 少し待ってからidleに戻る（非同期で実行）
    // 【UI更新猶予】: UIが完了状態を表示する時間を確保
    Future.delayed(const Duration(milliseconds: 100), () {
      state = TTSState.idle;
    });
  }

  /// リソース解放
  ///
  /// FlutterTtsのリソースを解放する。
  ///
  /// 【処理内容】:
  /// - 読み上げ中の場合は停止
  /// - TTSエンジンのリソースを解放
  ///
  /// 【呼び出しタイミング】: アプリ終了時、サービス破棄時
  ///
  /// 【メモリリーク防止】: dispose()を適切に呼ぶことでメモリリークを防止
  ///
  /// 🔵 信頼性レベル: 高（既存テストパターンベース）
  Future<void> dispose() async {
    // 【リソース解放】: 読み上げを停止してリソースを解放
    await tts.stop();
  }
}
