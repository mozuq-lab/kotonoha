// 【エクスポート定義】: 全Providerの一括エクスポート
// 【実装内容】: アプリ内の全Providerを一箇所からエクスポート
// 【設計根拠】: TASK-0057（Riverpod Provider構造設計）
// 🔵 信頼性レベル: 青信号 - アーキテクチャ設計に基づく

// ============================================================================
// 入力管理
// ============================================================================

// 入力バッファ管理Provider
export 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

// ============================================================================
// 定型文管理
// ============================================================================

// 定型文管理Provider
export 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';

// ============================================================================
// TTS管理
// ============================================================================

// TTS管理Provider
export 'package:kotonoha_app/features/tts/providers/tts_provider.dart';

// 音量警告Provider
export 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';

// ============================================================================
// 設定管理
// ============================================================================

// 設定管理Provider
export 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

// ============================================================================
// テーマ管理
// ============================================================================

// テーマ管理Provider
export 'package:kotonoha_app/core/themes/theme_provider.dart';

// ============================================================================
// 緊急機能
// ============================================================================

// 緊急状態管理Provider
export 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';

// ============================================================================
// 対面表示モード
// ============================================================================

// 対面表示モード管理Provider
export 'package:kotonoha_app/features/face_to_face/providers/face_to_face_provider.dart';

// ============================================================================
// 履歴管理
// ============================================================================

// 履歴管理Provider
export 'package:kotonoha_app/features/history/providers/history_provider.dart';

// 履歴モデル
export 'package:kotonoha_app/features/history/domain/models/history.dart';
export 'package:kotonoha_app/features/history/domain/models/history_type.dart';

// ============================================================================
// お気に入り管理
// ============================================================================

// お気に入り管理Provider
export 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';

// お気に入りモデル
export 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';

// ============================================================================
// ネットワーク状態管理
// ============================================================================

// ネットワーク状態管理Provider
export 'package:kotonoha_app/features/network/providers/network_provider.dart';

// ネットワーク状態モデル
export 'package:kotonoha_app/features/network/domain/models/network_state.dart';
