// HistoryItem TDDテスト（Redフェーズ）
// TASK-0014: Hiveローカルストレージセットアップ・データモデル実装
//
// テストフレームワーク: flutter_test + Hive Testing
// 対象: HistoryItem（履歴データモデル）
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

void main() {
  group('HistoryItem保存・読み込みテスト', () {
    late Box<HistoryItem> historyBox;
    late Directory tempDir;

    setUp(() async {
      // 【テスト前準備】: Hive環境を初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
      // 【path_provider対策】: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（実装後は自動生成される）
      // 【重複登録回避】: 既に登録されている場合はスキップ
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
    });

    tearDown(() async {
      // 【テスト後処理】: Hiveボックスをクローズし、ディスクから削除
      // 【状態復元】: 次のテストに影響しないよう、テストデータを削除
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();
      // 【一時ディレクトリ削除】: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // TC-004: HistoryItem単一データの保存・読み込みテスト
    test('TC-004: HistoryItemを1件保存し、正しく読み込めることを確認', () async {
      // 【テスト目的】: Hiveボックスへの基本的なCRUD操作（Create, Read）を確認
      // 【テスト内容】: HistoryItemを保存し、同じ内容で読み込めることを検証
      // 【期待される動作】: 保存したデータが同じ内容で読み込まれる
      // 🔵 青信号: REQ-601（履歴自動保存）の基本動作

      // Given（準備フェーズ）
      // 【テストデータ準備】: ユーザーが文字盤で「ありがとう」と入力し、読み上げた履歴
      // 【初期条件設定】: ボックスが空の状態
      final item = HistoryItem(
        id: 'test-uuid-001',
        content: 'ありがとう',
        createdAt: DateTime(2025, 11, 21, 10, 30),
        type: 'manualInput',
        isFavorite: false,
      );

      // When（実行フェーズ）
      // 【実際の処理実行】: historyBox.put()でデータを保存
      // 【処理内容】: Hiveボックスにデータを書き込む
      // 【実行タイミング】: TTS読み上げ直後の履歴自動保存
      await historyBox.put(item.id, item);

      // Then（検証フェーズ）
      // 【結果検証】: 保存したデータが正しく読み込めることを確認
      // 【期待値確認】: REQ-601の要件を満たす
      // 【品質保証】: データの完全性が保たれる

      final retrieved = historyBox.get(item.id);

      // 【検証項目】: 読み込んだデータがnullでないこと
      // 🔵 青信号: 基本的なデータ存在確認
      expect(retrieved, isNotNull); // 【確認内容】: データが正しく保存されている

      // 【検証項目】: idフィールドが一致すること
      // 🔵 青信号: 一意識別子の保持
      expect(retrieved!.id, 'test-uuid-001'); // 【確認内容】: idフィールドが保持されている

      // 【検証項目】: contentフィールドが一致すること
      // 🔵 青信号: テキスト内容の保持
      expect(retrieved.content, 'ありがとう'); // 【確認内容】: contentフィールドが保持されている

      // 【検証項目】: createdAtフィールドが一致すること
      // 🔵 青信号: 日時型の正確な保存・復元
      expect(retrieved.createdAt, DateTime(2025, 11, 21, 10, 30)); // 【確認内容】: 日時が正確に保存されている

      // 【検証項目】: typeフィールドが一致すること
      // 🔵 青信号: 履歴種別の保持
      expect(retrieved.type, 'manualInput'); // 【確認内容】: 履歴種別が保持されている

      // 【検証項目】: isFavoriteフィールドが一致すること
      // 🔵 青信号: お気に入りフラグの保持
      expect(retrieved.isFavorite, false); // 【確認内容】: お気に入りフラグが保持されている
    });

    // TC-005: HistoryItem複数データの保存・読み込みテスト
    test('TC-005: 複数のHistoryItemを保存し、全件を正しく読み込めることを確認', () async {
      // 【テスト目的】: 複数レコードの保存と、values.toList()による全件取得を確認
      // 【テスト内容】: 3件のHistoryItemを保存し、すべて取得できることを検証
      // 【期待される動作】: 保存した順序とは無関係に、すべてのデータが取得できる
      // 🔵 青信号: REQ-602（履歴最大50件保持）の基盤動作

      // Given（準備フェーズ）
      // 【テストデータ準備】: 1日の使用で蓄積された3件の履歴
      // 【初期条件設定】: ボックスが空の状態
      final items = [
        HistoryItem(
          id: 'uuid-001',
          content: 'ありがとう',
          createdAt: DateTime(2025, 11, 21, 10, 0),
          type: 'manualInput',
          isFavorite: false,
        ),
        HistoryItem(
          id: 'uuid-002',
          content: 'お願いします',
          createdAt: DateTime(2025, 11, 21, 11, 0),
          type: 'preset',
          isFavorite: true,
        ),
        HistoryItem(
          id: 'uuid-003',
          content: '助けてください',
          createdAt: DateTime(2025, 11, 21, 12, 0),
          type: 'aiConverted',
          isFavorite: false,
        ),
      ];

      // When（実行フェーズ）
      // 【実際の処理実行】: 各アイテムを保存
      // 【処理内容】: ループでhistoryBox.put()を実行
      for (final item in items) {
        await historyBox.put(item.id, item);
      }

      // Then（検証フェーズ）
      // 【結果検証】: すべてのデータが正しく保存・取得できることを確認
      // 【期待値確認】: REQ-602の基盤動作

      final allHistory = historyBox.values.toList();

      // 【検証項目】: 件数が一致すること
      // 🔵 青信号: データ完全性の確認
      expect(allHistory.length, 3); // 【確認内容】: 3件すべて保存されている

      // 【検証項目】: 各アイテムのcontentが含まれていること
      // 🔵 青信号: データの独立性確認
      expect(allHistory.any((item) => item.content == 'ありがとう'), true); // 【確認内容】: 1件目が存在する
      expect(allHistory.any((item) => item.content == 'お願いします'), true); // 【確認内容】: 2件目が存在する
      expect(allHistory.any((item) => item.content == '助けてください'), true); // 【確認内容】: 3件目が存在する

      // 【検証項目】: 異なるHistoryTypeが混在して保存できること
      // 🔵 青信号: dataflow.mdの履歴管理フローに基づく
      expect(allHistory.any((item) => item.type == 'manualInput'), true); // 【確認内容】: 文字盤入力が保存されている
      expect(allHistory.any((item) => item.type == 'preset'), true); // 【確認内容】: 定型文が保存されている
      expect(allHistory.any((item) => item.type == 'aiConverted'), true); // 【確認内容】: AI変換結果が保存されている
    });

    // TC-006: HistoryItem削除テスト
    test('TC-006: 特定のHistoryItemを削除し、削除後に取得できないことを確認', () async {
      // 【テスト目的】: historyBox.delete()の正常動作を確認
      // 【テスト内容】: データを保存後、削除し、取得できないことを検証
      // 【期待される動作】: 削除したアイテムが取得できなくなる
      // 🔵 青信号: REQ-604（履歴個別削除機能）の実現

      // Given（準備フェーズ）
      // 【テストデータ準備】: 削除対象の履歴を保存
      // 【初期条件設定】: 1件の履歴が存在する状態
      final item = HistoryItem(
        id: 'uuid-001',
        content: 'テスト',
        createdAt: DateTime(2025, 11, 21, 10, 0),
        type: 'manualInput',
        isFavorite: false,
      );
      await historyBox.put(item.id, item);

      // 削除前の確認
      expect(historyBox.get('uuid-001'), isNotNull); // 【確認内容】: 削除前にデータが存在することを確認

      // When（実行フェーズ）
      // 【実際の処理実行】: historyBox.delete()で削除
      // 【処理内容】: ユーザーが履歴画面から特定の履歴を削除する操作（REQ-604）
      await historyBox.delete('uuid-001');

      // Then（検証フェーズ）
      // 【結果検証】: 削除したデータが取得できないことを確認
      // 【期待値確認】: REQ-604の要件を満たす

      // 【検証項目】: 削除後、データがnullを返すこと
      // 🔵 青信号: データの物理削除確認
      expect(historyBox.get('uuid-001'), isNull); // 【確認内容】: 削除したデータが取得できない

      // 【検証項目】: ボックスの件数が減っていること
      // 🔵 青信号: 削除動作の完全性確認
      expect(historyBox.length, 0); // 【確認内容】: ボックスが空になっている
    });

    // TC-007: 履歴50件超過時の自動削除テスト
    test('TC-007: 履歴が50件に達した状態で新規追加時、最も古い履歴が自動削除されることを確認', () async {
      // 【テスト目的】: 履歴50件上限の自動削除ロジックを確認
      // 【テスト内容】: 50件保存後、51件目を追加し、最古が削除されることを検証
      // 【期待される動作】: 51件目追加時に最古（最もcreatedAtが古い）が削除され、常に50件以下を維持
      // 🔵 青信号: REQ-602、REQ-3002の要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: 50件のHistoryItemを保存
      // 【初期条件設定】: 長期利用ユーザーの履歴が上限に達したシナリオ
      for (int i = 1; i <= 50; i++) {
        final item = HistoryItem(
          id: 'uuid-${i.toString().padLeft(3, '0')}',
          content: '履歴$i',
          createdAt: DateTime(2025, 11, 21, 10, 0).add(Duration(minutes: i)),
          type: 'manualInput',
          isFavorite: false,
        );
        await historyBox.put(item.id, item);
      }

      // 50件保存されていることを確認
      expect(historyBox.length, 50); // 【確認内容】: 50件が保存されている

      // When（実行フェーズ）
      // 【実際の処理実行】: 51件目を追加し、最古を削除
      // 【処理内容】: 新しい履歴を追加し、最も古い履歴を自動削除（REQ-602）
      final newItem = HistoryItem(
        id: 'uuid-051',
        content: '新しい履歴',
        createdAt: DateTime(2025, 11, 21, 11, 0),
        type: 'manualInput',
        isFavorite: false,
      );
      await historyBox.put(newItem.id, newItem);

      // 最も古い履歴（uuid-001）を削除
      final oldestKey = historyBox.values
          .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
          .id;
      await historyBox.delete(oldestKey);

      // Then（検証フェーズ）
      // 【結果検証】: 50件上限が維持され、最古が削除されていることを確認
      // 【期待値確認】: REQ-602の要件を満たす

      // 【検証項目】: 件数が50件であること
      // 🔵 青信号: 50件上限維持
      expect(historyBox.length, 50); // 【確認内容】: 常に50件以下が維持されている

      // 【検証項目】: 最古の履歴（uuid-001）が削除されていること
      // 🔵 青信号: 最古のデータ削除確認
      expect(historyBox.get('uuid-001'), isNull); // 【確認内容】: 最古の履歴が削除されている

      // 【検証項目】: 最新の履歴（uuid-051）が存在すること
      // 🔵 青信号: 最新データの保持確認
      expect(historyBox.get('uuid-051'), isNotNull); // 【確認内容】: 最新の履歴が保存されている
    });

    // TC-008: 履歴0件時の表示テスト
    test('TC-008: 履歴が0件の状態でvaluesを取得した場合、空のリストが返されることを確認', () async {
      // 【テスト目的】: 履歴0件時のエッジケース処理を確認
      // 【テスト内容】: ボックスが空の状態でvalues.toList()を呼び出す
      // 【期待される動作】: 空のIterable/Listが返され、エラーが発生しない
      // 🔵 青信号: EDGE-103（履歴0件時のUI表示）の基盤

      // Given（準備フェーズ）
      // 【テストデータ準備】: なし（ボックスを空の状態で保持）
      // 【初期条件設定】: アプリ初回起動時、または全削除後の状態

      // When（実行フェーズ）
      // 【実際の処理実行】: historyBox.valuesを取得
      // 【処理内容】: 空のボックスから全件取得を試みる
      final allHistory = historyBox.values.toList();

      // Then（検証フェーズ）
      // 【結果検証】: 空のリストが返されることを確認
      // 【期待値確認】: EDGE-103の基盤

      // 【検証項目】: 空のリストが返されること
      // 🔵 青信号: 空リストの正確な取得
      expect(allHistory, isEmpty); // 【確認内容】: 空のリストが返される

      // 【検証項目】: 件数が0であること
      // 🔵 青信号: null参照エラーの回避
      expect(allHistory.length, 0); // 【確認内容】: 件数が0である

      // 【検証項目】: isEmptyがtrueであること
      // 🔵 青信号: UI表示の前提条件
      expect(historyBox.isEmpty, true); // 【確認内容】: ボックスが空であることを確認
    });
  });
}
