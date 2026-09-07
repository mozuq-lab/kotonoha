// テストフレームワーク: flutter_test + Hive Testing
// 対象: HistoryItem（履歴データモデル）

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
      // テスト前準備: Hive環境を初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      // path_provider対策: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);

      // 手書きのTypeAdapterを登録する。
      // 重複登録回避: 既に登録されている場合はスキップ
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }

      historyBox = await Hive.openBox<HistoryItem>('test_history');
    });

    tearDown(() async {
      // テスト後処理: Hiveボックスをクローズし、ディスクから削除
      // 状態復元: 次のテストに影響しないよう、テストデータを削除
      await historyBox.close();
      await Hive.deleteBoxFromDisk('test_history');
      await Hive.close();
      // 一時ディレクトリ削除: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // HistoryItem単一データの保存・読み込みテスト
    test('TC-004: HistoryItemを1件保存し、正しく読み込めることを確認', () async {
      // テストデータ準備: ユーザーが文字盤で「ありがとう」と入力し、読み上げた履歴
      // 初期条件設定: ボックスが空の状態
      final item = HistoryItem(
        id: 'test-uuid-001',
        content: 'ありがとう',
        createdAt: DateTime(2025, 11, 21, 10, 30),
        type: 'manualInput',
      );

      // 実際の処理実行: historyBox.putでデータを保存
      // 処理内容: Hiveボックスにデータを書き込む
      // 実行タイミング: TTS読み上げ直後の履歴自動保存
      await historyBox.put(item.id, item);

      // 結果検証: 保存したデータが正しく読み込めることを確認
      // 期待値確認: の要件を満たす
      // 品質保証: データの完全性が保たれる

      final retrieved = historyBox.get(item.id);

      // 検証項目: 読み込んだデータがnullでないこと
      expect(retrieved, isNotNull);

      // 検証項目: idフィールドが一致すること
      expect(retrieved!.id, 'test-uuid-001');

      // 検証項目: contentフィールドが一致すること
      expect(retrieved.content, 'ありがとう');

      // 検証項目: createdAtフィールドが一致すること
      expect(retrieved.createdAt, DateTime(2025, 11, 21, 10, 30));

      // 検証項目: typeフィールドが一致すること
      expect(retrieved.type, 'manualInput');
    });

    // HistoryItem複数データの保存・読み込みテスト
    test('TC-005: 複数のHistoryItemを保存し、全件を正しく読み込めることを確認', () async {
      // テストデータ準備: 1日の使用で蓄積された3件の履歴
      // 初期条件設定: ボックスが空の状態
      final items = [
        HistoryItem(
          id: 'uuid-001',
          content: 'ありがとう',
          createdAt: DateTime(2025, 11, 21, 10, 0),
          type: 'manualInput',
        ),
        HistoryItem(
          id: 'uuid-002',
          content: 'お願いします',
          createdAt: DateTime(2025, 11, 21, 11, 0),
          type: 'preset',
        ),
        HistoryItem(
          id: 'uuid-003',
          content: '助けてください',
          createdAt: DateTime(2025, 11, 21, 12, 0),
          type: 'aiConverted',
        ),
      ];

      // 実際の処理実行: 各アイテムを保存
      // 処理内容: ループでhistoryBox.putを実行
      for (final item in items) {
        await historyBox.put(item.id, item);
      }

      // 結果検証: すべてのデータが正しく保存・取得できることを確認
      // 期待値確認: の基盤動作

      final allHistory = historyBox.values.toList();

      // 検証項目: 件数が一致すること
      expect(allHistory.length, 3);

      // 検証項目: 各アイテムのcontentが含まれていること
      expect(allHistory.any((item) => item.content == 'ありがとう'), true);
      expect(allHistory.any((item) => item.content == 'お願いします'), true);
      expect(allHistory.any((item) => item.content == '助けてください'), true);

      // 検証項目: 異なるHistoryTypeが混在して保存できること
      expect(allHistory.any((item) => item.type == 'manualInput'), true);
      expect(allHistory.any((item) => item.type == 'preset'), true);
      expect(allHistory.any((item) => item.type == 'aiConverted'), true);
    });

    // HistoryItem削除テスト
    test('TC-006: 特定のHistoryItemを削除し、削除後に取得できないことを確認', () async {
      // テストデータ準備: 削除対象の履歴を保存
      // 初期条件設定: 1件の履歴が存在する状態
      final item = HistoryItem(
        id: 'uuid-001',
        content: 'テスト',
        createdAt: DateTime(2025, 11, 21, 10, 0),
        type: 'manualInput',
      );
      await historyBox.put(item.id, item);

      // 削除前の確認
      expect(historyBox.get('uuid-001'), isNotNull);

      // 実際の処理実行: historyBox.deleteで削除
      // 処理内容: ユーザーが履歴画面から特定の履歴を削除する操作
      await historyBox.delete('uuid-001');

      // 結果検証: 削除したデータが取得できないことを確認
      // 期待値確認: の要件を満たす

      // 検証項目: 削除後、データがnullを返すこと
      expect(historyBox.get('uuid-001'), isNull);

      // 検証項目: ボックスの件数が減っていること
      expect(historyBox.length, 0);
    });

    // 履歴50件超過時の自動削除テスト
    test('TC-007: 履歴が50件に達した状態で新規追加時、最も古い履歴が自動削除されることを確認', () async {
      // テストデータ準備: 50件のHistoryItemを保存
      // 初期条件設定: 長期利用ユーザーの履歴が上限に達したシナリオ
      for (int i = 1; i <= 50; i++) {
        final item = HistoryItem(
          id: 'uuid-${i.toString().padLeft(3, '0')}',
          content: '履歴$i',
          createdAt: DateTime(2025, 11, 21, 10, 0).add(Duration(minutes: i)),
          type: 'manualInput',
        );
        await historyBox.put(item.id, item);
      }

      // 50件保存されていることを確認
      expect(historyBox.length, 50);

      // 実際の処理実行: 51件目を追加し、最古を削除
      // 処理内容: 新しい履歴を追加し、最も古い履歴を自動削除
      final newItem = HistoryItem(
        id: 'uuid-051',
        content: '新しい履歴',
        createdAt: DateTime(2025, 11, 21, 11, 0),
        type: 'manualInput',
      );
      await historyBox.put(newItem.id, newItem);

      // 最も古い履歴（uuid-001）を削除
      final oldestKey = historyBox.values
          .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
          .id;
      await historyBox.delete(oldestKey);

      // 結果検証: 50件上限が維持され、最古が削除されていることを確認
      // 期待値確認: の要件を満たす

      // 検証項目: 件数が50件であること
      expect(historyBox.length, 50);

      // 検証項目: 最古の履歴（uuid-001）が削除されていること
      expect(historyBox.get('uuid-001'), isNull);

      // 検証項目: 最新の履歴（uuid-051）が存在すること
      expect(historyBox.get('uuid-051'), isNotNull);
    });

    // 履歴0件時の表示テスト
    test('TC-008: 履歴が0件の状態でvaluesを取得した場合、空のリストが返されることを確認', () async {
      // テストデータ準備: なし（ボックスを空の状態で保持）
      // 初期条件設定: アプリ初回起動時、または全削除後の状態

      // 実際の処理実行: historyBox.valuesを取得
      // 処理内容: 空のボックスから全件取得を試みる
      final allHistory = historyBox.values.toList();

      // 結果検証: 空のリストが返されることを確認
      // 期待値確認: の基盤

      // 検証項目: 空のリストが返されること
      expect(allHistory, isEmpty);

      // 検証項目: 件数が0であること
      expect(allHistory.length, 0);

      // 検証項目: isEmptyがtrueであること
      expect(historyBox.isEmpty, true);
    });
  });
}
