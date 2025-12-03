/// 緊急状態プロバイダー
///
/// TASK-0047: 緊急音・画面赤表示実装
/// 関連要件: REQ-303, REQ-304, REQ-2005
/// 信頼性レベル: 青信号（要件定義書ベース）
///
/// Riverpod Notifier を使用した緊急状態管理。
/// 緊急呼び出しの開始・リセットを管理し、
/// AudioService と連携して音声再生を制御する。
///
/// ## 設計概要
///
/// このプロバイダーは以下の責務を持つ:
/// - 緊急状態（EmergencyStateEnum）の管理
/// - 緊急音再生サービスとの連携
/// - 状態遷移の制御（normal <-> alertActive）
///
/// ## 状態遷移図
///
/// ```
/// [normal] --startEmergency()--> [alertActive]
///    ^                                |
///    |                                |
///    +----resetEmergency()------------+
/// ```
///
/// ## 使用例
///
/// ```dart
/// // 緊急呼び出し開始（確認ダイアログで「はい」タップ後）
/// await ref.read(emergencyStateProvider.notifier).startEmergency();
///
/// // 緊急呼び出しリセット（リセットボタンタップ後）
/// await ref.read(emergencyStateProvider.notifier).resetEmergency();
///
/// // 状態監視
/// final state = ref.watch(emergencyStateProvider);
/// if (state == EmergencyStateEnum.alertActive) {
///   // 緊急画面を表示
/// }
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/emergency/domain/models/emergency_state.dart';
import 'package:kotonoha_app/features/emergency/domain/services/emergency_audio_service.dart';

// =============================================================================
// 緊急音サービスプロバイダー
// =============================================================================

/// 緊急音サービスプロバイダー
final emergencyAudioServiceProvider = Provider<EmergencyAudioServiceInterface>(
  (ref) => EmergencyAudioService(),
);

// =============================================================================
// Notifier実装
// =============================================================================

/// 緊急状態管理 Notifier
///
/// 緊急呼び出し機能の状態を管理する Notifier。
/// EmergencyAudioServiceと連携して、状態変更時に音声再生/停止を制御する。
///
/// ## 状態遷移
///
/// - `normal` -> `alertActive`: `startEmergency()` 呼び出し時
/// - `alertActive` -> `normal`: `resetEmergency()` 呼び出し時
///
/// ## エラーハンドリング
///
/// 音声再生に失敗した場合でも、視覚的なフィードバック（赤画面）は
/// 継続して提供される。これは緊急機能の信頼性を確保するための設計判断。
class EmergencyStateNotifier extends Notifier<EmergencyStateEnum> {
  // ---------------------------------------------------------------------------
  // 初期状態
  // ---------------------------------------------------------------------------

  @override
  EmergencyStateEnum build() => EmergencyStateEnum.normal;

  // ---------------------------------------------------------------------------
  // 公開メソッド
  // ---------------------------------------------------------------------------

  /// 緊急呼び出しを開始
  ///
  /// 緊急音を再生し、状態を alertActive に変更する。
  /// 既に alertActive の場合は何もしない。
  ///
  /// 処理内容:
  /// 1. 緊急音の再生を開始
  /// 2. 状態を alertActive に変更
  ///
  /// 例外発生時:
  /// - 音声再生が失敗しても状態は alertActive に変更
  ///   （視覚的な緊急表示は継続）
  Future<void> startEmergency() async {
    if (state == EmergencyStateEnum.alertActive) return;

    try {
      final audioService = ref.read(emergencyAudioServiceProvider);
      await audioService.startEmergencySound();
    } catch (_) {
      // 音声再生エラーは無視し、画面表示は継続
    }

    state = EmergencyStateEnum.alertActive;
  }

  /// 緊急呼び出しをリセット
  ///
  /// 緊急音を停止し、状態を normal に戻す。
  /// 既に normal の場合は何もしない。
  ///
  /// 処理内容:
  /// 1. 緊急音の再生を停止
  /// 2. 状態を normal に変更
  Future<void> resetEmergency() async {
    if (state == EmergencyStateEnum.normal) return;

    try {
      final audioService = ref.read(emergencyAudioServiceProvider);
      await audioService.stopEmergencySound();
    } catch (_) {
      // 停止エラーは無視
    }

    state = EmergencyStateEnum.normal;
  }
}

// =============================================================================
// プロバイダー定義
// =============================================================================

/// 緊急状態プロバイダー
///
/// アプリケーション全体で緊急状態を管理するグローバルプロバイダー。
/// 緊急機能を使用する全ての画面からアクセス可能。
///
/// ## 使用方法
///
/// ```dart
/// // 状態の監視（リアクティブ）
/// final state = ref.watch(emergencyStateProvider);
///
/// // Notifier の取得（アクション実行用）
/// final notifier = ref.read(emergencyStateProvider.notifier);
/// await notifier.startEmergency();
/// ```
///
/// ## テスト時のオーバーライド
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     emergencyAudioServiceProvider.overrideWithValue(mockService),
///   ],
///   child: MyApp(),
/// )
/// ```
final emergencyStateProvider =
    NotifierProvider<EmergencyStateNotifier, EmergencyStateEnum>(
  EmergencyStateNotifier.new,
);
