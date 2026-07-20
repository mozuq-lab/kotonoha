import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/utils/hive_box_backup.dart'
    if (dart.library.io) 'package:kotonoha_app/core/utils/hive_box_backup_io.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import 'package:path_provider/path_provider.dart';

/// 【定数定義】: [HiveError.message]に含まれる場合に「データ破損」を意味する部分文字列
///
/// hive 2.2.3のソース（storage_backend_vm.dart、binary_reader_impl.dart等）を
/// 確認した限り、実際のバイナリ破損（チェックサム不一致・ファイル末尾の予期しない
/// 切断・不正なキー種別）を示す[HiveError]は、いずれも"checksum"・"corrupted"・
/// "unexpected eof"のいずれかを含む。
/// 一方、[HiveError]は「Boxが既に別の型で開かれている」
/// （例: `The box "x" is already open and of type Box<Y>.`）や
/// 「同じtypeIdのTypeAdapterが既に登録されている」等、データ破損とは無関係な
/// 使用方法エラーでも送出されるため、[HiveError]であることのみをもって
/// 削除対象と判定してはならない（Codexレビュー指摘1(a)）。
const _hiveCorruptionMessageMarkers = [
  'checksum',
  'corrupted',
  'unexpected eof'
];

/// 【関数定義】: 破損した例外のみを「削除して良い」対象として判定する
///
/// 【実装内容】: [FormatException]・[RangeError]は、Hiveのバイナリフォーマット
/// 自体が壊れていることを示す例外であり、Boxファイルを削除して作り直す以外に
/// 復旧手段がない。[HiveError]は上記の破損関連メッセージを含む場合のみ削除対象とする
/// （[_hiveCorruptionMessageMarkers]参照）。
/// 一方、[FileSystemException]（ディスクフル・権限エラー等）や、
/// 「既に別の型でオープン済み」等の使用方法エラーを示す[HiveError]、
/// その他の未分類の例外は、データ自体は壊れていない可能性が高いため、
/// ここには含めない（＝呼び出し元でBoxを削除させない）。
///
/// 【設計判断】: 「本当にデータが壊れている」と確信できる例外のみを許可リスト化する
/// （ホワイトリスト方式）。未知の例外は安全側（＝削除しない）に倒す。
///
/// 🔵 信頼性レベル: 青信号 - Codexレビュー指摘（P1: Hive復旧処理が非破損エラーでも
/// データを削除する問題、および1(a): HiveErrorの中に破損以外の原因が
/// 含まれるべきでない点）への対応
bool _isCorruptionError(Object error) {
  if (error is FormatException || error is RangeError) {
    return true;
  }
  if (error is HiveError) {
    final lowerMessage = error.message.toLowerCase();
    return _hiveCorruptionMessageMarkers.any(lowerMessage.contains);
  }
  return false;
}

