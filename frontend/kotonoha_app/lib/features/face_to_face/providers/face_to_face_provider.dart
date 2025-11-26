/// 対面表示モードの状態管理プロバイダー
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// TASK-0053: 180度画面回転機能実装
/// REQ-501: テキストを画面中央に大きく表示する拡大表示モード
/// REQ-502: 画面を180度回転できる機能
/// REQ-503: 通常モードと対面表示モードをシンプルな操作で切り替え
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/face_to_face_state.dart';

/// 対面表示状態管理プロバイダー
///
/// アプリ全体で対面表示モードの状態を管理する。
/// InputScreenや他のウィジェットからこのプロバイダーを参照して
/// モードの切り替えや表示テキストの取得を行う。
final faceToFaceProvider =
    StateNotifierProvider<FaceToFaceNotifier, FaceToFaceState>((ref) {
  return FaceToFaceNotifier();
});

/// 対面表示モードのNotifier
///
/// 状態の変更ロジックを担当する。
/// REQ-503に基づき、シンプルな操作でモード切り替えを提供。
class FaceToFaceNotifier extends StateNotifier<FaceToFaceState> {
  /// FaceToFaceNotifierを作成
  ///
  /// 初期状態は対面表示モード無効、空のテキスト
  FaceToFaceNotifier() : super(const FaceToFaceState());

  /// 対面表示モードを有効化
  ///
  /// [text] 表示するテキスト
  ///
  /// REQ-501: テキストを画面中央に大きく表示
  /// REQ-503: シンプルな操作で切り替え
  void enableFaceToFace(String text) {
    state = state.copyWith(
      isEnabled: true,
      displayText: text,
    );
  }

  /// 対面表示モードを無効化
  ///
  /// 通常モードに戻る。表示テキストはクリアされない（必要に応じて保持）。
  /// REQ-503: シンプルな操作で切り替え
  void disableFaceToFace() {
    state = state.copyWith(isEnabled: false);
  }

  /// 表示テキストを更新
  ///
  /// [text] 新しい表示テキスト
  ///
  /// 対面表示モード中にテキストを変更する場合に使用。
  void updateText(String text) {
    state = state.copyWith(displayText: text);
  }

  /// 対面表示モードをトグル
  ///
  /// [text] 有効化時に表示するテキスト
  ///
  /// 現在のモードを反転する。
  /// REQ-503: シンプルな操作で切り替え
  void toggleFaceToFace(String text) {
    if (state.isEnabled) {
      disableFaceToFace();
    } else {
      enableFaceToFace(text);
    }
  }

  /// 180度回転を有効化
  ///
  /// REQ-502: 画面を180度回転できる機能
  void enableRotation() {
    state = state.copyWith(isRotated180: true);
  }

  /// 180度回転を無効化
  ///
  /// REQ-502: 画面を180度回転できる機能
  void disableRotation() {
    state = state.copyWith(isRotated180: false);
  }

  /// 180度回転をトグル
  ///
  /// 現在の回転状態を反転する。
  /// REQ-502: 画面を180度回転できる機能
  /// REQ-503: シンプルな操作で切り替え
  void toggleRotation() {
    state = state.copyWith(isRotated180: !state.isRotated180);
  }
}
