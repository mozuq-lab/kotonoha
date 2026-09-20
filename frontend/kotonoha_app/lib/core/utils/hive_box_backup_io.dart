/// 破損したHive Boxを削除する前に退避する。
/// バックアップに失敗した場合はfalseを返し、呼び出し元に削除を中止させる。
/// Box名はHiveと同じ小文字化規則で扱い、大小文字を区別する環境でも元ファイルを見つける。
library;

import 'dart:io';

/// 書きかけの退避（`<box>.hive.corrupt.bak.tmp`）が残っていれば片付ける。
/// 写している最中にプロセスが落ちると残り、**利用者の発話を含む写しが端末に残って
/// OSのバックアップにも乗る**。次に破損するまで誰も消さないので、box が正常に
/// 開けたときに片付ける（`openBoxWithRecovery`が呼ぶ。台帳 L-114）。
/// 消せなくても呼び出し元は何も変えない（次の退避が上書きする）。
Future<void> removeStaleBackupStaging(String? hivePath, String boxName) async {
  if (hivePath == null) {
    return;
  }
  try {
    final stagingFile =
        File('${resolveBoxBackupFilePath(hivePath, boxName)}.tmp');
    if (await stagingFile.exists()) {
      await stagingFile.delete();
    }
  } catch (_) {
    // 片付けに失敗しても、box の利用には影響しない
  }
}

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
/// 既存のバックアップは置き換える。元ファイルがなければ退避不要としてtrueを返す。
/// パス不明・I/O失敗・サイズ不一致はfalseを返し、呼び出し元に削除を中止させる。
/// 置き換えは**一時名へ書き切ってから rename** で行う（台帳 L-114）。古い退避を
/// 先に消すと、写しに失敗したとき新旧どちらの退避も残らない。そのとき元のBoxには
/// 手を付けないのでBoxの中身は無事だが、**前回の破損で退避した分**（もう元の
/// ファイルには無いデータ）は永久に失われる。
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
    // 一時名へ書き切ってから入れ替える（台帳 L-114）。ここで失敗しても、
    // 前回の退避は退避の場所に残ったままになる。
    final stagingFile = File('${backupFile.path}.tmp');
    try {
      await sourceFile.copy(stagingFile.path);

      // バックアップ検証: コピー後にファイルの存在と元ファイルと同一バイト長で
      // あることを検証してから入れ替える。検証に失敗した場合、バックアップが
      // 不完全な可能性があるため、入れ替えずに（＝前回の退避を残したまま）
      // 呼び出し元でデータ保全を優先（削除を中止）させるためfalseを返す。
      if (!await stagingFile.exists()) {
        return false;
      }
      final sourceLength = await sourceFile.length();
      final stagedLength = await stagingFile.length();
      if (sourceLength != stagedLength) {
        return false;
      }

      // 中身をディスクへ確定させてから入れ替える。rename の順序は保たれるが、
      // hive と同じく書き込みの永続化までは保証されないので、入れ替えた直後に
      // 電源が落ちると「前回の退避は消え、新しい退避は中身が無い」になりうる
      // （台帳 L-126 と同じ窓。退避は破損時にしか通らないので、ここは fsync する）
      final staged = await stagingFile.open(mode: FileMode.append);
      try {
        await staged.flush();
      } finally {
        await staged.close();
      }

      // 入れ替え: 同じディレクトリ内の rename なので、宛先は旧版か新版のどちらか
      await stagingFile.rename(backupFile.path);
      return true;
    } finally {
      // 書きかけの一時ファイルを残さない（消せなくても退避の成否は変えない）
      try {
        if (await stagingFile.exists()) {
          await stagingFile.delete();
        }
      } catch (_) {
        // 一時ファイルの後始末に失敗しても、上の判定を覆さない
      }
    }
  } catch (_) {
    // バックアップ失敗: ディスクフル等でコピー自体に失敗した場合
    // 呼び出し元でデータ保全を優先（削除を中止）させるためfalseを返す
    return false;
  }
}
