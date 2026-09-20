/// Hive の失敗したオープンが残していく後始末を、テストの範囲で吸収するガード
///
/// hive 2.2.3 は `Hive.openBox` が失敗すると、失敗した box の `close()` を
/// **await せずに** 呼ぶ（`hive_impl.dart:117`）。この後始末が 2 つの形で
/// テストへ漏れるので、それぞれに 1 つずつ道具を置く。
/// [runGuardingHiveOpenLeak]: 誰も await しない Future のエラーがゾーンへ漏れる形。
/// [closeHiveIgnoringMissingLock]: 後始末が `.lock` を消した後で閉じる形。
/// hive_init_corruption_test.dart から切り出した（hive_init_* で共用）。
library;

import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';

/// テストヘルパー: Hiveパッケージ内部の既知の非同期リークを吸収して[body]を実行する
/// 背景: hive 2.2.3では、`Hive.openBox`が失敗すると内部の
/// `HiveImpl._openBox`が`_openingBoxes`用の`Completer`へ
/// `completer.completeError(error, stackTrace)`を呼ぶ。このCompleterの
/// Futureは（同名Boxを並行してオープンする別呼び出しがない限り）誰にも
/// awaitされないため、Dartのゾーンにハンドルされない非同期エラーとして
/// 別途リークする。これは本関数（openBoxWithRecovery）の実装の正しさとは
/// 無関係なHiveパッケージ側の既知の挙動であり、`crashRecovery: false`で
/// 意図的に例外を発生させるテストでは必ず観測される。
/// runZonedGuardedでこの既知のリークのみを握りつぶし、テスト対象の
/// 戻り値・例外送出の有無だけを検証できるようにする。
Future<T> runGuardingHiveOpenLeak<T>(Future<T> Function() body) async {
  final completer = Completer<T>();
  // unawaited の理由: この Future は意図的に await しない。完了は completer で
  // 受け取る。`unawaited_futures`（analysis_options.yaml）に対して「書き忘れではなく
  // 意図的な fire-and-forget である」ことを明示する。
  unawaited(runZonedGuarded(() async {
    try {
      completer.complete(await body());
    } catch (e, s) {
      completer.completeError(e, s);
    }
  }, (error, stackTrace) {
    // Hive内部のFire-and-Forgetによる既知のリークを無視する
  }));
  return completer.future;
}

/// テストヘルパー: `.lock` が既に消えていても Hive を閉じ切る
///
/// 背景: `openBoxWithRecovery` は壊れた box を最大 3 回開く（自動復旧なし →
/// 退避して救出 → 削除して作り直し）。失敗したオープンごとに、hive が await せずに
/// 始めた後始末が残り、その `_closeInternal` は `.lock` を削除する
/// （`storage_backend_vm.dart:210-216`）。この後始末が、最後に開き直した box が
/// 作った `.lock` を後から消すことがあり、そうなるとテストの後片付けの
/// `Hive.close()` が `PathNotFoundException` になる（台帳 L-124）。
/// 吸収してよい理由: 例外が出るのは `_closeInternal` の最後の unlink だけで、
/// その前に fd の close と `hive.unregisterBox` は終わっている
/// （`box_base_impl.dart:166-174`）。**その box について消したい状態（閉じていて
/// `.lock` が無い）には既に達している。**
/// 本番は box を閉じない（`lib` に `Hive.close()` も `box.close()` も無い。
/// `Hive.deleteBoxFromDisk` は open に失敗した box を対象にするので登録されておらず、
/// ファイルの有無を見る削除に落ちる）ので、この形で落ちるのはテストの後片付けだけ。
/// **消えた `.lock` の削除失敗だけ**を吸収し、それ以外は投げ直す。
/// 吸収したら閉じ直す理由: `Hive.close()` は `Future.wait` なので、複数の box が
/// 失敗しても**最初のエラーしか伝わらない**（残りは捨てられる。`hive_impl.dart:209-215`、
/// `Future.wait` は既定で `eagerError: false`）。消えた `.lock` がその 1 つ目だと、
/// 後ろの box の本当の失敗が見えなくなる。吸収するたびに閉じ直せば、その失敗が
/// 表に出る。例外まで進んだ box は登録が外れているので閉じ直しの対象にならず、
/// 開いている box の数だけで必ず終わる。
/// [close] は差し替え用（既定は `Hive.close`）。
Future<void> closeHiveIgnoringMissingLock({
  Future<void> Function()? close,
}) async {
  final closeAll = close ?? Hive.close;
  for (var attempt = 0; attempt < _maxCloseAttempts; attempt++) {
    try {
      await closeAll();
      return;
    } on PathNotFoundException catch (error) {
      if (error.path?.endsWith('.lock') != true) rethrow;
    }
  }
  // 閉じるたびに消えた `.lock` が出続けるのは想定外（開いている box は有限で、
  // 失敗した box は登録が外れる）。最後の結果は隠さない
  await closeAll();
}

/// 閉じ直しの上限。同時に開く box はアプリで 3 つ、テストでも数個なので十分に多い
const _maxCloseAttempts = 8;
