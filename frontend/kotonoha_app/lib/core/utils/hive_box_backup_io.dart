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
library;

import 'dart:io';

/// 破損したBoxファイル（`<hivePath>/<boxName>.hive`）を
/// `<boxName>.hive.corrupt.bak`として退避する。
///
/// - [hivePath]がnullの場合（パス不明）はfalseを返す。
/// - 元ファイルが存在しない場合は退避不要とみなしtrueを返す。
/// - 既存の`.bak`ファイルがあれば上書きする。
/// - コピー処理自体が失敗した場合（I/Oエラー等）はfalseを返す。
Future<bool> backupCorruptBoxFile(String? hivePath, String boxName) async {
  if (hivePath == null) {
    return false;
  }

  try {
    final sourceFile = File('$hivePath/$boxName.hive');
    if (!await sourceFile.exists()) {
      // 【退避不要】: 元ファイルが存在しない場合、削除しても失われるデータはない
      return true;
    }

    final backupFile = File('$hivePath/$boxName.hive.corrupt.bak');
    if (await backupFile.exists()) {
      // 【既存バックアップの上書き】: 前回の破損バックアップは上書きしてよい
      await backupFile.delete();
    }
    await sourceFile.copy(backupFile.path);
    return true;
  } catch (_) {
    // 【バックアップ失敗】: ディスクフル等でコピー自体に失敗した場合、
    // 呼び出し元でデータ保全を優先（削除を中止）させるためfalseを返す
    return false;
  }
}
