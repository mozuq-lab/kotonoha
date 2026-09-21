/// 文字入力バッファの状態管理（Riverpod Notifier）
/// 主な機能
/// 文字の追加（1文字ずつ）
/// 最後の文字の削除
/// バッファのクリア
/// テキストの設定（定型文挿入等）
/// 設計方針
/// Notifierによる同期的な状態管理でUI応答性を維持（100ms以内）
/// 1000文字制限
/// 制御文字（改行・タブ）は入力を拒否
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/character_board/domain/dakuten_converter.dart';

/// 文字入力バッファのプロバイダー
/// 使用例
/// ```dart
/// 状態の読み取り
/// final buffer = ref.watch(inputBufferProvider);
/// 文字の追加
/// ref.read(inputBufferProvider.notifier).addCharacter('あ');
/// ```
final inputBufferProvider = NotifierProvider<InputBufferNotifier, String>(
  InputBufferNotifier.new,
);

/// 入力バッファが上限（[InputBufferNotifier.maxLength]）に達しているか
/// 上限で黙って捨てるのではなく、利用者に伝えるための派生状態（EDGE-101、台帳 L-73）。
final inputLimitReachedProvider = Provider<bool>(
  (ref) =>
      ref.watch(inputBufferProvider).length >= InputBufferNotifier.maxLength,
);

/// 直近のテキスト設定で超過分を切り詰めたか。削除・全消去・次の設定で解除する。
final inputWasTruncatedProvider = Provider<bool>(
  (ref) => ref.watch(_inputTruncationProvider),
);

final _inputTruncationProvider =
    NotifierProvider<_InputTruncationNotifier, bool>(
  _InputTruncationNotifier.new,
);

class _InputTruncationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool truncated) => state = truncated;
}

/// 文字入力バッファの状態管理クラス
/// [Notifier]を継承し、同期的な状態更新でUI応答性を維持する。
/// 状態は[String]型で、入力された文字列を保持する。
class InputBufferNotifier extends Notifier<String> {
  /// 入力バッファの最大文字数
  static const int maxLength = 1000;

  /// 拒否する制御文字のセット
  static const Set<String> _rejectedControlChars = {'\n', '\t'};

  /// 初期状態を空文字列で構築
  @override
  String build() => '';

  /// 1文字を入力バッファに追加する
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
  /// バッファが空の場合は何もしない。
  /// 将来的にはgrapheme cluster単位での削除（絵文字対応）を検討。
  void deleteLastCharacter() {
    if (state.isEmpty) return;
    ref.read(_inputTruncationProvider.notifier).update(false);
    state = state.substring(0, state.length - 1);
  }

  /// 入力バッファを全消去する
  void clear() {
    ref.read(_inputTruncationProvider.notifier).update(false);
    state = '';
  }

  /// テキストを設定する（定型文挿入等に使用）
  /// [text]が[maxLength]を超える場合は切り捨てる。
  /// 既存のテキストは上書きされる。
  void setText(String text) {
    ref.read(_inputTruncationProvider.notifier).update(text.length > maxLength);
    state = text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  /// 入力バッファ末尾の文字を濁音化（または清音に戻すトグル）する
  /// 文字盤の「゛」キー用。バッファが空、または変換不能な文字の場合は
  /// 何もしない（無視する）。
  void applyDakuten() {
    if (state.isEmpty) return;

    final lastChar = state[state.length - 1];
    final converted = DakutenConverter.applyDakuten(lastChar);
    if (converted == null) return;

    state = state.substring(0, state.length - 1) + converted;
  }

  /// 入力バッファ末尾の文字を半濁音化（または清音に戻すトグル）する
  /// 文字盤の「゜」キー用。バッファが空、または変換不能な文字の場合は
  /// 何もしない（無視する）。
  void applyHandakuten() {
    if (state.isEmpty) return;

    final lastChar = state[state.length - 1];
    final converted = DakutenConverter.applyHandakuten(lastChar);
    if (converted == null) return;

    state = state.substring(0, state.length - 1) + converted;
  }
}
