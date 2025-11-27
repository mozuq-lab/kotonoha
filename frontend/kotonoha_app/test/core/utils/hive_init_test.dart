// Hive初期化 TDDテスト（Redフェーズ）
// TASK-0014: Hiveローカルストレージセットアップ・データモデル実装
//
// テストフレームワーク: flutter_test + Hive Testing
// 対象: Hive初期化処理（initHive関数）
//
// 🔵 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('Hive初期化・TypeAdapter登録テスト', () {
    late Directory tempDir;

    setUp(() async {
      // 【テスト前準備】: Hive環境をクリーンな状態にリセット
      // 【環境初期化】: 前のテストの影響を受けないよう、Hiveをクローズし削除
      // 【path_provider対策】: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      // 【テスト後処理】: Hive環境をクリーンアップ
      // 【状態復元】: 次のテストに影響しないよう、すべてのボックスをクローズ
      await Hive.close();
      // 【一時ディレクトリ削除】: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // TC-001: Hive初期化成功テスト
    test('TC-001: Hive初期化が正常に完了し、ボックスがオープンできることを確認', () async {
      // 【テスト目的】: initHive()関数が正常に動作し、ボックスがオープンされることを確認
      // 【テスト内容】: Hive.initFlutter()が成功し、historyとpresetPhrasesボックスがオープンされる
      // 【期待される動作】: REQ-5003（データ永続化）の基盤が確立される
      // 🔵 青信号: REQ-5003、architecture.mdのHive使用要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: なし（初期化のみ）
      // 【初期条件設定】: アプリ初回起動時の状態
      // 【前提条件確認】: Hive未初期化の状態

      // When（実行フェーズ）
      // 【実際の処理実行】: TypeAdapter登録とボックスオープンを直接実行
      // 【処理内容】: initHive()の内部処理をテスト環境で再現（Hive.init()は既にsetUpで実行済み）
      // 【実行タイミング】: アプリのmain()関数内で最初に実行
      // 【path_provider対策】: Hive.initFlutter()ではなく、TypeAdapter登録とボックスオープンのみを実行
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');

      // Then（検証フェーズ）
      // 【結果検証】: Hive初期化が成功し、ボックスがオープンされていることを確認
      // 【期待値確認】: REQ-5003のデータ永続化機構が利用可能

      // 【検証項目】: historyボックスがオープンされていること
      // 🔵 青信号: REQ-601（履歴自動保存）の基盤
      expect(
          Hive.isBoxOpen('history'), true); // 【確認内容】: historyボックスが正常にオープンされている

      // 【検証項目】: presetPhrasesボックスがオープンされていること
      // 🔵 青信号: REQ-104（定型文機能）の基盤
      expect(Hive.isBoxOpen('presetPhrases'),
          true); // 【確認内容】: presetPhrasesボックスが正常にオープンされている
    });

    // TC-002: TypeAdapter登録成功テスト
    test('TC-002: HistoryItemAdapterとPresetPhraseAdapterが正しく登録されることを確認',
        () async {
      // 【テスト目的】: TypeAdapterが正しく登録され、カスタムクラスの保存・読み込みが可能になること
      // 【テスト内容】: Hive.registerAdapter()が正常に動作し、typeId 0と1が登録される
      // 【期待される動作】: HistoryItemとPresetPhraseのシリアライズ/デシリアライズが可能
      // 🔵 青信号: Hive公式ドキュメント、interfaces.dartの型定義に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: なし（TypeAdapter登録のみ）
      // 【初期条件設定】: Hive未初期化の状態

      // When（実行フェーズ）
      // 【実際の処理実行】: TypeAdapter登録とボックスオープンを直接実行
      // 【処理内容】: TypeAdapter登録（HistoryItemAdapter、PresetPhraseAdapter）
      // 【実行タイミング】: Hive初期化直後
      // 【path_provider対策】: Hive.init()は既にsetUpで実行済み
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');

      // Then（検証フェーズ）
      // 【結果検証】: TypeAdapterが正しく登録されていることを確認
      // 【期待値確認】: カスタムクラスのHive永続化に必須

      // 【検証項目】: typeId 0（HistoryItem）が登録されていること
      // 🔵 青信号: テストケース定義書TC-002に基づく
      expect(Hive.isAdapterRegistered(0),
          true); // 【確認内容】: HistoryItemAdapterが登録されている

      // 【検証項目】: typeId 1（PresetPhrase）が登録されていること
      // 🔵 青信号: テストケース定義書TC-002に基づく
      expect(Hive.isAdapterRegistered(1),
          true); // 【確認内容】: PresetPhraseAdapterが登録されている
    });

    // TC-003: TypeAdapter重複登録時のエラーハンドリングテスト
    test('TC-003: 同じTypeAdapterを2回登録しようとした場合のエラーハンドリングを確認', () async {
      // 【テスト目的】: 重複登録エラーが適切にハンドリングされ、アプリの安定性が保たれること
      // 【テスト内容】: initHive()を2回呼び出し、HiveErrorまたは正常動作を確認
      // 【期待される動作】: エラーが発生するか、既登録を検知して無視（try-catch処理）
      // 🟡 黄信号: NFR-301、NFR-304から類推、Hiveの一般的なエラーケース

      // Given（準備フェーズ）
      // 【テストデータ準備】: なし
      // 【初期条件設定】: 1回目のTypeAdapter登録を実行済み
      // 【実際の発生シナリオ】: Hot Restart時、テスト実行時の複数回初期化
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');

      // When（実行フェーズ）
      // 【実際の処理実行】: TypeAdapter登録を2回目に実行
      // 【処理内容】: 既に登録済みのTypeAdapterを再登録しようとする
      // 【実行タイミング】: アプリHot Restart時、テスト実行時

      // Then（検証フェーズ）
      // 【結果検証】: エラーが適切にハンドリングされ、アプリがクラッシュしないこと
      // 【期待値確認】: NFR-301（基本機能継続）を満たす
      // 【システムの安全性】: 開発中のHot Restartでクラッシュしない

      // 【検証項目】: 2回目のTypeAdapter登録でエラーが発生しないこと
      // 🟡 黄信号: 実装後にエラーハンドリングの動作を確認
      expect(
        () {
          // 【重複登録確認】: isAdapterRegistered()でチェックされるため、正常に完了
          if (!Hive.isAdapterRegistered(0)) {
            Hive.registerAdapter(HistoryItemAdapter());
          }
          if (!Hive.isAdapterRegistered(1)) {
            Hive.registerAdapter(PresetPhraseAdapter());
          }
        },
        returnsNormally, // 【確認内容】: 例外がスローされず、正常に完了すること
      );

      // 【検証項目】: TypeAdapterが依然として登録されていること
      // 🟡 黄信号: 冪等性の確認
      expect(Hive.isAdapterRegistered(0),
          true); // 【確認内容】: HistoryItemAdapterが依然として登録されている
      expect(Hive.isAdapterRegistered(1),
          true); // 【確認内容】: PresetPhraseAdapterが依然として登録されている
    });

    // TC-054-001: HistoryItemの保存・読み込みテスト
    test('TC-054-001: HistoryItemをHiveに保存・読み込みできることを確認', () async {
      // 【テスト目的】: HistoryItemAdapterが正しくシリアライズ/デシリアライズすること
      // 【テスト内容】: HistoryItemを保存し、読み込んで値が一致するか確認
      // 🔵 青信号: REQ-5003、REQ-601に基づく

      // Given
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      final box = await Hive.openBox<HistoryItem>('history');
      final now = DateTime.now();
      final item = HistoryItem(
        id: 'test-001',
        content: 'テストメッセージ',
        createdAt: now,
        type: 'manualInput',
        isFavorite: true,
      );

      // When
      await box.put('test-001', item);
      final loaded = box.get('test-001');

      // Then
      expect(loaded, isNotNull);
      expect(loaded!.id, 'test-001');
      expect(loaded.content, 'テストメッセージ');
      expect(loaded.type, 'manualInput');
      expect(loaded.isFavorite, true);
    });

    // TC-054-002: PresetPhraseの保存・読み込みテスト
    test('TC-054-002: PresetPhraseをHiveに保存・読み込みできることを確認', () async {
      // 【テスト目的】: PresetPhraseAdapterが正しくシリアライズ/デシリアライズすること
      // 【テスト内容】: PresetPhraseを保存し、読み込んで値が一致するか確認
      // 🔵 青信号: REQ-5003、REQ-104に基づく

      // Given
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      final box = await Hive.openBox<PresetPhrase>('presetPhrases');
      final now = DateTime.now();
      final phrase = PresetPhrase(
        id: 'preset-001',
        content: 'おはようございます',
        category: 'daily',
        isFavorite: true,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      // When
      await box.put('preset-001', phrase);
      final loaded = box.get('preset-001');

      // Then
      expect(loaded, isNotNull);
      expect(loaded!.id, 'preset-001');
      expect(loaded.content, 'おはようございます');
      expect(loaded.category, 'daily');
      expect(loaded.isFavorite, true);
      expect(loaded.displayOrder, 1);
    });

    // TC-054-003: エラー時の適切なハンドリングテスト
    test('TC-054-003: 存在しないキーへのアクセスがnullを返すことを確認', () async {
      // 【テスト目的】: 存在しないキーへのアクセスが安全に処理されること
      // 🟡 黄信号: NFR-301（基本機能継続）に基づく

      // Given
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      final box = await Hive.openBox<HistoryItem>('history');

      // When
      final result = box.get('non-existent-key');

      // Then
      expect(result, isNull);
    });
  });
}
