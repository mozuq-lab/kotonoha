/// 文字入力バッファの状態管理（Riverpod Notifier）
///
/// TASK-0038: 文字入力バッファ管理（Riverpod Notifier）
///
/// 主な機能:
/// - 文字の追加（1文字ずつ）
/// - 最後の文字の削除
/// - バッファのクリア
/// - テキストの設定（定型文挿入等）
///
/// 設計方針:
/// - Notifierによる同期的な状態管理でUI応答性を維持（100ms以内）
/// - 1000文字制限（EDGE-101）
/// - 制御文字（改行・タブ）は入力を拒否
///
/// 対応要件: REQ-002, REQ-003, REQ-004, EDGE-101
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文字入力バッファのプロバイダー
///
/// 使用例:
/// ```dart
/// // 状態の読み取り
/// final buffer = ref.watch(inputBufferProvider);
///
/// // 文字の追加
/// ref.read(inputBufferProvider.notifier).addCharacter('あ');
/// ```
final inputBufferProvider = NotifierProvider<InputBufferNotifier, String>(
  InputBufferNotifier.new,
);

/// 文字入力バッファの状態管理クラス
///
/// [Notifier]を継承し、同期的な状態更新でUI応答性を維持する。
/// 状態は[String]型で、入力された文字列を保持する。
class InputBufferNotifier extends Notifier<String> {
  /// 入力バッファの最大文字数（EDGE-101）
  static const int maxLength = 1000;

  /// 拒否する制御文字のセット
  static const Set<String> _rejectedControlChars = {'\n', '\t'};

  /// 初期状態を空文字列で構築
  @override
  String build() => '';

  /// 1文字を入力バッファに追加する
  ///
  /// [character]が空文字列、制御文字（改行・タブ）の場合は何もしない。
  /// 2文字以上の場合は最初の1文字のみ追加する。
  /// バッファが[maxLength]に達している場合は追加しない。
  void addCharacter(String character) {
    if (character.isEmpty) return;

    final charToAdd = character[0];

    // 制御文字は拒否
    if (_rejectedControlChars.contains(charToAdd)) return;

    // 最大文字数制限
    if (state.length >= maxLength) return;

    state = state + charToAdd;
  }

  /// 最後の1文字を削除する
  ///
  /// バッファが空の場合は何もしない。
  /// 将来的にはgrapheme cluster単位での削除（絵文字対応）を検討。
  void deleteLastCharacter() {
    if (state.isEmpty) return;
    state = state.substring(0, state.length - 1);
  }

  /// 入力バッファを全消去する
  void clear() {
    state = '';
  }

  /// テキストを設定する（定型文挿入等に使用）
  ///
  /// [text]が[maxLength]を超える場合は切り捨てる。
  /// 既存のテキストは上書きされる。
  void setText(String text) {
    state = text.length > maxLength ? text.substring(0, maxLength) : text;
  }
}
