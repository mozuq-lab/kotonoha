import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

/// 【関数定義】: Box破損時の復旧つきオープン処理
///
/// 【実装内容】: [Hive.openBox]でBoxをオープンする。破損等でオープンに失敗した場合は
/// [Hive.deleteBoxFromDisk]で破損Boxを削除してから再オープンを試みる。
/// 再オープンにも失敗した場合はnullを返し、呼び出し側はインメモリフォールバック
/// （Box未オープン扱い）として継続できるようにする。
///
/// 【設計判断】: アプリ起動不能を防ぐことを最優先とする。破損データの復旧を試みるが、
/// 復旧が不可能な場合でも例外を再送出せず、null（未オープン）を返して呼び出し元
/// （initHive）の処理継続を可能にする。
///
/// 【テスト対応】: TC-059-006（Hive Box破損時の復旧処理）
/// 🔵 信頼性レベル: 青信号 - NFR-301（基本機能継続）、NFR-304に基づく
///
/// [crashRecovery]はテスト用のフック。既定値の`true`ではHive自身が持つ
/// フレーム単位の自動復旧が先に働くため、本関数のcatch節（削除→再オープン）まで
/// 到達するのは自動復旧でも救えない破損時のみとなる。テストで確実にcatch節を
/// 検証したい場合は`false`を渡し、Hive側の自動復旧を無効化する。
///
/// 戻り値: オープンに成功した[Box]。復旧を含めて失敗した場合はnull。
Future<Box<T>?> openBoxWithRecovery<T>(
  String name, {
  bool crashRecovery = true,
}) async {
  try {
    return await Hive.openBox<T>(name, crashRecovery: crashRecovery);
  } catch (error, stackTrace) {
    // 【破損検知ログ】: Box破損等でオープンに失敗した際に記録する
    // 🟡 黄信号: NFR-304から類推
    debugPrint('[hive_init] Box "$name" のオープンに失敗しました: $error');
    debugPrintStack(stackTrace: stackTrace);

    // 【復旧処理: 削除】: 破損したBoxファイルを削除する
    // 🔵 信頼性レベル: 青信号 - test/core/utils/hive_init_corruption_test.dartの復旧パターンに基づく
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
  await openBoxWithRecovery<HistoryItem>('history');

  // 【ボックスオープン】: presetPhrasesボックスのオープン（破損時は復旧を試み、失敗時はnull継続）
  // 【実装内容】: 'presetPhrases'という名前でPresetPhrase用のボックスをオープン
  // 【テスト対応】: TC-001の検証項目、TC-059-006
  // 🔵 信頼性レベル: 青信号 - REQ-104（定型文機能）の実現
  await openBoxWithRecovery<PresetPhrase>('presetPhrases');

  // 【TypeAdapter登録】: FavoriteItemAdapterの登録
  // 【実装内容】: typeId 2としてFavoriteItemAdapterを登録（重複登録時はtry-catchで無視）
  // 【テスト対応】: TASK-0065
  // 🔵 信頼性レベル: 青信号 - REQ-701（お気に入り機能）の基盤
  _registerAdapterSafely(FavoriteItemAdapter());

  // 【ボックスオープン】: favoritesボックスのオープン（破損時は復旧を試み、失敗時はnull継続）
  // 【実装内容】: 'favorites'という名前でFavoriteItem用のボックスをオープン
  // 【テスト対応】: TASK-0065、TC-059-006
  // 🔵 信頼性レベル: 青信号 - REQ-701（お気に入り機能）の実現
  await openBoxWithRecovery<FavoriteItem>('favorites');
}
