/// 対面表示モードの状態管理プロバイダー
/// テキストを画面中央に大きく表示する拡大表示モード
/// 画面を180度回転できる機能
/// 通常モードと対面表示モードをシンプルな操作で切り替え
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/face_to_face_state.dart';

/// 対面表示状態管理プロバイダー
/// アプリ全体で対面表示モードの状態を管理する。
/// InputScreenや他のウィジェットからこのプロバイダーを参照して
/// モードの切り替えや表示テキストの取得を行う。
final faceToFaceProvider =
    NotifierProvider<FaceToFaceNotifier, FaceToFaceState>(
  FaceToFaceNotifier.new,
);

/// 対面表示モードのNotifier
/// 状態の変更ロジックを担当する。
/// に基づき、シンプルな操作でモード切り替えを提供。
class FaceToFaceNotifier extends Notifier<FaceToFaceState> {
  /// 初期状態を構築
  /// 初期状態は対面表示モード無効、空のテキスト
  @override
  FaceToFaceState build() => const FaceToFaceState();

  /// 対面表示モードを有効化
  /// [text] 表示するテキスト
  /// テキストを画面中央に大きく表示
  /// シンプルな操作で切り替え
  void enableFaceToFace(String text) {
    state = state.copyWith(
      isEnabled: true,
      displayText: text,
    );
  }

  /// 対面表示モードを無効化
  /// 通常モードに戻る。表示テキストはクリアされない（必要に応じて保持）。
  /// シンプルな操作で切り替え
  void disableFaceToFace() {
    state = state.copyWith(isEnabled: false);
  }

  /// 表示テキストを更新
  /// [text] 新しい表示テキスト
  /// 対面表示モード中にテキストを変更する場合に使用。
  void updateText(String text) {
    state = state.copyWith(displayText: text);
  }

  /// 対面表示モードをトグル
  /// [text] 有効化時に表示するテキスト
  /// 現在のモードを反転する。
  /// シンプルな操作で切り替え
  void toggleFaceToFace(String text) {
    if (state.isEnabled) {
      disableFaceToFace();
    } else {
      enableFaceToFace(text);
    }
  }

  /// 180度回転を有効化
  /// 画面を180度回転できる機能
  void enableRotation() {
    state = state.copyWith(isRotated180: true);
  }

  /// 180度回転を無効化
  /// 画面を180度回転できる機能
  void disableRotation() {
    state = state.copyWith(isRotated180: false);
  }

  /// 180度回転をトグル
  /// 現在の回転状態を反転する。
  /// 画面を180度回転できる機能
  /// シンプルな操作で切り替え
  void toggleRotation() {
    state = state.copyWith(isRotated180: !state.isRotated180);
  }
}
