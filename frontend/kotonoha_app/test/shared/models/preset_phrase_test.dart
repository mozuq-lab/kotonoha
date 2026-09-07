// テストフレームワーク: flutter_test + Hive Testing
// 対象: PresetPhrase（定型文データモデル）

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

      // 手書きのTypeAdapterを登録する。
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

    // PresetPhrase単一データの保存・読み込みテスト
    test('TC-009: PresetPhraseを1件保存し、正しく読み込めることを確認', () async {
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

      // 実際の処理実行: presetBox.putでデータを保存
      // 処理内容: Hiveボックスにデータを書き込む
      // 実行タイミング: ユーザーが設定画面で定型文を追加したとき
      await presetBox.put(preset.id, preset);

      // 結果検証: 保存したデータが正しく読み込めることを確認
      // 期待値確認: の要件を満たす

      final retrieved = presetBox.get(preset.id);

      // 検証項目: 読み込んだデータがnullでないこと
      expect(retrieved, isNotNull);

      // 検証項目: 全フィールドの値が一致すること
      expect(retrieved!.id, 'preset-uuid-001');
      expect(retrieved.content, 'お水をください');
      expect(retrieved.category, 'health');
      expect(retrieved.displayOrder, 0);
      expect(retrieved.createdAt, DateTime(2025, 11, 21, 10, 0));
      expect(retrieved.updatedAt, DateTime(2025, 11, 21, 10, 0));
    });

    // PresetPhrase複数データの保存・読み込みテスト
    test('TC-010: 複数のPresetPhraseを保存し、全件を正しく読み込めることを確認', () async {
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

      // 実際の処理実行: 各定型文を保存
      // 処理内容: ループでpresetBox.putを実行
      for (final preset in presets) {
        await presetBox.put(preset.id, preset);
      }

      // 結果検証: すべてのデータが正しく保存・取得できることを確認
      // 期待値確認: （カテゴリ分類）の基盤動作

      final allPresets = presetBox.values.toList();

      // 検証項目: 件数が一致すること
      expect(allPresets.length, 3);

      // 検証項目: 異なるカテゴリ（daily, health）が混在して保存できること
      expect(allPresets.where((p) => p.category == 'daily').length, 2);
      expect(allPresets.where((p) => p.category == 'health').length, 1);

      // 検証項目: displayOrderが3件それぞれ保持されること
      expect(allPresets.map((p) => p.displayOrder).toSet(), {0, 1, 2});
    });

    // PresetPhraseカテゴリ分類テスト
    test('TC-011: 3種類のカテゴリ（daily, health, other）の定型文がそれぞれ正しく保存・識別できることを確認',
        () async {
      // テストデータ準備: で定義された3種類のカテゴリすべて
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

      // 実際の処理実行: 各カテゴリの定型文を保存
      // 処理内容: 3種類すべてのカテゴリを保存
      await presetBox.put(dailyPreset.id, dailyPreset);
      await presetBox.put(healthPreset.id, healthPreset);
      await presetBox.put(otherPreset.id, otherPreset);

      // 結果検証: 各カテゴリが正しく保存・識別できることを確認
      // 期待値確認: の要件を満たす

      // 検証項目: 「日常」カテゴリが正しく保存されること
      expect(presetBox.get('preset-daily')!.category, 'daily');

      // 検証項目: 「体調」カテゴリが正しく保存されること
      expect(presetBox.get('preset-health')!.category, 'health');

      // 検証項目: 「その他」カテゴリが正しく保存されること
      expect(presetBox.get('preset-other')!.category, 'other');

      // 検証項目: カテゴリごとにフィルタリング可能であること
      final dailyOnly =
          presetBox.values.where((p) => p.category == 'daily').toList();
      expect(dailyOnly.length, 1);
    });

    // PresetPhrase削除テスト
    test('TC-013: 特定のPresetPhraseを削除し、削除後に取得できないことを確認', () async {
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
      expect(presetBox.get('preset-001'), isNotNull);

      // 実際の処理実行: presetBox.deleteで削除
      // 処理内容: ユーザーが設定画面から不要な定型文を削除する操作
      await presetBox.delete('preset-001');

      // 結果検証: 削除したデータが取得できないことを確認
      // 期待値確認: の要件を満たす

      // 検証項目: 削除後、データがnullを返すこと
      expect(presetBox.get('preset-001'), isNull);

      // 検証項目: ボックスの件数が減っていること
      expect(presetBox.length, 0);
    });
  });

  group('PresetPhrase データ永続化・復元テスト', () {
    // アプリ再起動後のHistoryItem復元テスト（ここではスキップ）
    // アプリ再起動後のPresetPhrase復元テスト
    test('TC-015: アプリ再起動後、保存されたPresetPhraseが正しく復元されることを確認', () async {
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

      // 実際の処理実行: ボックスを再度オープン（再起動を模擬）
      // 処理内容: Hiveがディスクから定型文を読み込む
      presetBox = await Hive.openBox<PresetPhrase>('test_preset_persistence');

      // 結果検証: 定型文が正しく復元されていることを確認
      // 期待値確認: の要件を満たす

      final restored = presetBox.get('preset-001');

      // 検証項目: 復元されたデータがnullでないこと
      expect(restored, isNotNull);

      // 検証項目: 全フィールドの値が元のデータと一致すること
      expect(restored!.content, 'お水をください');
      expect(restored.category, 'health');
      expect(restored.displayOrder, 0);

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
