/// 音量警告プロバイダー
///
/// TASK-0051: OS音量0の警告表示
/// 音量警告の状態管理を提供
///
/// 【機能概要】: 音量0（ミュート）警告の表示/非表示を管理するRiverpodプロバイダー
/// 【設計方針】:
/// - Riverpod StateNotifierパターンに従った状態管理
/// - TTS読み上げ前の音量チェック機能を提供
/// 【保守性】: 音量警告に関する状態をこのプロバイダーに集約
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/volume_service.dart';

/// 音量警告の状態
///
/// 【状態管理】:
/// - showWarning: 警告を表示するかどうか
/// - currentVolume: 現在の音量（デバッグ用）
class VolumeWarningState {
  const VolumeWarningState({
    this.showWarning = false,
    this.currentVolume = 1.0,
  });

  /// 警告を表示するかどうか
  final bool showWarning;

  /// 現在の音量（0.0〜1.0）
  final double currentVolume;

  /// copyWithメソッド
  VolumeWarningState copyWith({
    bool? showWarning,
    double? currentVolume,
  }) {
    return VolumeWarningState(
      showWarning: showWarning ?? this.showWarning,
      currentVolume: currentVolume ?? this.currentVolume,
    );
  }
}

/// VolumeServiceプロバイダー
///
/// VolumeServiceのインスタンスを提供する。
/// テスト時はoverridesでモックを注入可能。
final volumeServiceProvider = Provider<VolumeService>((ref) {
  return VolumeService();
});

/// 音量警告状態管理Notifier
///
/// 音量警告の表示/非表示を管理するNotifier。
///
/// 【主要機能】:
/// - checkVolumeBeforeSpeak(): 読み上げ前に音量をチェックし、警告を表示するかを判断
/// - dismissWarning(): 警告を閉じる
///
/// 【要件対応】:
/// - EDGE-202: OSの音量が0の状態で読み上げを実行した場合の警告
class VolumeWarningNotifier extends StateNotifier<VolumeWarningState> {
  VolumeWarningNotifier(this._volumeService)
      : super(const VolumeWarningState());

  final VolumeService _volumeService;

  /// TTS読み上げ前に音量をチェック
  ///
  /// OSの音量をチェックし、音量0の場合は警告を表示する。
  ///
  /// 【戻り値】:
  /// - true: 音量が正常、読み上げを続行
  /// - false: 音量が0、警告を表示（読み上げを待機）
  ///
  /// 【処理フロー】:
  /// 1. VolumeServiceで現在の音量を取得
  /// 2. 音量0の場合はshowWarning=trueに設定
  /// 3. 音量0でない場合はshowWarning=false（警告不要）
  ///
  /// 参照: volume-warning-requirements.md「データフロー」セクション
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  Future<bool> checkVolumeBeforeSpeak() async {
    try {
      final isZero = await _volumeService.isVolumeZero();
      final volume = await _volumeService.getCurrentVolume();

      if (isZero) {
        state = state.copyWith(
          showWarning: true,
          currentVolume: volume,
        );
        return false; // 音量0のため、読み上げを待機
      } else {
        state = state.copyWith(
          showWarning: false,
          currentVolume: volume,
        );
        return true; // 音量正常、読み上げを続行
      }
    } catch (e) {
      // エラー時は警告を出さず、読み上げを続行（NFR-301準拠）
      state = state.copyWith(showWarning: false);
      return true;
    }
  }

  /// 警告を閉じる
  ///
  /// ユーザーが警告を確認した後、警告を非表示にする。
  ///
  /// 参照: volume-warning-requirements.md「VolumeWarningWidget」セクション
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  void dismissWarning() {
    state = state.copyWith(showWarning: false);
  }
}

/// 音量警告プロバイダー
///
/// VolumeWarningStateを提供するStateNotifierProvider。
///
/// 【使用例】:
/// ```dart
/// // 状態を読み取る
/// final showWarning = ref.watch(volumeWarningProvider).showWarning;
///
/// // Notifierを取得してメソッドを呼び出す
/// final shouldProceed = await ref.read(volumeWarningProvider.notifier).checkVolumeBeforeSpeak();
/// ```
final volumeWarningProvider =
    StateNotifierProvider<VolumeWarningNotifier, VolumeWarningState>((ref) {
  final volumeService = ref.watch(volumeServiceProvider);
  return VolumeWarningNotifier(volumeService);
});
