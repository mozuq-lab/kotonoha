/// 【Box破損バックアップ: 既定実装（dart:io非対応環境向け）】
///
/// [dart.library.io]が利用できない環境（主にWeb）向けの既定実装。
/// Web版Hive（IndexedDBバックエンド）はローカルファイルパスの概念を持たないため、
/// 破損したBoxファイルを退避（バックアップ）する手段がない。
/// 常にfalseを返し、呼び出し元（openBoxWithRecovery）にデータ保全を優先させる
/// （＝バックアップできない場合はBoxを削除しない）。
///
/// 実際のファイルシステム上でのバックアップ実装は[hive_box_backup_io.dart]を参照。
///
/// 🔵 信頼性レベル: 青信号 - Codexレビュー指摘（P1: Hive復旧処理が非破損エラーでも
/// データを削除する問題）への対応
library;

/// 破損したBoxファイル（`<hivePath>/<boxName>.hive`）を
/// `<boxName>.hive.corrupt.bak`として退避する。
///
/// [hivePath]がnull、またはこのプラットフォームでバックアップ手段がない場合はfalseを返す。
Future<bool> backupCorruptBoxFile(String? hivePath, String boxName) async {
  return false;
}
