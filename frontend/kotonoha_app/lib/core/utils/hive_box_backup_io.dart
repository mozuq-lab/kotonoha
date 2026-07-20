/// 【Box破損バックアップ: dart:io実装】
///
/// [dart.library.io]が利用可能な環境（iOS/Android/デスクトップ、および
/// `flutter test`実行時のDart VM）向けの実装。
/// Hiveの破損検知（[HiveError]・[FormatException]・[RangeError]）により
/// Boxファイルを削除する前に、削除前の状態を`<boxName>.hive.corrupt.bak`として
/// 退避する。バックアップに失敗した場合はfalseを返し、呼び出し元
/// （openBoxWithRecovery）にデータ保全を優先させる（＝削除を中止する）。
///
/// 🔵 信頼性レベル: 青信号 - Codexレビュー指摘（P1: Hive復旧処理が非破損エラーでも
/// データを削除する問題）への対応
///
/// 【Codexレビュー追加指摘（P1）】: HiveはBox名を内部で小文字化してから
/// ファイル名を組み立てる（hive 2.2.3 `hive_impl.dart`の`_openBox`内
/// `name = name.toLowerCase();`、および`backend/vm/backend_manager.dart`の
/// `findHiveFileAndCleanUp`内`'$path$_delimiter$name.hive'`で確認済み）。
/// そのため、camelCaseのBox名（例: `presetPhrases`）の実ファイルは
/// `presetphrases.hive`になる。呼び出し元から渡された大小文字のまま
/// パスを組み立てると、Android/Linux等の大小文字を区別するファイルシステムでは
/// 実際のBoxファイルを発見できず、「元ファイル不存在→バックアップ不要（true）」
/// と誤判定してしまい、後続の`Hive.deleteBoxFromDisk`がバックアップなしで
/// 実ファイルを削除してしまう。これを防ぐため、[resolveBoxFilePath]・
/// [resolveBoxBackupFilePath]でHiveと同じ小文字化規則を適用してパスを構築する。
library;

import 'dart:io';

/// Hiveと同じBox名→ファイル名変換規則（小文字化）で、Boxの実ファイルパスを解決する。
///
/// hive 2.2.3のソースコード（`lib/src/hive_impl.dart`の`_openBox`が
/// `name = name.toLowerCase();`でBox名を小文字化してから
/// `lib/src/backend/vm/backend_manager.dart`の`findHiveFileAndCleanUp`に渡し、
/// そこで`'$path$_delimiter$name.hive'`としてファイル名を組み立てる）を確認した結果、
/// Box名の大小文字に関わらず実ファイル名は常に小文字になることを確認済み。
///
/// この関数はその規則のみを純粋に反映した小さな関数であり、副作用（I/O）を持たない。
/// パス構築ロジックが正しく小文字を返すことを、ファイルシステムの大小文字区別に
/// 依存せずユニットテストで直接検証できるようにするために公開している
/// （macOS等の大小文字非区別環境でのテスト実行では、パス構築が誤っていても
/// 偶然ファイルが見つかってテストが green になってしまい、回帰を検出できないため）。
///
/// 🔵 信頼性レベル: 青信号 - hive 2.2.3のソースコードで確認済み
String resolveBoxFilePath(String hivePath, String boxName) {
  return '$hivePath/${boxName.toLowerCase()}.hive';
}

/// 破損Boxのバックアップファイルパスを、Hiveと同じ小文字化規則で解決する。
///
/// [resolveBoxFilePath]参照。バックアップファイル自体はHiveが管理する
/// ファイルではないが、対応する実Boxファイルと同じ命名規則（小文字化）を
/// 適用することで、大小文字混在によるパスの不整合を避ける。
String resolveBoxBackupFilePath(String hivePath, String boxName) {
  return '$hivePath/${boxName.toLowerCase()}.hive.corrupt.bak';
}

/// 破損したBoxファイル（Hiveの実ファイル: `resolveBoxFilePath(hivePath, boxName)`）を
/// `resolveBoxBackupFilePath(hivePath, boxName)`として退避する。
///
/// - [hivePath]がnullの場合（パス不明）はfalseを返す。
/// - Hiveと同じ小文字化規則で解決した実ファイルが存在しない場合、削除対象自体が
///   存在しない（＝これから[Hive.deleteBoxFromDisk]を呼んでも失われるデータは
///   ない）とみなし、退避不要としてtrueを返す。大小文字を区別しない実装だった
///   旧バージョンでは、この分岐が「大小文字の不一致で見つけられなかっただけ」
///   のケースでも誤って成立してしまい、実際には存在するBoxファイルが
///   バックアップなしで削除される不具合があった（Codexレビュー指摘 P1）。
///   小文字化修正後は、この分岐に到達するのは本当にファイルが存在しない
///   場合のみである。
/// - 既存の`.bak`ファイルがあれば上書きする。
/// - コピー処理自体が失敗した場合（I/Oエラー等）はfalseを返す。
/// - コピー後、バックアップファイルが実際に存在し、かつ元ファイルと
///   同一バイト長であることを検証する。検証に失敗した場合はバックアップが
///   不完全である可能性が高いため、falseを返し呼び出し元にデータ保全を
///   優先（削除を中止）させる。
Future<bool> backupCorruptBoxFile(String? hivePath, String boxName) async {
  if (hivePath == null) {
    return false;
  }

  try {
    final sourceFile = File(resolveBoxFilePath(hivePath, boxName));
    if (!await sourceFile.exists()) {
      // 【退避不要】: Hiveと同じ小文字化規則で解決した実ファイルが存在しない
      // 場合、これから削除しても失われるデータはない
      return true;
    }

    final backupFile = File(resolveBoxBackupFilePath(hivePath, boxName));
    if (await backupFile.exists()) {
      // 【既存バックアップの上書き】: 前回の破損バックアップは上書きしてよい
      await backupFile.delete();
    }
    await sourceFile.copy(backupFile.path);

    // 【バックアップ検証】: コピー後にバックアップファイルの存在と
    // 元ファイルと同一バイト長であることを検証してから成功とみなす。
    // 検証に失敗した場合、バックアップが不完全な可能性があるため、
    // 呼び出し元でデータ保全を優先（削除を中止）させるためfalseを返す。
    if (!await backupFile.exists()) {
      return false;
    }
    final sourceLength = await sourceFile.length();
    final backupLength = await backupFile.length();
    if (sourceLength != backupLength) {
      return false;
    }
    return true;
  } catch (_) {
    // 【バックアップ失敗】: ディスクフル等でコピー自体に失敗した場合、
    // 呼び出し元でデータ保全を優先（削除を中止）させるためfalseを返す
    return false;
  }
}
