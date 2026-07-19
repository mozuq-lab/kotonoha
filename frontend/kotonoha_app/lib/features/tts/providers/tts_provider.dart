/// TTSプロバイダー
///
/// TASK-0048: OS標準TTS連携（flutter_tts）
/// Riverpod StateNotifierを使用したTTS状態管理
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../settings/providers/settings_provider.dart';
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
    // Provider破棄時にネイティブTTSリソースを解放（リソースリーク防止）
    // dispose内のネイティブ呼び出し失敗（例: テスト環境のプラグイン未登録）が
    // 未処理の非同期エラーにならないよう握りつぶす。
    ref.onDispose(() {
      unawaited(_service.dispose().catchError((Object _) {}));
    });
    // バックグラウンドでTTS初期化を開始（TASK-0090: TTS最適化）
    // build()完了後に非同期で初期化を実行することで、
    // 最初のspeak()呼び出し時の遅延を削減
    // 【TTS-SPEED-RESTORE-FIX】: Futureを保持し、setSpeed()等から初期化完了を
    // 待ち合わせられるようにする。初期化とsetSpeed()が並行して走ると、
    // 初期化側のsetSpeechRate呼び出しが後から実行されて直前に設定した速度を
    // 上書きしてしまう競合状態が起こり得るため。
    // 初期化後、保存済みの速度設定（SettingsNotifier）が既に読み込まれていれば
    // それを実際のTTSエンジンへ反映する（_applyPersistedSpeedIfAvailable参照）。
    _initFuture = Future.microtask(() async {
      final success = await _service.initialize();
      await _applyPersistedSpeedIfAvailable();
      return success;
    });
    return TTSServiceState.initial();
  }

  /// TTSServiceインスタンス
  late final TTSService _service;

  /// バックグラウンド初期化のFuture
  ///
  /// 【役割】: build()で開始した初期化処理の完了をsetSpeed()等から待ち合わせる
  /// 【TTS-SPEED-RESTORE-FIX】: 初期化完了前にsetSpeed()が呼ばれても、
  /// 初期化完了後に確実に指定した速度が適用されるようにする
  late Future<bool> _initFuture;

  /// SettingsNotifierに保存済みのTTS速度が既に読み込まれている場合、
  /// それを実際のTTSエンジンへ反映する
  ///
  /// 【バグ修正の背景】: 従来はSettingsNotifierが復元した速度が状態にのみ
  /// 反映され、TTSエンジン（flutter_tts）にはユーザーが設定画面で速度を
  /// 変更したときにしか反映されなかった。そのためアプリ再起動直後は
  /// 「設定画面には保存済みの速度が表示されているのに、実際の読み上げは
  /// 標準速度(1.0倍)のまま」という不整合が発生していた。
  ///
  /// 【安全対策（重要）】: `ref.exists(settingsNotifierProvider)`で
  /// SettingsNotifierが「既に他の場所で構築済み」の場合に限り読み取る
  /// （ここで新規に構築はしない）。もし無条件に
  /// `ref.read(settingsNotifierProvider.future)`を呼ぶと、TTSNotifierを
  /// 単体でテストする既存のテスト（tts_button_test.dart等、SharedPreferences
  /// のモック設定を行っていないテストが多数存在する）まで実
  /// SharedPreferencesアクセスを発生させてしまう。flutter_ttsと同様、
  /// モック未設定のテスト環境（testWidgets）ではプラットフォームチャンネル
  /// 呼び出しが応答を返さずアプリのイベントループごと停止してしまう
  /// （pumpAndSettleのタイムアウトを引き起こす）ことを実機検証で確認しており、
  /// これを避けるためのガードである。
  ///
  /// 実アプリでは、通常SettingsNotifierは起動シーケンスの中でTTSButton等が
  /// 表示されるより先に読み込みが開始されるため、この時点で
  /// `ref.exists(settingsNotifierProvider)`はtrueとなり、保存済みの速度が
  /// 正しく反映される。
  ///
  /// 【破棄安全性】: build()完了直後（バックグラウンドタスクが未実行のうち）に
  /// ProviderContainerが破棄されるテストケース等では、このメソッドが実行される
  /// 時点で既にこのNotifier自身のrefが破棄済みになっていることがある。
  /// `ref.exists()`はrefが破棄済みだと例外を投げるため、まず`ref.mounted`
  /// （例外を投げない安全なチェック）で確認し、各await後の再開時にも
  /// 都度確認する。
  Future<void> _applyPersistedSpeedIfAvailable() async {
    try {
      if (!ref.mounted || !ref.exists(settingsNotifierProvider)) {
        return;
      }
      final settings = await ref.read(settingsNotifierProvider.future);
      if (!ref.mounted) return;
      await _service.setSpeed(settings.ttsSpeed);
      if (!ref.mounted) return;
      state = state.copyWith(currentSpeed: settings.ttsSpeed);
    } catch (e) {
      // 【エラーハンドリング】: 設定読み込み・TTS反映に失敗しても、
      // TTS自体の初期化結果には影響を与えない（NFR-301）
    }
  }

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
  /// 【TTS-SPEED-RESTORE-FIX】: build()で開始したバックグラウンド初期化
  /// （_initFuture、_service.initialize() + 保存済み速度の反映）をそのまま
  /// 待ち合わせる。以前は`_service.initialize()`を独立してもう一度呼んで
  /// いたため、(1) 初期化が二重に実行される、(2) このメソッドの完了後も
  /// バックグラウンド側の「保存済み速度の反映」処理が終わっているとは限らず、
  /// 直後に`setSpeed()`を呼ぶテストコードとの間で速度設定の呼び出し回数が
  /// 想定より増える競合状態が発生する、という問題があった。
  ///
  /// 参照: requirements.md（119-126行目）
  Future<void> initialize() async {
    final success = await _initFuture;
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
    // 【競合防止】: バックグラウンド初期化が完了してから速度を適用する。
    // これにより、初期化のsetSpeechRate呼び出しが後から実行されて
    // 直前に適用した速度を上書きしてしまう競合状態を防ぐ（TTS-SPEED-RESTORE-FIX）。
    await _initFuture;
    await _service.setSpeed(speed);
    state = state.copyWith(currentSpeed: speed);
  }
}
