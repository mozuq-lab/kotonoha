/// 対面表示モードの状態モデル
///
/// TASK-0052: 対面表示モード（拡大表示）実装
/// TASK-0053: 180度画面回転機能実装
/// REQ-501: テキストを画面中央に大きく表示する拡大表示モード
/// REQ-502: 画面を180度回転できる機能
/// REQ-503: 通常モードと対面表示モードをシンプルな操作で切り替え
library;

import 'package:flutter/foundation.dart';

/// 対面表示モードの状態を表す不変クラス
///
/// Riverpod StateNotifierパターンで使用する状態モデル。
/// copyWithメソッドで状態の一部を更新した新しいインスタンスを作成できる。
@immutable
class FaceToFaceState {
  /// 対面表示モードが有効かどうか
  ///
  /// true: 対面表示モード（拡大表示）
  /// false: 通常モード
  final bool isEnabled;

  /// 対面表示で表示するテキスト
  ///
  /// REQ-501: テキストを画面中央に大きく表示
  final String displayText;

  /// 画面が180度回転しているかどうか
  ///
  /// true: 180度回転している
  /// false: 通常の向き
  /// REQ-502: 画面を180度回転できる機能
  final bool isRotated180;

  /// FaceToFaceStateを作成
  ///
  /// [isEnabled] 対面表示モードが有効かどうか（デフォルト: false）
  /// [displayText] 表示するテキスト（デフォルト: 空文字列）
  /// [isRotated180] 画面が180度回転しているかどうか（デフォルト: false）
  const FaceToFaceState({
    this.isEnabled = false,
    this.displayText = '',
    this.isRotated180 = false,
  });

  /// 指定したプロパティのみを更新した新しいインスタンスを作成
  ///
  /// 不変オブジェクトパターンに従い、状態の一部を更新する際に使用。
  /// 指定されなかったプロパティは現在の値を維持する。
  FaceToFaceState copyWith({
    bool? isEnabled,
    String? displayText,
    bool? isRotated180,
  }) {
    return FaceToFaceState(
      isEnabled: isEnabled ?? this.isEnabled,
      displayText: displayText ?? this.displayText,
      isRotated180: isRotated180 ?? this.isRotated180,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaceToFaceState &&
        other.isEnabled == isEnabled &&
        other.displayText == displayText &&
        other.isRotated180 == isRotated180;
  }

  @override
  int get hashCode => Object.hash(isEnabled, displayText, isRotated180);

  @override
  String toString() =>
      'FaceToFaceState(isEnabled: $isEnabled, displayText: $displayText, isRotated180: $isRotated180)';
}
