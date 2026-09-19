/// Hive の box ファイルの中身を、バイト列で確かめる共通ヘルパー
/// ファイル目的: 「消したはずの内容が端末のファイルに残っていないか」を、
/// box の API（`keys`・`values`）ではなく実ファイルのバイト列で見る。
/// box 越しに見ると、Hive が削除の印を付けただけのフレームは「無い」ように
/// 見えるが、ファイルにも OS のバックアップにも残っている（台帳 L-119）。
/// 2 ファイル（`persisted_box_delete_test.dart`・
/// `hive_init_startup_compact_test.dart`）が同じ確かめ方をするため、ここ 1 箇所に置く。
library;

import 'dart:convert';
import 'dart:io';

/// [file] のバイト列に [text]（UTF-8）が含まれるか
///
/// Hive は文字列を UTF-8 のまま書くので、平文で探せる。
Future<bool> fileContains(File file, String text) async {
  final haystack = await file.readAsBytes();
  final needle = utf8.encode(text);
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return true;
  }
  return false;
}
