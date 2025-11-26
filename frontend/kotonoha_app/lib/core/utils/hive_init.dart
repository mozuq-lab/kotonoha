import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

/// 【関数定義】: Hive初期化処理
/// 【実装内容】: Hive.initFlutter()、TypeAdapter登録、ボックスオープンを順に実行
/// 【テスト対応】:
///   - TC-001: Hive初期化が正常に完了し、ボックスがオープンできることを確認
///   - TC-002: HistoryItemAdapterとPresetPhraseAdapterが正しく登録されることを確認
///   - TC-003: 同じTypeAdapterを2回登録しようとした場合のエラーハンドリングを確認
/// 🔵 信頼性レベル: 青信号 - REQ-5003、TASK-0014の実装詳細に基づく
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
  try {
    // 【既登録確認】: typeId 0が未登録の場合のみ登録
    // 【冪等性保証】: Hot Restart時の重複登録エラーを防ぐ
    // 🟡 黄信号: NFR-301、NFR-304から類推、Hiveの一般的なエラーケース
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HistoryItemAdapter());
    }
  } catch (e) {
    // 【エラーハンドリング】: 重複登録エラーを無視（アプリの安定性維持）
    // 【実装方針】: エラーが発生しても処理を継続
    // 🟡 黄信号: NFR-301（基本機能継続）を満たすための実装
    // ignore: empty_catches
  }

  // 【TypeAdapter登録】: PresetPhraseAdapterの登録
  // 【実装内容】: typeId 1としてPresetPhraseAdapterを登録（重複登録時はtry-catchで無視）
  // 【テスト対応】: TC-002、TC-003
  // 🔵 信頼性レベル: 青信号 - REQ-104（定型文機能）の基盤
  try {
    // 【既登録確認】: typeId 1が未登録の場合のみ登録
    // 【冪等性保証】: Hot Restart時の重複登録エラーを防ぐ
    // 🟡 黄信号: NFR-301、NFR-304から類推、Hiveの一般的なエラーケース
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PresetPhraseAdapter());
    }
  } catch (e) {
    // 【エラーハンドリング】: 重複登録エラーを無視（アプリの安定性維持）
    // 【実装方針】: エラーが発生しても処理を継続
    // 🟡 黄信号: NFR-301（基本機能継続）を満たすための実装
    // ignore: empty_catches
  }

  // 【ボックスオープン】: historyボックスのオープン
  // 【実装内容】: 'history'という名前でHistoryItem用のボックスをオープン
  // 【テスト対応】: TC-001の検証項目
  // 🔵 信頼性レベル: 青信号 - REQ-601（履歴自動保存）の実現
  await Hive.openBox<HistoryItem>('history');

  // 【ボックスオープン】: presetPhrasesボックスのオープン
  // 【実装内容】: 'presetPhrases'という名前でPresetPhrase用のボックスをオープン
  // 【テスト対応】: TC-001の検証項目
  // 🔵 信頼性レベル: 青信号 - REQ-104（定型文機能）の実現
  await Hive.openBox<PresetPhrase>('presetPhrases');
}
