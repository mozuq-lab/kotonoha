/// 破損したHive Boxを削除する前に退避する。
/// バックアップに失敗した場合はfalseを返し、呼び出し元に削除を中止させる。
/// Box名はHiveと同じ小文字化規則で扱い、大小文字を区別する環境でも元ファイルを見つける。
library;

import 'dart:io';

/// Hiveと同じ小文字のBox名でファイルパスを解決する。
/// 大小文字を区別しないファイルシステムでは誤ったパスでもファイルが見つかるため、
/// I/Oから分離してパス自体をテストできるようにする。
String resolveBoxFilePath(String hivePath, String boxName) {
  return '$hivePath/${boxName.toLowerCase()}.hive';
}

/// バックアップにも[resolveBoxFilePath]と同じ小文字化規則を使う。
String resolveBoxBackupFilePath(String hivePath, String boxName) {
  return '$hivePath/${boxName.toLowerCase()}.hive.corrupt.bak';
}

/// Boxを`.hive.corrupt.bak`へコピーし、元ファイルと同じバイト長であることを確認する。
/// 既存のバックアップは上書きする。元ファイルがなければ退避不要としてtrueを返す。
/// パス不明・I/O失敗・サイズ不一致はfalseを返し、呼び出し元に削除を中止させる。
Future<bool> backupCorruptBoxFile(String? hivePath, String boxName) async {
  if (hivePath == null) {
    return false;
  }

  try {
    final sourceFile = File(resolveBoxFilePath(hivePath, boxName));
    if (!await sourceFile.exists()) {
      // 退避不要: Hiveと同じ小文字化規則で解決した実ファイルが存在しない
      // 場合、これから削除しても失われるデータはない
      return true;
    }

    final backupFile = File(resolveBoxBackupFilePath(hivePath, boxName));
    if (await backupFile.exists()) {
      // 既存バックアップの上書き: 前回の破損バックアップは上書きしてよい
      await backupFile.delete();
    }
    await sourceFile.copy(backupFile.path);

    // バックアップ検証: コピー後にバックアップファイルの存在と
    // 元ファイルと同一バイト長であることを検証してから成功とみなす。
    // 検証に失敗した場合、バックアップが不完全な可能性があるため
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
    // バックアップ失敗: ディスクフル等でコピー自体に失敗した場合
    // 呼び出し元でデータ保全を優先（削除を中止）させるためfalseを返す
    return false;
  }
}
