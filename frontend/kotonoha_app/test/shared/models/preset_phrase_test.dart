// PresetPhrase TDDテスト（Redフェーズ）
// TASK-0014: Hiveローカルストレージセットアップ・データモデル実装
//
// テストフレームワーク: flutter_test + Hive Testing
// 対象: PresetPhrase（定型文データモデル）
//
// 信頼性レベル凡例:
// - 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 黄信号: 要件定義書から妥当な推測によるテスト
// - 赤信号: 要件定義書にない推測によるテスト

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('PresetPhrase保存・読み込みテスト', () {
    late Box<PresetPhrase> presetBox;
    late Directory tempDir;

    setUp(() async {
      // テスト前準備: Hive環境を初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      // path_provider対策: 一時ディレクトリを使用してpath_providerプラグインへの依存を回避
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録（実装後は自動生成される）
      // 重複登録回避: 既に登録されている場合はスキップ
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_presetPhrases');
    });

    tearDown(() async {
      // テスト後処理: Hiveボックスをクローズし、ディスクから削除
      // 状態復元: 次のテストに影響しないよう、テストデータを削除
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_presetPhrases');
      await Hive.close();
      // 一時ディレクトリ削除: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // TC-009: PresetPhrase単一データの保存・読み込みテスト
    test('TC-009: PresetPhraseを1件保存し、正しく読み込めることを確認', () async {
      // テスト目的: PresetPhraseのCRUD操作（Create, Read）を確認
      // テスト内容: PresetPhraseを保存し、同じ内容で読み込めることを検証
      // 期待される動作: 保存したデータが同じ内容で読み込まれる
      // 青信号: REQ-104（定型文追加機能）の基本動作

      // Given（準備フェーズ）
      // テストデータ準備: ユーザーが設定画面で新規登録した定型文
      // 初期条件設定: ボックスが空の状態
      final preset = PresetPhrase(
        id: 'preset-uuid-001',
        content: 'お水をください',
        category: 'health',
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 21, 10, 0),
        updatedAt: DateTime(2025, 11, 21, 10, 0),
      );

      // When（実行フェーズ）
      // 実際の処理実行: presetBox.put()でデータを保存
      // 処理内容: Hiveボックスにデータを書き込む
      // 実行タイミング: ユーザーが設定画面で定型文を追加したとき
      await presetBox.put(preset.id, preset);

      // Then（検証フェーズ）
      // 結果検証: 保存したデータが正しく読み込めることを確認
      // 期待値確認: REQ-104の要件を満たす

      final retrieved = presetBox.get(preset.id);

      // 検証項目: 読み込んだデータがnullでないこと
      // 青信号: 基本的なデータ存在確認
      expect(retrieved, isNotNull); // 確認内容: データが正しく保存されている

      // 検証項目: 全フィールドの値が一致すること
      // 青信号: データの完全性確認
      expect(retrieved!.id, 'preset-uuid-001'); // 確認内容: idフィールドが保持されている
      expect(retrieved.content, 'お水をください'); // 確認内容: contentフィールドが保持されている
      expect(retrieved.category, 'health'); // 確認内容: categoryフィールドが保持されている
      expect(retrieved.displayOrder, 0); // 確認内容: displayOrderフィールドが保持されている
      expect(retrieved.createdAt,
          DateTime(2025, 11, 21, 10, 0)); // 確認内容: createdAtフィールドが保持されている
      expect(retrieved.updatedAt,
          DateTime(2025, 11, 21, 10, 0)); // 確認内容: updatedAtフィールドが保持されている
    });

    // TC-010: PresetPhrase複数データの保存・読み込みテスト
    test('TC-010: 複数のPresetPhraseを保存し、全件を正しく読み込めることを確認', () async {
      // テスト目的: 複数定型文の保存と全件取得を確認
      // テスト内容: 3件のPresetPhraseを保存し、すべて取得できることを検証
      // 期待される動作: すべての定型文が正確に保存・取得できる
      // 青信号: REQ-104、REQ-106、dataflow.mdの定型文管理フローに基づく

      // Given（準備フェーズ）
      // テストデータ準備: ユーザーがよく使う定型文3件（日常2件、体調1件）
      // 初期条件設定: ボックスが空の状態
      final presets = [
        PresetPhrase(
          id: 'preset-001',
          content: 'おはようございます',
          category: 'daily',
          displayOrder: 0,
          createdAt: DateTime(2025, 11, 21, 10, 0),
          updatedAt: DateTime(2025, 11, 21, 10, 0),
        ),
        PresetPhrase(
          id: 'preset-002',
          content: 'お水をください',
          category: 'health',
          displayOrder: 1,
          createdAt: DateTime(2025, 11, 21, 10, 5),
          updatedAt: DateTime(2025, 11, 21, 10, 5),
        ),
        PresetPhrase(
          id: 'preset-003',
          content: 'ありがとう',
          category: 'daily',
          displayOrder: 2,
          createdAt: DateTime(2025, 11, 21, 10, 10),
          updatedAt: DateTime(2025, 11, 21, 10, 10),
        ),
      ];

      // When（実行フェーズ）
      // 実際の処理実行: 各定型文を保存
      // 処理内容: ループでpresetBox.put()を実行
      for (final preset in presets) {
        await presetBox.put(preset.id, preset);
      }

      // Then（検証フェーズ）
      // 結果検証: すべてのデータが正しく保存・取得できることを確認
      // 期待値確認: REQ-106（カテゴリ分類）の基盤動作

      final allPresets = presetBox.values.toList();

      // 検証項目: 件数が一致すること
      // 青信号: データ完全性の確認
      expect(allPresets.length, 3); // 確認内容: 3件すべて保存されている

      // 検証項目: 異なるカテゴリ（daily, health）が混在して保存できること
      // 青信号: REQ-106のカテゴリ分類確認
      expect(allPresets.where((p) => p.category == 'daily').length,
          2); // 確認内容: 「日常」カテゴリが2件
      expect(allPresets.where((p) => p.category == 'health').length,
          1); // 確認内容: 「体調」カテゴリが1件

      // 検証項目: displayOrderが3件それぞれ保持されること
      // 青信号: データの完全性確認
      expect(allPresets.map((p) => p.displayOrder).toSet(),
          {0, 1, 2}); // 確認内容: 3件のdisplayOrderが保持されている
    });

    // TC-011: PresetPhraseカテゴリ分類テスト
    test('TC-011: 3種類のカテゴリ（daily, health, other）の定型文がそれぞれ正しく保存・識別できることを確認',
        () async {
      // テスト目的: categoryフィールドの正確な保存と読み込みを確認
      // テスト内容: 3種類すべてのカテゴリを保存し、正しく分類できることを検証
      // 期待される動作: カテゴリごとにデータが正しく分類される
      // 青信号: REQ-106（カテゴリ分類）の実現

      // Given（準備フェーズ）
      // テストデータ準備: REQ-106で定義された3種類のカテゴリすべて
      // 初期条件設定: ボックスが空の状態
      final dailyPreset = PresetPhrase(
        id: 'preset-daily',
        content: 'おはよう',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final healthPreset = PresetPhrase(
        id: 'preset-health',
        content: '痛いです',
        category: 'health',
        displayOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final otherPreset = PresetPhrase(
        id: 'preset-other',
        content: '趣味の話',
        category: 'other',
        displayOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // When（実行フェーズ）
      // 実際の処理実行: 各カテゴリの定型文を保存
      // 処理内容: 3種類すべてのカテゴリを保存
      await presetBox.put(dailyPreset.id, dailyPreset);
      await presetBox.put(healthPreset.id, healthPreset);
      await presetBox.put(otherPreset.id, otherPreset);

      // Then（検証フェーズ）
      // 結果検証: 各カテゴリが正しく保存・識別できることを確認
      // 期待値確認: REQ-106の要件を満たす

      // 検証項目: 「日常」カテゴリが正しく保存されること
      // 青信号: REQ-106のカテゴリ分類
      expect(presetBox.get('preset-daily')!.category,
          'daily'); // 確認内容: 「日常」カテゴリが正しく保存されている

      // 検証項目: 「体調」カテゴリが正しく保存されること
      // 青信号: REQ-106のカテゴリ分類
      expect(presetBox.get('preset-health')!.category,
          'health'); // 確認内容: 「体調」カテゴリが正しく保存されている

      // 検証項目: 「その他」カテゴリが正しく保存されること
      // 青信号: REQ-106のカテゴリ分類
      expect(presetBox.get('preset-other')!.category,
          'other'); // 確認内容: 「その他」カテゴリが正しく保存されている

      // 検証項目: カテゴリごとにフィルタリング可能であること
      // 青信号: UI表示の基盤
      final dailyOnly =
          presetBox.values.where((p) => p.category == 'daily').toList();
      expect(dailyOnly.length, 1); // 確認内容: 「日常」カテゴリのみフィルタリングできる
    });

    // TC-013: PresetPhrase削除テスト
    test('TC-013: 特定のPresetPhraseを削除し、削除後に取得できないことを確認', () async {
      // テスト目的: presetBox.delete()の正常動作を確認
      // テスト内容: データを保存後、削除し、取得できないことを検証
      // 期待される動作: 削除した定型文が取得できなくなる
      // 青信号: REQ-104（定型文削除機能）の実現

      // Given（準備フェーズ）
      // テストデータ準備: 削除対象の定型文を保存
      // 初期条件設定: 1件の定型文が存在する状態
      final preset = PresetPhrase(
        id: 'preset-001',
        content: '削除予定',
        category: 'other',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await presetBox.put(preset.id, preset);

      // 削除前の確認
      expect(
          presetBox.get('preset-001'), isNotNull); // 確認内容: 削除前にデータが存在することを確認

      // When（実行フェーズ）
      // 実際の処理実行: presetBox.delete()で削除
      // 処理内容: ユーザーが設定画面から不要な定型文を削除する操作（REQ-104）
      await presetBox.delete('preset-001');

      // Then（検証フェーズ）
      // 結果検証: 削除したデータが取得できないことを確認
      // 期待値確認: REQ-104の要件を満たす

      // 検証項目: 削除後、データがnullを返すこと
      // 青信号: データの物理削除確認
      expect(presetBox.get('preset-001'), isNull); // 確認内容: 削除したデータが取得できない

      // 検証項目: ボックスの件数が減っていること
      // 青信号: 削除動作の完全性確認
      expect(presetBox.length, 0); // 確認内容: ボックスが空になっている
    });
  });

  group('PresetPhrase データ永続化・復元テスト', () {
    // TC-014: アプリ再起動後のHistoryItem復元テスト（ここではスキップ）
    // TC-015: アプリ再起動後のPresetPhrase復元テスト
    test('TC-015: アプリ再起動後、保存されたPresetPhraseが正しく復元されることを確認', () async {
      // テスト目的: Hiveの永続化機能（ディスク書き込み）を確認
      // テスト内容: アプリ再起動後も全定型文が保持されることを検証
      // 期待される動作: アプリ再起動後も全定型文が保持される
      // 青信号: REQ-5003（設定永続化）の要件に基づく

      // Given（準備フェーズ）
      // テストデータ準備: 定型文を保存し、ボックスをクローズ（再起動を模擬）
      // 初期条件設定: 設定した定型文がアプリ終了後も保持される
      // path_provider対策: 一時ディレクトリを使用
      await Hive.close();
      final tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      var presetBox =
          await Hive.openBox<PresetPhrase>('test_preset_persistence');

      final preset = PresetPhrase(
        id: 'preset-001',
        content: 'お水をください',
        category: 'health',
        displayOrder: 0,
        createdAt: DateTime(2025, 11, 21, 10, 0),
        updatedAt: DateTime(2025, 11, 21, 10, 0),
      );
      await presetBox.put(preset.id, preset);

      // ボックスをクローズ（アプリ終了を模擬）
      await presetBox.close();

      // When（実行フェーズ）
      // 実際の処理実行: ボックスを再度オープン（再起動を模擬）
      // 処理内容: Hiveがディスクから定型文を読み込む
      presetBox = await Hive.openBox<PresetPhrase>('test_preset_persistence');

      // Then（検証フェーズ）
      // 結果検証: 定型文が正しく復元されていることを確認
      // 期待値確認: REQ-5003の要件を満たす

      final restored = presetBox.get('preset-001');

      // 検証項目: 復元されたデータがnullでないこと
      // 青信号: データ永続化の確認
      expect(restored, isNotNull); // 確認内容: データが復元されている

      // 検証項目: 全フィールドの値が元のデータと一致すること
      // 青信号: データの完全性確認
      expect(restored!.content, 'お水をください'); // 確認内容: contentが復元されている
      expect(restored.category, 'health'); // 確認内容: categoryが復元されている
      expect(restored.displayOrder, 0); // 確認内容: displayOrderが復元されている

      // クリーンアップ
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_preset_persistence');
      await Hive.close();
      // 一時ディレクトリ削除: テスト用の一時ファイルを削除
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
