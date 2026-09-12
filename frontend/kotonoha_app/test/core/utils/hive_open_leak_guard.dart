/// Hive の失敗したオープンが内部で漏らす非同期エラーを、テストの範囲で握りつぶすガード
///
/// hive_init_corruption_test.dart から切り出した（hive_init_areas_test.dart と共用）。
library;

import 'dart:async';

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
