/// 中のボタンの連続タップを、まとめて誤操作として無視する
///
/// 大ボタン（クイック応答）・定型文と同じ [DebounceMixin]（300ms）を、
/// StatelessWidget の中に並ぶボタンにも使えるようにする。
/// [builder] に渡す `debounced` で包んだ操作は、どれか 1 つが通ってから
/// 300ms の間、同じ [DebouncedTaps] の中のどの操作も無視される
/// （手の震えで隣のボタンに触れたときも、2 回目は読み上げない）。
library;

import 'package:flutter/widgets.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';

/// [builder] の中の操作に、まとめてデバウンスをかける
class DebouncedTaps extends StatefulWidget {
  /// 作る
  const DebouncedTaps({super.key, required this.builder});

  /// `debounced(操作)` は、デバウンスを通ったときだけ操作を行うコールバックを返す
  final Widget Function(
    BuildContext context,
    VoidCallback Function(VoidCallback action) debounced,
  ) builder;

  @override
  State<DebouncedTaps> createState() => _DebouncedTapsState();
}

class _DebouncedTapsState extends State<DebouncedTaps>
    with DebounceMixin<DebouncedTaps> {
  VoidCallback _debounced(VoidCallback action) => () {
        if (checkDebounce()) action();
      };

  @override
  Widget build(BuildContext context) => widget.builder(context, _debounced);
}
