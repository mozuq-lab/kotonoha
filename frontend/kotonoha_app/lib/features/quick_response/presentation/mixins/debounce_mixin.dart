/// デバウンス処理ミックスイン
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
///
/// ボタンの連続タップを防止するためのデバウンス機能を提供。
/// State クラスにミックスインして使用する。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_constants.dart';

/// デバウンス処理を提供するミックスイン
///
/// 連続タップによる誤操作を防止するため、指定期間内の
/// 重複タップを無視する機能を提供。
///
/// 使用例:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with DebounceMixin {
///   void _handleTap() {
///     if (!checkDebounce()) return;
///     // タップ処理
///   }
/// }
/// ```
mixin DebounceMixin<T extends StatefulWidget> on State<T> {
  /// 最後にタップされた時刻
  DateTime? _lastTapTime;

  /// デバウンスチェックを行い、タップを許可するかを返す
  ///
  /// [durationMs] デバウンス期間（ミリ秒）。省略時はデフォルト値を使用。
  ///
  /// 戻り値:
  /// - true: タップを許可（デバウンス期間外）
  /// - false: タップを拒否（デバウンス期間内）
  bool checkDebounce({int? durationMs}) {
    final now = DateTime.now();
    final duration = durationMs ?? QuickResponseConstants.debounceDurationMs;

    if (_lastTapTime != null) {
      final difference = now.difference(_lastTapTime!).inMilliseconds;
      if (difference < duration) {
        return false;
      }
    }

    _lastTapTime = now;
    return true;
  }

  /// デバウンス状態をリセット
  ///
  /// テストやウィジェット再構築時に使用。
  void resetDebounce() {
    _lastTapTime = null;
  }
}