/// 【関数定義】: Box破損時の復旧つきオープン処理
///
/// 【実装内容】: [Hive.openBox]でBoxをオープンする。オープンに失敗した場合、
/// 例外の種類によって扱いを分岐する。
///
/// - データ破損を示す例外（[HiveError]・[FormatException]・[RangeError]、
///   [_isCorruptionError]参照）: 削除前に破損Boxファイルを
///   `<boxName>.hive.corrupt.bak`として退避（[backupCorruptBoxFile]）した上で
///   [Hive.deleteBoxFromDisk]により削除し、再オープンを試みる。
///   バックアップ自体に失敗した場合は、データ保全を優先して削除を中止しnullを返す。
/// - それ以外の例外（[FileSystemException]によるディスクフル・権限エラー等、
///   環境起因の可能性がある失敗）: Boxを削除せずnullを返す。
///
/// いずれの場合も、復旧が不可能な場合は例外を再送出せずnullを返し、
/// 呼び出し側はインメモリフォールバック（Box未オープン扱い）として
/// 継続できるようにする。
///
/// 【設計判断】: アプリ起動不能を防ぐことに加え、履歴・定型文・お気に入り等の
/// 端末内にしか存在しない復元不能なユーザーデータを、非破損エラーで
/// 無言のまま失わないことを最優先とする。
///
/// 【テスト対応】: TC-059-006（Hive Box破損時の復旧処理）
/// 🔵 信頼性レベル: 青信号 - NFR-301（基本機能継続）、NFR-304、
/// Codexレビュー指摘（P1）に基づく
///
/// [crashRecovery]はテスト用のフック。既定値の`true`ではHive自身が持つ
/// フレーム単位の自動復旧が先に働くため、本関数のcatch節（削除→再オープン）まで
/// 到達するのは自動復旧でも救えない破損時のみとなる。テストで確実にcatch節を
/// 検証したい場合は`false`を渡し、Hive側の自動復旧を無効化する。
///
/// [hivePath]はBoxファイルが格納されているディレクトリのパス（Hiveの
/// ホームディレクトリ）。破損時のバックアップ退避に使用する。不明な場合は
/// nullを渡してよい（その場合、破損時のバックアップは行えないため、
/// データ保全を優先して削除は行われない）。
///
/// 戻り値: オープンに成功した[Box]。復旧を含めて失敗した場合はnull。
Future<Box<T>?> openBoxWithRecovery<T>(
  String name, {
  bool crashRecovery = true,
  String? hivePath,
}) async {
  try {
    return await Hive.openBox<T>(name, crashRecovery: crashRecovery);
  } catch (error, stackTrace) {
    // 【破損検知ログ】: Box破損等でオープンに失敗した際に記録する
    // 🟡 黄信号: NFR-304から類推
    debugPrint('[hive_init] Box "$name" のオープンに失敗しました: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (!_isCorruptionError(error)) {
      // 【環境起因エラー: 削除しない】: ディスクフル・権限エラー等、
      // データ自体は壊れていない可能性が高い失敗ではBoxファイルを削除せず、
      // nullを返してインメモリフォールバックに委ねる。
      // これにより、履歴・定型文・お気に入り等の復元不能なユーザーデータを
      // 一時的な環境エラーで無言のまま失うことを防ぐ。
      // 🔵 信頼性レベル: 青信号 - Codexレビュー指摘（P1）に基づく
      debugPrint(
        '[hive_init] Box "$name" は環境起因のエラーの可能性があるため、'
        '削除せずインメモリフォールバックで継続します: $error',
      );
      return null;
    }

    // 【復旧処理: バックアップ】: 破損したBoxファイルを削除する前に退避する。
    // バックアップに失敗した場合（パス不明・I/Oエラー等）は、削除してしまうと
    // データが完全に失われるため、データ保全を優先して削除を中止しnullを返す。
    // 🔵 信頼性レベル: 青信号 - Codexレビュー指摘（P1）に基づく
    final backedUp = await backupCorruptBoxFile(hivePath, name);
    if (!backedUp) {
      debugPrint(
        '[hive_init] Box "$name" の破損ファイルのバックアップに失敗したため、'
        'データ保全を優先して削除を中止します。インメモリフォールバックで継続します。',
      );
      return null;
    }

    // 【復旧処理: 削除】: バックアップ退避済みの破損Boxファイルを削除する
    // 🔵 信頼性レベル: 青信号 - test/core/utils/hive_init_corruption_test.dartの復旧パターンに基づく
    //
    // 【大小文字に関する確認】: [Hive.deleteBoxFromDisk]は内部で`name`を
    // 小文字化してからファイルを解決・削除するため（hive 2.2.3 hive_impl.dartの
    // `deleteBoxFromDisk`内`name.toLowerCase()`）、ここで渡す`name`（呼び出し元の
    // 大小文字のまま）をこちらで小文字化する必要はない。大小文字の不一致に
    // 起因する問題は[backupCorruptBoxFile]側（hive_box_backup_io.dartの
    // resolveBoxFilePath/resolveBoxBackupFilePath）でのみ対応が必要だった
    // （Codexレビュー指摘 P1）。
    //
    // 【削除失敗を致命的エラーにしない理由】: Hive内部では、openBox失敗時の
    // クリーンアップ（失敗したBoxインスタンスのclose()）がawaitされず
    // 実行される（hiveパッケージ内部の既知の挙動）。このクリーンアップも
    // 対象ファイル（.lock等）の削除を行うため、本関数のdeleteBoxFromDisk呼び出しと
    // 競合し、「削除しようとしたファイルが（クリーンアップにより）既に存在しない」
    // という無害な競合でdeleteBoxFromDisk自体が例外を投げることがある。
    // この場合でも実質的にはBoxファイルは既に片付いているため、削除の成否では
    // 復旧を諦めず、最終的な再オープンの成否のみで復旧成功/失敗を判定する。
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (deleteError) {
      debugPrint(
        '[hive_init] Box "$name" の破損ファイル削除中にエラーが発生しました'
        '（既に削除済みの可能性）。再オープンを試みます: $deleteError',
      );
    }

    try {
      // 【復旧処理: 再オープン】: 削除後にBoxを再オープンする
      final recovered = await Hive.openBox<T>(name);
      debugPrint('[hive_init] Box "$name" の復旧に成功しました');
      return recovered;
    } catch (recoveryError, recoveryStackTrace) {
      // 【復旧失敗】: 再オープンも失敗した場合はnullを返し、インメモリフォールバックへ委ねる
      // 🟡 黄信号: NFR-301（基本機能継続）を満たすための実装
      debugPrint(
        '[hive_init] Box "$name" の復旧に失敗しました。インメモリフォールバックで継続します: $recoveryError',
      );
      debugPrintStack(stackTrace: recoveryStackTrace);
      return null;
    }
  }
}

