/// 保存経路の `catch` が、プログラムの誤りまで隠してしまわないための報告
///
/// 利用者を閉じ込めないために、保存経路の `catch` は広く取る（例外で
/// `_saving` が戻らなくなる方が悪い）。その代わり、拾った例外のうち
/// `Error`（`HiveError` を含む）だけは端末内のログへ出し、開発者に届ける。
/// debug とテストで見え、release でも端末内に留まる。**送信経路は作らない**
/// （ADR-009）。台帳 L-162(a)。
///
/// provider からも presentation からも呼ぶので、presentation には置かない。
library;

import 'package:flutter/foundation.dart';

/// [error] が `Error` なら端末内のログへ出す。例外（`Exception`）は何もしない。
///
/// `Exception` は想定済みの失敗（利用者へは呼び出し側が穏当な文で伝える）だが、
/// `Error` はプログラムの誤りなので、穏当な文に隠したままにしない。
void reportProgrammingError(Object error, StackTrace stack) {
  if (error is! Error) return;
  FlutterError.reportError(FlutterErrorDetails(
    exception: error,
    stack: stack,
    library: 'kotonoha preset_phrase',
  ));
}