/// 【TypeAdapter登録】: 指定されたtypeIdが未登録の場合のみ[adapter]を登録する
///
/// 【実装内容】: Hot Restart時等の重複登録エラーを防ぐための冪等な登録処理
/// 🔵 信頼性レベル: 青信号 - REQ-5003、TASK-0014の実装詳細に基づく
void _registerAdapterSafely<T>(TypeAdapter<T> adapter) {
  try {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  } catch (error) {
    // 【エラーハンドリング】: 重複登録エラーを無視（アプリの安定性維持）
    // 🟡 黄信号: NFR-301、NFR-304から類推、Hiveの一般的なエラーケース
    debugPrint(
      '[hive_init] TypeAdapter(typeId=${adapter.typeId}) の登録に失敗しました: $error',
    );
  }
}

/// 【関数定義】: Hive初期化処理
/// 【実装内容】: Hive.initFlutter()、TypeAdapter登録、ボックスオープンを順に実行
/// 【テスト対応】:
///   - TC-001: Hive初期化が正常に完了し、ボックスがオープンできることを確認
///   - TC-002: HistoryItemAdapterとPresetPhraseAdapterが正しく登録されることを確認
///   - TC-003: 同じTypeAdapterを2回登録しようとした場合のエラーハンドリングを確認
///   - TC-059-006: Hive Box破損時に復旧し、アプリ起動不能に陥らないことを確認
/// 🔵 信頼性レベル: 青信号 - REQ-5003、TASK-0014の実装詳細に基づく
///
/// 【破損時の継続動作】: 各Boxのオープンは個別にtry/catchされ、復旧不可能な場合でも
/// 例外を外部に投げない。該当するBoxは未オープンのまま扱われ、
/// `repository_providers`側のnullフォールバックによりインメモリ動作で継続する。
Future<void> initHive() async {
  // 【Hive初期化】: Flutter環境用のHive初期化
  // 【実装内容】: ローカルストレージのパス設定とHive環境の準備
  // 【テスト対応】: TC-001の前提条件
  // 🔵 信頼性レベル: 青信号 - Hive公式ドキュメントに基づく
  await Hive.initFlutter();

  // 【バックアップ用パス取得】: Box破損時の復旧（openBoxWithRecovery）で、削除前に
  // Boxファイルを退避できるよう、Hive.initFlutter()と同じ場所
  // （アプリのドキュメントディレクトリ）のパスを取得しておく。
  // Web環境（kIsWeb）ではIndexedDBバックエンドが使われファイルパスの概念が
  // ないため取得しない（nullのまま。バックアップは行われず、破損時は
  // データ保全を優先してBoxを削除しない）。
  // 🔵 信頼性レベル: 青信号 - hive_flutterのinitFlutter()実装
  // （getApplicationDocumentsDirectoryでHive.init()する）と同じ参照先を得るための実装
  String? hivePath;
  if (!kIsWeb) {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      hivePath = appDir.path;
    } catch (error) {
      // 【パス取得失敗時のフォールバック】: パスが取得できなくても初期化自体は
      // 継続する。この場合、破損時のバックアップは行われずBoxは削除されない
      // （データ保全を優先）。
      debugPrint('[hive_init] Hiveのホームディレクトリ取得に失敗しました: $error');
    }
  }

  // 【TypeAdapter登録】: HistoryItemAdapterの登録
  // 【実装内容】: typeId 0としてHistoryItemAdapterを登録（重複登録時はtry-catchで無視）
  // 【テスト対応】: TC-002、TC-003
  // 🔵 信頼性レベル: 青信号 - REQ-601（履歴自動保存）の基盤
  _registerAdapterSafely(HistoryItemAdapter());

  // 【TypeAdapter登録】: PresetPhraseAdapterの登録
  // 【実装内容】: typeId 1としてPresetPhraseAdapterを登録（重複登録時はtry-catchで無視）
  // 【テスト対応】: TC-002、TC-003
  // 🔵 信頼性レベル: 青信号 - REQ-104（定型文機能）の基盤
  _registerAdapterSafely(PresetPhraseAdapter());

  // 【ボックスオープン】: historyボックスのオープン（破損時は復旧を試み、失敗時はnull継続）
  // 【実装内容】: 'history'という名前でHistoryItem用のボックスをオープン
  // 【テスト対応】: TC-001の検証項目、TC-059-006
  // 🔵 信頼性レベル: 青信号 - REQ-601（履歴自動保存）の実現
  await openBoxWithRecovery<HistoryItem>('history', hivePath: hivePath);

  // 【ボックスオープン】: presetPhrasesボックスのオープン（破損時は復旧を試み、失敗時はnull継続）
  // 【実装内容】: 'presetPhrases'という名前でPresetPhrase用のボックスをオープン
  // 【テスト対応】: TC-001の検証項目、TC-059-006
  // 🔵 信頼性レベル: 青信号 - REQ-104（定型文機能）の実現
  await openBoxWithRecovery<PresetPhrase>('presetPhrases', hivePath: hivePath);

  // 【TypeAdapter登録】: FavoriteItemAdapterの登録
  // 【実装内容】: typeId 2としてFavoriteItemAdapterを登録（重複登録時はtry-catchで無視）
  // 【テスト対応】: TASK-0065
  // 🔵 信頼性レベル: 青信号 - REQ-701（お気に入り機能）の基盤
  _registerAdapterSafely(FavoriteItemAdapter());

  // 【ボックスオープン】: favoritesボックスのオープン（破損時は復旧を試み、失敗時はnull継続）
  // 【実装内容】: 'favorites'という名前でFavoriteItem用のボックスをオープン
  // 【テスト対応】: TASK-0065、TC-059-006
  // 🔵 信頼性レベル: 青信号 - REQ-701（お気に入り機能）の実現
  await openBoxWithRecovery<FavoriteItem>('favorites', hivePath: hivePath);
}
